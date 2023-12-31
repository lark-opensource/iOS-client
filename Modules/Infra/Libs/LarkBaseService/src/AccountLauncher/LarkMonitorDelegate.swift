//
//  LarkMonitorDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/11/27.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Swinject
import LKCommonsLogging
import LarkReleaseConfig
import LarkAccountInterface
import LarkFeatureGating
import LarkMonitor
import LarkTracker
import RustPB
import RunloopTools
import LarkRustClient
import LarkKAFeatureSwitch
import LarkAppConfig
import LarkSetting
import LarkContainer
import LarkEnv
import LarkStorage

public final class LarkMonitorDelegate: LauncherDelegate, PassportDelegate {
    public let name: String = "LarkMonitor"

    static let logger = Logger.log(LarkMonitorDelegate.self, category: "LarkApp.LarkMonitorDelegate")

    private let resolver: Resolver
    @Provider var deviceService: DeviceService // Global
    @Provider private var trackService: TrackService // Global
    @Injected var passport: PassportService // Global
    private var disposeBag = DisposeBag()

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    func updateMonitor(resolver: UserResolver) throws {
        disposeBag = DisposeBag()
        let passportUser = try resolver.resolve(assert: PassportUserService.self)
        setupSlardar(account: passportUser.user)
        setupTea(userResolver: resolver)
    }

    // MARK: Delegate
    public func afterLogout(_ context: LauncherContext) {
        setupSlardar(account: nil)
        setupTea(userResolver: nil)
    }

    public func userDidOffline(state: PassportState) {
        if state.action == .logout {
            setupSlardar(account: nil)
            setupTea(userResolver: nil)
        }
    }

    // MARK: - Slardar
    // sladar不太关心用户，只是作为额外参考信息，串的影响不大，所以切换用户时直接设置，未做隔离
    func setupSlardar(account: User?) {
        let userId = account?.userID ?? ""
        //针对切换租户和登录场景，补齐一些slardar维度
        let tenant = account?.tenant
        let tenantId = tenant?.tenantID ?? ""
        let injectedInfo = HMDInjectedInfo.default()
        injectedInfo.setCustomFilterValue(tenantId, forKey: "tenant_id")
        injectedInfo.setCustomFilterValue(userId, forKey: "user_id")
        injectedInfo.deviceID = deviceService.deviceId
        LarkMonitor.updateUserInfo(
            userId,
            userName: "",
            userEnv: account?.userEnv ?? ""
        )
        if account != nil {
            let isOpen = LarkFeatureGating.shared.getFeatureBoolValue(for: .oomDetector)
            updateOOMSetting(isOpen: isOpen)

            if let customExceptionConfig = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "custom_exception_config")) {
                // lint:disable:next lark_storage_check
                UserDefaults(suiteName: "lk_safe_mode")?.set(customExceptionConfig, forKey: "lark_custom_exception_config")
            }
            
            let fpEnable = FeatureGatingManager.shared.featureGatingValue(with: "messenger.ios.bdfishhook.patch.enable")
            UserDefaults.standard.set(fpEnable, forKey: "messenger_ios_bdfishhook_patch_enable")

        } else {
            updateOOMSetting(isOpen: false)
        }
    }

    private func updateOOMSetting(isOpen: Bool) {
        KVPublic.FG.oomDetectorOpen.setValue(isOpen)
    }

    // MARK: - Tea
    func setupTea(userResolver: UserResolver?) {
        let user = try? userResolver?.resolve(assert: PassportUserService.self).user
        @Injected var passport: PassportService // Global
        let deviceService = self.deviceService
        let chatterId = user?.userID ?? ""
        let tenantId = user?.tenant.tenantID ?? ""
        let deviceId = deviceService.deviceId
        let installId = deviceService.installId
        let isGuest = user?.isGuestUser ?? true
        let geo = user?.geo ?? EnvManager.env.geo
        let brand = user?.tenant.tenantBrand ?? passport.tenantBrand

        /* 登陆后重新请求一次 */
        pullGeneralSettings { globalTeaMonitorService?.updateFilterType(by: $1) }
        updateTeaDomain(self.trackService)

        trackService.config(
            chatterID: chatterId,
            tenantID: tenantId,
            isGuest: isGuest,
            deviceID: deviceId,
            installID: installId,
            platform: "lark",
            subPlatform: "others",
            geo: geo,
            brand: brand.rawValue)

        /* 登陆后重新请求一次 */
        updateTeaConfig(userResolver: userResolver)
    }

    /* 收到SDK端的配置更新数据，更新埋点工具配置（例： 上传URL地址）*/
    private func updateTeaConfig(userResolver: UserResolver?) {
        if let userResolver = userResolver,
           let settings = try? userResolver.resolve(assert: SettingService.self) {
            settings.observe(key: .make(userKeyLiteral: "et_config"), current: false, ignoreError: true).subscribe(onNext: { jsonDict in
                guard let filterStatus = jsonDict["filter_status"] as? Int else {
                    LarkMonitorDelegate.logger.error("[get config] get filter_status failed")
                    return
                }
                globalTeaMonitorService?.updateFilterType(by: filterStatus)

                guard let endpoints = jsonDict["endpoints"] as? [String] else {
                    LarkMonitorDelegate.logger.error("[get config] get endpoints failed")
                    return
                }
            }, onError: { (error) in
                LarkMonitorDelegate.logger.error("[通用配置push handler] 拉取配置失败 \(error)")
            }).disposed(by: disposeBag)
        }

        DomainSettingManager.shared.domainObservable.subscribe(onNext: { [weak self] _ in updateTeaDomain(self?.trackService) }).disposed(by: disposeBag)
    }
}
