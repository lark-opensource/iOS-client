//
//  LarkMagicSDKSetupTask.swift
//  LarkMagic
//
//  Created by Yuri on 2023/7/20.
//

import Foundation
import LarkContainer
import LarkRustClient
import ADFeelGood
import LarkReleaseConfig
import LarkAccountInterface
import LKCommonsTracker
import RxSwift
import LarkUIKit
import LarkLocalizations

class LarkMagicSDKSetupTask: UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
    @ScopedProvider private var deviceService: DeviceService?
    @ScopedProvider private var configurationAPI: LarkMagicConfigAPI?
    private let disposeBag = DisposeBag()

    var didUpdateConfigHandler: ((LarkMagicConfig) -> Void)?

    deinit {
        LarkMagicLaunchTask.logger.info("LarkMagicSDKSetupTask deinit")
    }

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func fetchConfig() {
        LarkMagicLaunchTask.logger.info("LarkMagicSDKSetupTask fetch")
        let start = LarkMagicTracker.timeCostStart()
        configurationAPI?.fetchSettingsRequest(fields: ["ug_magic_config"])
            .subscribe(onNext: { result in
                self.updateConfig(result)
                let cost = LarkMagicTracker.timeCostEnd(for: start)
                LarkMagicTracker.trackFetchConfig(succeed: true, cost: cost)
                LarkMagicLaunchTask.logger.info("LarkMagicSDKSetupTask fetchConfig fetch success")
            }, onError: { error in
                self.trackError(error)
                LarkMagicLaunchTask.logger.error("LarkMagicSDKSetupTask fetchConfig error: \(error)")
            }).disposed(by: disposeBag)
    }

    func trackError(_ error: Error) {
        if let rcError = error.underlyingError as? RCError,
           let errorCode = self.rcErrorCode(rcError: rcError) {
            LarkMagicTracker.trackFetchConfig(succeed: false,
                                              errorCode: errorCode,
                                              errorMsg: "\(rcError)")
        } else {
            LarkMagicTracker.trackFetchConfig(succeed: false,
                                              errorMsg: "\(error)")
        }
    }

    func rcErrorCode(rcError: RCError) -> Int32? {
        switch rcError {
        case .businessFailure(let errorInfo):
            return errorInfo.code
        default:
            return nil
        }
    }

    func updateConfig(_ result: [String: String]) {
        guard let config = result["ug_magic_config"]?.data(using: .utf8)
                .flatMap({ (data) -> LarkMagicConfig? in
                    let decoder: JSONDecoder = JSONDecoder()
                    return try? decoder.decode(LarkMagicConfig.self, from: data)
        }) else {
            LarkMagicLaunchTask.logger.error("LarkMagicSDKSetupTask update config error: \(result)")
            return
        }
        registerTeaTracker(config: config)
        didUpdateConfigHandler?(config)
    }

    func initFeelGood(appKey: String) {
        let config = ADFeelGoodConfig()
        config.appKey = appKey
        if ReleaseConfig.isFeishu {
            config.channel = "cn"
        } else {
            config.channel = "va"
        }

        config.language = LanguageManager.currentLanguage.rawValue
        config.uid = secreatString(str: userResolver.userID)
        deviceService.flatMap { config.did = secreatString(str: $0.deviceId) }
        config.deviceType = Display.pad ? "tablet" : "mobile"
        ADFeelGoodManager.sharedInstance().setConfig(config)
    }

    fileprivate func registerTeaTracker(config: LarkMagicConfig) {
        let manager = LarkMagicConsumerManager.shared
        if let lastConsumer = manager.consumer {
            Tracker.unregister(key: .tea, tracker: lastConsumer)
        }
        let consumer = LarkMagicTeaEventConsumer(config: config, userResolver: userResolver)
        Tracker.register(key: .tea, tracker: consumer)
        manager.consumer = consumer
    }
}
