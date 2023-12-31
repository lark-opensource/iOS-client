//
//  OPBadge.swift
//  LarkOPInterface
//
//  Created by lilun.ios on 2020/12/24.
//

import Foundation
import UIKit
import LKCommonsLogging
import LarkContainer
import RxSwift
import RxRelay
import RustPB

/// log
private let log = Logger.oplog(OPBadge.self, category: "OPBadge")

public struct OPBadge {
    public static let isEnableGadgetAppBadge = "gadget.open_app.badge"
    public enum AppAbility: Int, Codable {
        case unknown = 0
        case MiniApp = 1
        case H5 = 2
        public var description: String {
            get {
                switch self {
                case .MiniApp:
                    return "mina"
                case .H5:
                    return "h5"
                default:
                    return "unknown"
                }
            }
        }
        public static func AppAbilityWithDescription(description: String) -> Self {
            switch description {
            case "mina":
                return .MiniApp
            case "h5":
                return .H5
            default:
                return .unknown
            }
        }
        public func toAppFeatureType() -> RustPB.Openplatform_V1_CommonEnum.OpenAppFeatureType? {
            switch self {
            case .MiniApp:
                return .miniApp
            case .H5:
                return .h5
            default:
                return nil
            }
        }
    }
    /// Badge广播的通知名字
    public enum Noti: String {
        case BadgePush = "workplace.badge.push"
        public var notification : Notification.Name  {
            return Notification.Name(rawValue: self.rawValue )
        }
        public static func BadgeDataKey() -> String {
            return "BadgeNodeList"
        }
    }
    public struct GadgetBadgeNode: Codable {
        public let appId: String
        public let type: String
        public let num: Int
        public let show: Bool
        
        public init(appId: String, type: String, num: Int, show: Bool) {
            self.appId = appId
            self.type = type
            self.num = num
            self.show = show
        }
    }
    public final class BadgePushObserver {
        private let appId: String
        private let type: AppAbility
        private let badgeNumCallback: ((_ badgeNum: Int, _ needShow: Bool) -> Void)
        public init(appId: String,
                    type: AppAbility,
                    badgeNumCallback: @escaping ((_ badgeNum: Int, _ needShow: Bool) -> Void)) {
            self.appId = appId
            self.type = type
            self.badgeNumCallback = badgeNumCallback
            observeBadgePush()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        func observeBadgePush() {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleBadgePush(notification:)),
                                                   name: Noti.BadgePush.notification,
                                                   object: nil)
            
        }
        /// 当收到Badge变化的时候，过滤出当前应用的badge，然后回调出去

        @objc func handleBadgePush(notification: Notification) {
            log.info("App \(appId) \(type.description) handleBadgePush")
            guard let badgeListValue = notification.userInfo?[Noti.BadgeDataKey()],
                  let badgeList = badgeListValue as? [GadgetBadgeNode] else {
                return
            }
            for badgeNode in badgeList {
                if badgeNode.appId == appId,
                   type == AppAbility.AppAbilityWithDescription(description: badgeNode.type),
                   type != .unknown {
                    log.info("App \(appId) \(badgeNode.type) received badge \(badgeNode.num) needShow \(badgeNode.show)")
                    /// 如果存在这个Badge
                    DispatchQueue.main.async {
                        self.badgeNumCallback(badgeNode.num, badgeNode.show)
                    }
                    break
                }
            }
        }
    }
    
    public final class OPBadgeService {
        private let pushCenter: PushNotificationCenter
        private let appId: String
        private let featureType: OPBadgeRustAlias.OpenAppFeatureType
        private let badgeAPI: OPBadgeAPI
        private let badgeNodeCallback: ((_ badgeNode: OPBadgeRustAlias.OpenAppBadgeNode) -> Void)
        private let badgeRelay = BehaviorRelay<OPBadgeRustAlias.OpenAppBadgeNode?>(value: nil)
        private let disposeBag = DisposeBag()
        
        public init(
            pushCenter: PushNotificationCenter,
            badgeAPI: OPBadgeAPI,
            appId: String,
            featureType: OPBadgeRustAlias.OpenAppFeatureType,
            badgeNodeCallback: @escaping ((_ badgeNode: OPBadgeRustAlias.OpenAppBadgeNode) -> Void)
        ) {
            self.pushCenter = pushCenter
            self.badgeAPI = badgeAPI
            self.appId = appId
            self.featureType = featureType
            self.badgeNodeCallback = badgeNodeCallback
            observeBadgePush()
            pullBadge()
            subscribeBadge()
        }
        
        private func observeBadgePush() {
            pushCenter
                .observable(for: OPBadgeUpdateMessage.self)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (message) in
                    guard let `self` = self else { return }
                    self.onPushBadges(message)
                }).disposed(by: disposeBag)
        }
        
        private func pullBadge() {
            log.info("[OPBadge] start pull badge, appId: \(appId), feature: \(featureType.rawValue)")
            
            badgeAPI.pullBadgeData(
                for: appId,
                featureType: featureType
            )
            .subscribe(onNext: { [weak self] badgeNodes in
                guard let `self` = self else { return }
                log.info("[OPBadge] get badge data response, appId: \(self.appId), feature: \(self.featureType.rawValue)")
                guard let badgeNode = self.filterAppBadge(badgeNodes) else {
                    log.error("[OPBadge] get badge data response, but not requested one, appId: \(self.appId), feature: \(self.featureType.rawValue)")
                    return
                }
                self.updateBadgeIfNeeded(badgeNode)
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                log.error("[OPBadge] request badge fail, appId: \(self.appId), feature: \(self.featureType.rawValue), error: \(error)")
            })
            .disposed(by: disposeBag)
        }
        
        private func onPushBadges(_ message: OPBadgeUpdateMessage) {
            log.info("[OPBadge] receive pushed badge, appId: \(appId), feature: \(featureType.rawValue)")
            guard let node = filterAppBadge(message.pushRequest.noticeNodes) else {
                log.info("[OPBadge] receive pushed badge, but not observed app, appId: \(appId), feature: \(featureType.rawValue)")
                return
            }
            updateBadgeIfNeeded(node)
        }
        
        private func filterAppBadge(
            _ badgeNodes: [OPBadgeRustAlias.OpenAppBadgeNode]
        ) -> OPBadgeRustAlias.OpenAppBadgeNode? {
            let noticeNodes = badgeNodes.compactMap({ noticeNode in
                if noticeNode.appID == appId,
                   noticeNode.feature == featureType {
                    return noticeNode
                }
                return nil
            })
            guard !noticeNodes.isEmpty,
                  let node = noticeNodes.first else {
                log.info("[OPBadge] receive pushed badge, but not observed app, appId: \(appId), feature: \(featureType.rawValue)")
                return nil
            }
            return node
        }
        
        func updateBadgeIfNeeded(_ badge: OPBadgeRustAlias.OpenAppBadgeNode) {
            log.info("[OPBadge] start update badge node, appId: \(appId), feature: \(featureType.rawValue), previousBadgeVersion: \(badgeRelay.value?.version ?? "-1"), currentBadgeVersion: \(badge.version), needShow: \(badge.needShow), badgeNum: \(badge.badgeNum)")
            if let previousBadge = badgeRelay.value,
                  let previousBadgeVersionInt = Int(previousBadge.version),
               let badgeVersionInt = Int(badge.version),
                previousBadgeVersionInt >= badgeVersionInt {
                return
            }
            badgeRelay.accept(badge)
        }
        
        func subscribeBadge() {
            badgeRelay
                .distinctUntilChanged()
                .subscribe(onNext: { [weak self] badgeNode in
                    guard let badge = badgeNode else {
                        return
                    }
                    self?.badgeNodeCallback(badge)
                })
                .disposed(by: disposeBag)
        }
    }
}

