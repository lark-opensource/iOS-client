//
//  TemporaryTabService.swift
//  LarkQuickLaunchInterface
//
//  Created by Yaoguoguo on 2023/6/25.
//

import Foundation
import LarkTab
import RxSwift

public protocol TemporaryTabDelegate: AnyObject {
    /// Temporary数据变更时更新
    ///
    /// 只负责更新临时区域的数据，不包括main和quick的 custom数据
    func updateTabs()

    /// 用于判断是否更新临时区域数据
    ///
    /// 因为Main和Quick区域可能会有custom数据，避免重复添加至临时区域
    func shouldUpdateTemporary(_ candidate: TabCandidate, oldID: String) -> Bool

    /// 用于展示Temporary
    ///
    /// 与Update不同，show会影响导航栏展示逻辑
    func showTab(_ vc: TabContainable)

    /// 移除TabCandidate
    ///
    /// id：TabCandidate tabContainableIdentifier，同时会触发update
    func removeTab(_ ids: [String])
}

public protocol TemporaryTabService {
    var delegate: TemporaryTabDelegate? { get }

    var isTemporaryEnabled: Bool { get }

    /// 全量tabs
    var tabs: [TabCandidate] { get }

    /// 全量tabContainables
    var tabContainables: [TabContainable] { get }

    /// 设置代理方法
    /// - Parameter delegate:
    func set(delegate: TemporaryTabDelegate)

    /// 在导航区展示Tab，不论是在Main和Quick还是 Temporary
    ///
    /// - Parameter vc: TabContainable
    /// 主导航会持有传入vc，并且将其从原先的parent移除
    func showTab(_ vc: TabContainable)

    func showTab(url: String, context: [String: Any])

    /// 更新导航区Tab
    ///
    /// - Parameter vc:TabContainable
    /// 主导航会持有传入vc，使用时会将其从原先的parent移除
    func updateTab(_ vc: TabContainable)

    /// 通过id和Context获取vc
    ///
    /// - Parameters:
    ///   - id: TabContainable id
    ///   - context:
    /// - Returns: TabContainable
    func getTab(id: String, context: [String: Any]) -> TabContainable?

    /// 根据tabCandidate异步获取 vc
    ///
    /// - Parameters:
    ///   - tabCandidate:
    ///   - completion:
    func getTab(_ tabCandidate: TabCandidate, context: [String: Any], with completion: ((TabContainable?) -> Void)?)

    /// 移除对应Tab
    ///
    /// - Parameter id:
    func removeTab(ids: [String])

    /// 移除对应Tab
    ///
    /// - Parameter id:
    func removeTab(id: String)

    /// 移除对应TabCache
    ///
    /// - Parameter id:
    func removeTabCache(id: String)

    /// 对全部Temporary的tabs进行排序
    /// - Parameter tabs:
    func modifyTabs(_ tabs: [TabCandidate])

    /// 监听移除通知
    func removeTabsnotification() -> Observable<[TabCandidate]>
}
