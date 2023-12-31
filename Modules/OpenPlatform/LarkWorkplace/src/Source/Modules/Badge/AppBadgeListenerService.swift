//
//  BadgeListenerManager.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2022/2/11.
//

import Foundation
import ThreadSafeDataStructure
import LarkOPInterface
import LKCommonsLogging
import LarkSetting
import AppContainer
import RxSwift
import LarkContainer

/// Badge API 监听服务
/// TODO: 考虑 Badge 服务整体依赖合理性
///
/// tt.onServerBadgePush
/// tt.offServerBadgePush
final class AppBadgeListenerServiceImpl: AppBadgeListenerService {

    typealias BadgeNode = LarkOPInterface.AppBadgeNode

    struct Listener {
        let appId: String
        let callback: (BadgeNode) -> Void

        init(appId: String, callback: @escaping (BadgeNode) -> Void) {
            self.appId = appId
            self.callback = callback
        }
    }

    static let logger = Logger.log(AppBadgeListenerService.self)

    /// 重试配置
    private var config: BadgePushAPIConfig {
        return configService.settingValue(BadgePushAPIConfig.self, decodeStrategy: .useDefaultKeys)
    }
    private let configService: WPConfigService

    private var listeners: SafeDictionary<String, Listener> = [:] + .readWriteLock
    private let disposeBag = DisposeBag()

    init(pushCenter: PushNotificationCenter, configService: WPConfigService) {
        self.configService = configService
        pushCenter
            .observable(for: BadgeUpdateMessage.self, replay: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](message) in
                self?.onPushBadges(message)
            }).disposed(by: disposeBag)
    }

    func observeBadge(appId: String, subAppIds: [String], callback: @escaping (BadgeNode) -> Void) {
        Self.logger.info("add app badge listener", additionalData: [
            "appId": appId,
            "subAppIds": "\(subAppIds)",
            "config.enableAppIds": "\(config.enableAppIds)"
        ])
        // 判断白名单
        if config.enableAppIds.contains(appId) {
            ([appId] + subAppIds).forEach({
                listeners[$0] = Listener(appId: $0, callback: callback)
            })
        } else {
            listeners[appId] = Listener(appId: appId, callback: callback)
        }
    }

    func removeObserver(appId: String, subAppIds: [String]) {
        Self.logger.info("remove app badge listener", additionalData: [
            "appId": appId,
            "subAppIds": "\(subAppIds)",
            "config.enableAppIds": "\(config.enableAppIds)"
        ])
        // 判断白名单
        if config.enableAppIds.contains(appId) {
            ([appId] + subAppIds).forEach({ listeners.removeValue(forKey: $0) })
        } else {
            listeners.removeValue(forKey: appId)
        }
    }

    private func onPushBadges(_ message: BadgeUpdateMessage) {
        let noticeNodes = message.pushRequest.noticeNodes.compactMap({ $0.toOPAppBadgeNode() })
        noticeNodes.forEach { node in
            guard let listener = listeners[node.appID] else { return }
            Self.logger.info("notify app badge change", additionalData: ["appId": node.appID])
            listener.callback(node)
        }
    }
}
