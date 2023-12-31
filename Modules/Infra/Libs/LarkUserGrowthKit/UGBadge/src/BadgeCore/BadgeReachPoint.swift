//
//  BadgeReachPoint.swift
//  UGBadge
//
//  Created by liuxianyu on 2021/11/26.
//

import UIKit
import Foundation
import UGContainer
import ServerPB
import LKCommonsLogging

public protocol BadgeReachPointDelegate: AnyObject {
    func onShow(badgeView: UIView, badgeReachPoint: BadgeReachPoint)
    func onHide(badgeView: UIView, badgeReachPoint: BadgeReachPoint)
}

public final class BadgeReachPoint: BasePBReachPoint {
    static let log = Logger.log(BadgeReachPoint.self, category: "UGReach.Badge")

    public typealias ReachPointModel = ServerPB_Ug_reach_material_BadgeMaterial

    public static var reachPointType: ReachPointType = "Badge"

    public weak var delegate: BadgeReachPointDelegate? {
        didSet {
            if delegate != nil {
                self.reportEvent(ReachPointEvent(eventName: .onReady,
                                                 reachPointType: BadgeReachPoint.reachPointType,
                                                 reachPointId: reachPointId,
                                                 extra: [:]))
            }
        }
    }

    public let handlerRegistry = BadgeHandlerRegistry()

    public var badgeView: UIView {
        return containerView
    }

    let containerView: BadgeContainer
    public var badgeData: BadgeInfo?

    required public init() {
        containerView = BadgeContainer()
        containerView.delegate = self
    }

    public func register(badgeName: String, for handler: BadgeHandler) {
        handlerRegistry.register(badgeName: badgeName, for: handler)
    }

    public func onUpdateData(data: ReachPointModel) -> Bool {
        self.badgeData = data
        Self.log.info("Badge consume type: \(data.base.consumeType)")
        return containerView.onUpdateData(badgeData: data)
    }

    public func onShow() {
        Self.log.info("Badge show data is empty: \(containerView.badgeData == nil)")
        guard let badgeData = self.badgeData else {
            return
        }
        delegate?.onShow(badgeView: containerView, badgeReachPoint: self)
    }

    public func onHide() {
        Self.log.info("Badge hide data is empty: \(containerView.badgeData == nil)")
        guard let badgeData = self.badgeData else {
            return
        }
        containerView.onHide()
        delegate?.onHide(badgeView: containerView, badgeReachPoint: self)
        reportEvent(eventName: .didHide)
    }

    public func reportShow() {
        guard let badgeData = self.badgeData else {
            return
        }
        /// 需要业务主动调用，内部埋点，上报事件
        reportEvent(eventName: .didShow)
    }

    public func reportClosed() {
        guard let badgeData = self.badgeData else {
            return
        }
        reportEvent(eventName: .consume)
    }

    public func reportEvent(eventName: ReachPointEvent.Key) {
        reportEvent(ReachPointEvent(eventName: eventName,
                                    reachPointType: Self.reachPointType,
                                    reachPointId: reachPointId,
                                    materialKey: self.badgeData?.base.key ?? nil,
                                    materialId: self.badgeData?.base.id ?? nil,
                                    consumeTypeValue: self.badgeData?.base.consumeType.rawValue ?? 0,
                                    extra: [:]))
    }
}

extension BadgeReachPoint: LarkBadgeDelegate {
    public func onBadgeShow() {
        self.reportShow()
    }
}
