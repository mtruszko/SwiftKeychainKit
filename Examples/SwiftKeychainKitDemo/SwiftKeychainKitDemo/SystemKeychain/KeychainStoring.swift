import SwiftKeychainKit
import Foundation

protocol KeychainStoring {
    func set(_ data: Data, for key: KeychainKey) throws
    func getData(for key: KeychainKey) throws -> Data?
    func delete(for key: KeychainKey) throws
}

extension SystemKeychain: KeychainStoring {}

