//
//  SpotlightBaseView.swift
//  UGSpotlight
//
//  Created by zhenning on 2021/3/25.
//

import UIKit
import Foundation
import UGContainer
import ServerPB
import LarkGuideUI
import LKCommonsLogging

// MARK: - SpotlightReachPoint

public final class SpotlightReachPoint: BasePBReachPoint {

    static let log = Logger.log(SpotlightReachPoint.self, category: "LarkUserGrowthKit.UGSpotlight")

    public static var reachPointType: ReachPointType = "Spotlight"
    public weak var singleDelegate: UGSingleSpotlightDelegate?
    public weak var multiDelegate: UGMultiSpotlightDelegate?

    public weak var datasource: SpotlightReachPointDataSource? {
        didSet {
            if datasource != nil {
                self.reportEvent(ReachPointEvent(eventName: .onReady,
                                                 reachPointType: SpotlightReachPoint.reachPointType,
                                                 reachPointId: reachPointId,
                                                 extra: [:]))
            }
        }
    }
    private var ugSpotlightData: UGSpotlightData?

    required public init() {
    }

    public func onShow() {
        showSpotlight()
    }

    public func onHide() {
        Self.log.debug("SpotlightReachPoint onHide trigger")
        guard let spotlightData = ugSpotlightData,
              let datasource = datasource else { return }
        ugSpotlightData = nil
        // 气泡锚点
        guard let provider = datasource.onShow(spotlightReachPoint: self, spotlightData: spotlightData, isMult: spotlightData.isMult) else { return }

        // 关闭当前的气泡
        GuideUITool.closeGuideIfNeeded(hostProvider: provider.hostProvider())

        let result = datasource.onHide(spotlightReachPoint: self, spotlightData: spotlightData)
        Self.log.debug("SpotlightReachPoint onHide result = \(result)")
    }

    public func onUpdateData(data: SpotlightMaterials) -> Bool {
        // update bubble view data
        let ugSpotlightData = UGSpotlightData(spotlightData: SpotlightData(spotlightMaterials: data))
        self.ugSpotlightData = ugSpotlightData
        return true
    }

    private func showSpotlight() {
        Self.log.debug("SpotlightReachPoint showBubble trigger")
        guard let spotlightData = ugSpotlightData,
              let datasource = datasource else { return }

        // 气泡锚点
        guard let provider = datasource.onShow(spotlightReachPoint: self, spotlightData: spotlightData, isMult: spotlightData.isMult) else { return }

        let targetSourceTypes: [TargetSourceType] = provider.targetSourceTypes()
        guard let bubbleConfigs = SpotlightDataManager.transformSpotlightPBToBubbleConfig(spotlightPB: spotlightData,
                                                                                          targetSourceTypes: targetSourceTypes),
              let firstBubbleConfig = bubbleConfigs.first else { return }
        let maskConfig = SpotlightDataManager.transformSpotlightPBToMaskConfigData(spotlightPB: spotlightData)

        let singleBubbleConfig = SingleBubbleConfig(delegate: self, bubbleConfig: firstBubbleConfig, maskConfig: maskConfig)
        var bubbleType: BubbleType = .single(singleBubbleConfig)
        if bubbleConfigs.count > 1 {
            let multiBubbleConfig = MultiBubblesConfig(delegate: self, bubbleItems: bubbleConfigs, maskConfig: maskConfig)
            bubbleType = .multiple(multiBubbleConfig)
        }
        GuideUITool.displayBubble(hostProvider: provider.hostProvider(), bubbleType: bubbleType) { [weak self] in
            guard let self = self else { return }
            // TODO：多步气泡的上报，先取第一个
            let materialKey = self.ugSpotlightData?.spotlightData.spotlightMaterials.base.key ?? ""
            let materialID = self.ugSpotlightData?.spotlightData.spotlightMaterials.base.id
            self.reportEvent(ReachPointEvent(eventName: .consume,
                                             reachPointType: SpotlightReachPoint.reachPointType,
                                             reachPointId: self.reachPointId,
                                             materialKey: materialKey,
                                             materialId: materialID,
                                             extra: ["event": "didClickLeftButton"]))
        }
    }

    // 关闭当前的气泡
    public func closeSpotlight(hostProvider: UIViewController, customWindow: UIWindow? = nil) {
        GuideUITool.closeGuideIfNeeded(hostProvider: hostProvider, customWindow: customWindow)
    }
}

// MARK: - LarkGuideUI Delegate

extension SpotlightReachPoint: GuideSingleBubbleDelegate {
    public func didClickLeftButton(bubbleView: GuideBubbleView) {
        self.singleDelegate?.didClickLeftButton(bubbleConfig: bubbleView.bubbleConfig)
        self.reportEvent(ReachPointEvent(eventName: .onClick,
                                         reachPointType: SpotlightReachPoint.reachPointType,
                                         reachPointId: reachPointId,
                                         extra: ["event": "didClickLeftButton"]))
        Self.log.debug("SpotlightReachPoint didClickLeftButton: \(bubbleView.bubbleConfig)")
    }

    public func didClickRightButton(bubbleView: GuideBubbleView) {
        self.singleDelegate?.didClickRightButton(bubbleConfig: bubbleView.bubbleConfig)
        self.reportEvent(ReachPointEvent(eventName: .onClick,
                                         reachPointType: SpotlightReachPoint.reachPointType,
                                         reachPointId: reachPointId,
                                         extra: ["event": "didClickRightButton"]))
        Self.log.debug("SpotlightReachPoint didClickRightButton: \(bubbleView.bubbleConfig)")
    }

