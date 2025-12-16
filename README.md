# SwiftKeychainKit

A simple, modern, and type-safe Swift wrapper for iOS/macOS Keychain Services. SwiftKeychainKit provides an elegant interface for storing and retrieving sensitive data like passwords, tokens, and encryption keys with minimal boilerplate.

## Features

- **Simple API**: Store, retrieve, and delete keychain items with straightforward methods
- **Codable Support**: Built-in support for encoding/decoding any `Codable` type
- **Flexible Configuration**: Control accessibility levels, access groups, and iCloud synchronization
- **Thread-Safe**: Full `Sendable` conformance for concurrent access patterns
- **Type-Safe**: Leverages Swift's type system to prevent keychain key collisions
- **Comprehensive Error Handling**: Semantic error types for easy error handling

## Installation

### Swift Package Manager

Add SwiftKeychainKit to your `Package.swift`:

```swift
.package(url: "https://github.com/your-org/SwiftKeychainKit.git", from: "1.0.0")
```

Or in Xcode: File → Add Packages → Enter the repository URL

### Platform Support

- iOS 13.0+
- macOS 10.15+
- tvOS 13.0+
- watchOS 6.0+

## Quick Start

### Basic Usage

```swift
import SwiftKeychainKit

let keychain = SystemKeychain()
let key = KeychainKey(service: "com.myapp.auth", account: "userToken")

// Store data
try keychain.set("secret-token".data(using: .utf8)!, for: key)

// Retrieve data
if let data = try keychain.getData(for: key),
   let token = String(data: data, encoding: .utf8) {
    print("Token: \(token)")
}

// Delete data
try keychain.delete(for: key)
```

### Using Codable (Optional)

SwiftKeychainKit includes built-in support for `Codable` types, making it easy to store structured data:

```swift
struct AuthToken: Codable {
    let token: String
    let expiresAt: Date
}

let keychain = SystemKeychain()
let key = KeychainKey(service: "com.myapp.auth", account: "authToken")

// Store a Codable value
let token = AuthToken(token: "abc123", expiresAt: Date().addingTimeInterval(3600))
try keychain.setCodable(token, for: key)

// Retrieve and decode
if let retrieved = try keychain.getCodable(AuthToken.self, for: key) {
    print("Token: \(retrieved.token)")
}
```

## Core Concepts

### KeychainKey

A `KeychainKey` uniquely identifies an item in the keychain using two components:

- **service** (or `namespace`): A grouping identifier, typically a reverse-DNS string like `"com.myapp.auth"`
- **account** (or `keyName`): The specific item identifier within that group, like `"userToken"`

```swift
// Using Keychain terminology
let key1 = KeychainKey(service: "com.myapp.auth", account: "userToken")

// Using application-friendly terminology (equivalent)
let key2 = KeychainKey(namespace: "com.myapp.auth", keyName: "userToken")

// Both create identical keys
assert(key1 == key2)
```

### KeychainConfiguration

Control how keychain items are stored:

```swift
let config = KeychainConfiguration(
    accessibility: .afterFirstUnlockThisDeviceOnly,
    accessGroup: nil,
    synchronizable: false
)

let keychain = SystemKeychain(config: config)
```

#### Accessibility Levels

- **`whenUnlocked`**: Most restrictive. Only accessible while device is unlocked.
- **`afterFirstUnlock`**: Accessible after first unlock until reboot. Suitable for background access.
- **`whenUnlockedThisDeviceOnly`**: Like `whenUnlocked` but device-specific; won't migrate to new devices.
- **`afterFirstUnlockThisDeviceOnly`** (default): Best balance—device-specific but allows background access.

#### Configuration Examples

```swift
// Device-specific (no iCloud sync)
let config = KeychainConfiguration(
    accessibility: .whenUnlockedThisDeviceOnly,
    synchronizable: false
)

// Share between apps in an app group
let config = KeychainConfiguration(
    accessGroup: "group.com.company.appgroup",
    accessibility: .afterFirstUnlockThisDeviceOnly
)

// Sync via iCloud Keychain
let config = KeychainConfiguration(
    accessibility: .afterFirstUnlock,
    synchronizable: true
)
```

