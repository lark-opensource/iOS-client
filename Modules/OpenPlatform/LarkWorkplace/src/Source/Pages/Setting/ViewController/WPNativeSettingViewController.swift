//
//  WPNativeSettingViewController.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/15.
//

// 文件过长，注意精简
// swiftlint:disable file_length

import Foundation
import LarkUIKit
import LKCommonsLogging
import Swinject
import RoundedHUD
import LarkAlertController
import EENavigator
import LarkOPInterface
import UniverseDesignToast
import UniverseDesignDialog
import LarkContainer
import LarkNavigator
import LarkSetting

let recommendSection: Int = 0    // 推荐应用
let distributedRecommendSection: Int = 1 // 用户可删除的推荐应用
let commonWidgetSection: Int = 2 // 常用widget
let commonIconSection: Int = 3   // 常用icon

/// 用途：支持cell移除滑块的点击事件（非移除按钮区域）
private class TouchTestView: UIView {
    var interceptClick: (() -> Void)?

    /// Execute interceptClick if the area other than DeleteBarView is tapped.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if !(view is DeleteBarView), let eventHandle = interceptClick {
            eventHandle()
            interceptClick = nil
        }
        return view
    }
}

/// 原生工作台-Settings 页面 & 排序页面
final class WPNativeSettingViewController: BaseUIViewController,
                                      UICollectionViewDataSource,
                                      UICollectionViewDelegateFlowLayout {
    static let logger = Logger.log(WPNativeSettingViewController.self)

    private let userId: String
    private let tenantId: String
    private let navigator: UserNavigator
    private let dataManager: AppCenterDataManager
    private let configService: WPConfigService
    /// 数据model
    private var rankPageInfoModel: WorkPlaceRankPageViewModel?
    /// 数据model备份，用于保存更新前的数据
    private var rankPageInfoModelBackup: WorkPlaceRankPageViewModel?

    /// Show badge settings bar or not
    private var showBadge: Bool

    /// 标志是否正在进行拖动排序，处理跨设备同步case
    private var isMoving = false
    /// 记录正在拖动排序的section
    private var sortSection: Int?
    /// 拖动排序的时候需要的拖动视图（被附着到window上）
    private var sortDragView: UIView?
    /// 正在拖拽的cell
    private var sortingCell: AppRankCell?
    /// 拖拽cell的容器相对于window的x（因为被拖动的cell附着在window上）
    private var sortingContainerX: CGFloat = 0
    /// 拖拽的cell 的初始 indexPath
    private var dragIndexPath: IndexPath?
    /// 正在删除的cell
    private var deletingCell: AppRankCell?
    /// 添加一层View用来拦截删除状态下的touch事件
    private lazy var touchView = TouchTestView(frame: view.bounds)
    /// 排序列表的View
    private lazy var appRankCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = CGFloat.leastNonzeroMagnitude
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.ud.bgBase
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(
            AppRankCell.self,
            forCellWithReuseIdentifier: AppRankCell.AppRankCellConfig.cellID
        )
        collectionView.register(
            AppRankBadgeSettingCell.self,
            forCellWithReuseIdentifier: AppRankBadgeSettingCell.Config.reuseID
        )
        collectionView.register(
            AppRankHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: AppRankHeader.resueId
        )
        collectionView.contentInset = UIEdgeInsets(horizontal: 16, vertical: 0)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    /// 空态页
    private lazy var emptyView: WPPageStateView = {
        let view = WPPageStateView()
        view.state = .hidden
        view.layer.cornerRadius = showBadge ? 10 : 0
        view.layer.masksToBounds = showBadge ? true : false
        return view
    }()

    /// 常用应用更新回调
    var commonItemsUpdate: (() -> Void)?

    /// 展示顶层toast的window
    private lazy var toastWindow: UIWindow = {
        if let viewWindow = view.window {
            return viewWindow
        } else if let topWindow = navigator.mainSceneWindow {
            return topWindow
        } else {
            Self.logger.error("get show toast’s window failed")
            return UIWindow()
        }
    }()

    private var enableNormalUserRemoveApps: Bool {
        return configService.fgValue(for: .enableNormalUserRemoveApps)
    }

    init(
        userId: String,
        tenantId: String,
        navigator: UserNavigator,
        dataManager: AppCenterDataManager,
        configService: WPConfigService,
        showBadge: Bool,
        commonItemsUpdate: (() -> Void)?
    ) {
        self.userId = userId
        self.tenantId = tenantId
        self.navigator = navigator
        self.dataManager = dataManager
        self.configService = configService
        self.showBadge = showBadge
        self.commonItemsUpdate = commonItemsUpdate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setViewConstraint()
        setupNavigationBar()
        fetchDataAndRefreshViews()
        setupLongPressGestureRecognizer()
        WPEventReport(
            name: WPNewEvent.openplatformWorkspaceSettingPageView.rawValue,
            userId: userId,
            tenantId: tenantId
        ).post()
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        // 适配iPad分/转屏，CollectionView 重新布局
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: { [weak self](_) in
            self?.appRankCollectionView.collectionViewLayout.invalidateLayout()
        })
    }

    /// 设置视图
    private func setupViews() {
        /* view hierarchy
         - view
            - touchView
                - appRankCollectionView (result view)
                - emptyView (state view) (no result / failed)
                - loadingPlaceholderView (loading view)
         */
        view.addSubview(touchView)
        touchView.addSubview(appRankCollectionView)
        touchView.addSubview(emptyView)
    }

    /// 设置视图约束关系
    private func setViewConstraint() {
        touchView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        appRankCollectionView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        let topInset = showBadge ? AppRankBadgeSettingCell.Config.cellHeight + 3 * Layout.sectionMargin : 0
        let bottomInset = showBadge ? 34 : 0
        let horizontalInset = showBadge ? 16 : 0
        emptyView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(topInset)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
            make.bottom.equalToSuperview().inset(bottomInset)
        }
    }

    /// Set up the style of navigation bar
    private func setupNavigationBar() {
        // Navi Button on the left side
        addBackItem()
        // Finish button on the right side
        setRightItem(text: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Done, enable: true)
        // Navigation Bar's title
        title = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_SettingTitle
    }

    /// Show loading page
    private func showLoadingPage() {
        loadingPlaceholderView.isHidden = false
    }

    /// Hide loading page
    private func hideLoadingPage() {
        loadingPlaceholderView.isHidden = true
    }

    /// 展示正常页面
    /// Show rank result page (not empty result)
    ///
    /// - Parameter model: view model for render result view
    private func showNormalPage(with model: WorkPlaceRankPageViewModel) {
        loadingPlaceholderView.isHidden = true
        emptyView.state = .hidden
        rankPageInfoModel = model
        rankPageInfoModelBackup = rankPageInfoModel?.getCopy()
        appRankCollectionView.reloadData()
    }

    /// 展示空态页
    /// Show empty result page
    /// 1. If show badge settings bar, there's no add favorite button in empty page
    /// 2. If not show badge settings bar, there's an add favorite button in empty page
    private func showEmptyPage() {
        loadingPlaceholderView.isHidden = true
        if showBadge {
            emptyView.state = .noApp(.create(action: nil))
        } else {
            emptyView.state = .noApp(.create(action: { [weak self] in
                self?.switchToAppSearchPage()
            }))
        }
        appRankCollectionView.reloadData()
    }

    /// 展示加载失败页面
    private func showFailedPage() {
        loadingPlaceholderView.isHidden = true
        emptyView.state = .loadFail(
            .create { [weak self] in
                self?.fetchDataAndRefreshViews()
            }
        )
        appRankCollectionView.reloadData()
    }

    /// 设置导航栏右侧按钮
    ///
    /// - Parameters:
    ///   - text: 按钮文字
    ///   - enable: 按钮开关
    private func setRightItem(text: String, enable: Bool) {
        let barItem = LKBarButtonItem(image: nil, title: text)
        barItem.button.addTarget(self, action: #selector(rightItemClick), for: .touchUpInside)
        barItem.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        barItem.button.setTitleColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        barItem.button.setTitleColor(UIColor.ud.primaryContentLoading, for: .disabled)
        barItem.isEnabled = enable
        self.navigationItem.rightBarButtonItem = barItem
    }

    /// 关闭page的点击事件
    override func backItemTapped() {
        if getModifyResult() != nil {
            Self.logger.info("user tap close button, show modify ensure alert")
            showModifyNotSaveAlert()
        } else {
            Self.logger.info("user tap close button, exit rankPage directly")
            self.exitRankPage()
        }
    }

    /// 右侧按钮点击事件
    @objc private func rightItemClick() {
        if let diff = getModifyResult() {   // 有改动内容时，提交改动
            ensureRankResult(diff: diff)
        } else {    // 否则直接退出
            Self.logger.info("user tap complete button with no modify, exit rankPage directly")
            self.exitRankPage()
        }
    }

    /// 确认排序结果
    ///
    /// - Parameter diff: contains commonly used and recommend apps' old version and new version
    private func ensureRankResult(diff: UpdateRankResult) {
        Self.logger.info("complete button tapped, try to update rank result \(diff)")
        UDToast.showLoading(with: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_SavingSetting, on: toastWindow)
        // Send HTTP request to update the list of commonly used and recommend apps
        dataManager.updateCommonList(
            updateData: diff,
            cacheModel: rankPageInfoModel,
            success: { [weak self] in
                // Request success, update backup view model and switch to forehead page
                Self.logger.info("update rank result successed")
                guard let self = self else {
                    Self.logger.error("new appRankPage's self already released")
                    return
                }
                UDToast.showSuccess(
                    with: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_SettingSuccess,
                    on: self.toastWindow
                )
                self.rankPageInfoModelBackup = self.rankPageInfoModel
                self.commonItemsUpdate?()
                self.exitRankPage()
                WPNoti.workplaceCommonAppDataChange.postDataNeedUpdateNoti()
            },
            failure: { [weak self] (error) in
                // Request failed, show failure toast
                Self.logger.error("update rank result failed", error: error)
                guard let self = self else {
                    Self.logger.error("new appRankPage's self already released")
                    return
                }
                UDToast.showFailure(
                    with: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_SettingFail,
                    on: self.toastWindow
                )
            }
        )
    }

    /// 展示修改内容未保存的弹窗提示
    private func showModifyNotSaveAlert() {
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_CancelEditTips)
        alert.addCancelButton()
        alert.addPrimaryButton(
            text: BundleI18n.LarkWorkplace.AppDetail_Application_Mechanism_Confirm,
            dismissCompletion: { [weak self] in self?.exitRankPage() }
        )
        navigator.present(alert, from: self)
    }

    /// 获取排序页面修改结果（若无修改，返回nil）
    ///
    /// - Returns: If commonly used and recommend apps are deleted or location is updated, return diff data struct, else return nil
    private func getModifyResult() -> UpdateRankResult? {
        guard let newModel = rankPageInfoModel, let oldModel = rankPageInfoModelBackup else {
            Self.logger.error("view model missed, get update result failed!")
            return nil
        }

        // Update view model
        newModel.reorderLists()
        let newCommonWidgetList = newModel.commonWidgetItemList ?? []
        let oldCommonWidgetList = oldModel.commonWidgetItemList ?? []
        let newCommonIconList = newModel.commonIconItemList ?? []
        let oldCommonIconList = oldModel.commonIconItemList ?? []
        let newDistributedList = newModel.distributedRecommendItemList ?? []
        let oldDistributedList = oldModel.distributedRecommendItemList ?? []

        // Check if new view model and old view model are the same
        let isIconSame = newCommonIconList.elementsEqual(oldCommonIconList) { $0 == $1 }
        let isWidgetSame = newCommonWidgetList.elementsEqual(oldCommonWidgetList) { $0 == $1 }
        let distributedSame = newDistributedList.elementsEqual(oldDistributedList) { $0 == $1 }

        if isIconSame, isWidgetSame, distributedSame {
            // If same, return nil
            Self.logger.info("item list is no modified, not need to update")
            return nil
        } else {
            // If not same, return diff data struct
            Self.logger.info("item list is modified, need to update")
            return UpdateRankResult(
                newCommonWidgetItemList: newCommonWidgetList,
                originCommonWidgetItemList: oldCommonWidgetList,
                newCommonIconItemList: newCommonIconList,
                originCommonIconItemList: oldCommonIconList,
                newDistributedRecommendItemList: newDistributedList,
                originDistributedRecommendItemList: oldDistributedList
            )
        }
    }

    /// 退出排序页面
    private func exitRankPage() {
        // ipad下，如果是唯一一个VC，则展示Default来关闭VC
        if Display.pad, navigationController?.viewControllers.first == self {
            navigator.showDetail(DefaultDetailController(), from: self)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    /// Switch to app search page
    @objc func switchToAppSearchPage() {
        Self.logger.info("switch to app search page")
        let body = FavoriteSettingBody(showCommonBar: true)
        navigator.push(body: body, from: self)
    }

    /// 设置touch拦截事件
    /// Hide delete button on the right side, if tapped area other than delete button.
    private func setTouchInterceptEvent() {
        touchView.interceptClick = { [weak self] in
            self?.deletingCell?.hideDeleteBar()
            self?.deletingCell = nil
        }
    }

    /// 页面所需数据生成
    /// Fetch rank page data from remote server, and refresh views.
    /// - Request / Decode failed -> Show fail page
    /// - Rank model with empty app list -> Show no app page
    /// - Rank model request success & not empty app list -> Show rank app page
    private func fetchDataAndRefreshViews() {
        showLoadingPage()
        dataManager.fetchRankPageInfoWith(
            success: { [weak self] (model, isFromCache) in
                Self.logger.info("rank page fetch data success(isFromCache: \(isFromCache))")
                guard let `self` = self else {
                    Self.logger.error("AppRankViewController.self missed, refresh view aborted.")
                    return
                }
                if model.isEmptyModel() {    // 返回数据为空,展示空态页
                    Self.logger.warn("rank page model is empty, need to retry")
                    self.showEmptyPage()
                    WPMonitor().setCode(WPMCode.workplace_myapp_page_render_fail)
                        .setError(errMsg: "rank page model is empty, show page failed")
                        .postFailMonitor()
                } else {                     // 返回数据正常，展示正常页面
                    Self.logger.info("rank page model is ready, show rank page")
                    WPMonitor().setCode(WPMCode.workplace_myapp_page_render_success)
                        .postSuccessMonitor()
                    self.showNormalPage(with: model)
                }
            },
            failure: { [weak self] (error) in
                Self.logger.error("rank page fetch data failed", error: error)
                guard let `self` = self else {
                    Self.logger.error("AppRankViewController.self missed, refresh view aborted")
                    return
                }
                WPMonitor().setCode(WPMCode.workplace_myapp_page_render_fail)
                    .setError(errMsg: "rank page data request failed", error: error)
                    .postFailMonitor()
                if self.rankPageInfoModel != nil {
                    Self.logger.error("rank page fetch data failed, display current data without update")
                    self.hideLoadingPage()
                } else {
                    Self.logger.error("rank page fetch data failed, no current data show failedPage")
                    self.showFailedPage()
                }
            }
        )
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let originCount = rankPageInfoModel?.orderedItemLists.count ?? 0
        return numberOfSectionsWithAppBadgeCellShowOrHide(for: originCount)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showBadge && section == 0 { return 1 }
        let dataIndex = originSectionWithAppBadgeCellShowOrHide(for: section)
        guard let modelLists = rankPageInfoModel?.orderedItemLists, dataIndex < modelLists.count else {
            Self.logger.error("view model is nil or section(\(dataIndex)) out of bound")
            return 0
        }
        return modelLists[dataIndex].count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        // Badget Settings Bar
        if showBadge && indexPath.section == 0 {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: AppRankBadgeSettingCell.Config.reuseID,
                for: indexPath
            )
        }
        // Commonly used and recommend app
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AppRankCell.AppRankCellConfig.cellID,
            for: indexPath
        )
        guard let rankCell = cell as? AppRankCell else {
            return cell
        }
        let dataSectionIndex = originSectionWithAppBadgeCellShowOrHide(for: indexPath.section)
        guard let model = rankPageInfoModel,
              let appInfo = model.getItemInfo(in: dataSectionIndex, at: indexPath.row) else {
            Self.logger.error("get item info failed with indexPath:\(indexPath)")
            return cell
        }
        let position = getCellPosition(
            rowIndex: indexPath.row,
            rowCount: self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        )
        rankCell.refresh(
            itemInfo: appInfo,
            sortable: isSortable(indexPath: indexPath),
            tagType: model.getTagType(section: dataSectionIndex, itemInfo: appInfo),
            deleteEvent: getDeleteEvent(section: dataSectionIndex),
            position: position
        )
        return rankCell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        moveItemAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        let sourceDataSection = originSectionWithAppBadgeCellShowOrHide(for: sourceIndexPath.section)
        let destinationDataSection = originSectionWithAppBadgeCellShowOrHide(for: destinationIndexPath.section)
        if sourceIndexPath != destinationIndexPath {
            // Get source item info
            guard let modelLists = rankPageInfoModel?.orderedItemLists else {
                Self.logger.error("data model is empty, move cell failed")
                return
            }
            guard sourceDataSection < modelLists.count, sourceIndexPath.row < modelLists[sourceDataSection].count else {
                // swiftlint:disable line_length
                Self.logger.error("section(\(sourceDataSection)) or index(\(sourceIndexPath.row)) out bounds of data model(\(modelLists)), move cell failed")
                // swiftlint:enable line_length
                return
            }
            let appId = modelLists[sourceDataSection][sourceIndexPath.row]
            // Remove from old position in view model
            rankPageInfoModel?.orderedItemLists[sourceDataSection].remove(at: sourceIndexPath.row)
            // Insert into new position in view model
            if destinationIndexPath.row < modelLists[destinationDataSection].count {
                rankPageInfoModel?.orderedItemLists[destinationDataSection].insert(appId, at: destinationIndexPath.row)
            } else {
                rankPageInfoModel?.orderedItemLists[destinationDataSection].append(appId)
            }
            WPEventReport(
                name: WPEvent.appcenter_adjustorder.rawValue,
                userId: userId,
                tenantId: tenantId
            ).post()
            // Refresh UI
            collectionView.reloadSections(IndexSet(integer: sourceIndexPath.section))
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        // Badge settings bar has no section header
        if showBadge && indexPath.section == 0 { return UICollectionReusableView(frame: .zero) }

        if kind == UICollectionView.elementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: AppRankHeader.resueId,
                for: indexPath
            )
            if let groupHeader = headerView as? AppRankHeader {
                let dataSection = originSectionWithAppBadgeCellShowOrHide(for: indexPath.section)
                let info = getSectionTitleInfo(section: dataSection)
                if let titleText = info.text {
                    groupHeader.refresh(text: titleText, showTip: info.showTip)
                }
                if info.showTip {
                    groupHeader.showTipEvent = { [weak self] in
                        self?.showTipDialog()
                    }
                } else {
                    groupHeader.showTipEvent = nil
                }

                return groupHeader
            }
            return headerView
        }
        return UICollectionReusableView(frame: .zero)
    }

    /// Get section title and check if should show tips on the right of section title
    ///
    /// - Parameter section: Section index
    /// - Returns: A tuple. First element is the title of section. Second element represents whether should show tips.
    private func getSectionTitleInfo(section: Int) -> (text: String?, showTip: Bool) {
        // swiftlint:disable line_length
        guard let modelLists = rankPageInfoModel?.orderedItemLists, section < modelLists.count else {
            Self.logger.error("data model is empty or section(\(section)) out of dataBound, collectionView header not display")
            return (nil, false)
        }

        let recommendText = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AdminRecAppTtl
        let commonText = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_CustomFavAppTtl

        if section == recommendSection && !modelLists[recommendSection].isEmpty {
            // 推荐应用分组，展示标题，提示图标与否分为以下两种情况
            // Case1: 展示角标哦设置栏的情况下，展示提示图标
            // Case2: 不展示角标设置栏的情况下, 如果没有可移除推荐应用，不展示提示图标；否则，展示提示图标
            return (recommendText, showBadge ? true : !modelLists[distributedRecommendSection].isEmpty)
        } else if section == distributedRecommendSection && modelLists[recommendSection].isEmpty && !modelLists[distributedRecommendSection].isEmpty {
            // 没有推荐应用分组 && 有可移除推荐应用分组，展示标题和提示图标
            return (recommendText, true)
        } else if section == commonWidgetSection && !modelLists[commonWidgetSection].isEmpty {
            // 有常用widget分组，展示标题
            return (commonText, false)
        } else if section == commonIconSection && modelLists[commonWidgetSection].isEmpty && !modelLists[commonIconSection].isEmpty {
            // 没有常用widget分组 && 有常用icon分组，展示标题
            return (commonText, false)
        } else {
            return (nil, false)
        }
        // swiftlint:enable line_length
    }

    /// Show dialog when click tips icon on the right of section title
    private func showTipDialog() {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AdminRecAppPrompt)

        let contentText = (enableNormalUserRemoveApps || !showBadge) ?
            BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AdminRecAppDesc :
            BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AdminRecAppDescGa
        dialog.setContent(text: contentText)

        dialog.addPrimaryButton(
            text: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_IKnow,
            dismissCompletion: {}
        )
        self.present(dialog, animated: true, completion: nil)
    }

    /// Generate callback when user tap the delect button.
    ///
    /// - Parameter section: Data index in view model
    /// - Returns: Callback when user tap the delect button.
    private func getDeleteEvent(section: Int) -> ((_ cell: AppRankCell, _ isDeleted: Bool) -> Void)? {
        if section == recommendSection {
            // Apps in recommed section could not be deleted
            return nil
        } else {
            return { [weak self] (cell, isDeleted) in
                self?.deleteItem(cell: cell, isDeleted: isDeleted)
            }
        }
    }

    /// 删除应用
    /// - Parameters:
    ///   - cell: 要删除的cell
    ///   - isDeleted: 是否是已经删除
    private func deleteItem(cell: AppRankCell, isDeleted: Bool) {
        // 删除应用
        if isDeleted {
            guard let indexPath = appRankCollectionView.indexPath(for: cell) else {
                Self.logger.error("get indexPath failed, delete cell failed")
                return
            }
            let dataSection = originSectionWithAppBadgeCellShowOrHide(for: indexPath.section)
            let itemId: String = rankPageInfoModel?.orderedItemLists[dataSection].remove(at: indexPath.row) ?? ""
            let itemInfo = rankPageInfoModel?.allItemInfos?[itemId]
            let appId: String = itemInfo?.appId ?? ""
            WPEventReport(
                name: WPEvent.appcenter_my_deleteapp.rawValue,
                userId: userId,
                tenantId: tenantId
            ).set(key: WPEventNewKey.appId.rawValue, value: appId).post()

            // 埋点字段判断，现在没有绝对统一的判断标准，而且不收敛，后续需要梳理统一。
            var removeType: String?
            if itemInfo?.itemType == .link,
               itemInfo?.linkUrl != nil {
                removeType = "link"
            } else if itemInfo?.block != nil {
                removeType = "block"
            } else {
                removeType = "icon"
            }

            WPEventReport(
                name: WPNewEvent.openplatformWorkspaceSettingPageClick.rawValue,
                userId: userId,
                tenantId: tenantId
            )
                .set(key: WPEventNewKey.click.rawValue, value: WPClickValue.remove.rawValue)
                .set(key: "target", value: WPTargetValue.none.rawValue)
                .set(key: "remove_type", value: removeType)
                .set(key: WPEventNewKey.appId.rawValue, value: itemInfo?.appId)
                .set(key: WPEventNewKey.blockTypeId.rawValue, value: itemInfo?.block?.blockTypeId)
                .set(key: "item_id", value: itemInfo?.itemId)
                .post()

            appRankCollectionView.performBatchUpdates({
                    appRankCollectionView.deleteItems(at: [indexPath])
                },
                completion: { (_) in
                    Self.logger.info("user delete cell at \(indexPath)")
                }
            )
            if let model = rankPageInfoModel, model.isEmptyForReorderLists() {
                // 删除后，检查数据为空时，展示空态页
                Self.logger.warn("after user deletion, rank page model is empty, need to retry")
                showEmptyPage()
            }
        } else {    // 进入准备删除状态（有可能会取消状态，点击移除按钮以外的区域，删除状态取消）
            deletingCell = cell
            setTouchInterceptEvent()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 跳转到「应用角标设置」页
        if showBadge && indexPath.section == 0 {
            Self.logger.info("user tap setting, navigate to appBadgeSettingPage")
            navigator.push(body: AppBadgeSettingBody(), from: self)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.contentSize.width
        if showBadge && indexPath.section == 0 {
            return CGSize(width: width, height: AppRankBadgeSettingCell.Config.cellHeight)
        }
        return CGSize(width: width, height: AppRankCell.AppRankCellConfig.cellHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        // Badge settings bar has no section header
        if showBadge && section <= 0 { return .zero }
        let dataSection = originSectionWithAppBadgeCellShowOrHide(for: section)
        guard let modelLists = rankPageInfoModel?.orderedItemLists, dataSection < modelLists.count else {
            // swiftlint:disable line_length
            Self.logger.error("data model is empty or section(\(dataSection)) out of dataBound, collectionView header not display")
            // swiftlint:enable line_length
            return .zero
        }
        let sectionTitleText = getSectionTitleInfo(section: dataSection).text
        return sectionTitleText == nil ? .zero : CGSize(width: collectionView.WP_w, height: 42.0)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        let top = (showBadge && section == 0) ? Layout.sectionMargin * 2 : Layout.sectionMargin
        if collectionView.numberOfItems(inSection: section) > 0 {
            return UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)
        }
        return .zero
    }

    /// 添加长按手势
    private func setupLongPressGestureRecognizer() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handle(longGesture:))
        )
        appRankCollectionView.addGestureRecognizer(longPressGestureRecognizer)
    }

    /// 处理长按
    @objc private func handle(longGesture: UILongPressGestureRecognizer) {
        switch longGesture.state {
        case .began:
            // Get drag begin position
            let longGestureDragPoint = longGesture.location(in: appRankCollectionView)
            guard let indexPath = appRankCollectionView.indexPathForItem(
                at: CGPoint(x: appRankCollectionView.bdp_width / 2, y: longGestureDragPoint.y)
            ) else {
                Self.logger.warn("cell drag illegally")
                return
            }

            // Check if could be dragged
            if !isDraggable(indexPath: indexPath) { return }

            // Get dragged cell
            let dataSection = originSectionWithAppBadgeCellShowOrHide(for: indexPath.section)
            guard let modelLists = rankPageInfoModel?.orderedItemLists,
                  dataSection < modelLists.count,
                  indexPath.row < modelLists[dataSection].count,
                  let cell = appRankCollectionView.cellForItem(at: indexPath) as? AppRankCell
            else {
                Self.logger.warn("cell drag illegally")
                return
            }

            // Generate drag view, and put it on the right position
            sortDragView = cell.getDargView()
            let dragPosition = longGesture.location(in: view.window)
            let cellPosition = cell.superview?.convert(cell.frame, to: view.window)
            let containerX = cellPosition?.minX ?? 0
            sortDragView?.frame = CGRect(
                origin: CGPoint(x: containerX, y: dragPosition.y - cell.contentView.bdp_height / 2),
                size: CGSize(width: cell.contentView.bdp_width, height: cell.contentView.bdp_height)
            )
            // 拖动时候跟手的头像层级要高
            // 原本是加到 animatedTabBarController.view上的，但其实不应该依赖Tabbar的位置，比如iPad上tabbar在侧边栏的情况就会出问题
            if let imageView = sortDragView {
                view.window?.addSubview(imageView)
            } else {
                Self.logger.warn("generate dragView failed")
            }

            // Save drag status
            isMoving = true
            sortSection = indexPath.section
            sortingCell = cell
            sortingContainerX = containerX
            sortingCell?.startDrag()
            dragIndexPath = indexPath
        case .changed:
            // Hide dragged cell in collection view
            hiddenTempCell()

            // Updates the position of dragged cell within the collection view’s bounds.
            // Only can be dragged within same section.
            if let indexPath = appRankCollectionView.indexPathForItem(
                at: longGesture.location(in: appRankCollectionView)
            ), indexPath.section == sortSection {
                let longGestureDragPoint = longGesture.location(in: appRankCollectionView)
                appRankCollectionView.updateInteractiveMovementTargetPosition(
                    CGPoint(
                        x: appRankCollectionView.bdp_width / 2,
                        y: longGestureDragPoint.y
                    )
                )
            }

            // Update the position of drag view
            let dragPosition = longGesture.location(in: view.window)
            sortDragView?.bdp_origin = CGPoint(
                x: sortingContainerX,
                y: dragPosition.y - AppRankCell.AppRankCellConfig.cellHeight / 2
            )
        case .ended:
            // Remove drag view
            sortDragView?.removeFromSuperview()
            sortDragView = nil

            let cancelAction = {
                self.endOrCancelDragAction()
                self.appRankCollectionView.cancelInteractiveMovement()
                self.isMoving = false
            }

            let endAction = {
                self.endOrCancelDragAction()
                self.appRankCollectionView.endInteractiveMovement()
                self.isMoving = false
            }

            // If drag happens not in the same section, cancel
            guard let indexPath = appRankCollectionView.indexPathForItem(
                    at: longGesture.location(in: appRankCollectionView)
                ), indexPath.section == sortSection else {
                cancelAction()
                return
            }

            // If view model in target index path is unavailable, cancel
            let dataSection = originSectionWithAppBadgeCellShowOrHide(for: indexPath.section)
            guard let modelLists = rankPageInfoModel?.orderedItemLists,
                  dataSection < modelLists.count,
                  indexPath.row < modelLists[dataSection].count else {
                cancelAction()
                return
            }

            // Successfully moved
            endAction()
        default:
            // Remove drag view
            sortDragView?.removeFromSuperview()
            sortDragView = nil
            // Drag cancelled
            endOrCancelDragAction()
            appRankCollectionView.cancelInteractiveMovement()
            isMoving = false
        }
    }

    /// Check if cell at `indexPath` is draggable
    ///
    /// - Parameter indexPath: Index path
    /// - Returns: Is draggable or not
    private func isDraggable(indexPath: IndexPath) -> Bool {
        if !isSortable(indexPath: indexPath) { return false }
        // Cannot drag when other cell is moving
        if isMoving { return false }
        // Cannot drag if reordering was prevented from beginning
        if !appRankCollectionView.beginInteractiveMovementForItem(at: indexPath) { return false }

        return true
    }

    private func isSortable(indexPath: IndexPath) -> Bool {
        // Badge settings bar can not be dragged
        if showBadge && indexPath.section == 0 { return false }
        // Recommend apps can not be dragged
        let dataSection = originSectionWithAppBadgeCellShowOrHide(for: indexPath.section)
        if dataSection == recommendSection || dataSection == distributedRecommendSection { return false }
        // Block does not support sorting
        // https://bytedance.feishu.cn/docx/Gn1vdfHm8o1w7BxRWiqcDiVCnTh
        if dataSection == commonWidgetSection { return false }
        return true
    }

    /// Hide dragged cell in collection view
    private func hiddenTempCell() {
        sortingCell?.isHidden = true
        sortingCell?.contentView.isHidden = true
        sortingCell?.alpha = 0
        sortingCell?.contentView.alpha = 0
    }

    /// Drag ended or cancelled, refresh UI
    private func endOrCancelDragAction() {
        sortingCell?.endDrag()
        sortingCell = nil
        dragIndexPath = nil
        sortSection = nil
    }

    /// Get cell position in correspond section
    /// Different position -> Different cell appearance
    ///
    /// - Parameters:
    ///    - rowIndex: Cell's row index
    ///    - rowCount: The number of cell in correspond section
    private func getCellPosition(rowIndex: Int, rowCount: Int) -> AppCollectionCellPosition {
        if rowCount > 1 {
            if rowIndex == 0 {
                return .top
            } else if rowIndex == rowCount - 1 {
                return .bottom
            } else {
                return .middle
            }
        } else {
            return .topAndBottom
        }
    }

    /// 根据是否展示角标设置栏，计算 CollectionView 中的 Section 数量
    /// Calculate the number of sections in the UICollectionView according to whether to display badge settings bar.
    /// If show badge settings bar, " the number of sections" = "the number of data collections" + 1
    /// If not show badge settings bar, "the number of sections" = "the number of data collections"
    ///
    /// - Parameter dataCollectionCount: The number of data collections.
    private func numberOfSectionsWithAppBadgeCellShowOrHide(for dataCollectionCount: Int) -> Int {
        return showBadge ? dataCollectionCount + 1 : dataCollectionCount
    }

    /// 根据是否展示角标设置栏，计算当前 Section 索引对应的 data 索引
    /// Calculate the index of data model according to whether to display badge settings bar.
    /// If show badge settings bar and not the first section(badge section), "the index of data model" = "the index of section" - 1
    ///
    /// - Parameter sectionIndex: The index of section in UICollectionView
    private func originSectionWithAppBadgeCellShowOrHide(for sectionIndex: Int) -> Int {
        if showBadge {
            return sectionIndex > 0 ? sectionIndex - 1 : sectionIndex
        } else {
            return sectionIndex
        }
    }

    private enum Layout {
        /// Margin between sections
        static let sectionMargin: CGFloat = 8.0
    }
}

// swiftlint:enable file_length