    // 点击气泡事件
    public func didTapBubbleView(bubbleView: GuideBubbleView) {
        self.singleDelegate?.didTapBubbleView(bubbleConfig: bubbleView.bubbleConfig)
        self.reportEvent(ReachPointEvent(eventName: .onClick,
                                         reachPointType: SpotlightReachPoint.reachPointType,
                                         reachPointId: reachPointId,
                                         extra: ["event": "didTapBubbleView"]))
        Self.log.debug("SpotlightReachPoint didTapBubbleView: \(bubbleView.bubbleConfig)")
    }
}

extension SpotlightReachPoint: GuideMultiBubblesViewDelegate {
    public func didClickNext(stepView: GuideBubbleView, for step: Int) {
        self.multiDelegate?.didClickNext(bubbleConfig: stepView.bubbleConfig, for: step)
        self.reportEvent(ReachPointEvent(eventName: .onClick,
                                         reachPointType: SpotlightReachPoint.reachPointType,
                                         reachPointId: reachPointId,
                                         extra: [
                                            "event": "didClickSkip",
                                            "step": "\(step)"
                                         ]))
        Self.log.debug("SpotlightReachPoint didClickNext: \(stepView.bubbleConfig), step: \(step)")
    }

    public func didClickPrevious(stepView: GuideBubbleView, for step: Int) {
        self.multiDelegate?.didClickNext(bubbleConfig: stepView.bubbleConfig, for: step)
        self.reportEvent(ReachPointEvent(eventName: .onClick,
                                         reachPointType: SpotlightReachPoint.reachPointType,
                                         reachPointId: reachPointId,
                                         extra: [
                                            "event": "didClickSkip",
                                            "step": "\(step)"
                                         ]))
        Self.log.debug("SpotlightReachPoint didClickPrevious: \(stepView.bubbleConfig), step: \(step)")
    }

    // 在bottomConfig中指定skipTitle后，点击了skipTitle后回调
    public func didClickSkip(stepView: GuideBubbleView, for step: Int) {
        self.multiDelegate?.didClickSkip(bubbleConfig: stepView.bubbleConfig, for: step)
        self.reportEvent(ReachPointEvent(eventName: .onClick,
                                         reachPointType: SpotlightReachPoint.reachPointType,
                                         reachPointId: reachPointId,
                                         extra: [
                                            "event": "didClickSkip",
                                            "step": "\(step)"
                                         ]))
        Self.log.debug("SpotlightReachPoint didClickSkip: \(stepView.bubbleConfig), step: \(step)")
    }

    public func didClickEnd(stepView: GuideBubbleView) {
        self.multiDelegate?.didClickEnd(bubbleConfig: stepView.bubbleConfig)
        self.reportEvent(ReachPointEvent(eventName: .onClick,
                                         reachPointType: SpotlightReachPoint.reachPointType,
                                         reachPointId: reachPointId,
                                         extra: ["event": "didClickEnd"]))
        Self.log.debug("SpotlightReachPoint didClickEnd: \(stepView.bubbleConfig)")
    }
}

// MARK: - Delegate

// 视图代理- 单个气泡
public protocol UGSingleSpotlightDelegate: AnyObject {
    // 点击左边按钮
    func didClickLeftButton(bubbleConfig: BubbleItemConfig)
    // 点击右边按钮
    func didClickRightButton(bubbleConfig: BubbleItemConfig)
    // 点击气泡事件
    func didTapBubbleView(bubbleConfig: BubbleItemConfig)
}
extension UGSingleSpotlightDelegate {
    // 点击左边按钮
    public func didClickLeftButton(bubbleConfig: BubbleItemConfig) {}
    // 点击右边按钮
    public func didClickRightButton(bubbleConfig: BubbleItemConfig) {}
    // 点击气泡事件
    public func didTapBubbleView(bubbleConfig: BubbleItemConfig) {}
}

// 视图代理- 单个气泡
public protocol UGMultiSpotlightDelegate: AnyObject {
    func didClickNext(bubbleConfig: BubbleItemConfig, for step: Int)
    func didClickPrevious(bubbleConfig: BubbleItemConfig, for step: Int)
    // 在bottomConfig中指定skipTitle后，点击了skipTitle后回调
    func didClickSkip(bubbleConfig: BubbleItemConfig, for step: Int)
    func didClickEnd(bubbleConfig: BubbleItemConfig)
}
extension UGMultiSpotlightDelegate {
    public func didClickNext(bubbleConfig: BubbleItemConfig, for step: Int) {}
    public func didClickPrevious(bubbleConfig: BubbleItemConfig, for step: Int) {}
    // 在bottomConfig中指定skipTitle后，点击了skipTitle后回调
    public func didClickSkip(bubbleConfig: BubbleItemConfig, for step: Int) {}
    public func didClickEnd(bubbleConfig: BubbleItemConfig) {}
}

// MARK: - DataSource

public protocol SpotlightReachPointDataSource: AnyObject {
    /// SpotlightBizProvider提供锚点等信息，如果拿不到不会展示气泡， isMult: 是否是多气泡
    func onShow(spotlightReachPoint: SpotlightReachPoint, spotlightData: UGSpotlightData, isMult: Bool) -> SpotlightBizProvider?
    func onHide(spotlightReachPoint: SpotlightReachPoint, spotlightData: UGSpotlightData) -> Bool
}
extension SpotlightReachPointDataSource {
    public func onHide(spotlightReachPoint: SpotlightReachPoint, spotlightData: UGSpotlightData) -> Bool { return true }
}
