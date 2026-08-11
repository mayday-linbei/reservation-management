import SwiftUI

struct DateRangePickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding private var checkInDate: Date
    @Binding private var checkOutDate: Date

    @State private var draftCheckIn: Date?
    @State private var draftCheckOut: Date?
    @State private var displayedMonth: Date

    private let calendar: Calendar

    init(checkInDate: Binding<Date>, checkOutDate: Binding<Date>) {
        _checkInDate = checkInDate
        _checkOutDate = checkOutDate

        var mondayCalendar = Calendar.current
        mondayCalendar.firstWeekday = 2
        calendar = mondayCalendar

        let start = checkInDate.wrappedValue.startOfDay
        let end = checkOutDate.wrappedValue.startOfDay
        _draftCheckIn = State(initialValue: start)
        _draftCheckOut = State(initialValue: end > start ? end : nil)
        _displayedMonth = State(initialValue: mondayCalendar.date(from: mondayCalendar.dateComponents([.year, .month], from: start)) ?? start)
    }

    private var hasCompleteRange: Bool {
        guard let draftCheckIn, let draftCheckOut else { return false }
        return draftCheckOut > draftCheckIn
    }

    private var numberOfNights: Int {
        guard let draftCheckIn, let draftCheckOut else { return 0 }
        return max(calendar.dateComponents([.day], from: draftCheckIn, to: draftCheckOut).day ?? 0, 0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                selectionSummary
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                Divider()

                monthHeader
                    .padding(.horizontal)
                    .padding(.vertical, 16)

                weekdayHeader
                    .padding(.horizontal, 12)

                calendarGrid
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                Spacer(minLength: 16)

                Text(selectionHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)

                Button {
                    applySelection()
                } label: {
                    Text(hasCompleteRange ? "确认 · \(numberOfNights) 晚" : "请选择离店日期")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasCompleteRange)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("选择入住日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private var selectionSummary: some View {
        HStack(spacing: 12) {
            SelectionDateCard(
                title: "入住",
                date: draftCheckIn,
                isActive: draftCheckIn == nil
            )

            Image(systemName: "arrow.right")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            SelectionDateCard(
                title: "离店",
                date: draftCheckOut,
                isActive: draftCheckIn != nil && draftCheckOut == nil
            )
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { moveMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 40, height: 40)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            Spacer()
            Text(displayedMonth.formatted(.dateTime.year().month(.wide)))
                .font(.title3.bold())
            Spacer()
            Button { moveMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 40, height: 40)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { weekday in
                Text(weekday)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
            ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                if let date {
                    CalendarDayCell(
                        date: date,
                        isEndpoint: isEndpoint(date),
                        isInRange: isInRange(date),
                        isToday: calendar.isDateInToday(date)
                    ) {
                        select(date)
                    }
                } else {
                    Color.clear
                        .frame(height: 42)
                }
            }
        }
    }

    private var selectionHint: String {
        if draftCheckIn == nil { return "请先选择入住日期" }
        if draftCheckOut == nil { return "再选择离店日期" }
        return "点击任意日期可重新选择范围"
    }

    private var monthCells: [Date?] {
        guard
            let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth),
            let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingEmptyCells = (weekday - calendar.firstWeekday + 7) % 7
        var cells = Array<Date?>(repeating: nil, count: leadingEmptyCells)
        cells.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        })
        return cells
    }

    private func select(_ date: Date) {
        let selectedDate = date.startOfDay

        if draftCheckIn == nil || draftCheckOut != nil {
            draftCheckIn = selectedDate
            draftCheckOut = nil
        } else if let draftCheckIn {
            if selectedDate <= draftCheckIn {
                self.draftCheckIn = selectedDate
            } else {
                draftCheckOut = selectedDate
            }
        }
    }

    private func isEndpoint(_ date: Date) -> Bool {
        if let draftCheckIn, calendar.isDate(date, inSameDayAs: draftCheckIn) { return true }
        if let draftCheckOut, calendar.isDate(date, inSameDayAs: draftCheckOut) { return true }
        return false
    }

    private func isInRange(_ date: Date) -> Bool {
        guard let draftCheckIn, let draftCheckOut else { return false }
        let value = date.startOfDay
        return value > draftCheckIn && value < draftCheckOut
    }

    private func moveMonth(by value: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    private func applySelection() {
        guard let draftCheckIn, let draftCheckOut, draftCheckOut > draftCheckIn else { return }
        checkInDate = draftCheckIn
        checkOutDate = draftCheckOut
        dismiss()
    }
}

private struct SelectionDateCard: View {
    let title: String
    let date: Date?
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(date?.formatted(.dateTime.month().day().weekday(.abbreviated)) ?? "请选择")
                .font(.subheadline.bold())
                .foregroundStyle(date == nil ? Color.secondary : Color.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isActive ? Color.accentColor.opacity(0.10) : Color(.secondarySystemGroupedBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 1.5)
        }
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let isEndpoint: Bool
    let isInRange: Bool
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(date.formatted(.dateTime.day()))
                .font(.subheadline.weight(isEndpoint ? .bold : .regular))
                .foregroundStyle(isEndpoint ? Color.white : Color.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background {
                    if isInRange {
                        Rectangle().fill(Color.accentColor.opacity(0.12))
                    }
                    if isEndpoint {
                        Circle().fill(Color.accentColor).frame(width: 40, height: 40)
                    } else if isToday {
                        Circle().stroke(Color.accentColor, lineWidth: 1).frame(width: 38, height: 38)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(isEndpoint ? .isSelected : [])
    }
}
