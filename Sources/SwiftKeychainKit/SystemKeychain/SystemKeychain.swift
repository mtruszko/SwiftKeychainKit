import Foundation
import Security

// MARK: - SystemKeychain

/// A synchronous wrapper around the iOS/macOS Keychain Services API.
///
/// `SystemKeychain` provides a simple, type-safe interface for storing and retrieving
/// sensitive data in the system keychain. It supports raw `Data` storage as well as
/// `Codable` types for convenience.
///
/// ## Overview
/// The keychain is the recommended place to store small amounts of sensitive data
/// such as passwords, tokens, and encryption keys. Unlike `UserDefaults`, keychain
/// data is encrypted and persists even when the app is deleted (unless using
/// `ThisDeviceOnly` accessibility).
///
/// ## Example
/// ```swift
/// let keychain = SystemKeychain()
/// let key = KeychainKey(service: "com.myapp", account: "apiToken")
///
/// // Store data
/// try keychain.set("secret-token".data(using: .utf8)!, for: key)
///
/// // Retrieve data
/// if let data = try keychain.getData(for: key),
///    let token = String(data: data, encoding: .utf8) {
///     print("Token: \(token)")
/// }
///
/// // Delete data
/// try keychain.delete(for: key)
/// ```
///
/// ## Thread Safety
/// Keychain operations are thread-safe at the system level, but consider using
/// ``AsyncKeychain`` or ``SystemKeychainCombine`` for concurrent access patterns.
public final class SystemKeychain: Sendable {
    /// The configuration used for keychain operations.
    public let config: KeychainConfiguration

    /// Creates a new keychain instance with the specified configuration.
    ///
    /// - Parameter config: The configuration for keychain operations.
    ///   Defaults to a standard configuration with `.afterFirstUnlockThisDeviceOnly` accessibility.
    public init(config: KeychainConfiguration = .init()) {
        self.config = config
    }

    // MARK: - Public API (sync)

    /// Stores data in the keychain, creating a new item or updating an existing one.
    ///
    /// This method attempts to update an existing item first. If the item doesn't exist
    /// (indicated by a `notFound` error), it creates a new one instead. This behavior
    /// provides a convenient "set or create" semantics.
    ///
    /// - Parameters:
    ///   - data: The raw data to store in the keychain.
    ///   - key: The unique identifier for this keychain item.
    ///
    /// - Throws: ``KeychainError`` if the operation fails (e.g., permission issues,
    ///   security policy violations).
    ///
    /// - Note: The keychain uses the configuration's accessibility settings to control
    ///   when the data can be retrieved.
    ///
    /// ## Example
    /// ```swift
    /// let keychain = SystemKeychain()
    /// let key = KeychainKey(service: "com.myapp", account: "password")
    /// try keychain.set("mySecret".data(using: .utf8)!, for: key)
    /// ```
    public func set(_ data: Data, for key: KeychainKey) throws {
        do {
            try update(data, for: key, allowSynchronizableFallback: false)
        } catch KeychainError.notFound {
            try add(data, for: key)
        } catch {
            throw error
        }
    }

    /// Retrieves data from the keychain.
    ///
    /// This method first attempts to retrieve data according to the strict synchronization
    /// settings. If not found, it falls back to searching for items regardless of their
    /// synchronization state, which handles cases where items may have been stored
    /// with different synchronization settings.
    ///
    /// - Parameter key: The unique identifier for the keychain item.
    ///
    /// - Returns: The data stored for this key, or `nil` if no item exists.
    ///
    /// - Throws: ``KeychainError`` if the retrieval operation fails (e.g., permission issues,
    ///   format problems).
    ///
    /// ## Example
    /// ```swift
    /// let keychain = SystemKeychain()
    /// let key = KeychainKey(service: "com.myapp", account: "password")
    /// if let data = try keychain.getData(for: key) {
    ///     let password = String(data: data, encoding: .utf8)
    ///     print("Password: \(password ?? "invalid encoding")")
    /// }
    /// ```
    public func getData(for key: KeychainKey) throws -> Data? {
        do {
            return try copyMatchingData(for: key, synchronizableMode: .strict)
        } catch KeychainError.notFound {
            return try? copyMatchingData(for: key, synchronizableMode: .any)
        }
    }

