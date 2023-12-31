//
//  SetupModuleTask.swift
//  LarkMessenger
//
//  Created by KT on 2020/7/2.
//

import UIKit
import Foundation
import BootManager
import LarkSDKInterface
import LarkFeatureGating
import LarkModel
import RxSwift
import LarkContainer
import RustPB
import LKCommonsLogging
import LarkSensitivityControl
import LarkLocalizations

final class NewSetupModuleTask: UserFlowBootTask, Identifiable {

    static let logger = Logger.log(NewSetupGuideTask.self, category: "LaunchTask.NewSetupModuleTask")

    static var identify = "SetupModuleTask"

    override var scheduler: Scheduler { return .async }

    override var deamon: Bool { return true }

    private let disposeBag = DisposeBag()

    @ScopedProvider private var authAPI: AuthAPI?
    @ScopedProvider private var userGeneralSettings: UserGeneralSettings?
    @ScopedProvider private var configurationAPI: ConfigurationAPI?
    @ScopedProvider private var userAppConfig: UserAppConfig?
    @ScopedProvider private var userUniversalSettingService: UserUniversalSettingService?
    @ScopedProvider private var tenantUniversalSettingService: TenantUniversalSettingService?

    override func execute(_ context: BootContext) {
        // 3. 设备信息上报
        self.authAPI.flatMap { self.updateDeviceInfo(authAPI: $0) }
        // 4. 通用设置同步
        self.userGeneralSettings?.initializeSyncSettings()
        let language = LanguageManager.currentLanguage.localeIdentifier
        // 5. 同步端上语言设置给接口
        self.configurationAPI?.updateDeviceSetting(language: language).subscribe(onError: { error in
            Self.logger.error("update device language: \(language) failed: \(error)")
        }).disposed(by: self.disposeBag)
        // 6. 拉取系统消息模板
        self.configurationAPI?.getSystemMessageTemplate(language: language).subscribe(onError: { error in
            Self.logger.error("get system message template: \(language) failed: \(error)")
        }).disposed(by: self.disposeBag)
        // 9. 加载app config
        self.userAppConfig?.fetchAppConfigIfNeeded()
        // 13. 拉取效率页配置信息
        self.userUniversalSettingService?.setupUserUniversalInfo()
        //拉取租户维度全局配置
        self.tenantUniversalSettingService?.loadTenantMessageConf(forceServer: false, onCompleted: nil)
    }

    private func updateDeviceInfo(authAPI: AuthAPI) {
        var session = RustPB.Basic_V1_Device()
        session.os = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        do {
            let deviceName = try DeviceInfoEntry.getDeviceName(
                forToken: Token(withIdentifier: "LARK-PSDA-MessengerMod_update_session"),
                device: UIDevice.current)
            session.name = deviceName
        } catch {
            session.name = UIDevice.current.lu.modelName()
            Self.logger.warn("Could not fetch device name by LarkSensitivityControl API, use model name as fallback.")
        }
        session.model = UIDevice.current.lu.modelName()
        authAPI.updateDeviceInfo(deviceInfo: session)
            .subscribe()
            .disposed(by: self.disposeBag)
    }
}
