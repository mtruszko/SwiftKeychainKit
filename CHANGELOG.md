# Changelog

All notable changes to SwiftKeychainKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-16

### Added
- Initial release of SwiftKeychainKit
- `SystemKeychain` class for synchronous keychain operations
- `KeychainKey` for uniquely identifying keychain items
- `KeychainConfiguration` for customizing keychain item accessibility and synchronization
- Support for storing and retrieving raw `Data` with `set(_:for:)` and `getData(for:)`
- Codable support with `setCodable(_:for:)` and `getCodable(_:for:)` methods
- `KeychainError` enum with semantic error types for easy error handling
- Full `Sendable` conformance for thread-safe concurrent access
- Comprehensive documentation and examples
- Support for multiple platforms:
  - iOS 13.0+
  - macOS 10.15+
  - tvOS 13.0+
  - watchOS 6.0+

### Features
- Simple, type-safe API for keychain operations
- Flexible configuration with accessibility levels and access groups
- Built-in JSON encoding/decoding for Codable types
- iCloud Keychain synchronization support
- Device-specific storage option
- App group sharing capability
- Comprehensive error handling
