import Security


// MARK: - KeychainAccessibility

/// Defines when keychain items are accessible.
///
/// These options correspond to the `kSecAttrAccessible` values in the Security framework
/// and control when the keychain item can be read and decrypted.
///
/// ## Choosing an Accessibility Level
/// - **`whenUnlocked`**: Most restrictive. Item accessible only while device is unlocked.
///   Recommended for highly sensitive data that should never be accessed in the background.
/// - **`afterFirstUnlock`**: Item accessible after first unlock until reboot.
///   Useful for data that needs background access (e.g., push notifications).
/// - **`whenUnlockedThisDeviceOnly`**: Like `whenUnlocked` but items cannot migrate to new devices
///   via backup/restore. Suitable for device-specific secrets.
/// - **`afterFirstUnlockThisDeviceOnly`**: Like `afterFirstUnlock` but device-specific.
///   Best balance for most apps—data persists but is tied to this device.
///
/// ## Migration and Device Binding
/// Items stored without `ThisDeviceOnly` will migrate when the user restores their device
/// from a backup or sets up a new device using iCloud account migration. Items with
/// `ThisDeviceOnly` remain on the original device and are not migrated.
public enum KeychainAccessibility: Sendable {
    /// The item is accessible only when the device is unlocked.
    ///
    /// Once the device locks, the item becomes inaccessible. This is the most restrictive
    /// option and is ideal for the most sensitive data.
    case whenUnlocked

    /// The item is accessible after the first unlock until the device restarts.
    ///
    /// This is useful for data that may need to be accessed while the device is locked,
    /// such as during background app refresh, push notifications, or background downloads.
    case afterFirstUnlock

    /// The item is accessible only when the device is unlocked.
    /// Items with this attribute do not migrate to a new device.
    ///
    /// Combines the restrictiveness of `whenUnlocked` with device binding.
    /// Use this for secrets that should never leave the current device.
    case whenUnlockedThisDeviceOnly

    /// The item is accessible after the first unlock until the device restarts.
    /// Items with this attribute do not migrate to a new device.
    ///
    /// This is the default accessibility level used by `SystemKeychain`.
    /// It provides a good balance: items are accessible in background scenarios
    /// but are tied to this specific device.
    case afterFirstUnlockThisDeviceOnly
    
    /// isThisDeviceOnly
    var isThisDeviceOnly: Bool {
        switch self {
        case .whenUnlockedThisDeviceOnly, .afterFirstUnlockThisDeviceOnly:
            return true
        case .whenUnlocked, .afterFirstUnlock:
            return false
        }
    }

    /// Maps this accessibility level to the corresponding Security framework constant.
    var secValue: CFString {
        switch self {
        case .whenUnlocked: return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
        case .whenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
}

// MARK: - KeychainConfiguration

/// Configuration options for keychain operations.
///
/// Use this struct to customize how keychain items are stored, including
/// their accessibility level, access group for sharing, and iCloud synchronization.
///
/// ## Creating a Configuration
/// ```swift
/// // Default configuration (recommended for most apps)
/// let config = KeychainConfiguration()
///
/// // Device-specific configuration without iCloud sync
/// let config = KeychainConfiguration(
///     accessibility: .whenUnlockedThisDeviceOnly,
///     accessGroup: nil,
///     synchronizable: false
/// )
///
/// // Shared between apps in an app group
/// let config = KeychainConfiguration(
///     accessibility: .afterFirstUnlockThisDeviceOnly,
///     accessGroup: "group.com.company.appgroup",
///     synchronizable: false
/// )
///
/// // Synchronized via iCloud Keychain
/// let config = KeychainConfiguration(
///     accessibility: .afterFirstUnlock,
///     accessGroup: nil,
///     synchronizable: true
/// )
/// ```
///
/// ## Thread Safety
/// `KeychainConfiguration` is `Sendable` and can be safely shared across threads.
public struct KeychainConfiguration: Sendable {
    /// When the keychain item is accessible.
    ///
    /// See ``KeychainAccessibility`` for details on each option.
    public let accessibility: KeychainAccessibility

    /// The access group for sharing keychain items between apps.
    ///
    /// Set this to share keychain items between apps in the same app group.
    /// All apps with the same access group value and proper entitlements can
    /// read, write, and delete items in this group.
    ///
    /// - Note: Requires the "Keychain Sharing" capability in Xcode and the same
    ///   team ID across all apps.
    public let accessGroup: String?

    /// Whether the item should be synchronized via iCloud Keychain.
    ///
    /// When `true`, the item will be synced across all devices using the same iCloud account.
    /// The user can turn off iCloud Keychain synchronization in system settings, and items
    /// with `synchronizable: true` will respect that choice.
    ///
    /// - Note: Items with `ThisDeviceOnly` accessibility cannot be synchronized, even if
    ///   this is set to `true`. When iCloud Keychain is disabled, synchronizable items
    ///   are still stored locally on the device.
    public let synchronizable: Bool

    /// Creates a new keychain configuration with the specified parameters.
    ///
    /// - Parameters:
    ///   - accessibility: When the item should be accessible. Defaults to
    ///     `.afterFirstUnlockThisDeviceOnly`, which provides the best balance
    ///     for most applications.
    ///   - accessGroup: Optional access group for sharing keychain items between apps.
    ///     The access group must be configured in your app's capabilities.
    ///   - synchronizable: Whether the item should be synchronized via iCloud Keychain.
    ///     Defaults to `false`. When `true`, items sync across all user devices but
    ///     respect the user's iCloud Keychain settings.
    ///
    /// ## Default Behavior
    /// The default configuration:
    /// - Uses `.afterFirstUnlockThisDeviceOnly` accessibility
    /// - Does not share items between apps
    /// - Does not sync via iCloud Keychain
    ///
    /// This is suitable for most apps that store device-specific secrets.
    public init(
        accessibility: KeychainAccessibility = .afterFirstUnlockThisDeviceOnly,
        accessGroup: String? = nil,
        synchronizable: Bool = false
    ) {
        if synchronizable && accessibility.isThisDeviceOnly {
            assertionFailure("ThisDeviceOnly accessibility is incompatible with synchronizable")
            self.synchronizable = false
        } else {
            self.synchronizable = synchronizable
        }
        self.accessibility = accessibility
        self.accessGroup = accessGroup
    }
}
