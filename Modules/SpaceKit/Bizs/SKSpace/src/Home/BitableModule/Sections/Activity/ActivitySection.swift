//
//  ActivitySection.swift
//  SKSpace
//
//  Created by yinyuan on 2023/4/17.
//
// disable-lint: magic number

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKResource
import SKUIKit
import SKCommon
import UniverseDesignIcon
import LarkUIKit
import EENavigator
import LarkContainer

public final class ActivitySection: SpaceSection {
    
    static let sectionIdentifier: String = "activity"
    public var identifier: String { Self.sectionIdentifier }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private let disposeBag = DisposeBag()
    
    private let dataModel: ActivityDataModel
    private let homeType: SpaceHomeType
    private let headerSection: HeaderSection
        
    private weak var homeActivity: HomeActivityController?
    public let userResolver: UserResolver

    public init(userResolver: UserResolver,
                dataModel: ActivityDataModel,
                homeType: SpaceHomeType,
                headerSection: HeaderSection) {
        self.userResolver = userResolver
        self.dataModel = dataModel
        self.homeType = homeType
        self.headerSection = headerSection
        dataModel.delegate = self
    }

    public func prepare() {
        DocsLogger.info("ActivitySection prepare")
        updateHeader()
    }

    public func notifyPullToRefresh() {
        DocsLogger.info("ActivitySection notifyPullToRefresh")
        dataModel.pull()
    }
    public func notifyPullToLoadMore() {
        DocsLogger.info("ActivitySection notifyPullToLoadMore")
    }

    public func notifySectionDidAppear() {
        DocsLogger.info("ActivitySection notifySectionDidAppear")
        dataModel.resume()
        
        if case let .baseHomeType(context) = homeType {
            DocsTracker.reportBitableHomePageEvent(enumEvent: .baseHomepageActivityView, parameters: [
                "current_sub_view": "homepage"
            ], context: context)
        }
        
    }
    
    public func notifySectionWillDisappear() {
        DocsLogger.info("ActivitySection notifySectionWillDisappear")
        dataModel.pause()
    }
    
    private func updateHeader() {
        var headerInfo: SectionHeaderInfo = SectionHeaderInfo(title: BundleI18n.SKResource.Bitable_Workspace_Activities_Tab)
        if !dataModel.homePageData.isEmpty || (!UserScopeNoChangeFG.YY.bitableActivityNewDisable && !dataModel.failed) {
            headerInfo.info = BundleI18n.SKResource.Bitable_Workspace_ViewAll_Button
            headerInfo.rightIcon = UDIcon.rightOutlined
            headerInfo.rightClickHandler = { [weak self] _ in
                self?.gotoActivityViewController()
            }
        } else {
            DocsLogger.info("dataModel.homePageData.isEmpty")
        }
        headerSection.headerInfo = headerInfo
    }
}

extension ActivitySection: SpaceSectionLayout {
    
    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        if !UserScopeNoChangeFG.YY.bitableActivityNewDisable {
            if dataModel.failed {
                // 失败状态
                return CGSize(width: containerWidth, height: ActivityTableViewErrorCell.height)
            } else if dataModel.homePageData.isEmpty {
                // 空状态
                return CGSize(width: containerWidth, height: ActivityTableViewEmptyCell.height)
            }
        }
        return CGSize(width: containerWidth, height: ActivityCollectionViewCell.height)
    }

    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0,
                            left: 0,
                            bottom: 0,
                            right: 0)
    }

    public func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        4
    }

    public func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        0
    }

    public func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        0
    }

    public func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        18
    }
}

extension ActivitySection: SpaceSectionDataSource {
    public var numberOfItems: Int {
        if UserScopeNoChangeFG.YY.bitableActivityNewDisable {
            return dataModel.failed ? 1 : min(max(dataModel.homePageData.count, 1), 2) //  1 - 2 条
        }
        if dataModel.failed {
            // 失败状态
            return 1
        } else if dataModel.homePageData.isEmpty {
            // 空状态
            return 1
        }
        return min(dataModel.homePageData.count, 2) //  最多 2 条
    }

