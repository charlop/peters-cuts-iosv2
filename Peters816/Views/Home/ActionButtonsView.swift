//
//  ActionButtonsView.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Action buttons for booking and cancellation
//

import SwiftUI

struct ActionButtonsView: View {
    let currentState: AppointmentStatus
    @Binding var haircutCount: Int
    let onGetNumber: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            switch currentState {
            case .loadingView:
                ProgressView("Loading...")

            case .noUserInfo:
                Text("Please tap User Info above to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()

            case .noAppointment:
                // Haircut count stepper
                HStack(spacing: 12) {
                    Text("Number of haircuts:")
                        .font(.body)

                    HStack(spacing: 8) {
                        Button(action: {
                            if haircutCount > 1 {
                                haircutCount -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(haircutCount > 1 ? .blue : .gray)
                        }
                        .disabled(haircutCount <= 1)

                        Text("\(haircutCount)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(minWidth: 30)

                        Button(action: {
                            if haircutCount < 4 {
                                haircutCount += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(haircutCount < 4 ? .blue : .gray)
                        }
                        .disabled(haircutCount >= 4)
                    }
                }
                .padding(.horizontal)

                Button(action: onGetNumber) {
                    Text("Get A Number!")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .glassButtonStyle()
                .padding(.horizontal)

                NavigationLink(value: NavigationDestination.reservation) {
                    Text("Make a Reservation")
                        .font(.system(size: 17))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .glassButtonStyle()
                .padding(.horizontal)

            case .hasNumber, .hasReservation:
                Button(action: onCancel) {
                    Text("Cancel Appointment")
                        .font(.system(size: 17))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.horizontal)

            case .shopClosed:
                // No buttons when shop is closed
                EmptyView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        VStack(spacing: 40) {
            ActionButtonsView(
                currentState: .noAppointment,
                haircutCount: .constant(1),
                onGetNumber: {},
                onCancel: {}
            )

            ActionButtonsView(
                currentState: .hasNumber,
                haircutCount: .constant(1),
                onGetNumber: {},
                onCancel: {}
            )
        }
        .padding()
    }
}
