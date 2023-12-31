//
//  PushCardModel.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/25.
//

import UIKit
import Foundation

/// 卡片支持
protocol PushCardCenterService {
    /// 推送卡片
    ///
    /// - parameter model: 卡片数据组
    func post(_ models: [Cardable])
    /// 移除卡片
    ///
    /// - parameter with: 卡片标识符
    /// - parameter changeToStack: 卡片被移除后，是否进入折叠状态
    func remove(with id: String, changeToStack: Bool)
}

/// 卡片模型
public protocol Cardable {
    /// 卡片的唯一 ID，由业务方自己传入
    ///
    /// - 同样 ID 的卡片，只允许显示一张，以最先加入的卡片为准
    var id: String { get }

    /// 卡片优先级
    ///
    /// - 最高优先卡片`required`将无法被统一清除，需手动确认
    /// - 建议非必需，请使用 `normal`
    var priority: CardPriority { get set }

    /// 卡片图标 / 头像
    ///
    /// - 卡片左上角展示的图标或头像
    var icon: UIImage? { get }

    /// 卡片标题
    ///
    /// - 卡片左上角展示的卡片标题，用来标注具体卡片信息
    var title: String? { get }

    /// 卡片自定义视图
    ///
    /// - 可完全不传其他值，只展示自定义视图。
    var customView: UIView? { get set }

    /// 卡片按钮点击事件
    var buttonConfigs: [CardButtonConfig]? { get set }

    /// 卡片持续时间
    var duration: TimeInterval? { get set }

    /// 卡片空白区域点击回调
    var bodyTapHandler: ((Cardable) -> Void)? { get set }

    /// 卡片由 PushCard 强制移除时（如清除全部）触发的回调，如用户点击清除全部。
    var removeHandler: ((Cardable) -> Void)? { get set }

    /// 卡片定时结束自动移除回调
    var timedDisappearHandler: ((Cardable) -> Void)? { get set }

    /// 卡片额外承载的信息
    var extraParams: Any? { get }

    func calculateCardHeight(with width: CGFloat) -> CGFloat?
}

public extension Cardable {
    func calculateCardHeight(with width: CGFloat) -> CGFloat? { return nil }
}

/// 预设按钮配置
public struct CardButtonConfig {

    /// 预设按钮标题
    var title: String

    /// 预设按钮颜色
    var buttonColorType: ButtonColorTheme

    /// 预设按钮点击事件
    var action: (Cardable) -> Void

    /// 初始化函数
    public init(title: String,
                buttonColorType: ButtonColorTheme,
                action: @escaping (Cardable) -> Void) {
        self.title = title
        self.buttonColorType = buttonColorType
        self.action = action
    }
}

/// 预设卡片按钮颜色配置
public enum ButtonColorTheme {
    /// 预设次要按钮
    ///
    /// - 白底黑字
    case secondary

    /// 预设主要按钮
    ///
    /// - 蓝底白字
    case primaryBlue
}

/// 卡片优先级
public enum CardPriority {
    /// 高优卡片规则
    ///
    /// - 卡片最优先展示
    /// - 组件无法统一清除，需要手动清除
    case high

    // 中间优先级
    ///
    /// - 卡片按照时间顺序展示
    /// - 不可统一清除，需要手动清除
    case medium

    /// 默认卡片规则
    ///
    /// - 按照时间显示，可统一清除
    case normal
}
