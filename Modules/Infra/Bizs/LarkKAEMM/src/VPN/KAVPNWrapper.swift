//
//  Interface.swift
//  SFSDKToLarkDemo
//
//  Created by guhaowei on 2021/9/2.
//

import UIKit
import Foundation
import LKCommonsLogging
import SangforSDK
import LarkAppConfig
import LarkAccountInterface
import LarkContainer
import LarkSetting

struct VPNConfig: Decodable {
    let vpnDomain: String
}

final class KAVPNWrapper: NSObject {
    private static let logger = Logger.log(KAVPNWrapper.self, category: "Module.KAVPNWrapper")
    #if !targetEnvironment(simulator)
    // SDK初始化和setAuthResultDelegate注册
    private lazy var sdk: SFMobileSecuritySDK? = {
        if KAVPNInitTask.initResult {
            SFMobileSecuritySDK.sharedInstance().setAuthResultDelegate(self)
            return SFMobileSecuritySDK.sharedInstance()
        }
        Self.logger.error("KAVPN: SDK init failed")
        return nil
    }()

    // 读取SDK状态方法
    private var sdkStatus: SFAuthStatus {
        SFMobileSecuritySDK.sharedInstance().getAuthStatus()
    }
    // 免密登录标志位
    private var isSSHLogin: Bool = false
    // 免密登录三次失败计数器
    private var failedTime: Int = 0
    // 回调存储
    private var sshLoginHandler: CompletionHanlder?
    private var passwordLoginHandler: CompletionHanlder?
    private var isInBackground: Bool = false
    #endif

    /// SDK 登出踢出飞书的回调
    var mainAppLogout: (() -> Void)?

    override init() {
        super.init()
        #if targetEnvironment(simulator)
        assert(false, "Only supports debug with real machine.")
        #else
        addAppStatusObserver()
        #endif
    }
}

#if targetEnvironment(simulator)
// 处理模拟器构建失败问题
extension KAVPNWrapper: KAVPNWrapperInterface {
    func ticketAuth(_ completion: CompletionHanlder?) {
        assert(false, "Only supports debug with real machine.")
        completion?(.success(""))
    }
}
#else
extension KAVPNWrapper: KAVPNWrapperInterface {
    private var vpnConfig: VPNConfig? {
        do {
            let config = try SettingManager.shared.setting(with: VPNConfig.self, key: UserSettingKey.make(userKeyLiteral: "vpn_config"))
            Self.logger.info("KAEMM: Get config form LarkSetting.")
            return config
        } catch {
            Self.logger.error("KAEMM: vpnConfig拉取失败", error: error)
            return nil
        }
    }
    /// 登录 VPN SDK
    /// - Parameters:
    ///   - config: 登录的参数，使用枚举数组是为方便更新或者插入新的配置
    ///   - completion: 登录结果回调
    func login(with configs: [VPNLoginConfig], _ completion: CompletionHanlder?) {
        guard let sdk = sdk else { return }

        isSSHLogin = false
        passwordLoginHandler = completion

        var userName: String?
        var password: String?

        for config in configs {
            switch config {
            case .account(let account):
                userName = account
            case .password(let string):
                password = string
            }
        }

        guard let userName = userName, let password = password else {
            let error = NSError(domain: "Miss login config(username or password)", code: 1, userInfo: nil)
            completion?(.failure(error as Error))
            Self.logger.error("KAVPN: miss login config.", error: error)
            return
        }

        guard let domain = self.vpnConfig?.vpnDomain,
              let url = URL(string: "https://\(domain)") else {
            Self.logger.error("KAVPN: Read domain failed or URL init with domain failed.")
            return
        }

        if sdk.startPasswordAuth(url, userName: userName, password: password) {
            Self.logger.info("KAVPN: Start VPN login success.")
        } else {
            completion?(.failure(NSError(domain: "VPN login failed.", code: 1, userInfo: nil)))
            Self.logger.error("KAVPN: Start VPN login failed.")
        }
    }

    /// 登出EMM方法
    func logout() {
        SFMobileSecuritySDK.sharedInstance().logout()
        Self.logger.info("KAVPN: VPN logout")
    }
}

extension KAVPNWrapper {
    /// 免密登录
    /// - Parameter completion: 回调结果
    func ticketAuth(_ completion: CompletionHanlder?) {
        guard let sdk = sdk else { return }

        sshLoginHandler = completion

        isSSHLogin = true
        Self.logger.info("KAVPN: SFSDKTickAuth called")
        // 免密登录
        if sdk.supportTicketAuth() {
            Self.logger.info("KAVPN: supportTicketAuth success")
            sdk.startTicketAuth()
            Self.logger.info("KAVPN: startTicketAuth start")
        } else {
            completion?(.failure(NSError(domain: "VPN login failed.", code: 1, userInfo: nil)))
        }
    }
}

// BaseMessage结构抽象,只用errorCode和errorMessage
private extension BaseMessage {
    var error: NSError {
        NSError(domain: errStr, code: errCode.rawValue, userInfo: nil)
    }
}

// 实现SFAuthResultDelegate, 目前只使用成功和失败两个地方的回调
extension KAVPNWrapper: SFAuthResultDelegate {
    func onAuthSuccess(_ msg: BaseMessage) {
        if isSSHLogin {
            sshLoginHandler?(.success(msg.serverInfo))
            Self.logger.info("KAVPN: startPasswordAuth success.")
        } else {
            passwordLoginHandler?(.success(msg.serverInfo))
            Self.logger.info("KAVPN: startTicketAuth success.")
        }
    }

    func onAuthSuccessPre(_ msg: BaseMessage) -> Bool {
        true
    }

    func onAuthProcess(_ nextAuthType: SFAuthType, message msg: BaseMessage) {
    }

    func onAuthFailed(_ msg: BaseMessage) {
        // 免密登录
        if isSSHLogin {
            if failedTime < 3 {
                failedTime += 1
                sdk?.startTicketAuth()
            } else {
                Self.logger.error("KAVPN: TicketAuth Login failed.", additionalData: ["TicketAuth Login failed": msg.errStr])
                sshLoginHandler?(.failure(msg.error))
            }
        } else if let passwordComplaction = self.passwordLoginHandler {
            // 账号密码登录
            passwordComplaction(.failure(msg.error))
            Self.logger.error("KAVPN: Password Login failed.", additionalData: ["Password Login failed": msg.errStr])
        } else {
            // 都不是则当SDK主动踢出处理
            if !isInBackground {
                mainAppLogout?()
            }
        }
    }
}

extension KAVPNWrapper {
    @objc
    func addAppStatusObserver() {
        // 添加应用进入后台的通知监听
        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(didBecomeActive(_:)),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )

        // 添加应用进入后台的通知监听
        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(appDidEnterBackground(_:)),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
    }

    // 后台状态检查(是否进入前台)
    @objc
    func didBecomeActive(_ : Notification) {
        isInBackground = false
    }

    // 后台状态检查(是否进入后台)
    @objc
    func appDidEnterBackground(_ : Notification) {
        isInBackground = true
    }
}
#endif
