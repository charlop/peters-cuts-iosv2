//
//  ToastView.swift
//  Peters816
//
//  Toast notification for user-facing messages
//

import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType

    enum ToastType {
        case error
        case warning
        case info

        var backgroundColor: Color {
            switch self {
            case .error:
                return Color.red.opacity(0.9)
            case .warning:
                return Color.orange.opacity(0.9)
            case .info:
                return Color.blue.opacity(0.9)
            }
        }

        var icon: String {
            switch self {
            case .error:
                return "exclamationmark.triangle.fill"
            case .warning:
                return "exclamationmark.circle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)

            Text(message)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding()
        .background(type.backgroundColor)
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(.horizontal)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?

    func body(content: Content) -> some View {
        ZStack {
            content

            if let toast = toast {
                VStack {
                    Spacer()
                    ToastView(message: toast.message, type: toast.type)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                                withAnimation {
                                    self.toast = nil
                                }
                            }
                        }
                        .padding(.bottom, 20)
                }
                .animation(.spring(), value: toast)
            }
        }
    }
}

struct ToastMessage: Equatable {
    let message: String
    let type: ToastView.ToastType
    let duration: TimeInterval

    init(message: String, type: ToastView.ToastType = .info, duration: TimeInterval = 3.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}
