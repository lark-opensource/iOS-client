//
//  Component.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2022/12/6.
//  Copyright © 2022 cactus. All rights reserved.
//

import Foundation
import UIKit
import RustPB
import LarkModel

/** Component
 *  作为一个子组件使用：由vm构造和持有
 *  生成view
 *  更新view数据
 *  处理事件
*/

// 组件类别，新增一个组件，需要在这里新增枚举
public enum FeedCardComponentType {
    case unknown
    case navigation
    case avatar
    case title
    case customStatus
    case specialFocus
    case tag
    case time
    case flag
    case status
    case subtitle
    case msgStatus
    case reaction
    case digest
    case mention
    case mute
    case cta
}

// 这是一个component 接口，需要组件类去实现
// 在子线程下，通过数据接口拿到数据时生成 view data
public protocol FeedCardBaseComponentVM: FeedCardComponentEvent {
    // 指定组件类型
    var type: FeedCardComponentType { get }
}

// 事件协议
public protocol FeedCardComponentEvent {
    // 组件事件信息上下文
    var eventContext: [String: Any]? { get }
    // 组件预期订阅的事件类型
    func subscribedEventTypes() -> [FeedCardEventType]
    // 根据订阅的事件类型，接收关联事件
    func postEvent(type: FeedCardEventType, value: FeedCardEventValue, object: Any)
}

public extension FeedCardComponentEvent {
    // 组件事件信息上下文
    var eventContext: [String: Any]? { return nil }
    // 组件预期订阅的事件类型
    func subscribedEventTypes() -> [FeedCardEventType] { return [] }
    // 根据订阅的事件类型，接收关联事件
    func postEvent(type: FeedCardEventType, value: FeedCardEventValue, object: Any) {}
}

// 描述单个组件的布局信息，比如：width、height、padding等，如果不提供，则使用自适应布局，由系统处理
public struct FeedCardComponentLayoutInfo {
    public let padding: CGFloat? // 左右间隔
    public let width: CGFloat?
    public let height: CGFloat?

    public init(padding: CGFloat?,
         width: CGFloat?,
         height: CGFloat?) {
        self.padding = padding
        self.width = width
        self.height = height
    }
}

// 组件需要遵守的协议
public protocol FeedCardBaseComponentView: FeedCardComponentEvent {
    // 指定组件类型
    var type: FeedCardComponentType { get }

    // 提供布局信息，比如：width、height、padding等（cell初始化进行布局时获取）
    var layoutInfo: FeedCardComponentLayoutInfo? { get }

    // 在主线程下 cell init 时，会使用该接口创建view
    func creatView() -> UIView

    // 在主线程下 cell 上屏时，会通过该接口，通知组件进行渲染view
    func updateView(view: UIView, vm: FeedCardBaseComponentVM)
}

// 目前该协议只被 status 坑位中的组件使用
public protocol FeedCardStatusVisible {
    // 组件是否可见，框架层使用
    var isVisible: Bool { get }
    // 需要依赖feed card上屏时机才能计算出view data的组件，需要实现这个方法
    func showOrHiddenView(isVisible: Bool)
}

public extension FeedCardStatusVisible {
    func showOrHiddenView(isVisible: Bool) {}
}

// 单行高度
public protocol FeedCardLineHeight {
    // 返回组件高度，最终是为了计算cell的高度
    var height: CGFloat { get }
}
