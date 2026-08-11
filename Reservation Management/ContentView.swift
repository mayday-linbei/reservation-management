//
//  ContentView.swift
//  Reservation Management
//
//  Created by chung on 2026/8/11.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("概览", systemImage: "chart.pie.fill")
                }

            ScheduleView()
                .tabItem {
                    Label("排期", systemImage: "calendar")
                }

            BookingListView()
                .tabItem {
                    Label("订单", systemImage: "list.bullet.rectangle")
                }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Booking.self, inMemory: true)
}
