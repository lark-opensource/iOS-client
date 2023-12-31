//
//  FeatureGatingLaunchTask.swift
//  LarkSetting
//
//  Created by Supeng on 2021/6/24.
//

import Foundation
import LarkRustClient
import RustPB
import LarkContainer
import LarkAccountInterface
import BootManager
import RxSwift
import LarkEnv
import LarkStorage
import LKCommonsLogging

/// 启动任务，首屏之后拉取Setting和FG数据
final class SettingLaunchTask: UserFlowBootTask, Identifiable {
    static let identify = "SettingLaunchTask"

    override func execute(_ context: BootContext) {
        guard let userID = context.currentUserID else { return }
        
        let resolver = userResolver
        DispatchQueue.global(qos: .default).async {
            SettingStorage.settingDatasource?.fetchSetting(resolver: resolver)
            FeatureGatingStorage.featureGatingDatasource?.fetchImmutableFeatureGating(with: userID)
        }
    }
}

final class SettingIdleTask: UserFlowBootTask, Identifiable {
    static let identify = "SettingIdleTask"
        
    override func execute(_ context: BootContext) {
        guard let userID = context.currentUserID else { return }

        FeatureGatingTracker.trackAndSyncIfNeeded(with: userID)
    }
}

final class CommonSettingLaunchTask: FlowBootTask, Identifiable {
    private static let disposeBag = DisposeBag()

    static let identify = "CommonSettingLaunchTask"

    override var runOnlyOnce: Bool { true }

    override var deamon: Bool { true }

    override func execute(_ context: BootContext) {
        // 监听PushCommonSettingUpdated
        if let golbalService = Container.shared.resolve(GlobalRustService.self) {
            let response: Observable<RustPB.Settings_V1_PushCommonSettingsUpdated> =
                golbalService.register(pushCmd: .pushCommonSettingsUpdated)
            response
                .subscribeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "config.manager.scheduler"))
                .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "config.manager.scheduler"))
                .subscribe(onNext: { response in
                    let envV2 = response.envV2
                    SettingStorage.settingDatasource?.fetchCommonSetting(envV2: envV2)
                }).disposed(by: Self.disposeBag)
        }
        // 异步HTTP请求拉取无用户态FG(只依赖网络、域名)
        guard let deviceService = Container.shared.resolve(DeviceService.self) else { return }

        if deviceService.deviceInfo.deviceId.isEmpty {
            deviceService.deviceInfoObservable
                .subscribeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "config.manager.scheduler"))
                .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "config.manager.scheduler"))
                .subscribe(onNext: { deviceInfo in
                    guard let deviceId = deviceInfo?.deviceId, !deviceId.isEmpty else { return }
                    FeatureGatingStorage.featureGatingDatasource?.fetchGlobalFeatureGating(deviceID: deviceId)
                }).disposed(by: Self.disposeBag)
        }else {
            FeatureGatingStorage.featureGatingDatasource?.fetchGlobalFeatureGating(deviceID: deviceService.deviceInfo.deviceId)
        }
    }
}

final class SaveRustLogKeyTask: UserFlowBootTask, Identifiable {
    private static let disposeBag = DisposeBag()

    static let identify = "SaveRustLogKeyTask"

    static let logger = Logger.log(SaveRustLogKeyTask.self, category: "SaveRustLogKeyTask")

    override func execute(_ context: BootContext) {
        do {
            let rawLogSetting = try SettingManager.shared.staticSetting(with: .make(userKeyLiteral: "sdk_log_encryption"))

            guard let rawLogSetting = rawLogSetting as? [String: String] else {
                Self.logger.error("Failed to get rust log secret key with userID: \(userResolver.userID)")
                return
            }

            LarkStorage.KVPublic.Setting.rustLogSecretKey.setValue(rawLogSetting)
            Self.logger.info("Get rust log secret key with userID: \(userResolver.userID)")

        } catch {
            Self.logger.error("Failed to get rust log secret key with userID: \(userResolver.userID)", error: error)
        }
    }
}
