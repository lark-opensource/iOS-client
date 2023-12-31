//
//  CertTool.swift
//  ZeroTrust
//
//  Created by kongkaikai on 2020/10/26.
//

import Foundation
import LarkStorage

/// 证书解析工具
public struct CertTool {
    private static var hasCertKey = "ZeroTrust.hasCert"

    private static var hasCert: Bool {
        get {
            let store = KVStores.mmkv(space: .global, domain: Domain.fun.network)
            return store.value(forKey: hasCertKey) ?? true
        }
        set {
            let store = KVStores.mmkv(space: .global, domain: Domain.fun.network)
            store.set(newValue, forKey: hasCertKey)
        }
    }

    static func save(p12: Data, password: String, label: String, error: inout Error?) -> Bool {
        var items: CFArray?

        let importError = SecPKCS12Import(
            p12 as CFData,
            [kSecImportExportPassphrase as String: password] as CFDictionary,
            &items
        )

        guard importError == errSecSuccess else {
            error = NSError(domain: "ZeroTrust: Failed to import p12", code: Int(importError), userInfo: nil)
            return false
        }

        guard let info = (items as? [Any])?.first as? [String: Any] else {
            error = NSError(domain: "ZeroTrust: Import p12 get none itmes", code: -1, userInfo: nil)
            return false
        }

        // swiftlint:disable force_cast
        let identity = info[kSecImportItemIdentity as String] as! SecIdentity
        // swiftlint:enable force_cast

        let addIdentityQuery = [
            kSecAttrLabel: label,
            kSecValueRef: identity
        ] as CFDictionary

        let addResult = SecItemAdd(addIdentityQuery, nil)

        if addResult == errSecDuplicateItem {
            SecItemDelete(addIdentityQuery)
            let addResult = SecItemAdd(addIdentityQuery, nil)
            if addResult != errSecSuccess {
                error = NSError(domain: "ZeroTrust: Failed to add item", code: Int(addResult), userInfo: nil)
                return false
            }
        }

        let isSuccess = addResult == errSecSuccess
        hasCert = isSuccess
        if isSuccess {
            return true
        }

        error = NSError(domain: "ZeroTrust: Failed to add item", code: Int(addResult), userInfo: nil)
        return false
    }

    /// 证书读取结果 （identuty, 证书数组, 私钥）
    public typealias Result = (identity: SecIdentity, certificates: [SecCertificate], key: SecKey)

    /// 读取证书和私钥
    /// - Parameter label: 存证书的label
    /// - Returns: 读取结果，失败则返回nil
    public static func read(with label: String) -> Result? {
        var error: Error?
        return read(with: label, error: &error)
    }

    /// 读取证书和私钥
    /// - Parameters:
    ///   - label: 存证书的label
    ///   - error: error handler
    /// - Returns: 读取结果，失败则返回nil
    public static func read(with label: String, error: inout Error?) -> Result? {
        guard hasCert else {
            return nil
        }

        let idQuery: [CFString: Any] = [
            kSecAttrLabel: label,
            kSecClass: kSecClassIdentity,
            kSecReturnRef: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitAll
        ]

        var result: CFTypeRef?

        let copyError = SecItemCopyMatching(idQuery as CFDictionary, &result)
        guard copyError == errSecSuccess else {
            error = NSError(domain: "ZeroTrust: Failed to query indentity", code: Int(copyError), userInfo: nil)
            hasCert = false
            return nil
        }

        guard let identityRef = (result as? [Any])?.first else {
            error = NSError(domain: "ZeroTrust: Get nil when query indentity", code: -1, userInfo: nil)
            hasCert = false
            return nil
        }

        // swiftlint:disable force_cast
        let identity = identityRef as! SecIdentity
        // swiftlint:enable force_cast

        var inoutCert: SecCertificate?
        var inoutKey: SecKey?

        let statusCopyCert = SecIdentityCopyCertificate(identity, &inoutCert)
        guard statusCopyCert == errSecSuccess else {
            error = NSError(domain: "ZeroTrust: Failed to copy cert", code: Int(statusCopyCert), userInfo: nil)
            hasCert = false
            return nil
        }

        let statusCopyKey = SecIdentityCopyPrivateKey(identity, &inoutKey)
        guard statusCopyKey == errSecSuccess else {
            error = NSError(domain: "ZeroTrust: Failed to copy private key", code: Int(statusCopyKey), userInfo: nil)
            hasCert = false
            return nil
        }

        guard let certificate = inoutCert else {
            error = NSError(domain: "ZeroTrust: Get nil when copy cert", code: -1, userInfo: nil)
            hasCert = false
            return nil
        }

        guard let privateKey = inoutKey else {
            error = NSError(domain: "ZeroTrust: Get nil when copy private key", code: -1, userInfo: nil)
            hasCert = false
            return nil
        }

        hasCert = true
        return (identity, [certificate], privateKey)
    }

    /// 密钥 转 二进制
    /// - Parameter key: 密钥
    /// - Returns: 转换结果，失败则为 nil
    public static func data(from key: SecKey) -> Data? {
        SecKeyCopyExternalRepresentation(key, nil) as Data?
    }

    /// 证书 转 二级制
    /// - Parameter cert: 证书
    /// - Returns: 转换结果
    public static func data(from cert: SecCertificate) -> Data {
        SecCertificateCopyData(cert) as Data
    }
}
