//
//  GuideBubbleController.swift
//  LarkGuideUI
//
//  Created by zhenning on 2020/6/3.
//

import Foundation
import UIKit
import LKCommonsLogging

final class GuideBubbleController: BaseMaskController {

    var viewModel: GuideBubbleViewModel

    private var singleBubbleDelegate: GuideSingleBubbleDelegate? {
        return viewModel.singleBubbleConfig?.delegate
    }
    private var multiBubblesDelegate: GuideMultiBubblesViewDelegate? {
        return viewModel.multiBubblesConfig?.delegate
    }
    private lazy var bubbleView: GuideBubbleView = {
        var bubbleConfig = viewModel.getCurrentBubbleItemConfig()
        let bubble = GuideBubbleView(bubbleConfig: bubbleConfig)
        bubble.dataSource = self
        bubble.singleBubbleDelegate = self
        bubble.multiBubblesDelegate = self
        return bubble
    }()
    static let logger = Logger.log(GuideBubbleController.self)
    // 点击回调
    var bubbleViewTapHandler: GuideViewTapHandler?

    init(viewModel: GuideBubbleViewModel) {
        self.viewModel = viewModel
        super.init()
        self.shadowAlpha = viewModel.getShadowAlpha()
        self.windowBackgroundColor = viewModel.getWindowBackgroundColor()
        self.snapshotView = viewModel.getSnapshotView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.prepareTargetRectLayout()
        self.enableBackgroundTap = self.viewModel.checkEnableBackgroundTap()

        if let snapshotView = snapshotView {
            snapshotView.isUserInteractionEnabled = false
            self.view.addSubview(snapshotView)
            self.view.sendSubviewToBack(snapshotView)
        }
        self.view.addSubview(self.bubbleView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.prepareTargetRectLayout()
        updateMaskRectPath(bubbleItem: viewModel.currBubbleItem)
        self.bubbleView.refreshBubbleContent()
    }

    private var currentUserInterfaceStyle: UIUserInterfaceStyle?
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if currentUserInterfaceStyle == self.traitCollection.userInterfaceStyle { return }
        self.currentUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        bubbleView.updateBannerView()
    }

    override func showInWindow(to window: UIWindow, makeKey: Bool) {
        super.showInWindow(to: window, makeKey: makeKey)
        self.showBubble()
    }
}

extension GuideBubbleController {

    // 通过view转换targetView相对引导页的坐标
    @discardableResult
    func updateItemTargetRect(item: BubbleItemConfig) -> BubbleItemConfig {
        if let targetView = item.targetAnchor.targetView {
            let targetArea = viewModel.transformTargetViewRect(rooterView: view, targetView: targetView, item: item)
            item.targetAnchor.targetRect = targetArea
            let handledItem = BubbleItemConfig(guideAnchor: item.targetAnchor,
                                               textConfig: item.textConfig,
                                               bannerConfig: item.bannerConfig,
                                               bottomConfig: item.bottomConfig,
                                               containerConfig: item.containerConfig)
            return handledItem
        }
        return item
    }

    /// 阴影高亮区域
    func prepareTargetRectLayout() {
        // 处理每个Item的targetRect
        viewModel.bubbleItems.forEach {
            updateItemTargetRect(item: $0)
        }

        let targetsLayoutGuide = viewModel.targetsLayoutGuide

        targetsLayoutGuide.forEach { self.addMaskLayoutGuide(layoutGuide: $0) }
        zip(viewModel.bubbleItems, targetsLayoutGuide).forEach { (item, guide) in
            let targetRect = item.targetAnchor.targetRect
            guide.snp.remakeConstraints { (make) in
                make.size.equalTo(targetRect.size)
                make.leading.equalTo(targetRect.minX)
                make.top.equalTo(targetRect.minY)
            }
        }
    }

    // 展示Bubble
    func showBubble() {
        self.bubbleView.refreshBubbleContent()
    }
}

extension GuideBubbleController {

    private func updateMaskRectPath(bubbleItem: BubbleItemConfig?) {
        guard enableBackgroundMask, let item = bubbleItem else { return }

        let contentPath = viewModel.updateMaskRectPath(bubbleItem: item, containerRect: view.bounds)
        self.updateMaskShadowPath(shadowPath: contentPath)
    }
}

extension GuideBubbleController: GuideSingleBubbleDelegate {
    func didClickLeftButton(bubbleView: GuideBubbleView) {
        self.singleBubbleDelegate?.didClickLeftButton(bubbleView: bubbleView)
        // handle buttontype
        if case .close = bubbleView.bubbleConfig.bottomConfig?.rightBtnInfo.buttonType {
            // 关闭气泡
            self.removeFromWindow()
        }
    }
    func didClickRightButton(bubbleView: GuideBubbleView) {
        self.singleBubbleDelegate?.didClickRightButton(bubbleView: bubbleView)
        // handle buttontype
        if case .close = bubbleView.bubbleConfig.bottomConfig?.rightBtnInfo.buttonType {
            // 关闭气泡
            self.removeFromWindow()
        }
    }
    func didTapBubbleView(bubbleView: GuideBubbleView) {
        self.singleBubbleDelegate?.didTapBubbleView(bubbleView: bubbleView)
        if let bubbleTapHandler = self.bubbleViewTapHandler {
            bubbleTapHandler(bubbleView)
        }
    }
}

