//
//  SKBitableHomepageInterface.swift
//  SpaceInterface
//
//  Created by qiyongka on 2023/11/5.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging
import LarkModel

// 用于 SKBitable 中调用 CCMMod 搜索服务
public protocol BitableSearchFactoryProtocol {
    
    func jumpToSearchController(fromVC: UIViewController)
    
    func jumpToPickerBaseSearchController(selectDelegate: BitableSearchFactorySelectProtocol, fromVC: UIViewController)
}

// 用于 Skbitable 中调用 CCMMode 的搜索面板
public protocol BitableSearchFactorySelectProtocol: AnyObject {
    func pushSearchResultVCWithSelectItem(_ selectItem: PickerItem, pickerVC: UIViewController)
}

public enum BitableMultiListShowStyle {
    case fullScreen
    case embeded
}

public struct BitableMultiListUIConfig {
    public var widthForEmbededStyle: CGFloat
    public var heightForEmbededStyle: CGFloat
    public var widthForFullScreenStyle: CGFloat
    public var heightForFullScreenStyle: CGFloat
    public var heightForSectionHeader: CGFloat
    
    public init(widthForEmbededStyle: CGFloat, heightForEmbededStyle: CGFloat, widthForFullScreenStyle: CGFloat, heightForFullScreenStyle: CGFloat, heightForSectionHeader: CGFloat) {
        self.widthForEmbededStyle = widthForEmbededStyle
        self.heightForEmbededStyle = heightForEmbededStyle
        self.widthForFullScreenStyle = widthForFullScreenStyle
        self.heightForFullScreenStyle = heightForFullScreenStyle
        self.heightForSectionHeader = heightForSectionHeader
    }
}

public enum BitableMultiListSectionType {
    case recent
    case quickAccess
    case favorites
}

public enum BitableMultiListSectionLoadResult {
    case success
    case fail(reason: String)
}

public protocol BitableMultiListControllerDelegate: AnyObject {
    func createBitableFileIfNeeded(isEmpty: Bool)
    func didRightSlidingTriggerEmbedStyle()

    func multiListController(vc: UIViewController, startRefreshSection sectionType: BitableMultiListSectionType)
    func multiListController(vc: UIViewController, endRefreshSection sectionType: BitableMultiListSectionType, loadResult: BitableMultiListSectionLoadResult)
}

// 用于调用 SKSpace 中的 BitableMultiListController 的接口协议，实现 SKBitable 与 SKSpace 的解耦合
public protocol BitableMultiListControllerProtocol: UIViewController {
    var multiListCollectionView: UICollectionView { get set }
    var delegate: BitableMultiListControllerDelegate? { get set }
    
    func collectionViewWillShowInfullScreen()
    func collectionViewDidShowInfullScreen()
    func collectionViewWillShowInEmbed()
    func collectionViewDidShowInEmbed()
    func collectionViewShouldReloadCellsForAnimation()
    func collectionViewPullToRefresh()
    
    func update(config: BitableMultiListUIConfig)
    func update(style: BitableMultiListShowStyle)
    func showfullScreenAnimation()
    func showEmbededAnimation()
}
