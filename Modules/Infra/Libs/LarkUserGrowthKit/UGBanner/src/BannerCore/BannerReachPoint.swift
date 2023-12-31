//
//  BannerReachPoint.swift
//  AppContainer
//
//  Created by mochangxing on 2021/3/1.
//

import UIKit
import Foundation
import UGContainer
import ServerPB
import EENavigator
import LKCommonsLogging
import LKCommonsTracker

public protocol BannerReachPointDelegate: AnyObject {
    func onShow(bannerView: UIView, bannerData: BannerInfo, reachPoint: BannerReachPoint)

    func onHide(bannerView: UIView, bannerData: BannerInfo, reachPoint: BannerReachPoint)
}

public final class BannerReachPoint: BasePBReachPoint {
    static let log = Logger.log(BannerReachPoint.self, category: "UGReach.Banner")

    public typealias ReachPointModel = ServerPB_Ug_reach_material_BannerMaterialCollection

    public static var reachPointType: ReachPointType = "Banner"

    public weak var delegate: BannerReachPointDelegate? {
        didSet {
            if delegate != nil {
                self.reportEvent(ReachPointEvent(eventName: .onReady,
                                                 reachPointType: BannerReachPoint.reachPointType,
                                                 reachPointId: reachPointId,
                                                 extra: [:]))
            }
        }
    }

    public let handlerRegistry = BannerHandlerRegistry()

    public var bannerView: UIView {
        return containerView
    }

    let containerView: BannerContainer
    var bannerData: BannerInfo?

    required public init() {
        containerView = BannerContainer()
        containerView.delegate = self
    }

    var navigator: Navigatable?
    public func setNavigator(navigator: Navigatable) {
        self.navigator = navigator
    }

    public func register(bannerName: String, for handler: BannerHandler) {
        handlerRegistry.register(bannerName: bannerName, for: handler)
    }

    public func onShow() {
        Self.log.info("banner show data is empty: \(containerView.bannerData == nil)")
        guard let bannerData = self.bannerData else {
            return
        }
        delegate?.onShow(bannerView: containerView,
                         bannerData: bannerData,
                         reachPoint: self)
    }

    public func reportShow() {
        guard let bannerData = self.bannerData else {
            return
        }
        /// 需要业务主动调用，内部埋点，上报事件
        reportEvent(eventName: .didShow)
        Tracker.post(TeaEvent("growth_banner_view", params: ["task_id": bannerData.base.taskID,
                                                             "banner_id": bannerData.bannerName]))
    }

    public func reportClick() {
        guard let bannerData = self.bannerData else {
            return
        }
        Tracker.post(TeaEvent("growth_banner_click", params: ["task_id": bannerData.base.taskID,
                                                              "click": "open",
                                                              "banner_id": bannerData.bannerName]))
        reportEvent(eventName: .onClick)
    }

    public func reportClosed() {
        guard let bannerData = self.bannerData else {
            return
        }
        Tracker.post(TeaEvent("growth_banner_click", params: ["task_id": bannerData.base.taskID, "click": "close"]))
        reportEvent(eventName: .consume)
    }

    public func onHide() {
        Self.log.info("banner hide data is empty: \(containerView.bannerData == nil)")
        guard let bannerData = self.bannerData else {
            return
        }
        containerView.onHide()
        delegate?.onHide(bannerView: containerView,
                         bannerData: bannerData,
                         reachPoint: self)
        reportEvent(eventName: .didHide)
    }

    public func onUpdateData(data: ReachPointModel) -> Bool {
        guard let bannerInfo = data.banners.first else {
            return false
        }
        self.bannerData = bannerInfo
        return containerView.onUpdateData(bannerData: bannerInfo)
    }

    public func reportEvent(eventName: ReachPointEvent.Key) {
        reportEvent(ReachPointEvent(eventName: eventName,
                                    reachPointType: Self.reachPointType,
                                    reachPointId: reachPointId,
                                    materialKey: self.bannerData?.base.key ?? nil,
                                    materialId: self.bannerData?.base.id ?? nil,
                                    extra: ["bannerName": self.bannerData?.bannerName ?? "none"]))
    }
}

extension BannerReachPoint: LarkBannerDelegate {
    public func onBannerClosed(bannerView: LarkBaseBannerView) {
        Self.log.info("banner closed data is empty: \(self.bannerData == nil)")
        guard let bannerData = self.bannerData else {
            return
        }
        self.reportClosed()
        // 业务方是否拦截关闭事件
        if let handler = handlerRegistry.getBannerHandler(bannerName: bannerData.bannerName),
              handler.handleBannerClosed(bannerView: containerView) {
            Self.log.info("banner closed event was intercepted",
                          additionalData: ["bannerName": bannerData.bannerName])
            return
        }
        self.hide()
    }

    public func onBannerClick(bannerView: LarkBaseBannerView, url: String) {
        guard let bannerData = self.bannerData else {
            return
        }
        self.reportClick()
        // 判断是否被业务拦截点击事件
        if let handler = handlerRegistry.getBannerHandler(bannerName: bannerData.bannerName),
              handler.handleBannerClick(bannerView: containerView, url: url) {
            Self.log.info("banner click event was intercepted",
                          additionalData: ["bannerName": bannerData.bannerName])
            return
        }

        // 判断是否 url 是否合法
        guard let url = URL(string: url), let window = bannerView.window else {
            return
        }

        // 默认调用 Navigator 路由
        guard let navigator else {
            #if DEBUG
            fatalError("navigator should not be emtpy")
            #else
            Navigator.shared.push(url, from: window) //Global
            return
            #endif
        }
        navigator.push(url, from: window)
    }

    public func onBannerShow() {
        self.reportShow()
    }
}