    /// Deletes a keychain item.
    ///
    /// This method first attempts to delete an item according to the strict synchronization
    /// settings. If not found, it falls back to deleting regardless of synchronization state.
    /// This gracefully handles cases where the item doesn't exist and situations where
    /// synchronization states may have changed.
    ///
    /// - Parameter key: The unique identifier for the keychain item to delete.
    ///
    /// - Throws: ``KeychainError`` if the deletion operation fails due to permission issues
    ///   or other security policy violations. Note: does not throw if the item is not found.
    ///
    /// ## Example
    /// ```swift
    /// let keychain = SystemKeychain()
    /// let key = KeychainKey(service: "com.myapp", account: "password")
    /// try keychain.delete(for: key)
    /// ```
    public func delete(for key: KeychainKey) throws {
        do {
            try deleteItem(for: key, synchronizableMode: .strict)
        } catch KeychainError.notFound {
            try? deleteItem(for: key, synchronizableMode: .any)
        }
    }

    // MARK: - Codable convenience

    /// Stores a `Codable` value in the keychain.
    ///
    /// The value is encoded to JSON before storage.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The unique identifier for this keychain item.
    ///   - encoder: The JSON encoder to use. Defaults to a standard encoder.
    /// - Throws: ``KeychainError`` if the operation fails, or encoding errors.
    public func setCodable<T: Encodable>(_ value: T, for key: KeychainKey, encoder: JSONEncoder = .init()) throws {
        try set(encoder.encode(value), for: key)
    }

    /// Retrieves and decodes a `Codable` value from the keychain.
    ///
    /// - Parameters:
    ///   - type: The type to decode the stored data into.
    ///   - key: The unique identifier for the keychain item.
    ///   - decoder: The JSON decoder to use. Defaults to a standard decoder.
    /// - Returns: The decoded value, or `nil` if no item exists for the key.
    /// - Throws: ``KeychainError`` if the operation fails, or decoding errors.
    public func getCodable<T: Decodable>(_ type: T.Type, for key: KeychainKey, decoder: JSONDecoder = .init()) throws -> T? {
        guard let data = try getData(for: key) else { return nil }
        return try decoder.decode(type, from: data)
    }

    // MARK: - Private Helpers

    /// Controls how synchronizable items are matched during keychain queries.
    private enum SynchronizableMode {
        /// Match only items according to the configuration's synchronizable setting.
        case strict

        /// Match both synchronizable and non-synchronizable items.
        case any
    }

    /// Builds the base query dictionary for keychain operations.
    ///
    /// This constructs a common query used by most Keychain Services functions,
    /// including the item class, service, account, access group, and synchronization attributes.
    ///
    /// - Parameters:
    ///   - key: The keychain key specifying the service and account.
    ///   - synchronizableMode: Determines how the synchronization attribute is set.
    ///
    /// - Returns: A dictionary with Keychain query parameters ready for use with
    ///   `SecItemAdd`, `SecItemUpdate`, `SecItemDelete`, or `SecItemCopyMatching`.
    private func baseQuery(for key: KeychainKey, synchronizableMode: SynchronizableMode) -> [String: Any] {
        var q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account
        ]

        if let group = config.accessGroup {
            q[kSecAttrAccessGroup as String] = group
        }

        switch synchronizableMode {
        case .strict:
            if config.synchronizable {
                q[kSecAttrSynchronizable as String] = kCFBooleanTrue as Any
            }
        case .any:
            q[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
        }

        return q
    }

    /// Adds a new item to the keychain.
    ///
    /// This method calls `SecItemAdd` to create a new keychain entry using the
    /// configuration's accessibility settings.
    ///
    /// - Parameters:
    ///   - data: The raw data to store.
    ///   - key: The keychain key for this item.
    ///
    /// - Throws: ``KeychainError`` if the add operation fails. Common errors include
    ///   `.duplicateItem` if an item with the same key already exists.
    private func add(_ data: Data, for key: KeychainKey) throws {
        var q = baseQuery(for: key, synchronizableMode: .strict)
        q[kSecAttrAccessible as String] = config.accessibility.secValue
        q[kSecValueData as String] = data

        let status = SecItemAdd(q as CFDictionary, nil)
        if let err = mapStatus(status) { throw err }
    }

