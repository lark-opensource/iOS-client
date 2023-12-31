//
//  GuideBubbleViewModel.swift
//  LarkGuideUI
//
//  Created by zhenning on 2020/6/3.
//

import Foundation
import UIKit
import LKCommonsLogging

final class GuideBubbleViewModel {
    var bubbleType: BubbleType {
        didSet {
            self.reloadData()
        }
    }
    private(set) var targetsLayoutGuide: [UILayoutGuide] = []
    private(set) var bubbleItems: [BubbleItemConfig] = [] {
        didSet {
            assert(!bubbleItems.isEmpty, "bubbles should not be empty!")
            self.targetsLayoutGuide = bubbleItems.map({ _ in UILayoutGuide() })
        }
    }
    private(set) var singleBubbleConfig: SingleBubbleConfig?
    private(set) var multiBubblesConfig: MultiBubblesConfig?
    /// 当前的气泡
    var currBubbleItem: BubbleItemConfig?

    init(bubbleType: BubbleType) {
        self.bubbleType = bubbleType
        self.reloadData()
    }

    func reloadData() {
        var bubbleItems: [BubbleItemConfig] = []
        switch bubbleType {
        case let .single(singleConfig):
            self.singleBubbleConfig = singleConfig
            bubbleItems = [singleConfig.bubbleConfig]
        case let .multiple(multiConfig):
            self.multiBubblesConfig = multiConfig
            let tempItems = multiConfig.bubbleItems
            multiConfig.bubbleItems.enumerated().forEach { (index: Int, _) in
                tempItems[index].bottomConfig = getFlowBottomConfig(config: multiConfig, step: index)
            }
             bubbleItems = tempItems
        }
        self.bubbleItems = bubbleItems
        self.currBubbleItem = getBubbleItemConfig(by: bubbleType, step: 0)
    }

    /// 点击背景是否可以响应
    /// 1. 多个气泡下，带步骤按钮，背景不响应，需要点击步骤按钮
    /// 2. 单个气泡下，底部带按钮，则背景不响应
    /// 3. 单个气泡下，默认带按钮不响应，但如果强制开启响应，则点击背景响应
    func checkEnableBackgroundTap() -> Bool {
        switch bubbleType {
        case let .single(singleConfig):
            if let maskConfig = singleConfig.maskConfig,
               let maskInteractionForceOpen = maskConfig.maskInteractionForceOpen {
                return maskInteractionForceOpen
            }
            let hasBottom = singleConfig.bubbleConfig.bottomConfig != nil
            return !hasBottom
        case let .multiple(multiConfig):
            return multiConfig.bubbleItems.count == 1
        }
    }

    // 蒙层背景阴影设置
    func getShadowAlpha() -> CGFloat? {
        switch self.bubbleType {
        case let .single(singleConfig):
            if let maskConfig = singleConfig.maskConfig {
                return maskConfig.shadowAlpha ?? BaseMaskController.Layout.shadowAlpha
            }
            return nil
        case let .multiple(multiConfig):
            if let maskConfig = multiConfig.maskConfig {
                return maskConfig.shadowAlpha ?? BaseMaskController.Layout.shadowAlpha
            }
            return nil
        }
    }

    // 设置window底色
    func getWindowBackgroundColor() -> UIColor? {
        switch self.bubbleType {
        case let .single(singleConfig):
            if let maskConfig = singleConfig.maskConfig {
                return maskConfig.windowBackgroundColor
            }
            return nil
        case let .multiple(multiConfig):
            if let maskConfig = multiConfig.maskConfig {
                return maskConfig.windowBackgroundColor
            }
            return nil
        }
    }

    func getSnapshotView() -> UIView? {
        switch self.bubbleType {
        case let .single(singleConfig):
            if let maskConfig = singleConfig.maskConfig {
                return maskConfig.snapshotView
            }
            return nil
        case let .multiple(multiConfig):
            if let maskConfig = multiConfig.maskConfig {
                return maskConfig.snapshotView
            }
            return nil
        }
    }

    // 根据气泡类型参数获取气泡配置
    func getBubbleItemConfig(by bubbleType: BubbleType, step: Int) -> BubbleItemConfig {
        // step区间校验
        assert(!self.bubbleItems.isEmpty && (step < self.bubbleItems.count),
               "bubbleItems is empty or step should not over count")
        return self.bubbleItems[step]
    }

