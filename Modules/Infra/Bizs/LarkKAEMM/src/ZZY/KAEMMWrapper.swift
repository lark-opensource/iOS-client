//
//  KAEMMWrapper.swift
//  LarkKAEMM
//
//  Created by Crazy凡 on 2021/8/18.
//

import UIKit
import Foundation
import LKCommonsLogging
import RxSwift
#if canImport(MBSSDK)
import MBSSDK
#endif
import CommonCrypto
import CryptoSwift
import LarkReleaseConfig

/// KAEMMWrapper 的 Delegate, 抛出 KAEMMWrapper 依赖宿主实现的能力、
public protocol KAEMMWrapperDelegate: AnyObject {

    /// 拉取登录信息的接口
    func fetchLoginConfig() -> Observable<String>

    /// 登出接口
    /// - Parameters:
    ///   - onError: 登出失败
    ///   - onSuccess: 登出成功
    ///   - onInterrupt: 登出被打断
    func logout(
        _ onError: @escaping (_ message: String) -> Void,
        onSuccess: @escaping () -> Void,
        onInterrupt: @escaping () -> Void
    )
}

/// KAEMMWrapper初始化字段
public struct KAEMMWrapperInitConfig {
    var deviceID: String
    var groupID: String
    var domain: String
    var channel: String

    /// 初始化方法
    /// - Parameters:
    ///   - deviceID: 飞书 deviceID
    ///   - groupID: extension group, 共享的groupID
    public init(deviceID: String, groupID: String, domain: String, channel: String) {
        self.deviceID = deviceID
        self.groupID = groupID
        self.domain = domain
        self.channel = channel
    }
}

// swiftlint:disable missing_docs multiple_closures_with_trailing_closure
final class KAEMMWrapper {
    private static let logger = Logger.log(KAEMMWrapper.self, category: "Module.LarkKAEMM")

    private var disposeBag: DisposeBag = .init()

    private weak var delegate: KAEMMWrapperDelegate?
    private var config: KAEMMWrapperInitConfig

