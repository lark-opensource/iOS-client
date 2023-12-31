//
//  ActionMenuHost.swift
//  LarkWorkplace
//
//  Created by shengxy on 2023/7/11.
//

import Foundation
import LarkQuickLaunchInterface
import RxSwift

enum ActionMenuHostType: Int {
    case normal
    case template
}

/// 操作菜单协议（支持应用操作菜单的工作台门户，需实现该协议）
protocol ActionMenuHost: NSObjectProtocol {
    /// 工作台上下文，包含必要依赖
    var context: WorkplaceContext { get }
    var quickLaunchService: QuickLaunchService { get }
    var disposeBag: DisposeBag { get }
    var host: ActionMenuHostType { get }
    /// 菜单展示依赖的 UICollectionView
    var menuFromCollectionView: UICollectionView { get }
    var dataManager: AppCenterDataManager { get }
    var dependency: WPDependency { get }
    /// 操作菜单管理器（统一管理菜单展示依赖的状态）
    var actMenuShowManager: ActionMenuManager { get }
    /// 长按菜单是否显示「排序」选项，默认 false
    var showRankOptionInLongPressMenu: Bool { get }
    /// 菜单选项点击回调
    func onMenuItemTap(item: ActionMenuItem)

    /// ***********************************************
    /// 根据 itemId 和 section 查找 indexPath
    func getIndexPath(itemId: String, section: Int) -> IndexPath?
    /// 获取指定 indexPath 对应的 Data Model
    func getWorkPlaceItem(indexPath: IndexPath) -> ItemModel?
    /// 获取当前section的header高度
    func getHeaderHeight(section: Int) -> CGFloat

    /// ***********************************************
    /// 当前 icon 形态应用是否处于「常用」组件
    func isCommonAndRec(section: Int) -> Bool
    /// 当前 icon 形态应用是否处于「最近使用」子模块下
    func isInRecentlyUsedSubModule(section: Int) -> Bool
    /// 添加常用应用，对应「添加常用」操作项
    func addCommon(indexPath: IndexPath, itemId: String)
    /// 移除常用应用，对应「移除常用」操作项
    func removeCommon(indexPath: IndexPath, itemId: String)
}

extension ActionMenuHost {
    // 是否展示排序选项，默认不展示
    var showRankOptionInLongPressMenu: Bool { return false }
    // 当前应用是否处于「最近使用」子组件中，默认否
    func isInRecentlyUsedSubModule(section: Int) -> Bool { return false }
}