    // 根据气泡类型参数获取气泡配置, step标识多气泡的步骤
    func getCurrentBubbleItemConfig(step: Int? = nil) -> BubbleItemConfig {
        switch bubbleType {
        case let .single(singleConfig):
            self.singleBubbleConfig = singleConfig
            let bubbleConfig = singleConfig.bubbleConfig
            return bubbleConfig
        case let .multiple(multiConfig):
            self.multiBubblesConfig = multiConfig
            // step区间校验
            assert(!multiConfig.bubbleItems.isEmpty, "bubbleItems should not be empty")
            let bubbleItem = self.getBubbleItemConfig(by: bubbleType, step: step ?? 0)
            return bubbleItem
        }
    }

    // 获取底部的配置
    func getFlowBottomConfig(config: MultiBubblesConfig, step: Int) -> BottomConfig? {
        guard step < config.bubbleItems.count else { return nil }

        let bubbleItem = config.bubbleItems[step]
        // if only one bubble
        if config.bubbleItems.count == 1 {
            return bubbleItem.bottomConfig
        }
        let bottomConfig = bubbleItem.bottomConfig
        let isFlowEnd = (step == config.bubbleItems.count - 1)

        let endTitle = config.endTitle ?? Text.defaultEnd
        var leftTitle = Text.defaultPrevious
        var nextTitle = Text.defaultNext
        if let configLeftTitle = bottomConfig?.leftBtnInfo?.title,
           !configLeftTitle.isEmpty {
            leftTitle = configLeftTitle
        }
        if let configNextTitle = bottomConfig?.rightBtnInfo.title,
           !configNextTitle.isEmpty {
            nextTitle = configNextTitle
        }
        let rightTitle = isFlowEnd ? endTitle : nextTitle
        return BottomConfig(leftBtnInfo: ButtonInfo(title: leftTitle, skipTitle: bottomConfig?.leftBtnInfo?.skipTitle),
                            rightBtnInfo: ButtonInfo(title: rightTitle, skipTitle: bottomConfig?.rightBtnInfo.skipTitle))
    }
}

extension GuideBubbleViewModel {

    // 估计气泡的方向
    func estimateBubbleArrowDirection(bubbleSize: CGSize,
                                      containerSafeAreaFrame: CGRect) -> BubbleArrowDirection {
        guard let item = currBubbleItem else { return .up }
        // if user has specified direction
        if let arrowDirection = item.targetAnchor.arrowDirection { return arrowDirection }

        let focusArea = item.targetAnchor.targetRect
        let arrowSize = BubbleViewArrow.Layout.arrowHorizontalSize
        let (left, top, right, bottom) = (focusArea.minX, focusArea.minY,
                                          containerSafeAreaFrame.width - focusArea.maxX,
                                          containerSafeAreaFrame.height - focusArea.maxY)
        GuideBubbleController.logger.debug("estimateBubbleArrowDirection",
                                           additionalData: ["left": "\(left)",
                                            "top": "\(top)",
                                            "right": "\(right)",
                                            "bottom": "\(bottom)",
                                            "bubbleSize": "\(bubbleSize)"
        ])

        // 1. bottom: bubble at the top of focusArea
        if top >= bubbleSize.height + arrowSize.height + Layout.bubbleEdgeInset && top >= bottom {
            return .down
        }
        // 2. top : bubble at the bottom of focusArea
        if top < bottom && bottom >= bubbleSize.height + arrowSize.height + Layout.bubbleEdgeInset {
            return .up
        }
        // 3. right: bubble at the left of focusArea
        if left >= bubbleSize.width + arrowSize.width + Layout.bubbleEdgeInset && left >= right {
            return .right
        }
        // 4. left: bubble at the right of focusArea
        if left < right && right >= bubbleSize.width + arrowSize.width + Layout.bubbleEdgeInset {
            return .left
        }
        return .up
    }

