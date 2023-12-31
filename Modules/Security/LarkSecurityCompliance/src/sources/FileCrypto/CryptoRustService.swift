//
//  FileCryptoGlobalRustService.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/11/21.
//

import UIKit
import LarkContainer
import LarkRustClient
import RustPB
import RustSDK
import SwiftProtobuf
import LarkSetting
import LarkSecurityComplianceInfra
import Homeric
import LKCommonsTracker
import RxSwift

final class CryptoRustService: UserResolverWrapper {
    
    struct CryptoError {
        static let globalSdkNotInit = NSError(domain: "rust_sdk_not_inited", code: 10_000)
        static let userSdkNotInit = NSError(domain: "user_rust_sdk_not_inited", code: 10_001)
    }
    
    static let logger = Logger(tag: "[file_crypto][crypto_rust]")
    
    @ScopedProvider private var rustService: RustService?
    private static let rustClient = SimpleRustClient()
    @Provider private var globalRustService: GlobalRustService // Global
    
    let userResolver: UserResolver
    
    private let downgradeBag = DisposeBag()
    private let useUserRust: Bool
    private static var isGlobalSDKInited = false
    @SafeWrapper private var isUserSDKInited = false
    @ScopedProvider private var settings: Settings?
    
    var disableSDKInitWait: Bool {
        guard (settings?.enableSecuritySettingsV2).isTrue else {
            SCLogger.info("\(SettingsImp.CodingKeys.disableSDKInitWait.rawValue) \((settings?.disableSDKInitWait).isTrue)",
                          tag: SettingsImp.logTag)
            return (settings?.disableSDKInitWait).isTrue
        }
        return SCSetting.staticBool(scKey: .disableSDKInitWait, userResolver: userResolver)
    }
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        let fg = try? userResolver.resolve(type: SCFGService.self)
        useUserRust = fg?.staticValue(.cryptoUserRust) ?? false
        observeSDKInitEvent()
        setupCipherMode()
    }
    
    // MARK: - Private
    
    /// Attention Please:
    /// 等待 SDK 初始化完毕
    /// 如果是用户态的，需要等待RustService 初始化完成
    /// 如果是全局态的，需要等待 GlobalRustService 初始化完成
    /// 检查的结果对应下面的 checkSDKPrepared() 方法
    private func observeSDKInitEvent() {
        guard !disableSDKInitWait else { return }
        if useUserRust, let rustService {
            rustService.wait { [weak self] in
                guard let self else { return }
                self.isUserSDKInited = true
                Self.logger.info("user sdk inited")
            }
        } else {
            globalRustService.wait {
                Self.isGlobalSDKInited = true
                Self.logger.info("global sdk inited")
            }
        }
    }
    
    /// 检查 SDK 初始化是否完成
    /// 如果是使用用户态，则对应 RustService 的检查
    /// 如果用的是 Global，则对应的 GlobalRustService 检查
    private func checkSDKPrepared() throws {
        if disableSDKInitWait { // settings关闭时，不走下面逻辑
            return
        }
        if useUserRust {
            guard self.isUserSDKInited else {
                throw CryptoError.userSdkNotInit
            }
        } else {
            guard Self.isGlobalSDKInited else {
                throw CryptoError.globalSdkNotInit
            }
        }
    }
    
    /// Rust 加解密是否降级开关，默认是不降级
    private var shouldDowngrade: Bool {
        do {
            let fg = try userResolver.resolve(type: FeatureGatingService.self)
            return !fg.dynamicFeatureGatingValue(with: "rust.file.crypto.downgrade.disabled")
        } catch {
            return false
        }
    }
    
    /// 完成 Rust 内部算法降级的配置 enableDowngrade：
    /// true: 使用 v1 算法
    /// false: 使用 v2 算法
    private func setupCipherMode() {
        guard let rustService else { return }
        let enableDowngrade = shouldDowngrade
        Self.logger.info("set crypto downgrade mode begin: \(enableDowngrade)")
        var updateFileSettingRequest = Security_V1_UpdateFileSettingRequest()
        updateFileSettingRequest.downgrade = enableDowngrade
        rustService.async(message: updateFileSettingRequest)
            .subscribe(onNext: { (_: Security_V1_UpdateFileSettingResponse) in
                Self.logger.info("set crypto downgrade mode end: \(enableDowngrade)")
            })
            .disposed(by: downgradeBag)
    }
    
    // MARK: - Public
    /// 移动端加密功能是否开启
    /// - Returns: true:开启；false:关闭
    func isEnabled() throws -> Bool {
        try checkSDKPrepared()
        if useUserRust, let rustService {
            let request = Security_V1_FileSecurityQueryStatusV2Request()
            let response: Security_V1_FileSecurityQueryStatusV2Response = try rustService.sync(message: request, allowOnMainThread: true)
            Self.logger.info("enabled from user: \(response.mode)")
            return response.mode == 1
        } else {
            let request = Security_V1_FileSecurityQueryStatusRequest()
            let response: Security_V1_FileSecurityQueryStatusResponse = try Self.rustClient.sync(message: request)
            Self.logger.info("enabled from global: \(response.mode)")
            return response.mode == 1
        }
    }
    
    func deviceKey(uid: Int64, did: Int64) throws -> Data {
        try checkSDKPrepared()
        if useUserRust, let rustService {
            var request = Security_V1_FileSecurityQueryStatusV2Request()
            request.did = did
            request.uid = uid
            let response: Security_V1_FileSecurityQueryStatusV2Response = try rustService.sync(message: request, allowOnMainThread: true)
            Self.logger.info("deviceKey from user")
            return response.deviceKey
        } else {
            var request = Security_V1_FileSecurityQueryStatusRequest()
            request.did = did
            request.uid = uid
            let response: Security_V1_FileSecurityQueryStatusResponse = try Self.rustClient.sync(message: request)
            Self.logger.info("deviceKey from global")
            return response.deviceKey
        }
    }
    
    func encryptDir(_ path: String) throws -> String {
        try checkSDKPrepared()
        if useUserRust {
            var request = Security_V1_FileSecurityEncryptDirV2Request()
            request.dirPath = path
            let response: Security_V1_FileSecurityEncryptDirV2Response = try sendSyncRequest(request, path: path)
            Self.logger.info("encrypt dir from user : \(response.hasEncryptedDirPath)")
            return response.encryptedDirPath
        } else {
            var request = Security_V1_FileSecurityEncryptDirRequest()
            request.dirPath = path
            let response: Security_V1_FileSecurityEncryptDirResponse = try sendSyncRequest(request, path: path)
            Self.logger.info("encrypt dir from global : \(response.hasEncryptedDirPath)")
            return response.encryptedDirPath
        }
    }
    
    func encryptFile(_ path: String) throws -> String {
        try checkSDKPrepared()
        if useUserRust {
            var request = Security_V1_FileSecurityEncryptV2Request()
            request.filePath = path
            let response: Security_V1_FileSecurityEncryptV2Response = try sendSyncRequest(request, path: path)
            Self.logger.info("encrypt file from user : \(response.hasEncryptedFilePath)")
            return response.encryptedFilePath
        } else {
            var request = Security_V1_FileSecurityEncryptRequest()
            request.filePath = path
            let response: Security_V1_FileSecurityEncryptResponse = try sendSyncRequest(request, path: path)
            Self.logger.info("encrypt file from global : \(response.hasEncryptedFilePath)")
            return response.encryptedFilePath
        }
    }
    
    func decryptDir(_ path: String) throws -> String {
        try checkSDKPrepared()
        if useUserRust {
            var request = Security_V1_FileSecurityDecryptDirV2Request()
            request.dirPath = path
            let response: Security_V1_FileSecurityDecryptDirV2Response = try sendSyncRequest(request, path: path)
            Self.logger.info("decrypt dir from user : \(response.hasDecryptedDirPath)")
            return response.decryptedDirPath
        } else {
            var request = Security_V1_FileSecurityDecryptDirRequest()
            request.dirPath = path
            let response: Security_V1_FileSecurityDecryptDirResponse = try sendSyncRequest(request, path: path)
            Self.logger.info("decrypt dir from global : \(response.hasDecryptedDirPath)")
            return response.decryptedDirPath
        }
    }
    
    func decryptFile(_ path: String) throws -> String {
        try checkSDKPrepared()
        if useUserRust {
            var request = Security_V1_FileSecurityDecryptV2Request()
            request.filePath = path
            let response: Security_V1_FileSecurityDecryptV2Response = try sendSyncRequest(request, path: path)
            Self.logger.info("decrypt file from user : \(response.hasDecryptedFilePath)")
            return response.decryptedFilePath
        } else {
            var request = Security_V1_FileSecurityDecryptRequest()
            request.filePath = path
            let response: Security_V1_FileSecurityDecryptResponse = try sendSyncRequest(request, path: path)
            Self.logger.info("decrypt file from global : \(response.hasDecryptedFilePath)")
            return response.decryptedFilePath
        }
    }
    
    func writeBackPath(_ stagePath: String) throws -> String {
        try checkSDKPrepared()
        if useUserRust {
            var request = Security_V1_FileSecurityWriteBackV2Request()
            request.stagePath = stagePath
            let response: Security_V1_FileSecurityWriteBackV2Response = try sendSyncRequest(request, path: stagePath)
            Self.logger.info("write back file from user : \(response.hasEncryptedPath)")
            return response.encryptedPath
        } else {
            var request = Security_V1_FileSecurityWriteBackRequest()
            request.stagePath = stagePath
            let response: Security_V1_FileSecurityWriteBackResponse = try sendSyncRequest(request, path: stagePath)
            Self.logger.info("write back file from global : \(response.hasEncryptedPath)")
            return response.encryptedPath
        }
    }
    
    private func sendSyncRequest<Request, Response>(_ request: Request, path: String?) throws -> Response where Request: Message, Response: Message {
        let response: Response
        do {
            if useUserRust, let rustService {
                response = try rustService.sync(message: request, allowOnMainThread: true)
            } else {
                response = try Self.rustClient.sync(message: request)
            }
        } catch {
            Self.logger.error("Error to call rust cipher method, error: \(error)")
            throw error
        }
        // 错误码V1：https://bytedance.larkoffice.com/docs/doccnGYiClNNTHbi54FyaiNRq03
        // 错误码V3：https://bytedance.larkoffice.com/wiki/MGCZwmowWiUo9EkbDHjcHvsdnpk
        let fileAlreadyEncrypted = 10_301
        if let errorCode = (response as? ErrorCodeConvertible)?.error, errorCode != 0, errorCode != fileAlreadyEncrypted {
            Tracker.post(TeaEvent(Homeric.DISK_FILE_CIPHER_ERROR, params: ["error_code": errorCode]))
            var larkError = LarkError()
            larkError.code = errorCode
            let rcError = RCError.businessFailure(errorInfo: BusinessErrorInfo(larkError))
            Self.logger.error("rust crypto error: \(rcError)", additionalData: ["path": path ?? ""])
            throw RCError.businessFailure(errorInfo: BusinessErrorInfo(larkError))
        } else {
            return response
        }
    }
}

private protocol ErrorCodeConvertible {
    var error: Int32 { get }
}

// Global Rust PB
extension Security_V1_FileSecurityEncryptDirResponse: ErrorCodeConvertible {}

extension Security_V1_FileSecurityEncryptResponse: ErrorCodeConvertible {}

extension Security_V1_FileSecurityDecryptDirResponse: ErrorCodeConvertible {}

extension Security_V1_FileSecurityDecryptResponse: ErrorCodeConvertible {}

extension Security_V1_FileSecurityWriteBackResponse: ErrorCodeConvertible {}
// Global Rust PB

// User Rust PB
extension Security_V1_FileSecurityEncryptDirV2Response: ErrorCodeConvertible {}

extension Security_V1_FileSecurityEncryptV2Response: ErrorCodeConvertible {}

extension Security_V1_FileSecurityDecryptDirV2Response: ErrorCodeConvertible {}

extension Security_V1_FileSecurityDecryptV2Response: ErrorCodeConvertible {}

extension Security_V1_FileSecurityWriteBackV2Response: ErrorCodeConvertible {}
// User Rust PB
