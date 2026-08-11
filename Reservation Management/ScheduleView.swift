import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Query(sort: \Booking.checkInDate) private var bookings: [Booking]
    @State private var selectedMonth = Date.now
    @State private var showEditor = false

    private var monthBookings: [Booking] {
        bookings.filter { Calendar.current.isDate($0.checkInDate, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var groupedBookings: [(Date, [Booking])] {
        Dictionary(grouping: monthBookings) { $0.checkInDate.startOfDay }
            .map { ($0.key, $0.value) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MonthSelector(month: $selectedMonth)
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                if monthBookings.isEmpty {
                    ContentUnavailableView(
                        "本月暂无排期",
                        systemImage: "calendar",
                        description: Text("选择其他月份或添加一笔新订单。")
                    )
                } else {
                    List {
                        ForEach(groupedBookings, id: \.0) { date, items in
                            Section {
                                ForEach(items) { booking in
                                    NavigationLink(value: booking) {
                                        ScheduleRow(booking: booking)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(date.formatted(.dateTime.month().day()))
                                    Text(date.formatted(.dateTime.weekday(.wide)))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("入住排期")
            .navigationDestination(for: Booking.self) { booking in
                BookingDetailView(booking: booking)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showEditor = true } label: {
                        Label("新增订单", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                BookingEditorView()
            }
        }
    }
}

private struct MonthSelector: View {
    @Binding var month: Date

    var body: some View {
        HStack {
            Button { move(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.glass)
            Spacer()
            Button {
                month = .now
            } label: {
                Text(month.formatted(.dateTime.year().month(.wide)))
                    .font(.headline)
            }
            .buttonStyle(.plain)
            Spacer()
            Button { move(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.glass)
        }
    }

    private func move(by value: Int) {
        month = Calendar.current.date(byAdding: .month, value: value, to: month) ?? month
    }
}

private struct ScheduleRow: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(stateColor)
                .frame(width: 4, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(booking.hotelName).font(.headline).lineLimit(1)
                Text("\(booking.guestName) · \(booking.expectedArrival.formatted(date: .omitted, time: .shortened)) 预抵")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(booking.numberOfNights)晚").font(.subheadline.weight(.medium))
                Text(booking.scheduleState.rawValue)
                    .font(.caption2)
                    .foregroundStyle(stateColor)
            }
        }
        .padding(.vertical, 4)
    }

    private var stateColor: Color {
        switch booking.scheduleState {
        case .upcoming: .blue
        case .staying: .orange
        case .completed: .gray
        }
    }
}