## API Reference

### SystemKeychain

A synchronous wrapper for keychain operations. Use this for most cases.

#### Methods

##### `set(_ data: Data, for key: KeychainKey)`

Stores data in the keychain, creating a new item or updating an existing one.

```swift
let keychain = SystemKeychain()
let key = KeychainKey(service: "com.myapp.auth", account: "password")
try keychain.set("mySecret".data(using: .utf8)!, for: key)
```

**Throws**: `KeychainError` on failure

##### `getData(for key: KeychainKey) -> Data?`

Retrieves data from the keychain.

```swift
let keychain = SystemKeychain()
let key = KeychainKey(service: "com.myapp.auth", account: "password")
if let data = try keychain.getData(for: key) {
    let password = String(data: data, encoding: .utf8)
}
```

**Returns**: The stored data, or `nil` if the item doesn't exist

**Throws**: `KeychainError` on failure

##### `delete(for key: KeychainKey)`

Deletes a keychain item.

```swift
let keychain = SystemKeychain()
let key = KeychainKey(service: "com.myapp.auth", account: "password")
try keychain.delete(for: key)
```

**Throws**: `KeychainError` on failure (except "not found" errors are ignored)

##### `setCodable<T: Encodable>(_ value: T, for key: KeychainKey, encoder: JSONEncoder)`

Stores a `Codable` value after JSON encoding.

```swift
struct Credentials: Codable {
    let username: String
    let password: String
}

let creds = Credentials(username: "user", password: "pass")
let keychain = SystemKeychain()
let key = KeychainKey(service: "com.myapp", account: "credentials")
try keychain.setCodable(creds, for: key)
```

**Parameters**:
- `value`: The value to store
- `key`: The keychain key
- `encoder`: JSON encoder (optional, defaults to `JSONEncoder()`)

**Throws**: `KeychainError` or encoding errors

##### `getCodable<T: Decodable>(_ type: T.Type, for key: KeychainKey, decoder: JSONDecoder) -> T?`

Retrieves and decodes a `Codable` value from the keychain.

```swift
let keychain = SystemKeychain()
let key = KeychainKey(service: "com.myapp", account: "credentials")
if let creds = try keychain.getCodable(Credentials.self, for: key) {
    print("Username: \(creds.username)")
}
```

**Parameters**:
- `type`: The type to decode into
- `key`: The keychain key
- `decoder`: JSON decoder (optional, defaults to `JSONDecoder()`)

**Returns**: The decoded value, or `nil` if the item doesn't exist

**Throws**: `KeychainError` or decoding errors

### Error Handling

SwiftKeychainKit provides semantic error types through `KeychainError`:

```swift
public enum KeychainError: Error {
    case notFound                      // Item not found
    case duplicateItem                 // Item already exists
    case unexpectedData                // Data format issue
    case unexpectedStatus(OSStatus)    // System error
}
```

#### Error Handling Example

```swift
let keychain = SystemKeychain()
let key = KeychainKey(service: "com.myapp", account: "token")

do {
    try keychain.set(data, for: key)
} catch KeychainError.notFound {
    print("Item doesn't exist")
} catch KeychainError.duplicateItem {
    print("Item already exists")
} catch KeychainError.unexpectedData {
    print("Data is corrupted or invalid")
} catch let KeychainError.unexpectedStatus(status) {
    print("Keychain error with status: \(status)")
}
```

## Best Practices

### 1. Use Consistent Naming for Keys

Establish a naming convention for services and accounts:

```swift
enum KeychainNamespace {
    static let auth = "com.myapp.auth"
    static let payments = "com.myapp.payments"
}

let tokenKey = KeychainKey(service: KeychainNamespace.auth, account: "accessToken")
let refreshKey = KeychainKey(service: KeychainNamespace.auth, account: "refreshToken")
```

