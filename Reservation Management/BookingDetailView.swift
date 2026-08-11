import SwiftUI
import SwiftData

struct BookingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var booking: Booking
    @State private var showEditor = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(booking.hotelName)
                        .font(.title2.bold())
                    Label(booking.scheduleState.rawValue, systemImage: scheduleIcon)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(scheduleColor)
                }
                .padding(.vertical, 6)
            }

            Section("行程") {
                DetailLine(label: "入住", value: booking.checkInDate.formatted(date: .abbreviated, time: .omitted))
                DetailLine(label: "离店", value: booking.checkOutDate.formatted(date: .abbreviated, time: .omitted))
                DetailLine(label: "晚数", value: "\(booking.numberOfNights) 晚")
                DetailLine(label: "预抵", value: booking.expectedArrival.formatted(date: .omitted, time: .shortened))
            }

            Section("客人") {
                DetailLine(label: "姓名", value: booking.guestName)
                LabeledContent("手机号") {
                    Link(booking.guestPhone, destination: URL(string: "tel:\(booking.guestPhone.filter(\.isNumber))")!)
                }
            }

            Section("收益明细") {
                DetailLine(label: "订单收入", value: booking.grossIncome.currencyText)
                DetailLine(label: "平台手续费", value: "−\(booking.platformFee.currencyText)")
                DetailLine(label: "扣费后收入", value: booking.netIncome.currencyText)
                DetailLine(label: "订单成本", value: "−\(booking.cost.currencyText)")
                DetailLine(label: "通勤费", value: "−\(booking.commutingCost.currencyText)")
                DetailLine(label: "合计成本", value: "−\(booking.totalCost.currencyText)")
                HStack {
                    Text("本单收益").fontWeight(.semibold)
                    Spacer()
                    Text(booking.profit.currencyText)
                        .font(.headline)
                        .foregroundStyle(booking.profit >= 0 ? Color.green : Color.red)
                }
                Text("手续费档位：\(booking.feePlan.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("状态") {
                Toggle(isOn: $booking.isIncomeReceived) {
                    Label("收入已到账", systemImage: booking.isIncomeReceived ? "checkmark.circle.fill" : "clock")
                }
                Toggle(isOn: $booking.isDepositReturned) {
                    Label("押金已退还", systemImage: booking.isDepositReturned ? "checkmark.circle.fill" : "exclamationmark.circle")
                }
            }
            .onChange(of: booking.isIncomeReceived) { _, _ in saveStatus() }
            .onChange(of: booking.isDepositReturned) { _, _ in saveStatus() }

            if !booking.notes.isEmpty {
                Section("备注") {
                    Text(booking.notes)
                }
            }

            Section {
                Button("删除订单", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("订单详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            BookingEditorView(booking: booking)
        }
        .confirmationDialog("确认删除这笔订单？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除订单", role: .destructive) {
                modelContext.delete(booking)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("删除后无法恢复。")
        }
    }

    private var scheduleIcon: String {
        switch booking.scheduleState {
        case .upcoming: "calendar.badge.clock"
        case .staying: "bed.double.fill"
        case .completed: "checkmark.circle.fill"
        }
    }

    private var scheduleColor: Color {
        switch booking.scheduleState {
        case .upcoming: .blue
        case .staying: .orange
        case .completed: .secondary
        }
    }

    private func saveStatus() {
        booking.updatedAt = .now
        try? modelContext.save()
    }
}

private struct DetailLine: View {
    let label: String
    let value: String

    var body: some View {
        LabeledContent(label, value: value)
    }
}
