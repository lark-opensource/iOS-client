//
//  SpaceSection.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/25.
//

import UIKit
import RxCocoa
import SKCommon
import UniverseDesignToast
import LarkSceneManager
import SKWorkspace
import LarkContainer

public protocol SpaceSectionConvertible {
    func asSections() -> [SpaceSection]
}

public extension SpaceSection {
    func asSections() -> [SpaceSection] { [self] }
}

extension Array: SpaceSectionConvertible where Element == SpaceSectionConvertible {
    public func asSections() -> [SpaceSection] { flatMap { $0.asSections() } }
}

@resultBuilder
public struct SpaceSectionBuilder {
    public static func buildBlock() -> [SpaceSection] { [] }
    public static func buildBlock(_ sections: SpaceSectionConvertible...) -> [SpaceSection] { sections.flatMap { $0.asSections() } }
    public static func buildIf(_ value: SpaceSectionConvertible?) -> SpaceSectionConvertible { value ?? [] }
    public static func buildEither(first: SpaceSectionConvertible) -> SpaceSectionConvertible { first }
    public static func buildEither(second: SpaceSectionConvertible) -> SpaceSectionConvertible { second }
}

public enum SpaceSectionAction {
    public typealias DeleteCompletion = (_ confirm: Bool, _ deleteOrigin: Bool) -> Void
    case push(viewController: UIViewController)
    case showDetail(viewController: UIViewController)
    case open(entry: SKEntryBody, context: [String: Any])
    case present(viewController: UIViewController, popoverConfiguration: ((UIViewController) -> Void)?, completion: (() -> Void)?)
    public static func present(viewController: UIViewController, popoverConfiguration: ((UIViewController) -> Void)? = nil) -> SpaceSectionAction {
        .present(viewController: viewController, popoverConfiguration: popoverConfiguration, completion: nil)
    }
    
    case openURL(url: URL, context: [String: Any]?)
    case presentOrPush(viewController: UIViewController, popoverConfiguration: ((UIViewController) -> Void)?)
    case toast(content: String)
    case startSpaceUserGuide(tracker: SpaceBannerTracker, completion: () -> Void)
    case startCloudDriveOnboarding
    case confirmDeleteAction(file: SpaceEntry, completion: DeleteCompletion)
    case dismissPresentedVC
    // TODO: 和 confirmDelete 合并
    case confirmRemoveManualOffline(completion: (Bool) -> Void)
    case stopPullToRefresh(total: Int?)
    case stopPullToLoadMore(hasMore: Bool)
    case showRefreshTips(callback: () -> Void)
    case dismissRefreshTips(needScrollToTop: Bool)
    case showManualOfflineSuggestion(completion: (Bool) -> Void)
    case showDriveUploadList(folderToken: String)
    case create(with: SpaceCreateIntent, sourceView: UIView)
    case showHUD(_ action: HUDAction)
    case showDeleteFailListView(files: [SpaceEntry])
    case hideHUD
    case newScene(Scene)
    case exit
    // TODO: more面板优化
    case openWithAnother(_ file: SpaceEntry, originName: String?, popoverSourceView: UIView, arrowDirection: UIPopoverArrowDirection)
    case openShare(shareBody: SKShareViewControllerBody)
    case exportDocument(exportBody: ExportDocumentViewControllerBody)
    case copyFile(completion: ((UIViewController) -> Void ))
    // 交换 customWithController 与 copyFile 的定义
    static func customWithController(completion: @escaping (UIViewController) -> Void) -> SpaceSectionAction {
        .copyFile(completion: completion)
    }

    case saveToLocal(_ file: SpaceEntry, originName: String?)
    case showUserProfile(userID: String)

    public enum HUDAction {
        case customLoading(_ content: String?)
        case warning(_ content: String)
        case failure(_ content: String)
        case success(_ content: String)
        case tips(_ content: String)
        case custom(config: UDToastConfig, operationCallback: ((String?) -> Void)?)
        case tipsmanualOffline(text: String, buttonText: String)

