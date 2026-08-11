import SwiftUI

struct BookingCalendarView: View {
    let bookings: [Booking]

    @State private var displayedMonth = Date.now
    @State private var selectedDate: Date?

    private var calendar: Calendar {
        var value = Calendar.current
        value.firstWeekday = 2
        return value
    }

    private var selectedTracks: [CalendarBookingTrack] {
        guard let selectedDate else { return [] }
        return tracks(on: selectedDate, from: monthTracks)
            .sorted { $0.lane < $1.lane }
    }

    private var monthTracks: [CalendarBookingTrack] {
        guard
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)
        else { return [] }

        let relevantBookings = bookings
            .filter {
                $0.checkInDate.startOfDay < nextMonth &&
                $0.checkOutDate.startOfDay >= monthStart
            }
            .sorted {
                if $0.checkInDate != $1.checkInDate { return $0.checkInDate < $1.checkInDate }
                if $0.checkOutDate != $1.checkOutDate { return $0.checkOutDate < $1.checkOutDate }
                return $0.id.uuidString < $1.id.uuidString
            }

        var laneEnds: [Date] = []
        var tracks: [CalendarBookingTrack] = []

        for booking in relevantBookings {
            let start = booking.checkInDate.startOfDay
            let end = booking.checkOutDate.startOfDay
            let availableLane = laneEnds.firstIndex { $0 < start }
            let lane: Int

            if let availableLane {
                lane = availableLane
                laneEnds[availableLane] = end
            } else {
                lane = laneEnds.count
                laneEnds.append(end)
            }

            tracks.append(CalendarBookingTrack(
                booking: booking,
                lane: lane,
                color: trackColor(for: lane)
            ))
        }

        return tracks
    }

    private var trackLaneCount: Int {
        (monthTracks.map(\.lane).max() ?? -1) + 1
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                monthHeader
                weekdayHeader
                calendarGrid

                Divider()
                    .padding(.top, 2)

                selectedDateContent
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var monthHeader: some View {
        HStack {
            Button { moveMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.glass)

            Spacer()

            Button {
                displayedMonth = .now
                selectedDate = nil
            } label: {
                Text(displayedMonth.formatted(.dateTime.year().month(.wide)))
                    .font(.title3.bold())
            }
            .buttonStyle(.plain)

            Spacer()

            Button { moveMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.glass)
        }
        .padding(.top, 4)
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
        let tracks = monthTracks
        let laneCount = trackLaneCount
        let cellHeight = 38 + max(7, CGFloat(laneCount) * 5)

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
            spacing: 8
        ) {
            ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                if let date {
                    let dayTracks = self.tracks(on: date, from: tracks)
                    BookingCalendarDay(
                        date: date,
                        tracks: dayTracks,
                        laneCount: laneCount,
                        isToday: calendar.isDateInToday(date),
                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    ) {
                        selectedDate = date
                    }
                } else {
                    Color.clear.frame(height: cellHeight)
                }
            }
        }
    }

    @ViewBuilder
    private var selectedDateContent: some View {
        if let selectedDate {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(selectedDate.formatted(.dateTime.month().day().weekday(.wide)))
                        .font(.headline)
                    Spacer()
                    Text(selectedTracks.isEmpty ? "无订单" : "\(selectedTracks.count) 笔订单")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if selectedTracks.isEmpty {
                    Text("当天没有关联订单")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 16)
                } else {
                    ForEach(selectedTracks) { track in
                        NavigationLink(value: track.booking) {
                            CalendarBookingRow(booking: track.booking, color: track.color)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "hand.tap")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("点击带下划线的日期查看订单")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }

    private var monthCells: [Date?] {
        guard
            let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
            let days = calendar.range(of: .day, in: .month, for: firstDay)
        else { return [] }

        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingCount = (weekday - calendar.firstWeekday + 7) % 7
        var cells = Array<Date?>(repeating: nil, count: leadingCount)
        cells.append(contentsOf: days.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        })
        return cells
    }

    private func tracks(on date: Date, from tracks: [CalendarBookingTrack]) -> [CalendarBookingTrack] {
        let day = date.startOfDay
        return tracks.filter {
            day >= $0.booking.checkInDate.startOfDay &&
            day <= $0.booking.checkOutDate.startOfDay
        }
    }

    private func trackColor(for lane: Int) -> Color {
        let colors: [Color] = [.blue, .orange, .purple, .green, .pink, .cyan, .indigo, .red, .mint, .brown]
        return colors[lane % colors.count]
    }

    private func moveMonth(by value: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
        selectedDate = nil
    }
}

private struct CalendarBookingTrack: Identifiable {
    let booking: Booking
    let lane: Int
    let color: Color

    var id: UUID { booking.id }
}

private struct BookingCalendarDay: View {
    let date: Date
    let tracks: [CalendarBookingTrack]
    let laneCount: Int
    let isToday: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.day()))
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .frame(width: 34, height: 34)
                    .background {
                        if isSelected {
                            Circle().fill(Color.accentColor)
                        } else if isToday {
                            Circle().stroke(Color.accentColor, lineWidth: 1.5)
                        }
                    }

                ZStack(alignment: .top) {
                    ForEach(tracks) { track in
                        CalendarTrackLine(
                            color: track.color,
                            beginsHere: Calendar.current.isDate(date, inSameDayAs: track.booking.checkInDate),
                            endsHere: Calendar.current.isDate(date, inSameDayAs: track.booking.checkOutDate)
                        )
                        .offset(y: CGFloat(track.lane) * 5)
                    }
                }
                .frame(height: max(7, CGFloat(laneCount) * 5), alignment: .top)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(date.formatted(date: .complete, time: .omitted))，\(tracks.count)笔关联订单")
    }
}

private struct CalendarTrackLine: View {
    let color: Color
    let beginsHere: Bool
    let endsHere: Bool

    var body: some View {
        GeometryReader { proxy in
            let middle = proxy.size.width / 2
            let startX = beginsHere ? middle : 0
            let endX = endsHere ? middle : proxy.size.width

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: startX, y: 2.5))
                    path.addLine(to: CGPoint(x: endX, y: 2.5))
                }
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .butt))

                if beginsHere {
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                        .position(x: middle, y: 2.5)
                }
                if endsHere {
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                        .position(x: middle, y: 2.5)
                }
            }
        }
        .frame(height: 5)
    }
}

private struct CalendarBookingRow: View {
    let booking: Booking
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2")
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color, in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 3) {
                Text(booking.hotelName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(booking.guestName) · \(booking.numberOfNights)晚")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
