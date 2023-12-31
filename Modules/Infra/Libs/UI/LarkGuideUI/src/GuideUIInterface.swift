//
//  GuideUIInterface.swift
//  LarkGuideUI
//
//  Created by zhenning on 2020/6/3.
//

// MARK: - Data Struct

// 组件类型
import UIKit
import Foundation
public enum GuideUIType {
    case bubbleType(BubbleType)
    case dialogConfig(DialogConfig)
    case customConfig(GuideCustomConfig)
}

// 气泡类型
public enum BubbleType {
    // 单个气泡配置
    case single(SingleBubbleConfig)
    // 多气泡配置
    case multiple(MultiBubblesConfig)
}

public protocol GuideSingleBubbleDelegate: AnyObject {
    // 点击左边按钮
    func didClickLeftButton(bubbleView: GuideBubbleView)
    // 点击右边按钮
    func didClickRightButton(bubbleView: GuideBubbleView)
    // 点击气泡事件
    func didTapBubbleView(bubbleView: GuideBubbleView)
}

extension GuideSingleBubbleDelegate {
    public func didClickLeftButton(bubbleView: GuideBubbleView) { }
    public func didClickRightButton(bubbleView: GuideBubbleView) { }
    public func didTapBubbleView(bubbleView: GuideBubbleView) { }
}

public protocol GuideMultiBubblesViewDelegate: AnyObject {
    func didClickNext(stepView: GuideBubbleView, for step: Int)
    func didClickPrevious(stepView: GuideBubbleView, for step: Int)
    // 在bottomConfig中指定skipTitle后，点击了skipTitle后回调
    func didClickSkip(stepView: GuideBubbleView, for step: Int)
    func didClickEnd(stepView: GuideBubbleView)
}

extension GuideMultiBubblesViewDelegate {
    public func didClickNext(stepView: GuideBubbleView, for step: Int) { }
    public func didClickPrevious(stepView: GuideBubbleView, for step: Int) { }
    public func didClickSkip(stepView: GuideBubbleView, for step: Int) { }
    public func didClickEnd(stepView: GuideBubbleView) { }
}

// MARK: - Mask

// 箭头方向
public enum BubbleArrowDirection: Int {
    case left = 1
    case up = 2
    case right = 3
    case down = 4
}

// 遮罩配置, 配置后会显示默认shadow灰色
public struct MaskConfig {
    var shadowAlpha: CGFloat?
    var windowBackgroundColor: UIColor?
    // 默认带按钮的气泡不响应，但如果强制开启响应，则点击背景响应
    var maskInteractionForceOpen: Bool?
    var snapshotView: UIView?
    public init(shadowAlpha: CGFloat? = nil,
                maskInteractionForceOpen: Bool? = nil) {
        self.init(shadowAlpha: shadowAlpha,
                  windowBackgroundColor: nil,
                  maskInteractionForceOpen: maskInteractionForceOpen,
                  snapshotView: nil)
    }

    public init(shadowAlpha: CGFloat? = nil,
                windowBackgroundColor: UIColor? = nil,
                maskInteractionForceOpen: Bool? = nil) {
        self.init(shadowAlpha: shadowAlpha,
                  windowBackgroundColor: windowBackgroundColor,
                  maskInteractionForceOpen: maskInteractionForceOpen,
                  snapshotView: nil)
    }

    public init(shadowAlpha: CGFloat? = nil,
                windowBackgroundColor: UIColor? = nil,
                maskInteractionForceOpen: Bool? = nil,
                snapshotView: UIView? = nil) {
        self.shadowAlpha = shadowAlpha
        self.windowBackgroundColor = windowBackgroundColor
        self.maskInteractionForceOpen = maskInteractionForceOpen
        self.snapshotView = snapshotView
    }
}

// 高亮区域形状类型
public enum TargetRectType: Int {
    // 矩形，默认
    case rectangle = 1
    // 圆形
    case circle = 2
}
// 指向目标Rect来源枚举
public enum TargetSourceType {
    // 使用传入的view
    case targetView(UIView)
    //  使用Rect
    case targetRect(CGRect)
}

