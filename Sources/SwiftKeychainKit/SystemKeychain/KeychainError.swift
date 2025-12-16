import Foundation
import Security


// MARK: - KeychainError

/// Errors that can occur during keychain operations.
///
/// These errors wrap the underlying Security framework status codes into more semantic
/// Swift errors that are easier to handle and display to users.
///
/// ## Common Error Scenarios
/// - **`notFound`**: Item lookup failed. Typically means the item doesn't exist.
///   Use this to differentiate between "item not found" and other errors.
/// - **`duplicateItem`**: Attempted to add an item with a key that already exists.
///   Use `set(_:for:)` instead of `add(_:for:)` to handle both create and update cases.
/// - **`unexpectedData`**: The keychain returned data in an unexpected format.
///   This usually indicates a corrupted keychain item or a mismatch in stored data.
/// - **`unexpectedStatus(_:)`**: An unexpected system error occurred. The embedded `OSStatus`
///   can be used for detailed error handling or debugging.
///
/// ## Handling Errors
/// ```swift
/// let keychain = SystemKeychain()
/// let key = KeychainKey(service: "com.app", account: "token")
///
/// do {
///     try keychain.set(data, for: key)
/// } catch KeychainError.notFound {
///     print("Item doesn't exist")
/// } catch KeychainError.duplicateItem {
///     print("Item already exists")
/// } catch KeychainError.unexpectedData {
///     print("Data is corrupted or invalid")
/// } catch let KeychainError.unexpectedStatus(status) {
///     print("Keychain error with status: \(status)")
/// } catch {
///     print("Other error: \(error)")
/// }
/// ```
public enum KeychainError: Error, Equatable, Sendable {
    /// The requested item was not found in the keychain.
    ///
    /// This error occurs when trying to retrieve or delete an item that doesn't exist.
    /// It is not necessarily fatal—you may want to treat it as "no stored value" and
    /// handle it gracefully (e.g., prompt for user input).
    case notFound

    /// An item with the same key already exists.
    ///
    /// This error occurs when attempting to add a new keychain item with a key (service/account pair)
    /// that is already in use. To update an existing item, use `set(_:for:)` instead of
    /// the internal `add(_:for:)` method, or delete the old item first.
    case duplicateItem

    /// The data retrieved from the keychain was not in the expected format.
    ///
    /// This error indicates that the keychain returned data, but it could not be cast to `Data`
    /// or was otherwise malformed. This may suggest corruption or that the wrong accessor method
    /// was used for the stored item type.
    case unexpectedData

    /// An unexpected Security framework error occurred.
    ///
    /// This catches any `OSStatus` error codes from the Security framework that don't map
    /// to one of the specific cases above. Common status codes include:
    /// - `errSecParam`: Invalid parameters
    /// - `errSecAllocate`: Memory allocation failure
    /// - `errSecPermissions`: Permission denied
    /// - `errSecNotAvailable`: Keychain service not available
    ///
    /// - Parameter status: The raw `OSStatus` code from the Security framework.
    case unexpectedStatus(OSStatus)
}

extension KeychainError: LocalizedError {
    /// A human-readable description of the error.
    ///
    /// This property provides localized error messages suitable for display to users or logging.
    /// For `unexpectedStatus` errors, it attempts to retrieve the system's localized description
    /// using `SecCopyErrorMessageString` (available on iOS 11.3+).
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "Keychain item not found."
        case .duplicateItem:
            return "Keychain item already exists."
        case .unexpectedData:
            return "Keychain returned unexpected data."
        case .unexpectedStatus(let status):
            return "Keychain error (OSStatus: \(status)) - \(Self.describe(status) ?? "Unknown")"
        }
    }

    /// Attempts to retrieve the system's localized description for an `OSStatus`.
    ///
    /// Uses `SecCopyErrorMessageString` when available (iOS 11.3+) to get a human-readable
    /// error message from the Security framework.
    ///
    /// - Parameter status: The `OSStatus` code.
    /// - Returns: A localized error message, or `nil` if unavailable.
    private static func describe(_ status: OSStatus) -> String? {
        if #available(iOS 11.3, tvOS 11.3, watchOS 4.3, macOS 10.3, *) {
            return (SecCopyErrorMessageString(status, nil) as String?)
        } else {
            return nil
        }
    }
}
