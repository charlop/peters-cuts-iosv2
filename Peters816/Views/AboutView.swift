//
//  AboutView.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  About screen with shop info and contact actions
//

import SwiftUI

struct AboutView: View {
    @StateObject private var viewModel = AboutViewModel()

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Shop hours
            VStack(spacing: 8) {
                Text("Shop Hours")
                    .font(.headline)

                Text(viewModel.shopHours)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            // Action buttons
            HStack(spacing: 20) {
                // Call button
                Button(action: viewModel.callShop) {
                    VStack {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 24))
                        Text("Call")
                            .font(.system(size: 20))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)

                // Directions button
                Button(action: viewModel.openDirections) {
                    VStack {
                        Image(systemName: "map.fill")
                            .font(.system(size: 24))
                        Text("Directions")
                            .font(.system(size: 20))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadShopInfo()
        }
    }
}

@MainActor
class AboutViewModel: ObservableObject {
    @Published var shopHours: String = "Loading..."

    private let phoneNumber = "5198162887"
    private let addressURL = "939+Wyandotte+St+E+Windsor+ON"

    func loadShopInfo() async {
        let user = User()
        shopHours = user.getHoursText()
    }

    func callShop() {
        if let url = URL(string: "tel://\(phoneNumber)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func openDirections() {
        if let url = URL(string: "http://maps.apple.com/?daddr=\(addressURL)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
