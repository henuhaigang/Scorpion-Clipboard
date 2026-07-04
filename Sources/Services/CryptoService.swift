import Foundation
import CryptoKit
import Security

enum CryptoService {
    private static let service = "com.scorpion.clipboard.encryption"
    private static let account = "history-key"

    static func encrypt(_ plaintext: Data) -> Data? {
        let key = getOrCreateKey()
        guard let sealedBox = try? AES.GCM.seal(plaintext, using: key) else { return nil }
        return sealedBox.combined
    }

    static func decrypt(_ ciphertext: Data) -> Data? {
        let key = getOrCreateKey()
        guard let sealedBox = try? AES.GCM.SealedBox(combined: ciphertext) else { return nil }
        return try? AES.GCM.open(sealedBox, using: key)
    }

    private static func getOrCreateKey() -> SymmetricKey {
        if let existing = loadKeyFromKeychain() { return existing }
        let key = SymmetricKey(size: .bits256)
        saveKeyToKeychain(key)
        return key
    }

    private static func loadKeyFromKeychain() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return SymmetricKey(data: data)
    }

    private static func saveKeyToKeychain(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