// 锚点
public struct TargetAnchor {
    var targetRect: CGRect = .zero
    var targetView: UIView?
    // 高亮区域的内边距
    var offset: CGFloat?
    // 气泡指向的方向
    var arrowDirection: BubbleArrowDirection?
    var targetSourceType: TargetSourceType
    // 高亮区域为圆形，指定后为targetRect的外接圆
    var targetRectType: TargetRectType?
    // 是否忽略SafeArea
    // 引导默认保证展示在SafeArea内，特殊case会显示异常
    var ignoreSafeArea: Bool?
    public init(targetSourceType: TargetSourceType,
                offset: CGFloat? = nil,
                arrowDirection: BubbleArrowDirection? = nil,
                targetRectType: TargetRectType? = .rectangle) {
        var targetAnchorRect: CGRect = CGRect.zero
        self.targetSourceType = targetSourceType
        self.targetRectType = targetRectType
        self.arrowDirection = arrowDirection
        self.offset = offset

        switch targetSourceType {
        case let .targetRect(rect):
            targetAnchorRect = rect
        case let .targetView(view):
            targetAnchorRect = view.frame
            self.targetView = view
        }
        self.targetRect = targetAnchorRect
    }

    public init(targetSourceType: TargetSourceType,
                offset: CGFloat? = nil,
                arrowDirection: BubbleArrowDirection? = nil,
                targetRectType: TargetRectType? = .rectangle,
                ignoreSafeArea: Bool? = false) {
        self.init(targetSourceType: targetSourceType, offset: offset, arrowDirection: arrowDirection, targetRectType: targetRectType)
        self.ignoreSafeArea = ignoreSafeArea
    }
}

// MARK: - Bubble

// 气泡基础结构
public final class BubbleItemConfig {
    public var targetAnchor: TargetAnchor
    public var bannerConfig: BannerInfoConfig?
    public var textConfig: TextInfoConfig
    public var bottomConfig: BottomConfig?
    public var containerConfig: BubbleContainerConfig?
    public init(guideAnchor: TargetAnchor,
                textConfig: TextInfoConfig,
                bannerConfig: BannerInfoConfig? = nil,
                bottomConfig: BottomConfig? = nil,
                containerConfig: BubbleContainerConfig? = nil) {
        self.targetAnchor = guideAnchor
        self.textConfig = textConfig
        self.bannerConfig = bannerConfig
        self.bottomConfig = bottomConfig
        self.containerConfig = containerConfig
    }
    public convenience init(guideAnchor: TargetAnchor,
                            textConfig: TextInfoConfig,
                            bannerConfig: BannerInfoConfig? = nil,
                            bottomConfig: BottomConfig? = nil) {
        self.init(guideAnchor: guideAnchor,
                  textConfig: textConfig,
                  bannerConfig: bannerConfig,
                  bottomConfig: bottomConfig,
                  containerConfig: nil)
    }
}

// 单个气泡配置
public struct SingleBubbleConfig {
    public var bubbleConfig: BubbleItemConfig
    public weak var delegate: GuideSingleBubbleDelegate?
    public var maskConfig: MaskConfig?
    public init(delegate: GuideSingleBubbleDelegate? = nil,
                bubbleConfig: BubbleItemConfig,
                maskConfig: MaskConfig? = nil) {
        self.delegate = delegate
        self.bubbleConfig = bubbleConfig
        self.maskConfig = maskConfig
    }
}

// 多个气泡配置
public struct MultiBubblesConfig {
    public var bubbleItems: [BubbleItemConfig]
    public var endTitle: String?
    public var maskConfig: MaskConfig?
    public weak var delegate: GuideMultiBubblesViewDelegate?
    public init(delegate: GuideMultiBubblesViewDelegate? = nil,
                bubbleItems: [BubbleItemConfig],
                endTitle: String? = nil,
                maskConfig: MaskConfig? = nil) {
        self.delegate = delegate
        self.bubbleItems = bubbleItems
        self.endTitle = endTitle
        self.maskConfig = maskConfig
    }
}

