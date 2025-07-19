import Foundation
import SwiftUI

// Error recovery action protocol
protocol ErrorRecoveryAction {
    var title: String { get }
    var isDestructive: Bool { get }
    func execute() async throws
}

// Common recovery actions
struct RetryAction: ErrorRecoveryAction {
    let title = "Retry"
    let isDestructive = false
    let action: () async throws -> Void
    
    func execute() async throws {
        try await action()
    }
}

struct SignInAction: ErrorRecoveryAction {
    let title = "Sign In"
    let isDestructive = false
    let navigationAction: () -> Void
    
    func execute() async throws {
        await MainActor.run {
            navigationAction()
        }
    }
}

struct CancelAction: ErrorRecoveryAction {
    let title = "Cancel"
    let isDestructive = false
    
    func execute() async throws {
        // No-op, just dismisses
    }
}

// Error recovery coordinator
class ErrorRecovery: ObservableObject {
    @Published var currentError: RecoverableError?
    @Published var isShowingError = false
    
    func handle(_ error: Error, context: String? = nil, recovery: [ErrorRecoveryAction] = []) {
        let recoverableError = RecoverableError(
            error: error,
            context: context,
            recoveryActions: recovery.isEmpty ? defaultRecoveryActions(for: error) : recovery
        )
        
        DispatchQueue.main.async {
            self.currentError = recoverableError
            self.isShowingError = true
        }
    }
    
    func dismiss() {
        DispatchQueue.main.async {
            self.isShowingError = false
            self.currentError = nil
        }
    }
    
    private func defaultRecoveryActions(for error: Error) -> [ErrorRecoveryAction] {
        var actions: [ErrorRecoveryAction] = []
        
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                // For auth errors, suggest signing in again
                actions.append(SignInAction { 
                    // Navigation to login will be handled by the view
                })
            case .networkError, .serverError, .serverErrorWithMessage:
                // For network/server errors, allow retry
                actions.append(RetryAction { 
                    // Retry action will be provided by the calling context
                })
            default:
                break
            }
        }
        
        // Always add cancel option
        actions.append(CancelAction())
        
        return actions
    }
}

// Recoverable error model
struct RecoverableError: Identifiable {
    let id = UUID()
    let error: Error
    let context: String?
    let recoveryActions: [ErrorRecoveryAction]
    let timestamp = Date()
    
    var title: String {
        if let context = context {
            return "\(context) Failed"
        }
        return "Error"
    }
    
    var message: String {
        if let apiError = error as? APIError {
            return apiError.localizedDescription
        }
        return error.localizedDescription
    }
    
    var isRetryable: Bool {
        recoveryActions.contains { $0 is RetryAction }
    }
}

// View modifier for error handling
struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject var errorRecovery: ErrorRecovery
    let onRetry: (() async -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorRecovery.currentError?.title ?? "Error",
                isPresented: $errorRecovery.isShowingError,
                presenting: errorRecovery.currentError
            ) { error in
                ForEach(Array(error.recoveryActions.enumerated()), id: \.offset) { _, action in
                    Button(action.title, role: action.isDestructive ? .destructive : nil) {
                        Task {
                            do {
                                if action is RetryAction, let onRetry = onRetry {
                                    await onRetry()
                                } else {
                                    try await action.execute()
                                }
                                errorRecovery.dismiss()
                            } catch {
                                // If recovery fails, show new error
                                errorRecovery.handle(error, context: "Recovery")
                            }
                        }
                    }
                }
            } message: { error in
                Text(error.message)
            }
    }
}

extension View {
    func handleErrors(
        with errorRecovery: ErrorRecovery,
        onRetry: (() async -> Void)? = nil
    ) -> some View {
        modifier(ErrorHandlingModifier(errorRecovery: errorRecovery, onRetry: onRetry))
    }
}

// ViewModel error handling mixin
protocol ErrorHandlingViewModel: ObservableObject {
    var errorRecovery: ErrorRecovery { get }
    var isLoading: Bool { get set }
    
    func handleError(_ error: Error, context: String?, retryAction: @escaping () async throws -> Void)
}

extension ErrorHandlingViewModel {
    func handleError(_ error: Error, context: String? = nil, retryAction: @escaping () async throws -> Void) {
        let recovery: [ErrorRecoveryAction] = [
            RetryAction(action: retryAction),
            CancelAction()
        ]
        
        errorRecovery.handle(error, context: context, recovery: recovery)
    }
    
    func withErrorHandling<T>(
        context: String? = nil,
        action: @escaping () async throws -> T
    ) async -> T? {
        do {
            return try await action()
        } catch {
            handleError(error, context: context, retryAction: {
                _ = try await action()
            })
            return nil
        }
    }
}