import SwiftUI
import SwiftData

enum BookingFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case upcoming = "待入住"
    case incomePending = "待收款"
    case depositPending = "待退押金"

    var id: String { rawValue }
}

enum BookingViewMode: String, CaseIterable, Identifiable {
    case list = "列表"
    case calendar = "日历"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .list: "list.bullet"
        case .calendar: "calendar"
        }
    }
}

struct BookingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Booking.checkInDate) private var bookings: [Booking]
    @State private var selectedFilter: BookingFilter = .all
    @State private var searchText = ""
    @State private var showEditor = false
    @State private var viewMode: BookingViewMode = .list
    @State private var navigationPath: [Booking] = []

    private var filteredBookings: [Booking] {
        bookings.filter { booking in
            let matchesSearch = searchText.isEmpty ||
                booking.hotelName.localizedCaseInsensitiveContains(searchText) ||
                booking.guestName.localizedCaseInsensitiveContains(searchText) ||
                booking.guestPhone.localizedCaseInsensitiveContains(searchText) ||
                booking.notes.localizedCaseInsensitiveContains(searchText)
            let matchesFilter: Bool = switch selectedFilter {
            case .all: true
            case .upcoming: booking.scheduleState != .completed
            case .incomePending: !booking.isIncomeReceived
            case .depositPending: !booking.isDepositReturned
            }
            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                Picker("显示方式", selection: $viewMode) {
                    ForEach(BookingViewMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.systemImage).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)

                if viewMode == .list {
                    bookingList
                } else {
                    BookingCalendarView(bookings: filteredBookings)
                }
            }
            .navigationTitle("全部订单")
            .searchable(text: $searchText, prompt: "酒店、客人、手机号或备注")
            .navigationDestination(for: Booking.self) { booking in
                BookingDetailView(booking: booking)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("筛选订单", selection: $selectedFilter) {
                            ForEach(BookingFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                    } label: {
                        Label(selectedFilter.rawValue, systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
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

    private var bookingList: some View {
        List {
            if filteredBookings.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "没有符合条件的订单" : "没有搜索结果",
                    systemImage: searchText.isEmpty ? "tray" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "可以更换筛选条件或添加新订单。" : "请尝试其他酒店、客人、手机号或备注。")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredBookings) { booking in
                    NavigationLink(value: booking) {
                        BookingRow(booking: booking)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            booking.isIncomeReceived.toggle()
                            booking.updatedAt = .now
                            try? modelContext.save()
                        } label: {
                            Label(booking.isIncomeReceived ? "改为未到账" : "确认到账", systemImage: "creditcard")
                        }
                        .tint(booking.isIncomeReceived ? .gray : .green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(booking)
                            try? modelContext.save()
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct BookingRow: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(booking.hotelName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(booking.profit.currencyText)
                    .font(.subheadline.bold())
                    .foregroundStyle(booking.profit >= 0 ? Color.green : Color.red)
            }
            Text("\(booking.checkInDate.formatted(date: .abbreviated, time: .omitted)) – \(booking.checkOutDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !booking.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Label {
                    Text(booking.notes)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "note.text")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Label(booking.guestName, systemImage: "person")
                Spacer()
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        OrderStatusLabel(
                            text: booking.isIncomeReceived ? "已到账" : "待收款",
                            systemImage: booking.isIncomeReceived ? "checkmark.circle.fill" : "clock.fill",
                            color: booking.isIncomeReceived ? .green : .orange
                        )
                        OrderStatusLabel(
                            text: booking.isDepositReturned ? "已退押金" : "待退押金",
                            systemImage: booking.isDepositReturned ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                            color: booking.isDepositReturned ? .green : .orange
                        )
                    }
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 5)
    }
}

private struct OrderStatusLabel: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .glassEffect(.regular.tint(color.opacity(0.12)), in: .capsule)
    }
}