    // arrowOffset: 箭头的origin坐标（竖直方向x/水平方向y）
    // centerOffset: 气泡中点距离锚点中心偏移的距离
    // containerSafeAreaFrame: 容器的安全区域内的大小
    // 图示说明：https://bytedance.feishu.cn/docs/doccn76K5qbos1k12G7Oe6kMWOv#cP6GF7
    func caculateBubbleOffset(for step: Int,
                                bubbleSize: CGSize,
                                containerSafeAreaFrame: CGRect,
                                direction: BubbleArrowDirection) -> (arrowOffset: CGFloat, centerOffset: CGFloat) {
            guard let item = currBubbleItem else { return (0.0, 0.0) }

            let targetRect = item.targetAnchor.targetRect
            let halfBubbleWidth = bubbleSize.width / 2.0
            let halfBubbleHeight = bubbleSize.height / 2.0
            // width/height
            var halfBubbleArrowLenth = BubbleViewArrow.Layout.arrowVerticalSize.width / 2.0
            let (left, top, right, bottom) = (targetRect.minX - containerSafeAreaFrame.minX,
                                              targetRect.minY - containerSafeAreaFrame.minY,
                                              containerSafeAreaFrame.width - targetRect.maxX,
                                              containerSafeAreaFrame.height - targetRect.maxY)
            switch direction {
            case .left, .right:
                // 定位气泡Y方向的中心点偏移量
                if targetRect.height >= bubbleSize.height {
                    // 箭头水平方向，偏移量为气泡高度中点
                    return (arrowOffset: halfBubbleHeight, centerOffset: 0.0)
                }
                halfBubbleArrowLenth = BubbleViewArrow.Layout.arrowHorizontalSize.height / 2.0
                let baseMargin = min(top, bottom)
                let targetCenterHeight = baseMargin + (targetRect.height / 2.0) - Layout.bubbleEdgeInset
                // 计算气泡中点距离锚点中心偏移的距离，如果目标区域宽度小于气泡宽度，则需要调整
                let adjuestDelta = (targetCenterHeight > halfBubbleHeight) ? 0 : (halfBubbleHeight - targetCenterHeight)
                let centerOffset = top > bottom ? adjuestDelta : -adjuestDelta
                let arrowOffset = halfBubbleHeight + centerOffset - halfBubbleArrowLenth
                return (arrowOffset: arrowOffset, centerOffset: centerOffset)
            case .up, .down:
                // 定位气泡X方向的中心点偏移量
                if targetRect.width >= bubbleSize.width {
                    return (arrowOffset: halfBubbleWidth, centerOffset: 0.0)
                }
                let baseMargin = min(left, right)
                let targetCenterWidth = baseMargin + (targetRect.width / 2.0) - Layout.bubbleEdgeInset
                // 计算气泡中点距离锚点中心偏移的距离，如果目标区域宽度小于气泡宽度，则需要调整
                let adjuestDelta = (targetCenterWidth > halfBubbleWidth) ? 0 : (halfBubbleWidth - targetCenterWidth)
                let centerOffset = left > right ? adjuestDelta : -adjuestDelta
                let arrowOffset = halfBubbleWidth + centerOffset - halfBubbleArrowLenth
                return (arrowOffset: arrowOffset, centerOffset: centerOffset)
            }
    }

    // 更新高亮区域路径
    func updateMaskRectPath(bubbleItem: BubbleItemConfig, containerRect: CGRect) -> UIBezierPath {
        let targetRect = bubbleItem.targetAnchor.targetRect
        var cornerRadius: CGFloat = 0
        switch bubbleItem.targetAnchor.targetRectType {
        case .rectangle, .none:
            cornerRadius = Layout.targetRectCornerRadius
        case .circle:
            cornerRadius = targetRect.width
        }
        let targetPath = UIBezierPath(roundedRect: targetRect, cornerRadius: cornerRadius)
        let contentPath = UIBezierPath(rect: containerRect)
        contentPath.append(targetPath)
        return contentPath
    }

    // 转换目标视图在容器的坐标区域
    func transformTargetViewRect(rooterView: UIView, targetView: UIView, item: BubbleItemConfig) -> CGRect {
        let convertRect: CGRect = rooterView.convert(targetView.frame, from: targetView.superview)
        let targetRect = self.handleRectByTargetAnchor(rawRect: convertRect, offset: item.targetAnchor.offset)
        return targetRect
    }

    private func handleRectByTargetAnchor(rawRect: CGRect, offset: CGFloat?) -> CGRect {
        let targetRect = handleRectOffset(rect: rawRect, offset: offset)
        return targetRect
    }

    // 处理offset
    private func handleRectOffset(rect: CGRect, offset: CGFloat? = nil) -> CGRect {
        let defaultOffset: CGFloat = 2.0
        let offsetValue = offset ?? defaultOffset
        let rectX = rect.minX - offsetValue
        let rectY = rect.minY - offsetValue
        let offsetRect = CGRect(x: rectX, y: rectY,
                                width: rect.width + 2 * offsetValue,
                                height: rect.height + 2 * offsetValue)
        return offsetRect
    }
}

extension GuideBubbleViewModel {
    enum Layout {
        // 气泡距离屏幕边缘的间距
        static let bubbleEdgeInset: CGFloat = 8.0
        static let targetRectCornerRadius: CGFloat = 4.0
    }
    enum Text {
        static var defaultPrevious: String { BundleI18n.LarkGuideUI.Lark_Guide_SpotlightPrevious }
        static var defaultNext: String { BundleI18n.LarkGuideUI.Lark_Guide_SpotlightNext }
        static var defaultEnd: String { BundleI18n.LarkGuideUI.Lark_Guide_SpotlightFinish }
    }
}
