//
//  InstallCertificate.swift
//  ZeroTrust
//
//  Created by kongkaikai on 2020/10/27.
//

import Foundation
import EENavigator
import RxSwift
import LKCommonsLogging
import Swinject
import LarkRustClient
import RustPB
import LarkContainer
import RoundedHUD
import RxCocoa

struct InstallCertificateBody: CodablePlainBody {
    public static let pattern = "//client/install_certificate"

    var tenantID: String
    var version: String
    var nonce: String
    var publicKey: String
    var pkid: String
    var encryptData: String

    init?(info: [String: String]) {
        guard let tenantID = info[URLParameterKey.tenantID],
              let version = info[URLParameterKey.version],
              let nonce = info[URLParameterKey.nonce],
              let publicKey = info[URLParameterKey.publicKey],
              let pkid = info[URLParameterKey.pkid],
              let encryptData = info[URLParameterKey.encryptData] else {
            return nil
        }

        self.tenantID = tenantID
        self.version = version
        self.nonce = nonce
        self.publicKey = publicKey
        self.pkid = pkid
        self.encryptData = encryptData
    }
}

extension InstallCertificateBody {
    struct URLParameterKey {
        @inlinable static var tenantID: String { "tenant_id" }
        @inlinable static var version: String { "version" }
        @inlinable static var nonce: String { "r" }
        @inlinable static var publicKey: String { "public_key" }
        @inlinable static var pkid: String { "pkid" }
        @inlinable static var encryptData: String { "data" }
    }
}

final class InstallCertificateHandler: TypedRouterHandler<InstallCertificateBody> {
    static private let logger = Logger.log(InstallCertificateHandler.self, category: "InstallCertificateHandler")

    private let fixedTenantID = "1"
    private let fixedVersion = "1"

    private let disposeBag: DisposeBag = DisposeBag()
    @Injected private var client: RustService

    override init() {
        super.init()
    }

    public override func handle(_ body: InstallCertificateBody, req: EENavigator.Request, res: Response) {
        // 目前仅支持固定的版本： “1” 和 固定的租户: “1”，这里存在初始化时序问题，所以绕开取，直接写死。
        guard body.version == fixedVersion, body.tenantID == fixedTenantID else {
            Self.logger.error(
                "ZeroTrust: version or tenantID not support",
                additionalData: ["version": body.version, "tenantID": body.tenantID]
            )
            res.end(resource: nil)
            return
        }

        Observable.zip(decryption(with: body, from: req.from), pullConfigHost())
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
            .subscribe(onDisposed: {
                res.end(resource: nil)
            }).disposed(by: disposeBag)

        res.wait()
    }
}
// MARK: - 解密证书
private extension InstallCertificateHandler {
    /// 将URLSafe的Base64编码的字符串转成Data，部分实现参考下面的链接
    /// https://stackoverflow.com/questions/43499651/decode-base64url-to-base64-swift
    ///
    /// - Parameter urlSafeBase64String: URLSafe的Base64编码的字符串
    /// - Returns: 转换结果，nil表示解码失败
    func decode(_ urlSafeBase64String: String) -> Data? {
        var base64String = urlSafeBase64String
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let missCount = base64String.count % 4
        if missCount != 0 {
            base64String.append(String(repeating: "=", count: 4 - missCount))
        }

        return Data(base64Encoded: base64String)
    }

    /// 生成解密用的request
    @inline(__always)
    func decryptionRequest(from body: InstallCertificateBody) -> Tool_V1_DecryptSealRequest? {
        guard let pkid = decode(body.pkid),
              let publicKey = decode(body.publicKey),
              let nonce = decode(body.nonce),
              let data = decode(body.encryptData) else {
            return nil
        }

        var request = Tool_V1_DecryptSealRequest()
        request.pkid = pkid
        request.ephemeralPublickey = publicKey
        request.nonce = nonce
        request.ciphertext = data

        return request
    }

    /// 解密成功后的操作
    /// - Parameter response: client 返回的解密结果
    /// - Returns: Void
    func decryptionSuccess(from: NavigatorFrom, response: Tool_V1_DecryptSealResponse) {
        // 存在时序问题，沟通后，一期ID固定取1
        var error: Error?
        if CertTool.save(
            p12: response.plaintext,
            password: "",
            label: ZeroTrustConfig.fixedSaveP12Label,
            error: &error
        ) {
            DispatchQueue.main.async {
                if let hudOn = from.fromViewController?.view {
                    RoundedHUD.showTips(with: BundleI18n.ZeroTrust.Lark_Security_SealCertificationImported(), on: hudOn)
                }
            }
        } else {
            Self.logger.error("ZeroTrust: Save p12 failed.", error: error)
        }
    }

    /// 解密证书
    /// - Parameter body: 唤醒的body
    /// - Returns: 解密结果
    func decryption(with body: InstallCertificateBody, from: NavigatorFrom) -> Observable<Void> {
        guard let request = decryptionRequest(from: body) else {
            return .error(NSError(domain: "ZeroTrust: create decryption request failed.", code: 1, userInfo: nil))
        }

        return self.client.sendAsyncRequest(request).map { [weak self] (response: Tool_V1_DecryptSealResponse) in
            self?.decryptionSuccess(from: from, response: response)
        }
    }
}

// MARK: - 拉取 settingv3 的配置并保存到沙盒
private extension InstallCertificateHandler {
    /// 将请求 SettingV3 的 response 转换成需要的格式
    /// - Parameter response: 请求 SettingV3 的response
    /// - Returns: hosts, 字符串数组
    func transform(_ response: Settings_V1_GetSettingsResponse) -> [String] {
        guard let configContent = response.fieldGroups[ZeroTrustConfig.supportHostSettingV3Key],
              let data = configContent.data(using: .utf8) else {
            Self.logger.error("ZeroTrust: hosts, parse data failed.")
            return []
        }

        do {
            let hostMap = try JSONDecoder().decode([String: [String]].self, from: data)
            if let hosts = hostMap[ZeroTrustConfig.fixedSupportHostTenantKey] {
                return hosts
            } else {
                Self.logger.error("ZeroTrust: hosts, miss current tenant config.")
            }
        } catch {
            Self.logger.error("ZeroTrust: hosts, decode failed.", error: error)
        }

        return []
    }

    /// 保存SettingV3的配置到本地
    /// - Parameter hosts: 配置
    /// - Returns: Void
    func saveSettingV3Conig(_ hosts: [String]) {
        // 存在时序问题，沟通后，一期ID固定取1
        ZeroTrustConfig.fixedSupportHost = hosts
    }

    /// 拉取支持的域名配置
    /// - Returns: 拉取结果
    func pullConfigHost() -> Observable<Void> {
        var request = Settings_V1_GetSettingsRequest()
        request.fields = [ZeroTrustConfig.supportHostSettingV3Key]
        return self.client
            .sendSyncRequest(request, transform: self.transform)
            .map(saveSettingV3Conig)
    }
}
