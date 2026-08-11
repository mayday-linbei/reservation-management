//
//  Reservation_ManagementApp.swift
//  Reservation Management
//
//  Created by chung on 2026/8/11.
//

import SwiftUI
import SwiftData

@main
struct Reservation_ManagementApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Booking.self)
    }
}
