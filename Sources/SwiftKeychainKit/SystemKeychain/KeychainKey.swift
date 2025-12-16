
// MARK: - KeychainKey

/// A unique identifier for a Keychain item.
///
/// In Apple Keychain APIs, items are looked up using a set of attributes.
/// Two of the most common attributes for "generic password" items are:
/// - `kSecAttrService` (here: `service`)
/// - `kSecAttrAccount` (here: `account`)
///
/// This type packages them into a single, `Hashable`, `Sendable` key that provides
/// a consistent way to identify keychain items across your codebase. It also provides
/// convenience aliases (`namespace` and `keyName`) for more intuitive naming.
///
/// ## Mental Model
/// Think of keychain keys as hierarchical identifiers:
/// - `service` (or `namespace`): Groups related secrets by domain/module
///   - Examples: `"com.myapp.auth"`, `"com.myapp.payments"`, `"com.company.credentials"`
/// - `account` (or `keyName`): Identifies a specific secret within that group
///   - Examples: `"userToken"`, `"refreshToken"`, `"userId:12345"`, `"api@example.com"`
///
/// ## Creating Keys
/// Two equivalent ways to create a key:
///
/// ```swift
/// // Using Keychain terminology
/// let key1 = KeychainKey(service: "com.myapp.auth", account: "userToken")
///
/// // Using application-friendly terminology (preferred)
/// let key2 = KeychainKey(namespace: "com.myapp.auth", keyName: "userToken")
///
/// // Both create identical keys
/// assert(key1 == key2)
/// ```
///
/// ## Uniqueness and Organization
/// Each unique combination of `service` and `account` represents a different keychain item.
/// You can use this to organize related secrets:
///
/// ```swift
/// let authService = "com.myapp.auth"
/// let paymentsService = "com.myapp.payments"
///
/// let userToken = KeychainKey(service: authService, account: "userToken")
/// let refreshToken = KeychainKey(service: authService, account: "refreshToken")
/// let paymentMethod = KeychainKey(service: paymentsService, account: "cardId")
/// ```
///
/// ## Thread Safety
/// `KeychainKey` is `Sendable` and can be safely shared across threads.
/// It is also `Hashable`, so it can be used as a dictionary key or in sets.
public struct KeychainKey: Hashable, Sendable {

    /// The Keychain *service* identifier.
    ///
    /// This is typically a reverse-DNS string that groups related entries. It often
    /// corresponds to your app's bundle identifier or a functional module within your app.
    ///
    /// Common patterns:
    /// - `"com.company.appname.auth"`
    /// - `"com.company.appname.api"`
    /// - `"com.company.shared.credentials"`
    ///
    /// Choose a convention and use it consistently throughout your app.
    public let service: String

    /// The Keychain *account* identifier.
    ///
    /// This identifies a specific secret within the service group. Despite its name,
    /// it is often used as a descriptive key name rather than a literal account name.
    ///
    /// Examples:
    /// - `"userToken"` for the current user's authentication token
    /// - `"refreshToken"` for OAuth refresh tokens
    /// - `"userId:12345"` to store per-user secrets
    /// - `"api@example.com"` to store credentials for a specific endpoint
    public let account: String

    /// Alias for `service` to better express intent in application code.
    ///
    /// Use this property when you want to think of the service as a "namespace"
    /// for related secrets:
    /// ```swift
    /// let key = KeychainKey(service: "com.myapp.auth", account: "token")
    /// print(key.namespace) // "com.myapp.auth"
    /// ```
    public var namespace: String { service }

    /// Alias for `account` to better express intent in application code.
    ///
    /// Use this property when you want to think of the account as a "key name":
    /// ```swift
    /// let key = KeychainKey(service: "com.myapp.auth", account: "token")
    /// print(key.keyName) // "token"
    /// ```
    public var keyName: String { account }

    /// Creates a keychain key using Keychain Services terminology.
    ///
    /// This initializer uses the native Keychain API naming convention.
    ///
    /// - Parameters:
    ///   - service: A grouping identifier that organizes related keychain items.
    ///   - account: An identifier that names a specific item within the service group.
    ///
    /// ## Example
    /// ```swift
    /// let key = KeychainKey(service: "com.myapp.auth", account: "userToken")
    /// ```
    public init(service: String, account: String) {
        self.service = service
        self.account = account
    }

    /// Creates a keychain key using application-friendly terminology.
    ///
    /// This initializer uses more intuitive naming: `namespace` for `service`
    /// and `keyName` for `account`. It creates an identical key to the equivalent
    /// `init(service:account:)` call.
    ///
    /// - Parameters:
    ///   - namespace: A grouping identifier (alias for `service`). Often a reverse-DNS string.
    ///   - keyName: A specific item identifier within the namespace (alias for `account`).
    ///
    /// ## Example
    /// ```swift
    /// let key = KeychainKey(namespace: "com.myapp.auth", keyName: "userToken")
    /// // Equivalent to: KeychainKey(service: "com.myapp.auth", account: "userToken")
    /// ```
    public init(namespace: String, keyName: String) {
        self.init(service: namespace, account: keyName)
    }
}
