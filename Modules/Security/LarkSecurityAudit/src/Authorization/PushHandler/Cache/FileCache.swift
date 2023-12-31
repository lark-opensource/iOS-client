//
//  FileCache.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/12/28.
//

import Foundation
import LarkCache
import LarkAccountInterface
import LKCommonsLogging
import ServerPB
import LarkContainer
import LarkSecurityComplianceInfra
import CryptoSwift

final class SecurityCacheManager {

    static let logger = Logger.log(PullPermissionService.self, category: "SecurityAudit.Cache")

    let cache: Cache

    /// user id, 记录userId，防止切换租户串数据
    let snapshotUserId: String

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        // 初始化cache，固定cache目录
        self.userResolver = userResolver
        cache = securityComplianceCache(userResolver.userID, .securityAudit)
        let passportService = try? userResolver.resolve(assert: PassportUserService.self)
        snapshotUserId = passportService?.user.userID ?? ""
    }

    func writeCache(
        _ response: ServerPB_Authorization_PullPermissionResponse?
    ) {
        guard let resp = response else {
            Self.logger.info("no response to write")
            return
        }
        do {
            let data = try resp.serializedData()
            let encryptedData = try Utils.aes(key: snapshotUserId, op: .encrypt, data: data, padding: .pkcs7)
            let additionalData = [
                "raw_length": String(describing: data.count),
                "encrypted_length": String(describing: encryptedData.count)
            ]
            Self.logger.info(
                "serialize success",
                additionalData: additionalData
            )
            cache.set(object: encryptedData, forKey: Const.permissionCacheKeyWithPKCS7Padding)
        } catch {
            Self.logger.error("serialize fail", error: error)
            SCMonitor.info(business: .security_audit,
                           eventName: "write_cache_fail",
                           category: [
                            "error": "\(error)",
                            "padding": "pkcs7"
                           ]
            )
        }
    }

    func readCache() -> ServerPB_Authorization_PullPermissionResponse? {
        if let encryptedData: Data = cache.object(forKey: Const.permissionCacheKeyWithPKCS7Padding) {
            return decrypt(encryptedData: encryptedData, padding: .pkcs7)
        } else if let encryptedData: Data = cache.object(forKey: Const.permissionCacheKey) {
            SCMonitor.info(business: .security_audit, eventName: "zero_padding_decrypt")
            return decrypt(encryptedData: encryptedData, padding: .zeroPadding)
        } else {
            Self.logger.info("not found cache")
            return nil
        }
    }

    private func decrypt(encryptedData: Data, padding: CryptoSwift.Padding) -> ServerPB_Authorization_PullPermissionResponse? {
        do {
            let data = try Utils.aes(key: snapshotUserId, op: .decrypt, data: encryptedData, padding: padding)
            let resp = try ServerPB_Authorization_PullPermissionResponse(serializedData: data)
            Self.logger.info(
                "parse cache success",
                additionalData: ["length": String(describing: data.count)]
            )
            return resp
        } catch {
            return retryDecrypt(encryptedData: encryptedData, padding: padding)
        }
    }

    private func retryDecrypt(encryptedData: Data, padding: CryptoSwift.Padding) -> ServerPB_Authorization_PullPermissionResponse? {
        do {
            let data = try Utils.aes(key: snapshotUserId, op: .decrypt, data: encryptedData, padding: padding)
            let repairedData = repairBadDecrypedData(data: data)
            let resp = try ServerPB_Authorization_PullPermissionResponse(serializedData: repairedData)
            Self.logger.error(
                "parse cache success after retry",
                additionalData: ["length": String(describing: data.count)]
            )
            return resp
        } catch {
            Self.logger.error(
                "parse cache fail",
                additionalData: ["length": String(describing: encryptedData.count)],
                error: error
            )
            SCMonitor.info(business: .security_audit,
                           eventName: "read_cache_fail",
                           category: ["error": "\(error)",
                                      "padding": "\(padding)"]
            )
            return nil
        }
    }

    private func repairBadDecrypedData(data: Data) -> Data {
        var bytes = data.bytes
        let count = bytes.count
        let blockSize = 16
        if count % blockSize == 0 && count >= blockSize {
            var decrypedSuccess = false
            bytes.suffix(blockSize).forEach {
                if $0 != 0 {
                    decrypedSuccess = true
                    return
                }
            }
            if !decrypedSuccess {
                bytes = bytes.prefix(count - blockSize).map { $0 }
            }
        }
        return Data(bytes)
    }

    func clear() {
        Self.logger.info("Clear cache")
        cache.removeObject(forKey: Const.permissionCacheKey)
        cache.removeObject(forKey: Const.permissionCacheKeyWithPKCS7Padding)
    }
}