    required public init(config: KAEMMWrapperInitConfig, delegate: KAEMMWrapperDelegate) {
        self.config = config
        self.delegate = delegate

#if targetEnvironment(simulator)
        assert(false, "Only supports debug with real machine.")
#else
        setup()
#endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
#if targetEnvironment(simulator)
extension KAEMMWrapper {
    func login(userID: String) {
        assert(false, "Only supports debug with real machine.")
    }

    func logout() {
        assert(false, "Only supports debug with real machine.")
    }
}

#else
extension KAEMMWrapper {

    private func checkDelegate() -> KAEMMWrapperDelegate? {
        guard let delegate = self.delegate else {
            assert(false, "KAEMM: KAEMMWrapper will not hold delegate strongly.")
            Self.logger.error("KAEMM: delegate is nil")

            return nil
        }
        return delegate
    }
    // 日志回调初始化封装,方便打印指掌易日志到飞书.
    private func setUpEmmLogger() -> UUMbsSDKLogger {
        let logger = UUMbsSDKLogger()

        logger.infoLogger = { (tag: String?, content: String?) -> Void in
            Self.logger.info("Tag: \(tag),EMMLog: \(content)")
        }
        logger.errorLogger = { (tag: String?, content: String?) -> Void in
            Self.logger.error("Tag: \(tag),EMMLog: \(content)")
        }
        logger.verboseLogger = { (tag: String?, content: String?) -> Void in
            Self.logger.trace("Tag: \(tag),EMMLog: \(content)")
        }
        logger.warnLogger = { (tag: String?, content: String?) -> Void in
            Self.logger.warn("Tag: \(tag),EMMLog: \(content)")
        }
        logger.debugLogger = { (tag: String?, content: String?) -> Void in
            Self.logger.debug("Tag: \(tag),EMMLog: \(content)")
        }
        return logger
    }

    private func setup() {
        // 为了方便EMM SDK提供方Debug, Debug代码内有版本防护
        addDebugObserver()

        guard let delegate = checkDelegate() else { return }

        let configForSDK = UUMbsSDKConfig()
        configForSDK.serverUrl = config.domain
        configForSDK.orgCode = config.channel
        configForSDK.securityId = config.deviceID
        configForSDK.appGroupID = config.groupID
        configForSDK.urlScheme = "feishu-open"

        configForSDK.networkErrorBlock = { (error: Error?) -> Void in
            Self.logger.error("KAEMM: get network error.", error: error)

            if let error = error as NSError?, error.code == 1_001 {

                delegate.logout() { error in
                    Self.logger.info("KAEMM: active logout error.", additionalData: ["error": error])
                } onSuccess: {
                    Self.logger.info("KAEMM: active logout failed.")
                } onInterrupt: {
                    Self.logger.info("KAEMM: active logout interrupt.")
                }
            }
        }

        configForSDK.tokenInvalidBlock  = { (error) -> Void in
            Self.logger.error("KAEMM: tokenInvalidBlock", error: error)
        }
        // 注册日志回调,需要在初始化回调前注册
        UUMbsSDKManager.setLogger(setUpEmmLogger())

        guard UUMbsSDKManager.initialization(configForSDK) else {
            Self.logger.error("KAEMM: init failed.")
            return
        }

        Self.logger.info("KAEMM: init success.")
    }

    /// prepareForLogin,拼接后续EMM3次登录失败踢出飞书
    /// - Parameter code: fetchLogin返回code
    /// - Returns: Void
    private func prepareForLogin(code: String) -> Observable<Void> {
        Observable<Void>.create { observer in
            let param = UUMbsSDKLoginParam()
            param.userName = code
            param.userPassword = code
            param.loginType = 8 // 固定值，详见接口文档
            DispatchQueue.main.async {
                UUMbsSDKManager.login(param) { error in
                    if let error = error {
                        observer.onError(error)
                        Self.logger.error("KAEMM: UUMbsSDK login failed.", error: error)
                    } else {
                        observer.onNext(Self.logger.info("KAEMM: UUMbsSDK login success"))
                    }
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    public func login(userID: String) {
        guard let delegate = checkDelegate() else { return }

        delegate.fetchLoginConfig()
            .do(onNext: { code in
                Self.logger.info("KAEMM: current account", additionalData: ["md5": code.md5()])
            }, onError: { error in
                Self.logger.error("KAEMM: Fetchlogin code error.", error: error)
            })
            .concatMap { code in
                self.prepareForLogin(code: code)
                    .do(onError: { error in
                        Self.logger.error("KAEMM: Call SDK login error.", error: error)
                    })
            }
            .subscribe(onNext: { _ in
                Self.logger.info("KAEMM: SDK login success.")
            }, onError: { [ weak self ] error in
                Self.logger.error("KAEMM: Call SDK login error.")
                self?.delegate?.logout({ _ in
                    Self.logger.info("KAEMM: SDK login failed.", error: error)
                }, onSuccess: {
                    Self.logger.info("KAEMM: Feishu logout success.", error: error)
                }, onInterrupt: {
                    Self.logger.error("KAEMM: Feishu logout onInterrupt.", error: error)
                })
            }).disposed(by: self.disposeBag)
    }

    public func logout() {
        UUMbsSDKManager.logout { error in
            if let error = error {
                Self.logger.error("KAEMM: SDK logout failed.", error: error)
            } else {
                Self.logger.info("KAEMM: SDK logout success")
            }
        }
    }
}

private extension UIApplication {
    class func topViewController(
        controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
    ) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

// MARK: - Debug
private extension KAEMMWrapper {

    @objc
    func onReceive(_ notification: Notification) {
        Self.logger.info("KAEMM: Notification on received")
        if let view = UIApplication.topViewController()?.view {
            UUMbsSDKManager.exportMBSLog(view)
            Self.logger.info("KAEMM: Export log view shown.")
        }
    }

    /// 添加DEBUG通知监听
    func addDebugObserver() {
        // 校验版本和channel，多一层保障
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              (version.contains("alpha") || version.contains("beta"))
        else {
            Self.logger.info("KAEMM: can not add debug")
            return
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onReceive(_:)),
            name: .init(rawValue: "__ka_debug_notification"),
            object: nil
        )
        Self.logger.info("KAEMM: add debug observer")
    }
}
#endif
// swiftlint:enable missing_docs multiple_closures_with_trailing_closure

/// 默认实现，为了编译可以过
final class KAVPNWrapper: KAVPNWrapperInterface {}
