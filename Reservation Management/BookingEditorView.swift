import SwiftUI
import SwiftData

struct BookingEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let booking: Booking?

    @State private var hotelName: String
    @State private var checkInDate: Date
    @State private var checkOutDate: Date
    @State private var expectedArrival: Date
    @State private var guestName: String
    @State private var guestPhone: String
    @State private var costText: String
    @State private var commutingCostText: String
    @State private var incomeText: String
    @State private var feePlan: PlatformFeePlan
    @State private var isIncomeReceived: Bool
    @State private var isDepositReturned: Bool
    @State private var notes: String
    @State private var showValidation = false
    @State private var showDateRangePicker = false

    init(booking: Booking? = nil) {
        self.booking = booking
        let calendar = Calendar.current
        let defaultCheckIn = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: .now) ?? .now
        let defaultCheckOut = calendar.date(byAdding: .day, value: 1, to: defaultCheckIn) ?? .now
        let defaultArrival = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: defaultCheckIn) ?? defaultCheckIn

        _hotelName = State(initialValue: booking?.hotelName ?? "")
        _checkInDate = State(initialValue: booking?.checkInDate ?? defaultCheckIn)
        _checkOutDate = State(initialValue: booking?.checkOutDate ?? defaultCheckOut)
        _expectedArrival = State(initialValue: booking?.expectedArrival ?? defaultArrival)
        _guestName = State(initialValue: booking?.guestName ?? "")
        _guestPhone = State(initialValue: booking?.guestPhone ?? "")
        _costText = State(initialValue: booking.map { String(format: "%.2f", $0.cost) } ?? "")
        _commutingCostText = State(initialValue: booking.map { String(format: "%.2f", $0.commutingCost) } ?? "0.00")
        _incomeText = State(initialValue: booking.map { String(format: "%.2f", $0.grossIncome) } ?? "")
        _feePlan = State(initialValue: booking?.feePlan ?? .capped)
        _isIncomeReceived = State(initialValue: booking?.isIncomeReceived ?? false)
        _isDepositReturned = State(initialValue: booking?.isDepositReturned ?? false)
        _notes = State(initialValue: booking?.notes ?? "")
    }

    private var parsedCost: Double? { Double(costText.replacingOccurrences(of: ",", with: "")) }
    private var parsedCommutingCost: Double? { Double(commutingCostText.replacingOccurrences(of: ",", with: "")) }
    private var parsedIncome: Double? { Double(incomeText.replacingOccurrences(of: ",", with: "")) }
    private var calculatedFee: Double { feePlan.fee(for: parsedIncome ?? 0) }
    private var calculatedTotalCost: Double { (parsedCost ?? 0) + (parsedCommutingCost ?? 0) }
    private var calculatedProfit: Double { (parsedIncome ?? 0) - calculatedFee - calculatedTotalCost }

    private var isValid: Bool {
        !hotelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !guestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !guestPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        checkOutDate.startOfDay > checkInDate.startOfDay &&
        parsedCost.map { $0 >= 0 } == true &&
        parsedCommutingCost.map { $0 >= 0 } == true &&
        parsedIncome.map { $0 >= 0 } == true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("酒店与日期") {
                    TextField("酒店名称", text: $hotelName)
                    Button {
                        showDateRangePicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("入住 — 离店")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(checkInDate.formatted(.dateTime.month().day())) — \(checkOutDate.formatted(.dateTime.month().day()))")
                                    .foregroundStyle(.primary)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            Text("\(numberOfNights)晚")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    DatePicker("客人预抵时间", selection: $expectedArrival, displayedComponents: .hourAndMinute)
                    if checkOutDate.startOfDay <= checkInDate.startOfDay {
                        Label("离店日期必须晚于入住日期", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("客人信息") {
                    TextField("客人姓名", text: $guestName)
                    TextField("手机号", text: $guestPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                Section("收支") {
                    HStack {
                        Text("订单成本")
                        Spacer()
                        TextField("0.00", text: $costText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("元").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("通勤费")
                        Spacer()
                        TextField("0.00", text: $commutingCostText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("元").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("收入")
                        Spacer()
                        TextField("0.00", text: $incomeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("元").foregroundStyle(.secondary)
                    }
                    Picker("平台手续费", selection: $feePlan) {
                        ForEach(PlatformFeePlan.allCases) { plan in
                            Text(plan.rawValue).tag(plan)
                        }
                    }
                    LabeledContent("预计手续费", value: calculatedFee.currencyText)
                        .foregroundStyle(.secondary)
                    LabeledContent("合计成本", value: calculatedTotalCost.currencyText)
                        .foregroundStyle(.secondary)
                    LabeledContent("预计收益", value: calculatedProfit.currencyText)
                        .fontWeight(.semibold)
                        .foregroundStyle(calculatedProfit >= 0 ? Color.green : Color.red)
                }

                Section("订单状态") {
                    Toggle("收入已到账", isOn: $isIncomeReceived)
                    Toggle("押金已退还", isOn: $isDepositReturned)
                }

                Section("备注") {
                    TextField("房型、确认号、特殊需求等", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                if showValidation && !isValid {
                    Section {
                        Label("请填写酒店、客人、手机号和有效金额，并检查入住日期。", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(booking == nil ? "新增订单" : "编辑订单")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showDateRangePicker) {
                DateRangePickerView(checkInDate: $checkInDate, checkOutDate: $checkOutDate)
                    .presentationDetents([.large])
            }
            .onChange(of: checkInDate) { _, newValue in
                expectedArrival = combine(date: newValue, time: expectedArrival)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var numberOfNights: Int {
        max(Calendar.current.dateComponents([.day], from: checkInDate.startOfDay, to: checkOutDate.startOfDay).day ?? 0, 0)
    }

    private func combine(date: Date, time: Date) -> Date {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        return Calendar.current.date(bySettingHour: components.hour ?? 18, minute: components.minute ?? 0, second: 0, of: date) ?? date
    }

    private func save() {
        showValidation = true
        guard isValid,
              let cost = parsedCost,
              let commutingCost = parsedCommutingCost,
              let income = parsedIncome
        else { return }

        let arrival = combine(date: checkInDate, time: expectedArrival)
        if let booking {
            booking.hotelName = hotelName.trimmingCharacters(in: .whitespacesAndNewlines)
            booking.checkInDate = checkInDate.startOfDay
            booking.checkOutDate = checkOutDate.startOfDay
            booking.expectedArrival = arrival
            booking.guestName = guestName.trimmingCharacters(in: .whitespacesAndNewlines)
            booking.guestPhone = guestPhone.trimmingCharacters(in: .whitespacesAndNewlines)
            booking.cost = cost
            booking.commutingCost = commutingCost
            booking.grossIncome = income
            booking.feePlan = feePlan
            booking.isIncomeReceived = isIncomeReceived
            booking.isDepositReturned = isDepositReturned
            booking.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            booking.updatedAt = .now
        } else {
            modelContext.insert(Booking(
                hotelName: hotelName.trimmingCharacters(in: .whitespacesAndNewlines),
                checkInDate: checkInDate.startOfDay,
                checkOutDate: checkOutDate.startOfDay,
                expectedArrival: arrival,
                guestName: guestName.trimmingCharacters(in: .whitespacesAndNewlines),
                guestPhone: guestPhone.trimmingCharacters(in: .whitespacesAndNewlines),
                cost: cost,
                grossIncome: income,
                feePlan: feePlan,
                commutingCost: commutingCost,
                isIncomeReceived: isIncomeReceived,
                isDepositReturned: isDepositReturned,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }
        try? modelContext.save()
        dismiss()
    }
}
