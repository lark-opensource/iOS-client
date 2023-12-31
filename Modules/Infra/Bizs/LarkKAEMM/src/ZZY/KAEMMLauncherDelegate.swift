//
//  KAEMMLauncherDelegate.swift
//  LarkBaseService
//
//  Created by kongkaikai on 2021/8/18.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface
import LarkAppConfig
import LarkContainer
import LarkReleaseConfig
import LarkRustClient
import LarkOPInterface
import RustPB
import RxSwift
import UIKit
import Swinject
import LarkSetting

/// emm_config结构
private struct EMMConfig: Decodable {
    var emmAppId: String
    var emmDomain: String
    var emmOrgCode: String

    init?(with dictionary: [String: String]) {
        guard let emmAppId = dictionary["emm_app_id"] as? String,
              let emmDomain = dictionary["emm_domain"] as? String,
              let emmOrgCode = dictionary["emm_org_code"] as? String else {
                  return nil
              }
        self.emmAppId = emmAppId
        self.emmDomain = emmDomain
        self.emmOrgCode = emmOrgCode
    }
}

final class KAEMMLauncherDelegate: LauncherDelegate {
    public var name: String { "KAEMMLauncherDelegate-kazdtq" }
    static let logger = Logger.log(KAEMMLauncherDelegate.self, category: "Module.LarkKAEMMTask")

    @InjectedLazy private var deviceService: DeviceService
    @InjectedLazy private var opLogin: OPApiLogin

    private lazy var accountService: AccountService = AccountServiceAdapter.shared

    private var disposeBag = DisposeBag()

    private var wattingSetAccount: (Bool, Account)?
    private var emmWrapper: KAEMMWrapper?

    public init(container: Container) {}

    /// 获取租户ID
    /// - Returns: 租户ID: tenantId
    private func getTenantId() -> String {
        let tenantId = accountService.currentTenant.tenantId
        if tenantId.isEmpty {
            Self.logger.error("KAEMM: tenantId is empty.")
        }
        return tenantId
    }

    /// EMMConfig参数获取
    /// - Parameter TenantId: 租户ID
    /// - Returns: EMMConfig实例, 包括appId, domain(域名), OrgCode(KA的channel), 详情参考:https://cloud.bytedance.net/appSettings/config/139970/detail/status
    private func getEMMConfig(tenantId: String) -> EMMConfig? {
        do {
            let configDict = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "emm_config"))
            if let dict = configDict[getTenantId()] as? [String: String],
               let config = EMMConfig(with: dict) {
                Self.logger.info("KAEMM: emmConfig load success.")
                return config
            } else {
                Self.logger.error("KAEMM: Get emm_config setting error.")
                return nil
            }
        } catch {
            Self.logger.error("KAEMM: Get EMMConfig error.")
            return nil
        }
    }

    /// 初始化Wapper
    private func initWapper() {
        let config = getEMMConfig(tenantId: getTenantId())
        if let orgCode = config?.emmOrgCode, let domain = config?.emmDomain {
            self.emmWrapper = KAEMMWrapper(
                config: .init(
                    deviceID: deviceService.deviceId,
                    groupID: ReleaseConfig.groupId,
                    domain: "https://\(domain)",
                    channel: orgCode
                ),
                delegate: self
            )
            Self.logger.info("KAEMM: setup wrapper success.")
        } else {
            Self.logger.error("KAEMM: setup wrapper failed.")
        }
    }

    //冷启动登录接口
    func fastLoginAccount(_ account: Account) {
        Self.logger.info("KAEMM: Call fast login.")
        initWapper()
    }

    public func afterSetAccount(_ account: Account) {
        initWapper()
        if let emmWrapper = emmWrapper {
            wattingSetAccount = nil // reset cache
            opLogin.onGadgetEngineReady { [weak self] isReady in
                guard isReady else { return }
                self?.emmWrapper?.login(userID: account.userID)
            }
        } else {
            wattingSetAccount = (true, account)
            Self.logger.error("KAEMM: Wrapper not init.")
        }
    }

    public func beforeSwitchSetAccount(_ account: Account) {
        emmWrapper?.logout()
        emmWrapper = nil
    }

    public func afterSwitchSetAccount(_ account: Account) {
        opLogin.onGadgetEngineReady { [weak self] isReady in
            guard isReady else { return }
            self?.emmWrapper?.login(userID: account.userID)
        }
        if emmWrapper == nil {
            Self.logger.error("KAEMM: Wrapper not init.")
        }
    }

    public func afterLogout(context: LauncherContext, conf: LogoutConf) {
        if wattingSetAccount != nil {
            wattingSetAccount = nil
            Self.logger.error("KAEMM: cancel wait login.")
        } else {
            emmWrapper?.logout()
        }
    }
}

extension KAEMMLauncherDelegate: KAEMMWrapperDelegate {
    /// 拉取登录信息的接口
    public func fetchLoginConfig() -> Observable<String> {
        Observable<String>.create { [weak self] observer in
            guard let self = self, let appId = self.getEMMConfig(tenantId: self.getTenantId())?.emmAppId else {
                Self.logger.error("KAEMM: EMM appId load failed.")
                observer.onError(NSError(domain: "KAEMM: EMM appId load failed.", code: 1_001, userInfo: nil) as Error)
                return Disposables.create()
            }

            self.opLogin.gadgetLogin(appId) { result in
                switch result {
                case .success(let code):
                    observer.onNext(code)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            self.opLogin.offGadgetEngineReady()
            return Disposables.create()
        }
    }

    /// 登出接口
    /// - Parameters:
    ///   - onError: 登出失败
    ///   - onSuccess: 登出成功
    ///   - onInterrupt: 登出被打断
    public func logout(
        _ onError: @escaping (_ message: String) -> Void,
        onSuccess: @escaping () -> Void,
        onInterrupt: @escaping () -> Void) {
            let conf = LogoutConf.default
            conf.trigger = .emm
            AccountServiceAdapter.shared.relogin(
                conf: conf,
                onError: onError,
                onSuccess: onSuccess,
                onInterrupt: onInterrupt
            )
        }
}
