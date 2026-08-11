import Foundation
import SwiftData

enum PlatformFeePlan: String, Codable, CaseIterable, Identifiable {
    case none = "0%（免手续费）"
    case capped = "0.6%（60元封顶）"
    case standard = "1.6%（不封顶）"

    var id: String { rawValue }

    func fee(for grossIncome: Double) -> Double {
        switch self {
        case .none:
            return 0
        case .capped:
            return min(max(grossIncome, 0) * 0.006, 60)
        case .standard:
            return max(grossIncome, 0) * 0.016
        }
    }
}

@Model
final class Booking {
    var id: UUID
    var hotelName: String
    var checkInDate: Date
    var checkOutDate: Date
    var expectedArrival: Date
    var guestName: String
    var guestPhone: String
    var cost: Double
    var commutingCost: Double = 0
    var grossIncome: Double
    var feePlanRawValue: String
    var isIncomeReceived: Bool
    var isDepositReturned: Bool
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        hotelName: String,
        checkInDate: Date,
        checkOutDate: Date,
        expectedArrival: Date,
        guestName: String,
        guestPhone: String,
        cost: Double,
        grossIncome: Double,
        feePlan: PlatformFeePlan,
        commutingCost: Double = 0,
        isIncomeReceived: Bool = false,
        isDepositReturned: Bool = false,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.hotelName = hotelName
        self.checkInDate = checkInDate
        self.checkOutDate = checkOutDate
        self.expectedArrival = expectedArrival
        self.guestName = guestName
        self.guestPhone = guestPhone
        self.cost = cost
        self.commutingCost = commutingCost
        self.grossIncome = grossIncome
        self.feePlanRawValue = feePlan.rawValue
        self.isIncomeReceived = isIncomeReceived
        self.isDepositReturned = isDepositReturned
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var feePlan: PlatformFeePlan {
        get { PlatformFeePlan(rawValue: feePlanRawValue) ?? .capped }
        set { feePlanRawValue = newValue.rawValue }
    }

    var platformFee: Double { feePlan.fee(for: grossIncome) }
    var netIncome: Double { grossIncome - platformFee }
    var totalCost: Double { cost + commutingCost }
    var profit: Double { netIncome - totalCost }

    var numberOfNights: Int {
        max(Calendar.current.dateComponents([.day], from: checkInDate.startOfDay, to: checkOutDate.startOfDay).day ?? 0, 0)
    }

    var scheduleState: BookingScheduleState {
        let today = Date.now.startOfDay
        if checkOutDate.startOfDay <= today { return .completed }
        if checkInDate.startOfDay <= today { return .staying }
        return .upcoming
    }
}

enum BookingScheduleState: String {
    case upcoming = "待入住"
    case staying = "入住中"
    case completed = "已离店"
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}

extension Double {
    var currencyText: String {
        formatted(.currency(code: "CNY").precision(.fractionLength(0...2)))
    }
}
