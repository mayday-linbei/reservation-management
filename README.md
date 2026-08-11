# Reservation Management

A Chinese-language iOS and iPadOS app for managing hotel reservations, guest stays, payment status, deposits, and booking profitability. The app is displayed as **旅乞管家** on the device.

## Features

- Dashboard with monthly and total profit, outstanding income, pending deposits, and upcoming stays
- Create, edit, and delete reservations with guest, hotel, date, arrival-time, cost, income, and note fields
- Automatic platform-fee, total-cost, and profit calculations in CNY
- Monthly schedule and calendar views, including overlapping booking tracks
- Search by hotel, guest, phone number, or notes
- Filter bookings by upcoming stays, unpaid income, and unreturned deposits
- Update payment and deposit status from booking details or list actions
- Local persistence with SwiftData

## Tech Stack

- Swift
- SwiftUI
- SwiftData
- Xcode 26
- iOS 26

No third-party dependencies are required.

## Requirements

- Xcode 26 or later
- iOS or iPadOS 26.0 or later

## Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/linbeiwanglei/reservation-management.git
   ```

2. Open `Reservation Management.xcodeproj` in Xcode.
3. Select an iPhone or iPad simulator running iOS 26, or configure your development team to run on a physical device.
4. Run the `Reservation Management` scheme.

## Data Storage

Reservation data is stored locally on the device using SwiftData. The project currently has no backend or account system.
