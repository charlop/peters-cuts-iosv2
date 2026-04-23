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
        ScrollView {
            VStack(spacing: 24) {
                // Banner image
                Image("appBanner")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .padding(.top, 16)

                // Shop address
                VStack(spacing: 8) {
                    Text("Peter's Hair Salon")
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let address = viewModel.address, !address.isEmpty {
                        Text(address)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("1501 Tecumseh Road East")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Text("(across from Koolini's)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .multilineTextAlignment(.center)

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
                HStack(spacing: 16) {
                    // Call button
                    Button(action: viewModel.callShop) {
                        Label("Call", systemImage: "phone.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    // Directions button
                    Button(action: viewModel.openDirections) {
                        Label("Directions", systemImage: "map.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Divider()
                    .padding(.vertical, 8)

                // Legal links
                VStack(spacing: 16) {
                    NavigationLink(value: NavigationDestination.termsOfUse) {
                        Text("Terms of Use")
                            .font(.body)
                    }

                    NavigationLink(value: NavigationDestination.privacyPolicy) {
                        Text("Privacy Policy")
                            .font(.body)
                    }
                }
            }
            .padding(.horizontal)
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
    @Published var address: String?
    @Published var phone: String?

    private let apiClient = APIClientV2.shared
    private let fallbackPhone = "5198162887"
    private let fallbackAddressURL = "1501+Tecumseh+Road+East+Windsor+ON"

    func loadShopInfo() async {
        let user = User()
        shopHours = user.getHoursText()

        if let response: AddressResponse = try? await apiClient.request(.configAddress) {
            address = response.address.isEmpty ? nil : response.address
            phone = response.phone.isEmpty ? nil : response.phone
        }
    }

    func callShop() {
        let digits = phone?.filter(\.isNumber) ?? fallbackPhone
        if let url = URL(string: "tel:\(digits)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func openDirections() {
        let encodedAddress = address?
            .replacingOccurrences(of: "\n", with: " ")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            ?? fallbackAddressURL
        if let url = URL(string: "http://maps.apple.com/?daddr=\(encodedAddress)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