        static let loading: Self = .customLoading(nil)
    }
}

public enum SpaceSectionReloadAction {
    case reloadSection(animated: Bool)
    case reloadSectionCells(animated: Bool)
    // 触发 collectionView batchUpdate，willUpdate 闭包会在 batchUpdate 内调用，dataSource 的修改要放在闭包内
    case update(inserts: [Int], deletes: [Int], updates: [Int], moves: [(Int, Int)], willUpdate: () -> Void)
    // 获取对应 section 中当前可见的 cell 下标，第二个参数表明可见 cell 中是否包含其他 section 的cell
    case getVisableIndices(callback: ([Int], Bool) -> Void)
    case scrollToItem(index: Int, at: UICollectionView.ScrollPosition = .top, animated: Bool)
}

public protocol SpaceSection: SpaceSectionLayout, SpaceSectionDataSource, SpaceSectionDelegate, SpaceSectionConvertible {
    typealias Action = SpaceSectionAction
    typealias ReloadAction = SpaceSectionReloadAction
    
    var identifier: String { get }
    var reloadSignal: Signal<ReloadAction> { get }
    var actionSignal: Signal<Action> { get }
    func prepare()
    func notifyPullToRefresh()
    func notifyPullToLoadMore()
    func notifySectionDidAppear()
    func notifySectionWillDisappear()
    func notifyViewDidLayoutSubviews(hostVCWidth: CGFloat)
}

public extension SpaceSection {
    func notifySectionDidAppear() {}
    func notifySectionWillDisappear() {}
    func notifyViewDidLayoutSubviews(hostVCWidth: CGFloat) {}
}

// MARK: - Section Layout Config
public protocol SpaceSectionLayout {
    func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize
    func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets
    func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat
    func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat
    func headerHeight(for containerWidth: CGFloat) -> CGFloat
    func footerHeight(for containerWidth: CGFloat) -> CGFloat
}

// MARK: - Section View DataSource
public protocol SpaceSectionDataSource {
    var numberOfItems: Int { get }
    func setup(collectionView: UICollectionView)
    func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell
    func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView
    func dragItem(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem]
}

public protocol SpaceSectionDelegate {
    func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView)
    func notifyDidEndDragging(willDecelerate: Bool)
    func notifyDidEndDecelerating()
    func didEndDisplaying(at indexPath: IndexPath, cell: UICollectionViewCell, collectionView: UICollectionView)
    @available(iOS 13.0, *)
    func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration?
}

public extension SpaceSectionDelegate {
    func notifyDidEndDragging(willDecelerate: Bool) {}
    func notifyDidEndDecelerating() {}
    func didEndDisplaying(at indexPath: IndexPath, cell: UICollectionViewCell, collectionView: UICollectionView) {}
}

// 不同于 SpaceSection，HeaderSection 不参与 collectionView 内部的数据处理，而是作为 collectionView 的 headerView
public protocol SpaceHeaderSection {
    typealias Action = SpaceSectionAction
    var identifier: String { get }
    var actionSignal: Signal<Action> { get }
    // 暂时不支持 headerView 高度动态变化，因为涉及到更新 contentInset、处理 RefreshView 偏移量，后面有需求再优化
    // 会在 viewDidLoad 时就读取这两个属性
    var headerViewHeight: CGFloat { get }
    var headerView: UIView { get }

    func prepare()
    func notifyPullToRefresh()
    func notifyPullToLoadMore()
    func notifySectionDidAppear()
    func notifySectionWillDisappear()
    func notifyViewDidLayoutSubviews(hostVCWidth: CGFloat)
}

public extension SpaceHeaderSection {
    // header 一般不关心 load more 事件
    func notifyPullToLoadMore() {}
    func notifySectionDidAppear() {}
    func notifySectionWillDisappear() {}
    func notifyViewDidLayoutSubviews(hostVCWidth: CGFloat) {}
}