// 引导视图点击
public typealias GuideViewTapHandler = ((_ guideView: UIView) -> Void)

// 气泡容器
public struct BubbleContainerConfig {
    // 气泡背景色
    var bubbleBackColor: UIColor?
    // 气泡阴影色
    var bubbleShadowColor: UIColor?
    public init(bubbleBackColor: UIColor? = nil,
                bubbleShadowColor: UIColor? = nil) {
        self.bubbleBackColor = bubbleBackColor
        self.bubbleShadowColor = bubbleShadowColor
    }
}

// 文案部分
public struct TextInfoConfig {
    public let title: String?
    public let detail: String
    public init(title: String? = nil,
                detail: String) {
        self.title = title
        self.detail = detail
    }
}

// 图片部分
public typealias BubbleLOTImageInfo = (filePath: String, size: CGSize)
public typealias BubbleGifImageInfo = (url: URL, size: CGSize)
public enum GuideBubbleImageType {
    // 图片
    case image(UIImage)
    // GIF图片data
    case gifImageData(Data)
    // GIF图片URL
    case gifImageURL(BubbleGifImageInfo)
    // Lottie图片文件路径
    case lottie(BubbleLOTImageInfo)
}

public struct BannerInfoConfig {
    public let imageType: GuideBubbleImageType
    public init(imageType: GuideBubbleImageType) {
        self.imageType = imageType
    }
}

// 气泡底部按钮
public struct ButtonInfo {
    public enum BubbleButtonType {
        // 关闭
        case close
        // 跳过
        case skip
        // 上一步
        case previous
        // 下一步
        case next
        // 完成
        case finished
    }
    public var title: String
    // 是否显示跳过
    public var skipTitle: String?
    var shouldSkip: Bool {
        return skipTitle != nil
    }
    // 是否显示跳过
    public var buttonType: BubbleButtonType?
    public init(title: String,
                skipTitle: String? = nil,
                buttonType: BubbleButtonType? = nil) {
        self.title = skipTitle ?? title
        self.skipTitle = skipTitle
        self.buttonType = buttonType
    }
}

// 底部按钮
public struct BottomConfig {
    public var leftBtnInfo: ButtonInfo?
    public var rightBtnInfo: ButtonInfo
    public let leftText: String?
    public init(leftBtnInfo: ButtonInfo? = nil,
                rightBtnInfo: ButtonInfo,
                leftText: String? = nil) {
        self.leftBtnInfo = leftBtnInfo
        self.rightBtnInfo = rightBtnInfo
        self.leftText = leftText
    }
}

// MARK: - Dialog

// 卡片配置
public struct DialogConfig {
    public var title: String?
    public var detail: String
    public var bannerImage: UIImage
    public var buttonTitle: String
    public var shadowAlpha: CGFloat?
    public weak var delegate: GuideDialogViewDelegate?
    public init(title: String?,
                detail: String,
                delegate: GuideDialogViewDelegate,
                shadowAlpha: CGFloat? = nil,
                bannerImage: UIImage,
                buttonTitle: String) {
        self.title = title
        self.detail = detail
        self.delegate = delegate
        self.bannerImage = bannerImage
        self.buttonTitle = buttonTitle
        self.shadowAlpha = shadowAlpha
    }
}

// MARK: - Custom

// 自定义view配置
public struct GuideCustomConfig {
    public var customView: GuideCustomView
    public var viewFrame: CGRect
    public weak var delegate: GuideCustomViewDelegate?
    public var shadowAlpha: CGFloat?
    public var enableBackgroundTap: Bool?
    public init(customView: GuideCustomView,
                viewFrame: CGRect,
                delegate: GuideCustomViewDelegate,
                shadowAlpha: CGFloat? = nil,
                enableBackgroundTap: Bool? = nil) {
        self.customView = customView
        self.viewFrame = viewFrame
        self.delegate = delegate
        self.shadowAlpha = shadowAlpha
        self.enableBackgroundTap = enableBackgroundTap
    }
}
