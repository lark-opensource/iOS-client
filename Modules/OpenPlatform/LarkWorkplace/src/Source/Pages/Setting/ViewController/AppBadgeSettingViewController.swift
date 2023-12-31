//
//  AppBadgeSettingViewController.swift
//  LarkWorkplace
//
//  Created by houjihu on 2020/12/20.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import LKCommonsTracker
import Swinject
import RoundedHUD
import EENavigator
import LarkNavigator
import LarkContainer

/// 「应用角标设置」页面vc
final class AppBadgeSettingViewController: BaseUIViewController,
                                           UICollectionViewDelegate,
                                           UICollectionViewDelegateFlowLayout,
                                           UICollectionViewDataSource {
    /// 负责「应用角标设置」页VC相关的log输出
    static let logger = Logger.log(AppBadgeSettingViewController.self)

    private var appBadgeSettingModel: AppBadgeSettingModel?
    private let navigator: UserNavigator
    private let appBadgeSettingViewModel: AppBadgeSettingViewModel
    private let dataManager: AppCenterDataManager

    /// 「应用角标设置」列表的View
    private lazy var appBadgeSettingCollectioView: UICollectionView = {
        /// collectionView的layout配置
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = CGFloat.leastNonzeroMagnitude
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.ud.bgBase
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(
            AppBadgeSettingCell.self,
            forCellWithReuseIdentifier: AppBadgeSettingCell.Config.reuseID
        )
        collectionView.contentInset = UIEdgeInsets(horizontal: 16, vertical: 0)
//        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var headerView: UIView = {
        let container = UIView()
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        label.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_BadgeDesc
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        return container
    }()
    /// 空态页
    private lazy var emptyView: WPPageStateView = {
        WPPageStateView()
    }()

    // MARK: VC初始化
    init(
        userId: String,
        tenantId: String,
        navigator: UserNavigator,
        viewModel: AppBadgeSettingViewModel,
        dataManager: AppCenterDataManager
    ) {
        self.navigator = navigator
        self.appBadgeSettingViewModel = viewModel
        self.dataManager = dataManager
        super.init(nibName: nil, bundle: nil)
        WPEventReport(
            name: WPNewEvent.openplatformWorkspaceSettingPageView.rawValue,
            userId: userId,
            tenantId: tenantId
        ).post()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        dataProduce()
    }

    deinit {
        Self.logger.info("AppBadgeSettingViewController deinit")
    }

    // MARK: 视图相关

    /// 设置视图
    private func setupViews() {
        /// 设置导航栏左侧的关闭按钮
        addBackItem()
        title = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_BadgeSettingsTtl
        // 空态页
        view.addSubview(emptyView)
        emptyView.state = .hidden

        view.addSubview(headerView)

        // collectionView
        view.addSubview(appBadgeSettingCollectioView)
        appBadgeSettingCollectioView.isHidden = true
        // 设置视图约束
        setViewConstraint()
    }
    /// 设置视图约束关系
    private func setViewConstraint() {
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        headerView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
        }
        appBadgeSettingCollectioView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    /// 根据是否还有更多数据的状态，刷新loadMore视图
    private func loadMore(_ hasMore: Bool) {
        if hasMore {
            appBadgeSettingCollectioView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
                self?.dataProduce()
            }
        } else {
            appBadgeSettingCollectioView.removeBottomLoadMore()
        }
    }

    /// 展示正常页面
    private func showNoramlPage(with model: AppBadgeSettingModel) {
        emptyView.state = .hidden
        view.backgroundColor = UIColor.ud.bgBase  // 满足collectionView的背景需求
        appBadgeSettingModel = model
        appBadgeSettingCollectioView.reloadData()           // 刷新collectionView数据
        appBadgeSettingCollectioView.isHidden = false       // 展示collectionView
        trackView(count: model.items?.count)
    }

    /// 展示空态页
    private func showEmptyPage() {
        view.backgroundColor = UIColor.ud.bgBase           // 和empty页面保持一致
        emptyView.state = .noBadgeApp
        appBadgeSettingCollectioView.isHidden = true        // 展示collectionView
        trackView(count: 0)
    }

    /// 产品埋点 for 「工作台设置中的 badge 批量设置页面展示」
    private func trackView(count: Int?) {
        var trackParams = [String: Any]()
        trackParams["apps_count"] = count ?? 0 // 进入页面时展示的 app 数量
        Tracker.post(TeaEvent("appcenter_set_badgeSettingPageOnShow", params: trackParams))
    }

    /// 展示加载失败页面
    private func showFailedPage() {
        view.backgroundColor = UIColor.ud.bgBase           // 和retry页面保持一致

        emptyView.state = .loadFail(
            .create { [weak self] in
                /// 显示 Loading 页
                self?.loadingPlaceholderView.isHidden = false
                /// 刷新数据
                self?.dataProduce()
            }
        )
        appBadgeSettingCollectioView.isHidden = true        // 展示collectionView
    }

    /// page返回按钮的点击事件
    override func backItemTapped() {
        Self.logger.info("user tap close button")
        // ipad下，如果是唯一一个VC，则展示Default来关闭VC
        if Display.pad, navigationController?.viewControllers.first == self {
            navigator.showDetail(DefaultDetailController(), from: self)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    /// 屏幕底部显示请求错误相关提示
    func showRequestFailPrompt(with text: String) {
        if text.isEmpty {
            Self.logger.error("prompt text is empty")
            return
        }
        RoundedHUD.showFailure(with: text, on: view)
    }

    // MARK: 数据生成

    /// 页面所需数据生成
    func dataProduce() {
        /// 判断是「初始加载」，还是「加载更多」
        let initialLoad = (appBadgeSettingModel == nil)
        /// loading相关
        let showLoading = DispatchWorkItem { [weak self] in
            self?.loadingPlaceholderView.isHidden = false
        }
        let hideLoading = DispatchWorkItem { [weak self] in
            showLoading.cancel()
            self?.loadingPlaceholderView.isHidden = true
        }
        if initialLoad {
            showLoading.perform()   // 显示loading，进行数据拉取
        }
        let pageToken = appBadgeSettingModel?.pageToken
        dataManager.getAppBadgeSettings(pageToken: pageToken) { [weak self] model in
            // 拉取成功
            Self.logger.debug("\(model)")
            Self.logger.info("rank page fetch data success, appBadgeSettingModel is ready")
            guard let `self` = self else {
                Self.logger.error("AppRankViewController.self missed, data produce exit")
                return
            }
            if initialLoad {
                hideLoading.perform()
            }
            var mergedModel = model
            if let currentModel = self.appBadgeSettingModel {
                mergedModel = AppBadgeSettingModel.merge(former: currentModel, with: model)
            }
            if let items = mergedModel.items, !(items.isEmpty) { // 返回数据正常，展示正常页面
                Self.logger.info("appBadgeSetting page model is ready, show rank page")
                self.showNoramlPage(with: mergedModel)
                self.loadMore(mergedModel.hasMore)
            } else {    // 返回数据为空,展示空态页
                Self.logger.warn("appBadgeSetting page model is empty, need to retry")
                self.showEmptyPage()
                self.loadMore(false)
            }
        } failure: { [weak self] error in
            // 拉取失败
            Self.logger.error("appBadgeSetting page fetch data failed", error: error)
            if initialLoad {
                hideLoading.perform()
            }
            let exsitsData = (self?.appBadgeSettingModel != nil)
            self?.appBadgeSettingCollectioView.endBottomLoadMore(hasMore: exsitsData)
            if exsitsData {
                Self.logger.info("appBadgeSetting page fetch data failed, display current data without update")
                self?.showRequestFailPrompt(with: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_BadgeAppLoadingFail)
            } else {
                Self.logger.info("appBadgeSetting page fetch data failed, no current data show failedPage")
                self?.showFailedPage()
            }
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let items = appBadgeSettingModel?.items, !(items.isEmpty) {
            return 1
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let items = appBadgeSettingModel?.items else {
            Self.logger.error("data model is empty, collectionView not display")
            return 0
        }
        return items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        /// 获取cell
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AppBadgeSettingCell.Config.reuseID,
            for: indexPath
        )
        guard let settingCell = cell as? AppBadgeSettingCell else {
            return cell
        }
        /// 获取数据
        guard let model = appBadgeSettingModel, let items = model.items, indexPath.row < items.count else {
            Self.logger.error("get item info failed with indexPath:\(indexPath)")
            return settingCell
        }
        let appInfo = items[indexPath.row]
        /// 刷新cell
        var position: AppCollectionCellPosition = .middle
        let sectionCellCount = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        if sectionCellCount > 1 {
            let row = indexPath.row
            if row == 0 {
                position = .top
            } else if row == sectionCellCount - 1 {
                position = .bottom
            } else {
                position = .middle
            }
        } else {
            position = .topAndBottom
        }
        settingCell.refresh(
            itemInfo: appInfo,
            viewModel: appBadgeSettingViewModel,
            indexPath: indexPath,
            position: position
        ) { [weak self] in
            self?.showRequestFailPrompt(with: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_BadgeSettingFail)
        }
        return settingCell
    }

    // MARK: UICollectionViewDelegateFlowLayout
    /// 设置每个item大小
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.contentSize.width
        return CGSize(width: width, height: AppRankBadgeSettingCell.Config.cellHeight)
    }
}
