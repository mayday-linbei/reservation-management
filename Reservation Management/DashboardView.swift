import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Booking.checkInDate) private var bookings: [Booking]
    @State private var showEditor = false

    private var calendar: Calendar { .current }

    private var thisMonthBookings: [Booking] {
        bookings.filter { calendar.isDate($0.checkInDate, equalTo: .now, toGranularity: .month) }
    }

    private var upcomingBookings: [Booking] {
        Array(bookings
            .filter { $0.checkOutDate.startOfDay > Date.now.startOfDay }
            .prefix(5))
    }

    private var totalProfit: Double { bookings.reduce(0) { $0 + $1.profit } }
    private var monthProfit: Double { thisMonthBookings.reduce(0) { $0 + $1.profit } }
    private var receivable: Double {
        bookings.filter { !$0.isIncomeReceived }.reduce(0) { $0 + $1.netIncome }
    }
    private var pendingIncomeCount: Int { bookings.filter { !$0.isIncomeReceived }.count }
    private var pendingDeposits: Int { bookings.filter { !$0.isDepositReturned }.count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ProfitSummaryView(
                        monthTitle: Date.now.formatted(.dateTime.year().month(.wide)),
                        monthProfit: monthProfit,
                        totalProfit: totalProfit,
                        orderCount: thisMonthBookings.count
                    )
                    .padding(18)
                    .glassEffect(
                        .regular.tint(Color.blue.opacity(0.08)),
                        in: .rect(cornerRadius: 26)
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("待处理") {
                    DashboardMetricRow(
                        title: "收入待到账",
                        value: receivable.currencyText,
                        detail: "\(pendingIncomeCount) 笔订单",
                        systemImage: "creditcard",
                        color: .orange
                    )
                    DashboardMetricRow(
                        title: "押金待退还",
                        value: "\(pendingDeposits) 笔",
                        detail: pendingDeposits == 0 ? "全部处理完成" : "请及时核对",
                        systemImage: "arrow.uturn.backward.circle",
                        color: .purple
                    )
                }

                Section("近期排期") {
                    if upcomingBookings.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("暂无近期订单")
                                .font(.headline)
                            Text("添加订单后，近期入住安排会显示在这里。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(upcomingBookings) { booking in
                            NavigationLink(value: booking) {
                                DashboardBookingRow(booking: booking)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.10),
                        Color(.systemGroupedBackground),
                        Color.purple.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .navigationTitle("概览")
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

private struct ProfitSummaryView: View {
    let monthTitle: String
    let monthProfit: Double
    let totalProfit: Double
    let orderCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(monthTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("本月收益")
                        .font(.headline)
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 42, height: 42)
                    .background(Color.blue.opacity(0.12), in: Circle())
            }

            Text(monthProfit.currencyText)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(monthProfit >= 0 ? Color.primary : Color.red)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.75)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("累计收益")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(totalProfit.currencyText)
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("本月订单")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(orderCount) 笔")
                        .font(.headline)
                }
            }

            Text("收益已扣除平台手续费与订单成本")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}

private struct DashboardMetricRow: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct DashboardBookingRow: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text(booking.checkInDate.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(booking.checkInDate.formatted(.dateTime.day()))
                    .font(.title3.bold())
            }
            .frame(width: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(booking.hotelName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text("\(booking.guestName) · \(booking.numberOfNights)晚 · \(booking.expectedArrival.formatted(date: .omitted, time: .shortened))预抵")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}