@objc
public enum UpdateBadgeNodeActionCode: Int {
    case unknownBadgeCode = 0
    case codeSuccess = 1
    case codeInvalidParams = 2
    case codeNonexistentNode = 3
}

@objcMembers
public final class UpdateAppBadgeNodeResponse : NSObject {
    public var msg: String?
    public var code: UpdateBadgeNodeActionCode = .unknownBadgeCode

    public init(code: UpdateBadgeNodeActionCode, msg: String?) {
        self.code = code
        self.msg = msg
    }
    public override var description: String {
        return "code: \(code) msg: \(msg)"
    }
}

@objc
public enum AppBadgeAppFeatureType: Int {
    case miniApp = 1
    case h5 = 2
}

@objcMembers
public final class AppBadgeNode : NSObject {
    public let appID: String
    public var feature: AppBadgeAppFeatureType = .miniApp
    public var needShow: Bool = false
    public var updateTime: String
    public var badgeNum: Int = -1
    public var extra: String
    public var version: String

    public init(feature: AppBadgeAppFeatureType, appID: String, needShow: Bool, updateTime: String, badgeNum: Int, extra: String, version: String) {
        self.feature = feature
        self.appID = appID
        self.needShow = needShow
        self.updateTime = updateTime
        self.badgeNum = badgeNum
        self.extra = extra
        self.version = version
    }
}

@objcMembers
public final class PullAppBadgeNodeResponse : NSObject {
    public var noticeNodes: [AppBadgeNode]?

    public init(noticeNodes: [AppBadgeNode]?) {
        self.noticeNodes = noticeNodes
    }
}

@objc
public enum AppBadgeUpdateNodeScene: Int {
    case unknown = -1
    case appSetting = 1
    case appAbout = 2
    case workplaceSetting = 3
    case updateBadgeAPI = 4
}

@objc
public enum AppBadgePullNodeScene: Int {
    case unknown = -1
    case rustLocal = 1 // 暂时没有使用
    case rustNet = 2 // updateBadge api 调pull，reportBadge api调pull，批量设置里面的 pull，关于里面pull，设置里面调pull。都是2
    case workplaceCache = 3
    case workplaceServer = 4
}

@objc
public enum UpdateBadgeRequestParametersType: Int {
    case unknown = 0
    case badgeNum = 1
    case needShow = 2
}

@objcMembers
public final class UpdateBadgeRequestParameters : NSObject {
    public var scene: AppBadgeUpdateNodeScene = .unknown
    public var badgeNum: Int = -1
    public var needShow: Bool = false
    public var type: UpdateBadgeRequestParametersType = UpdateBadgeRequestParametersType.unknown

    public init(type: UpdateBadgeRequestParametersType) {
        self.type = type
    }
}

@objcMembers
public final class PullBadgeRequestParameters : NSObject {
    public var scene: AppBadgePullNodeScene = .unknown
    public var fromReportBadge: Bool = false

    public init(scene: AppBadgePullNodeScene) {
        self.scene = scene
    }
}

@objc
public enum AppBadgeAppType: Int {
    case unknown = 0
    case nativeApp = 1
    case html5App = 3
    case webApp = 5
    case nativeCard = 6
}