    /// Updates an existing keychain item, with optional fallback to any synchronization state.
    ///
    /// First attempts to update according to the configuration's strict synchronization
    /// setting. If `allowSynchronizableFallback` is `true` and the item is not found
    /// under strict matching, falls back to a broader search.
    ///
    /// - Parameters:
    ///   - data: The new data to store.
    ///   - key: The keychain key for this item.
    ///   - allowSynchronizableFallback: If `true`, retries with `.any` synchronization mode
    ///     on `.notFound` error.
    ///
    /// - Throws: ``KeychainError`` if the operation fails.
    private func update(_ data: Data, for key: KeychainKey, allowSynchronizableFallback: Bool) throws {
        do {
            try updateInternal(data, for: key, synchronizableMode: .strict)
        } catch KeychainError.notFound where allowSynchronizableFallback {
            try updateInternal(data, for: key, synchronizableMode: .any)
        }
    }

    /// Internal implementation of update that calls `SecItemUpdate`.
    ///
    /// - Parameters:
    ///   - data: The new data to store.
    ///   - key: The keychain key for this item.
    ///   - synchronizableMode: Controls which items are matched for updating.
    ///
    /// - Throws: ``KeychainError`` if the update fails.
    private func updateInternal(_ data: Data, for key: KeychainKey, synchronizableMode: SynchronizableMode) throws {
        let query = baseQuery(for: key, synchronizableMode: synchronizableMode) as CFDictionary
        let attrsToUpdate = [kSecValueData as String: data] as CFDictionary

        let status = SecItemUpdate(query, attrsToUpdate)
        if let err = mapStatus(status) { throw err }
    }

    /// Retrieves data from the keychain by copying the matching item.
    ///
    /// Calls `SecItemCopyMatching` and extracts the raw data. The search respects
    /// the synchronization mode settings.
    ///
    /// - Parameters:
    ///   - key: The keychain key to search for.
    ///   - synchronizableMode: Controls which items are matched.
    ///
    /// - Returns: The raw `Data` stored for this key.
    ///
    /// - Throws: ``KeychainError.notFound`` if no matching item exists,
    ///   ``KeychainError.unexpectedData`` if the returned data is malformed,
    ///   or other ``KeychainError`` variants for system errors.
    private func copyMatchingData(for key: KeychainKey, synchronizableMode: SynchronizableMode) throws -> Data {
        var query = baseQuery(for: key, synchronizableMode: synchronizableMode)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { throw KeychainError.unexpectedData }
            return data
        case errSecItemNotFound:
            throw KeychainError.notFound
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Deletes a keychain item by calling `SecItemDelete`.
    ///
    /// - Parameters:
    ///   - key: The keychain key to delete.
    ///   - synchronizableMode: Controls which items are matched for deletion.
    ///
    /// - Throws: ``KeychainError`` for errors other than "not found" (which is silently ignored).
    private func deleteItem(for key: KeychainKey, synchronizableMode: SynchronizableMode) throws {
        let status = SecItemDelete(baseQuery(for: key, synchronizableMode: synchronizableMode) as CFDictionary)
        switch status {
        case errSecSuccess, errSecItemNotFound:
            return
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Converts a Keychain Services `OSStatus` to a ``KeychainError``.
    ///
    /// Maps common Security framework status codes to semantic errors. Returns `nil`
    /// if the status indicates success.
    ///
    /// - Parameter status: The `OSStatus` from a Keychain Services call.
    /// - Returns: A ``KeychainError`` if the status indicates an error, or `nil` on success.
    private func mapStatus(_ status: OSStatus) -> KeychainError? {
        switch status {
        case errSecSuccess: return nil
        case errSecItemNotFound: return .notFound
        case errSecDuplicateItem: return .duplicateItem
        default: return .unexpectedStatus(status)
        }
    }
}
