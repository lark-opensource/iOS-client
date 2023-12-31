//
//  WorkPlaceItemViewModel+Additional.swift
//  LarkWorkplace
//  用于保存item的附属信息，包括是否widget展开，展开高度等
//  Created by lilun.ios on 2020/8/12.
//

import UIKit
/// widget容器的状态
final class WidgetContainerState: NSObject {
    private let widgetStateBizKey = "widgetContainerState"
    private let widgetStateVerticalModeKey = "widgetVerticalMode"
    /// 是否展开
    var isExpand: Bool = false
    /// 是否展开过
    private var hasExpanded: Bool = false
    /// 是否需要为展开收起变动容器size
    var isNeedChangeSizeForExpand: Bool = false
    /// 展开之后的高度
    var expandSize: CGSize
    /// 临时存储的widgetView，只能在第一次展开时获取
    private weak var widgetCache: WidgetView?
    init(expandSize: CGSize) {
        self.expandSize = expandSize
    }
    /// 获取widget数据索引（渲染引擎通过这个数据索引，选择相应的数据执行渲染）
    func getWidgetDataIndex(canExpand: Bool) -> [String: Any] {
        let expandMode = (canExpand && isExpand) ? "expand" : "fold"
        return [widgetStateBizKey: [widgetStateVerticalModeKey: expandMode]]
    }
    /// 保存widgetView，
    func saveWidgetView(widgetView: WidgetView) {
        widgetCache = widgetView
//        if !hasExpanded {
//            widgetCache = widgetView
//        } else {
//            WidgetView.log.info("forbiden save widgetView cache for not first expand")
//        }
    }
    /// 获取widgetView
    func getWidgetViewCache() -> WidgetView? {
        if let widgetView = widgetCache {
            widgetCache = nil
            return widgetView
        } else {
            return nil
        }
//        if !hasExpanded, let widgetView = widgetCache {
//            hasExpanded = true
//            return widgetView
//        } else {
//            return nil
//        }
    }
}
final class ItemModelAdditionInfo: NSObject {
    /// 标记对应哪个item的info
    private let itemId: String
    /// 只有widget才有对应的额外信息
    var widgetContainerState: WidgetContainerState?
    init(itemId: String) {
        self.itemId = itemId
    }
}
@objc
protocol WorkPlaceQueryAdditionContext {
    func queryAdditionItem(itemId: String) -> ItemModelAdditionInfo?
    func updateAdditionItem(itemId: String, item: ItemModelAdditionInfo?)
}
