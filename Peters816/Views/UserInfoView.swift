//
//  UserInfoView.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  User information form with validation
//

import SwiftUI

struct UserInfoView: View {
    @StateObject private var viewModel = UserInfoViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum Field {
        case name, phone, email
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $viewModel.name)
                    .textContentType(.name)
                    .focused($focusedField, equals: .name)

                if !viewModel.isNameValid && !viewModel.name.isEmpty {
                    Text("Name must be at least 3 characters")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } header: {
                Text("Required Information")
            }

            Section {
                TextField("Phone Number", text: $viewModel.phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .focused($focusedField, equals: .phone)

                if !viewModel.isPhoneValid && !viewModel.phone.isEmpty {
                    Text("Please enter a valid phone number")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Section {
                TextField("Email (optional)", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .email)
            } header: {
                Text("Optional")
            }
        }
        .navigationTitle("User Info")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.save()
                    dismiss()
                }
                .disabled(!viewModel.isFormValid)
            }
        }
        .task {
            await viewModel.loadUserInfo()
        }
    }
}

@MainActor
class UserInfoViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var phone: String = ""
    @Published var email: String = ""

    var isNameValid: Bool {
        name.count >= 3
    }

    var isPhoneValid: Bool {
        guard phone.count >= 10 && phone.count <= 20 else {
            return false
        }

        // North American phone number regex
        let regexStr = "^(?:(?:\\+?1\\s*(?:[.-]\\s*)?)?(?:\\(\\s*([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\\s*\\)|([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\\s*(?:[.-]\\s*)?)?([2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\\s*(?:[.-]\\s*)?([0-9]{4})(?:\\s*(?:#|x\\.?|ext\\.?|extension)\\s*(\\d+))?$"

        if let regex = try? NSRegularExpression(pattern: regexStr, options: []) {
            let range = NSRange(location: 0, length: phone.utf16.count)
            return regex.firstMatch(in: phone, options: [], range: range) != nil
        }

        return false
    }

    var isFormValid: Bool {
        isNameValid && isPhoneValid
    }

    func loadUserInfo() async {
        let user = User()
        name = user.userName
        phone = user.userPhone
        email = user.userEmail
    }

    func save() {
        let user = User()
        user.saveUserDetails(name: name, phone: phone, email: email)
    }
}

#Preview {
    NavigationStack {
        UserInfoView()
    }
}
