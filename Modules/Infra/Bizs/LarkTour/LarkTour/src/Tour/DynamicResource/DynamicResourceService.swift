//
//  DynamicResourceService.swift
//  LarkTour
//
//  Created by Meng on 2019/12/16.
//

import Foundation
import RxSwift
import LarkTourInterface
import LarkContainer
import LKCommonsLogging
import LarkLocalizations
import LarkGuide
import LarkAppConfig

struct StatusConfig: Codable {
    var status: [String: Status]
}

struct ResourceConfig: Codable {
    var data: [String: DomainRes]
}

struct DomainRes: Codable {
    var res: [String: Resource]
}

struct Resource: Codable, ResourceProtocol {
    let type: String
    let value: [String: String]
    init(type: String, value: [String: String]) {
        self.type = type
        self.value = value
    }

    var localizedValue: String? {
        var result = value[ LanguageManager.currentLanguage.localeIdentifier ]
        switch type {
        case ResourceTypeKey.text:
            result = result?.replacingOccurrences(of: "{{APP_DISPLAY_NAME}}", with: "\(LanguageManager.bundleDisplayName)")
        case ResourceTypeKey.image:
            break
        case ResourceTypeKey.video:
            break
        default:
            break
        }
        return result
    }
}

final class DynamicResourceServiceImpl: DynamicResourceService {
    static let logger = Logger.log(DynamicResourceServiceImpl.self, category: "Tour")

    private let configurationAPI: TourConfigAPI
    private let pushCenter: PushNotificationCenter
    private let productGuideAPI: ProductGuideAPI
    private let disposeBag = DisposeBag()

    private var statusStorage: [String: StatusConfig] = [:]
    private var resourceStorage: [String: ResourceConfig] = [:]
    private let decoder: JSONDecoder = JSONDecoder()

    init(
        configurationAPI: TourConfigAPI,
        pushCenter: PushNotificationCenter,
        productGuideAPI: ProductGuideAPI) {
        self.configurationAPI = configurationAPI
        self.pushCenter = pushCenter
        self.productGuideAPI = productGuideAPI
    }

    func preload(statusKeys: [String], resourceKeys: [String]) {
        handlePreload(statusKeys: statusKeys, resourceKeys: resourceKeys)
    }

    func dynamicStatus(for statusKey: String, domain: String) -> Status? {
        return statusStorage[statusKey]?.status[domain]
    }

    func dynamicResource(for resourceKey: String, domain: String) -> [String: ResourceProtocol]? {
        return resourceStorage[resourceKey]?.data[domain]?.res
    }

    func reportFinishStatus(domain: String) {
        productGuideAPI
            .deleteProductGuide(guides: [domain])
            .subscribe()
            .disposed(by: disposeBag)
    }
}

extension DynamicResourceServiceImpl {
    private func handlePreload(statusKeys: [String], resourceKeys: [String]) {
        configurationAPI
            .fetchSettingsRequest(fields: statusKeys + resourceKeys)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self]result in
                self?.handleConfigUpdate(statusKeys: statusKeys, resourceKeys: resourceKeys, datas: result)
            }, onError: { error in
                Self.logger.error("fetch dynamic config failed", additionalData: [
                    "statusKeys": "\(statusKeys)",
                    "resourceKeys": "\(resourceKeys)"
                ], error: error)
            }).disposed(by: disposeBag)
        pushCenter
            .observable(for: PushGeneralConfig.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self]config in
                self?.handleConfigUpdate(statusKeys: statusKeys, resourceKeys: resourceKeys, datas: config.fieldGroups)
            }, onError: { error in
                Self.logger.error("push dynamic config failed", additionalData: [
                    "statusKeys": "\(statusKeys)",
                    "resourceKeys": "\(resourceKeys)"
                ], error: error)
            }).disposed(by: disposeBag)
    }

    private func handleConfigUpdate(statusKeys: [String], resourceKeys: [String], datas: [String: String]) {
        statusKeys.forEach({ key in
            let statusConfig = datas[key]?.data(using: .utf8).flatMap({
                try? decoder.decode(StatusConfig.self, from: $0)
            })
            guard let config = statusConfig else { return }
            Self.logger.debug("cache status config", additionalData: ["key": key])
            statusStorage[key] = config
        })

        resourceKeys.forEach({ key in
            let resourceConfig = datas[key]?.data(using: .utf8).flatMap({
                try? decoder.decode(ResourceConfig.self, from: $0)
            })
            guard let config = resourceConfig else { return }
            Self.logger.debug("cache resources config", additionalData: ["key": key])
            resourceStorage[key] = config
        })
    }
}
