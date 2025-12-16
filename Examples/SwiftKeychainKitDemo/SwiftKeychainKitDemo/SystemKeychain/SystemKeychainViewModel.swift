import Observation
import SwiftUI
import SwiftKeychainKit
import Foundation

@MainActor
@Observable
final class SystemKeychainViewModel {
    var secretText: String = ""
    var retrievedSecret: String? = nil
    var toast: Toast? = nil
    var isBusy: Bool = false
    
    @ObservationIgnored private let keychain: KeychainStoring
    @ObservationIgnored private let secretKey: KeychainKey
    
    init(
        keychain: KeychainStoring = SystemKeychain(),
        secretKey: KeychainKey = .init(namespace: "com.swiftkeychainkitdemo.auth", keyName: "userSecret")
    ) {
        self.keychain = keychain
        self.secretKey = secretKey
    }
    
    func save() async {
        let input = self.secretText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        await self.perform(
            successMessage: "Secret saved successfully",
            autoHideSeconds: 2
        ) { [keychain, secretKey] in
            try keychain.set(Data(input.utf8), for: secretKey)
        } onSuccess: {
            self.secretText = ""
        }
    }
    
    func load() async {
        await self.perform(autoHideSeconds: 2) { [keychain, secretKey] in
            try keychain.getData(for: secretKey)
        } onSuccess: { data in
            guard
                let data,
                let secret = String(data: data, encoding: .utf8)
            else {
                self.toastNow(.info, "No secret found", autoHideSeconds: 2)
                return
            }
            
            self.retrievedSecret = secret
            self.toastNow(.success, "Secret loaded successfully", autoHideSeconds: 2)
        }
    }
    
    func delete() async {
        await self.perform(
            successMessage: "Secret deleted successfully",
            autoHideSeconds: 2
        ) { [keychain, secretKey] in
            try keychain.delete(for: secretKey)
        } onSuccess: {
            self.retrievedSecret = nil
        }
    }
    
    func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
        self.toastNow(.success, "Copied to clipboard", autoHideSeconds: 2)
    }
    
    // MARK: - Helpers
    
    private func perform(
        successMessage: String? = nil,
        autoHideSeconds: UInt64,
        _ work: @escaping () throws -> Void,
        onSuccess: @escaping () -> Void = {}
    ) async {
        await self.perform(
            autoHideSeconds: autoHideSeconds,
            { try work(); return () },
            onSuccess: { _ in
                onSuccess()
                if let successMessage {
                    self.toastNow(.success, successMessage, autoHideSeconds: autoHideSeconds)
                }
            }
        )
    }
    
    private func perform<T>(
        autoHideSeconds: UInt64,
        _ work: @escaping () throws -> T,
        onSuccess: @escaping (T) -> Void
    ) async {
        guard !self.isBusy else { return }
        self.isBusy = true
        defer { self.isBusy = false }
        
        do {
            let value = try await Task.detached(priority: .userInitiated) {
                try work()
            }.value
            
            onSuccess(value)
        } catch {
            self.toastNow(.error, "Error: \(error.localizedDescription)", autoHideSeconds: 3)
        }
    }
    
    private func toastNow(_ kind: Toast.Kind, _ message: String, autoHideSeconds: UInt64) {
        withAnimation {
            self.toast = .init(kind: kind, message: message)
        }
        
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: autoHideSeconds * 1_000_000_000)
            await MainActor.run {
                withAnimation {
                    self?.toast = nil
                }
            }
        }
    }
}