extension GuideBubbleController: GuideMultiBubblesViewDelegate {
    func didClickNext(stepView: GuideBubbleView, for step: Int) {
        viewModel.currBubbleItem = viewModel.bubbleItems[step]
        self.multiBubblesDelegate?.didClickNext(stepView: stepView, for: step)
        GuideBubbleController.logger.debug("didClickNext step = \(step)")
    }
    func didClickEnd(stepView: GuideBubbleView) {
        self.multiBubblesDelegate?.didClickEnd(stepView: stepView)
        viewModel.currBubbleItem = nil
        /// 结束流程
        self.removeFromWindow()
        GuideBubbleController.logger.debug("didClickEnd")
    }
    func didClickPrevious(stepView: GuideBubbleView, for step: Int) {
        viewModel.currBubbleItem = viewModel.bubbleItems[step]
        self.multiBubblesDelegate?.didClickPrevious(stepView: stepView, for: step)
        GuideBubbleController.logger.debug("didClickPrevious step = \(step)")
    }
    func didClickSkip(stepView: GuideBubbleView, for step: Int) {
        self.multiBubblesDelegate?.didClickSkip(stepView: stepView, for: step)
        viewModel.currBubbleItem = nil
        /// 结束流程
        self.removeFromWindow()
        GuideBubbleController.logger.debug("didClickSkip step = \(step)")
    }
}

extension GuideBubbleController: GuideMultiBubblesDataSource {

    func contentForStep(_ actionView: GuideBubbleView, for step: Int) -> BubbleItemConfig? {
        viewModel.getBubbleItemConfig(by: viewModel.bubbleType, step: step)
    }

    func numberOfSteps(actionView: GuideBubbleView) -> Int {
        return self.viewModel.bubbleItems.count
    }

    // 根据锚点位置，调整屏幕中气泡的位置
    // arrowOffset: 箭头离默认中心的偏移量
    func adjustBubblePositionForStep(for step: Int) -> (direction: BubbleArrowDirection, arrowOffset: CGFloat) {
        let bubbleContentSize = self.bubbleView.bubbleContentSize
        let safeAreaInset = viewModel.currBubbleItem?.targetAnchor.ignoreSafeArea ?? false ? UIEdgeInsets.zero : view.safeAreaInsets
        let containerSafeAreaFrame = CGRect(x: view.frame.minX + safeAreaInset.left,
                                    y: view.frame.minY + safeAreaInset.top,
                                    width: view.frame.width - safeAreaInset.left - safeAreaInset.right,
                                    height: view.frame.height - safeAreaInset.top - safeAreaInset.bottom)
        let direction = viewModel.estimateBubbleArrowDirection(bubbleSize: bubbleContentSize,
                                                               containerSafeAreaFrame: containerSafeAreaFrame)
        let offset = viewModel.caculateBubbleOffset(for: step,
                                                    bubbleSize: bubbleContentSize,
                                                    containerSafeAreaFrame: containerSafeAreaFrame,
                                                    direction: direction)
        var arrowSize = BubbleViewArrow.Layout.arrowVerticalSize
        let targetGuide = viewModel.targetsLayoutGuide[step]
        GuideBubbleController.logger.debug("️adjustBubblePositionForStep",
                                           additionalData: [
                                            "direction": "\(direction)",
                                            "targetGuide": "\(targetGuide)",
                                            "safeAreaInset": "\(safeAreaInset)",
                                            "containerSafeAreaFrame": "\(containerSafeAreaFrame)",
                                            "offset": "\(offset)"
        ])

        /// 更新阴影路径
        self.updateMaskRectPath(bubbleItem: viewModel.currBubbleItem)
        /// 更新气泡箭头方向
        switch direction {
        case .up:
            self.bubbleView.snp.remakeConstraints { (make) in
                make.centerX.equalTo(targetGuide).offset(-offset.centerOffset)
                make.top.equalTo(targetGuide.snp.bottom).offset(Layout.arrowSpacing)
                make.size.equalTo(CGSize(width: bubbleContentSize.width, height: bubbleContentSize.height + arrowSize.height))
            }
            return (.up, offset.arrowOffset)
        case .left:
            arrowSize = BubbleViewArrow.Layout.arrowHorizontalSize
            self.bubbleView.snp.remakeConstraints { (make) in
                make.centerY.equalTo(targetGuide).offset(-offset.centerOffset)
                make.leading.equalTo(targetGuide.snp.trailing).offset(Layout.arrowSpacing)
                make.size.equalTo(CGSize(width: bubbleContentSize.width + arrowSize.width, height: bubbleContentSize.height))
            }
            return (.left, offset.arrowOffset)
        case .right:
            arrowSize = BubbleViewArrow.Layout.arrowHorizontalSize
            self.bubbleView.snp.remakeConstraints { (make) in
                make.centerY.equalTo(targetGuide).offset(-offset.centerOffset)
                make.trailing.equalTo(targetGuide.snp.leading).offset(-Layout.arrowSpacing)
                make.size.equalTo(CGSize(width: bubbleContentSize.width + arrowSize.width, height: bubbleContentSize.height))
            }
            return (.right, offset.arrowOffset)
        case .down:
            self.bubbleView.snp.remakeConstraints { (make) in
                make.centerX.equalTo(targetGuide).offset(-offset.centerOffset)
                make.bottom.equalTo(targetGuide.snp.top).offset(-Layout.arrowSpacing)
                make.size.equalTo(CGSize(width: bubbleContentSize.width, height: bubbleContentSize.height + arrowSize.height))
            }
            return (.down, offset.arrowOffset)
        }
    }
}

extension GuideBubbleController {
    enum Layout {
        // 箭头和所指目标区域间距
        static let arrowSpacing: CGFloat = BaseBubbleView.Layout.arrowSpacing
    }
}
