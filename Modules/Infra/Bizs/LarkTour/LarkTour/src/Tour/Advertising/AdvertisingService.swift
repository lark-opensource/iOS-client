//
//  AdvertisingService.swift
//  LarkTour
//
//  Created by Meng on 2020/4/17.
//

import Foundation
import LarkAccountInterface
import LarkContainer
import LarkTourInterface
import LKCommonsLogging
import RxSwift
import RustPB
import LarkUIKit
import LKLaunchGuide

/// Advertising event handler
protocol AdvertisingEventHandler: AnyObject {
    /// for Feishu when device id get, request install source with deviceID
    func onDeviceIdChanged()
    /// for Lark conversionData get, request install source with mediaSource and campaign
    func onConversionDataReceived(serializedData: String)
    /// when login, use user source
    func onUserSourceReceivced(source: String)
    /// when logout clear user source
    func onLogout()
}

final class AdvertisingManager: AdvertisingService, UserResolverWrapper {
    static let logger = Logger.log(AdvertisingManager.self, category: "Tour")

    @ScopedProvider private var dependency: TourDependency?
    @ScopedInjectedLazy private var _storage: AdvertisingStorage?
    private var storage: AdvertisingStorage { _storage ?? .init() }
    @ScopedProvider private var passportService: PassportService?
    @ScopedProvider private var passportUserService: PassportUserService?
    @ScopedProvider private var deviceService: DeviceService?
    @ScopedProvider private var launchGuideService: LaunchGuideService?
    @ScopedInjectedLazy private var requestTool: AdvertisingRequestTool?

    private var serializedData: String?
    private let disposeBag = DisposeBag()

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 优先使用user source
    var source: String? {
        if storage.userSource.isEmpty {
            return storage.installSource.isEmpty ? nil : storage.installSource
        } else {
            return storage.userSource
        }
    }

    private func fetchInstallSourceConfigIfNeeded() {
        guard let deviceService else { return }
        guard !storage.hasInstallSource
            && deviceService.deviceInfo.isValidDeviceID
            && (dependency?.conversionDataReady ?? false)
            && !(passportService?.foregroundUser != nil) else {
            Self.logger.info("skip fetch ad source config", additionalData: [
                "userSource": storage.userSource,
                "installSource": storage.installSource,
                "isValidDeviceID": "\(deviceService.deviceInfo.isValidDeviceID)",
                "conversionDataReady": "\(dependency?.conversionDataReady)",
                "isLogin": "\(passportService?.foregroundUser != nil)"
            ])
            return
        }
        requestTool?.fetchInstallSource(
            deviceId: deviceService.deviceInfo.deviceId,
            rawAF: serializedData ?? "{}"
        )
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](config) in
                guard let config = config else { return }
                self?.updateSourceConfig(config)
            })
            .disposed(by: disposeBag)
    }

    private func updateSourceConfig(_ sourceConfig: InstallSourceConfig) {
        guard !storage.hasUserSource && !storage.hasInstallSource else {
            Self.logger.info("update source config skip", additionalData: [
                "userSource": storage.userSource,
                "installSource": storage.installSource,
                "configSource": sourceConfig.source,
                "sourceConfigs": "\(sourceConfig.configs)"
            ])
            return
        }
        Self.logger.info("update source config", additionalData: [
            "source": sourceConfig.source,
            "configs": "\(sourceConfig.configs)"
        ])
        storage.installSource = sourceConfig.source
        storage.installConfig = sourceConfig.configs

        applyInstallConfig()
    }

    private func updateUserSource(_ userSource: String?) {
        Self.logger.info("update user source", additionalData: [
            "oldUserSource": storage.userSource,
            "newUserSource": userSource ?? "",
            "installSource": storage.installSource,
            "installConfig": "\(storage.installConfig)"
        ])
        storage.userSource = userSource ?? ""
    }

    /// 使用当前installConfig配置
    /// 1. 跳转到对应的LauncheGuide
    /// 2. 注入登陆参数，ug_source, pattern
    private func applyInstallConfig() {
        if let key = storage.installConfig[InstallConfigKey.launchGuideKey] {
            let success = launchGuideService?.tryScrollToItem(name: key) ?? false
            Self.logger.info("try scroll launch guide", additionalData: ["key": key, "success": "\(success)"])
            TourMetric.switchGuidePageEvent(guideKey: key, succeed: success)
        } else {
            Self.logger.info("try scroll launch guide skip for no key")
        }

        let loginPattern = storage.installConfig[InstallConfigKey.loginPatternKey]
        if storage.installSource.isEmpty {
            passportService?.injectLogin(pattern: loginPattern, regParams: nil)
        } else {
            passportService?.injectLogin(pattern: loginPattern, regParams: [RegParamsKey.ugSourceKey: storage.installSource])
        }
        Self.logger.info("inject login config", additionalData: [
            "pattern": loginPattern ?? "",
            RegParamsKey.ugSourceKey: storage.installSource
        ])
    }
}

extension AdvertisingManager: AdvertisingEventHandler {
    func onDeviceIdChanged() {
        Self.logger.info("on device id changed")
        fetchInstallSourceConfigIfNeeded()
    }

    func onConversionDataReceived(serializedData: String) {
        Self.logger.info("on conversion data received")
        self.serializedData = serializedData
        fetchInstallSourceConfigIfNeeded()
    }

    func onUserSourceReceivced(source: String) {
        Self.logger.info("on user source received", additionalData: ["source": source])
        updateUserSource(source)
    }

    func onLogout() {
        Self.logger.info("on logout")
        updateUserSource(nil)
    }
}