### 2. Handle Not Found Gracefully

Not finding an item isn't necessarily an error:

```swift
let keychain = SystemKeychain()
let key = KeychainKey(service: "com.myapp", account: "token")

do {
    if let data = try keychain.getData(for: key) {
        // Use the data
    } else {
        // No token stored yet—prompt user to login
    }
} catch {
    // Handle actual errors
    print("Keychain error: \(error)")
}
```

### 3. Choose Appropriate Accessibility Levels

```swift
// For highly sensitive data
let sensitiveConfig = KeychainConfiguration(
    accessibility: .whenUnlockedThisDeviceOnly
)

// For background access (default)
let standardConfig = KeychainConfiguration(
    accessibility: .afterFirstUnlockThisDeviceOnly
)

// For data that should sync across devices
let syncConfig = KeychainConfiguration(
    accessibility: .afterFirstUnlock,
    synchronizable: true
)
```

### 4. Use Codable for Complex Data

Store structured data as JSON instead of raw bytes:

```swift
struct AuthState: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

let keychain = SystemKeychain()
let key = KeychainKey(service: "com.myapp", account: "authState")

// Store
let state = AuthState(accessToken: "...", refreshToken: "...", expiresAt: Date())
try keychain.setCodable(state, for: key)

// Retrieve
if let state = try keychain.getCodable(AuthState.self, for: key) {
    // Use state
}
```

### 5. Clean Up on Logout

Always delete keychain items when users log out:

```swift
func logout() throws {
    let keychain = SystemKeychain()
    let authKey = KeychainKey(service: "com.myapp.auth", account: "accessToken")
    let refreshKey = KeychainKey(service: "com.myapp.auth", account: "refreshToken")

    try keychain.delete(for: authKey)
    try keychain.delete(for: refreshKey)
}
```

## Synchronization and Device Binding

### iCloud Keychain

Enable synchronization to sync items across the user's devices:

```swift
let config = KeychainConfiguration(
    accessibility: .afterFirstUnlock,
    synchronizable: true
)

let keychain = SystemKeychain(config: config)
```

**Important**: Items with `ThisDeviceOnly` accessibility cannot be synchronized, even if `synchronizable: true` is set.

### Device-Specific Storage

Store items only on the current device:

```swift
let config = KeychainConfiguration(
    accessibility: .afterFirstUnlockThisDeviceOnly,
    synchronizable: false
)

let keychain = SystemKeychain(config: config)
```

## Thread Safety

All SwiftKeychainKit types are `Sendable` and thread-safe at the system level. You can safely share `SystemKeychain` instances across threads:

```swift
let keychain = SystemKeychain()

// Safe to use from multiple threads
Task {
    try keychain.set(data1, for: key1)
}

Task {
    try keychain.set(data2, for: key2)
}
```

## Troubleshooting

### "Item not found" Error

This is not always an error—it means the item hasn't been stored yet:

```swift
if let data = try keychain.getData(for: key) {
    // Item exists
} else {
    // Item not found—first time setup
}
```

### Data Encoding Issues

Ensure your `Codable` types are properly defined:

```swift
// Make sure all properties are Codable
struct MyData: Codable {
    let text: String
    let number: Int
    // Avoid non-Codable properties like Data or Date without custom encoding
}
```

### Accessibility and Background Operations

If you need background access (e.g., for push notifications), use `.afterFirstUnlock*` accessibility:

```swift
let config = KeychainConfiguration(
    accessibility: .afterFirstUnlockThisDeviceOnly
)
```

### App Group Sharing

To share keychain items between apps, configure the access group in Xcode and use the same group identifier:

```swift
let config = KeychainConfiguration(
    accessGroup: "group.com.company.appgroup"
)
```

Both apps must have the same team ID and the "Keychain Sharing" capability enabled.

## License

SwiftKeychainKit is available under the MIT License.
