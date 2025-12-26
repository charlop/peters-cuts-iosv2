//
//  PhoneVerificationView.swift
//  Peters816
//
//  SMS verification flow for authentication
//

import SwiftUI

struct PhoneVerificationView: View {
    @StateObject private var viewModel = PhoneVerificationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Image("logo1")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280)
                        .padding(.top, 40)

                    Text("Welcome to Peter's Haircuts")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    if viewModel.step == .phoneEntry {
                        phoneEntrySection
                    } else {
                        codeEntrySection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .opacity(viewModel.isLoading ? 0.5 : 1.0)

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuth in
            if isAuth {
                dismiss()
            }
        }
        .toast($viewModel.toast)
    }

    private var phoneEntrySection: some View {
        VStack(spacing: 20) {
            Text("Enter your phone number to continue")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            TextField("Phone Number", text: $viewModel.phoneNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .font(.title3)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .autocorrectionDisabled()

            Button(action: {
                Task { await viewModel.sendCode() }
            }) {
                Text("Send Code")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(viewModel.phoneNumber.isEmpty)
            .opacity(viewModel.phoneNumber.isEmpty ? 0.5 : 1.0)
        }
    }

    private var codeEntrySection: some View {
        VStack(spacing: 20) {
            Text("Enter the 6-digit code sent to")
                .font(.body)
                .foregroundColor(.secondary)

            Text(viewModel.phoneNumber)
                .font(.headline)

            TextField("000000", text: $viewModel.verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .autocorrectionDisabled()

            Button(action: {
                Task { await viewModel.verifyCode() }
            }) {
                Text("Verify Code")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(viewModel.verificationCode.count != 6)
            .opacity(viewModel.verificationCode.count != 6 ? 0.5 : 1.0)

            Button(action: {
                Task { await viewModel.sendCode() }
            }) {
                Text("Resend Code")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .disabled(viewModel.resendTimer > 0)
            .opacity(viewModel.resendTimer > 0 ? 0.5 : 1.0)

            if viewModel.resendTimer > 0 {
                Text("Resend in \(viewModel.resendTimer)s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                viewModel.step = .phoneEntry
                viewModel.verificationCode = ""
            }) {
                Text("Change Phone Number")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

@MainActor
class PhoneVerificationViewModel: ObservableObject {
    enum Step {
        case phoneEntry
        case codeEntry
    }

    @Published var step: Step = .phoneEntry
    @Published var phoneNumber: String = ""
    @Published var verificationCode: String = ""
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var resendTimer: Int = 0
    @Published var toast: ToastMessage?

    private let authService = AuthService.shared
    private var codeId: String?
    private var timer: Timer?

    init() {
        // Pre-fill phone number from User Info if available
        let user = User()
        if user.userInfoExists {
            phoneNumber = user.userPhone
        }
    }

    func sendCode() async {
        print("sendCode entry. Phone: \(phoneNumber)")
        guard !phoneNumber.isEmpty else { return }
        
        print("Past guard")
        // Check reachability first
        let hasConnection = await Reachability.isConnectedToNetwork()
        
        print("Has connection?")
        if !hasConnection {
            toast = ToastMessage(message: "No internet connection. Please check your network.", type: .error, duration: 4.0)
            return
        }

        print("Yes")
        isLoading = true
        defer { isLoading = false }

        do {
            // First check device trust
            print("check device trust")
            let isTrusted = try await authService.checkDeviceTrust(phoneNumber: phoneNumber)

            print("isTrusted? \(isTrusted)")
            if isTrusted {
                isAuthenticated = true
                return
            }

            print("Continuing to SMS...")
            // Device not trusted, send SMS code
            codeId = try await authService.sendVerificationCode(phoneNumber: phoneNumber)
            print("codeId \(codeId ?? "X")")
            step = .codeEntry
            print("step: codeEntry")
            startResendTimer()
            print("timer started")
        } catch let error as APIClientError {
            let message: String
            switch error {
            case .networkError(let underlying) where underlying.localizedDescription.contains("hostname"):
                message = "Server unavailable. Please try again later."
            default:
                message = error.localizedDescription
            }
            toast = ToastMessage(message: message, type: .error, duration: 4.0)
        } catch {
            toast = ToastMessage(message: error.localizedDescription, type: .error, duration: 4.0)
        }
    }

    func verifyCode() async {
        guard let codeId = codeId, verificationCode.count == 6 else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.verifyCode(codeId: codeId, code: verificationCode, name: nil)
            isAuthenticated = true
        } catch let error as APIClientError {
            let message: String
            switch error {
            case .networkError(let underlying) where underlying.localizedDescription.contains("hostname"):
                message = "Server unavailable. Please try again later."
            case .httpError(_, let serverMessage):
                message = serverMessage
            default:
                message = error.localizedDescription
            }
            toast = ToastMessage(message: message, type: .error, duration: 4.0)
            verificationCode = ""
        } catch {
            toast = ToastMessage(message: error.localizedDescription, type: .error, duration: 4.0)
            verificationCode = ""
        }
    }

    private func startResendTimer() {
        timer?.invalidate()
        resendTimer = 60

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                self.resendTimer -= 1
                if self.resendTimer <= 0 {
                    self.timer?.invalidate()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PhoneVerificationView()
    }
}