    public func setup(collectionView: UICollectionView) {
        collectionView.register(ActivityCollectionViewCell.self,
                                forCellWithReuseIdentifier: ActivityCollectionViewCell.reuseIdentifier)
        collectionView.register(ActivityTableViewErrorCell.self,
                                forCellWithReuseIdentifier: ActivityTableViewErrorCell.reuseIdentifier)
        collectionView.register(ActivityTableViewEmptyCell.self,
                                forCellWithReuseIdentifier: ActivityTableViewEmptyCell.reuseIdentifier)
        collectionView.register(RecommendedFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: RecommendedFooterView.reuseIdentifier)
    }

    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        if dataModel.failed {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActivityTableViewErrorCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? ActivityTableViewErrorCell {
                cell.delegate = self
            }
            return cell
        } else if !UserScopeNoChangeFG.YY.bitableActivityNewDisable, dataModel.homePageData.isEmpty {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActivityTableViewEmptyCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? ActivityTableViewEmptyCell {
                cell.delegate = self
                cell.update(activityEmptyConfig: dataModel.activityEmptyConfig)
            }
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActivityCollectionViewCell.reuseIdentifier, for: indexPath)
        guard let cell = cell as? ActivityCollectionViewCell else {
            return cell
        }
        if indexPath.row < dataModel.homePageData.count {
            let data = dataModel.homePageData[indexPath.row]
            cell.update(data: data, delegate: self)
        } else {
            cell.update(data: nil, delegate: self)
        }
        return cell
    }

    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: RecommendedFooterView.reuseIdentifier, for: indexPath)
        default:
            assertionFailure()
            return UICollectionReusableView()
        }
    }

    public func dragItem(at indexPath: IndexPath,
                         sceneSourceID: String?,
                         collectionView: UICollectionView) -> [UIDragItem] {
        return []
    }
    
    private func gotoActivityViewController(selectedItem: HomePageData? = nil) {
        guard case let .baseHomeType(context) = self.homeType else {
            return
        }
        let homeActivity = HomeActivityController(userResolver: userResolver, context: context)
        self.homeActivity = homeActivity
        self.actionInput.accept(.showDetail(viewController: homeActivity))
        self.homeActivity?.update(data: self.dataModel.homePageData, activityEmptyConfig: dataModel.activityEmptyConfig, delegate: self, selectedItem: selectedItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000) { [weak self] in
            // 进去后要做item选中高亮动画，期间不适合刷新列表
            self?.dataModel.pull()
        }
        
    }
}

extension ActivitySection: SpaceSectionDelegate {
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        DocsLogger.info("didSelectItem at\(indexPath.row)")
        collectionView.deselectItem(at: indexPath, animated: true)
        guard indexPath.row < dataModel.homePageData.count else {
            return
        }
        let data = dataModel.homePageData[indexPath.row]
        
        gotoActivityViewController(selectedItem: data)
        /*
        if data.noticeInfo?.noticeStatus == .COMMENT_DELETE {
            DocsLogger.info("LarkCCM_Doc_Feed_Comment_Delete")
            // 评论已被删除
            actionInput.accept(.showHUD(.warning(BundleI18n.SKResource.LarkCCM_Doc_Feed_Comment_Delete)))
        } else if data.messageType == .teamMessage {
            gotoActivityViewController()
        } else if let url = data.noticeInfo?.linkURL {
            var fromValue: FileListStatistics.Module
            if data.noticeInfo?.noticeType == .BEAR_MENTION_AT_IN_CONTENT {
                if case let .baseHomeType(context) = homeType, context.containerEnv == .larkTab {
                    fromValue = FileListStatistics.Module.baseHomeLarkTabMention
                } else {
                    fromValue = FileListStatistics.Module.baseHomeWorkbenchMention
                }
            } else {
                if case let .baseHomeType(context) = homeType, context.containerEnv == .larkTab {
                    fromValue = FileListStatistics.Module.baseHomeLarkTabComment
                } else {
                    fromValue = FileListStatistics.Module.baseHomeWorkbenchComment
                }
            }
            actionInput.accept(.openURL(
                url: url,
                context: [SKEntryBody.fromKey: fromValue]
            ))
        } else if let url = data.cardInfo?.linkURL {
            actionInput.accept(.openURL(url: url, context: nil))
        } else {
            DocsLogger.error("invalid noticeInfo")
        }
        */
        if case let .baseHomeType(context) = homeType {
            var params: [String: Any] = [
                "click": "notice_card_click",
                "current_sub_view": "homepage"
            ]
            params["notice_id"] = data.noticeInfo?.noticeID
            params["file_id"] = data.noticeInfo?.sourceToken?.encryptToken
            params["notice_card_type"] = data.tarckTypeStr
            DocsTracker.reportBitableHomePageEvent(enumEvent: .baseHomepageActivityClick, parameters: params, context: context)
        }
    }

    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath,
                                  sceneSourceID: String?,
                                  collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        return nil
    }
}

extension ActivitySection: ActivityDataModelDelegate {
    
    public func dataUpdate() {
        self.reloadInput.accept(.reloadSection(animated: false))
        updateHeader()
        self.homeActivity?.update(data: self.dataModel.homePageData, activityEmptyConfig: dataModel.activityEmptyConfig, delegate: self)
    }
}

extension ActivitySection: ActivityCellDelegate, ActivityTableViewErrorCellDelegate, ActivityTableViewEmptyCellDelegate {
    func profileClick(data: HomePageData?) {
        if let userID = data?.noticeInfo?.fromUser?.userID {
            actionInput.accept(.showUserProfile(userID: userID))
        }
    }
    
    func activityErrorReload() {
        dataModel.failed = false
        self.reloadInput.accept(.reloadSection(animated: false))
        updateHeader()
        dataModel.pull()
    }
    
    func activityEmptyTaped() {
        gotoActivityViewController()
    }
}


