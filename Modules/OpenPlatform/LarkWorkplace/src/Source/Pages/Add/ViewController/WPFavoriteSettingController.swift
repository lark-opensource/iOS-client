//
//  CategoryPageViewController.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/6/18.
//

import EENavigator
import LarkUIKit
import RoundedHUD
import SwiftyJSON
import Swinject
import LKCommonsLogging
import LarkOPInterface
import UniverseDesignIcon
import UniverseDesignToast
import LarkContainer
import LarkNavigator
import LarkSetting
import LarkAccountInterface

/// 应用中心-常用应用设置页的Item配置
enum AppCategoryVCConst {
    static let createCellH: CGFloat = 76
    static let cellIdentify: String = "ContentCellIdentify"
    static let searchFieldHeight: CGFloat = 32
    static let mostUsedAppBarHeight: CGFloat = 56
    static let interSpaceHeight: CGFloat = 8
    static let allAppHeaderHeight: CGFloat = 70
}

/// 应用中心-常用应用设置页
final class WPFavoriteSettingController: BaseUIViewController,
                                       UITableViewDataSource,
                                       UITableViewDelegate,
                                       AppCenterAllAppHeaderViewProtocol,
                                       AppCenterHomeCategroyProtocol {
    static let logger = Logger.log(WPFavoriteSettingController.self)

    private let userId: String
    private let navigator: UserNavigator
    /// 是否展示常用应用栏
    private let showMostUsedBar: Bool
    private let dataManager: AppCenterDataManager
    private let openService: WorkplaceOpenService
    private let configService: WPConfigService
    private let userService: PassportUserService

    @available(*, deprecated, message: "be compatible for monitor")
    var tenantId: String {
        return userService.userTenant.tenantID
    }

    /// view model
    private lazy var viewModel: AppCategoryViewModel = {
        let model = AppCategoryViewModel(dataManager: dataManager)
        /// 整个页面数据更新时的回调
        model.dataUpdateBlock = { [weak self] (model) in
            guard let `self` = self else {
                Self.logger.error("Category VC missed, data update event exit")
                return
            }
            DispatchQueue.main.async {
                self.handleDataUpdate(model: model)
                /// 更新常用应用列表
                self.updateCommonAppBar()
            }
        }
        /// 分类页面cell按钮事件
        model.cellButtonClickEvent = { [weak self] (model) in
            Self.logger.info("cell button click to \(model.state)")
            if model.state == .add {
                self?.addCommonApp(model: model)
                WPEventReport(
                    name: WPEvent.appcenter_addapp.rawValue,
                    userId: self?.userId,
                    tenantId: self?.tenantId
                )
                    .set(key: "item_id", value: model.item.itemId)
                    .post()
            } else if model.state == .alreadyAdd {
                self?.removeCommonApp(model: model)
                WPEventReport(
                    name: WPEvent.appcenter_deleteapp.rawValue,
                    userId: self?.userId,
                    tenantId: self?.tenantId
                )
                    .set(key: "item_id", value: model.item.itemId)
                    .post()
            } else if model.state == .get {
                self?.installApp(model: model)
            }
        }
        return model
    }()
    /// Main Frame
    private lazy var mainFrameTable: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.separatorColor = .clear
        table.separatorStyle = .none
        table.backgroundColor = UIColor.ud.bgBody
        return table
    }()

    private lazy var stateView = WPPageStateView()

    /// header部分容器
    private lazy var mainTableHeader: UIView = {
        let headerContainer = UIView()
        headerContainer.backgroundColor = UIColor.ud.bgBase
        return headerContainer
    }()

    /// 常用应用栏
    private lazy var mostUsedBar: MostUsedAppBar = {
        let bar = MostUsedAppBar(frame: .zero)
        bar.settingClick = { [weak self] in
            self?.mostUsedBarSettingClick()
        }
        return bar
    }()
    private lazy var appCategoryHeaderWrapper: UIView = {
        let vi = UIView()
        vi.backgroundColor = UIColor.ud.bgBody
        return vi
    }()
    /// 分类选择器
    private lazy var appCategoryHeader: AppCenterAllAppHeaderView = {
        let appAppHeader = AppCenterAllAppHeaderView()
        appAppHeader.delegate = self
        return appAppHeader
    }()
    /// 分类页面
    private lazy var appListPage: WPAppListView = {
        Self.logger.debug("appListPage initial size", additionalData: [
            "width": "\(mainFrameTable.bdp_width)",
            "height": "\(mainFrameTable.bdp_height - heightForMainHeader())"
        ])
        let rect = CGRect(
            x: 0,
            y: 0,
            width: mainFrameTable.bdp_width,
            height: mainFrameTable.bdp_height - heightForMainHeader()
        )
        let listPage = WPAppListView(frame: rect)
        listPage.viewModel = self.viewModel
        return listPage
    }()

    /// 蒙层（能盖住Tab）
    private lazy var maskView: UIView = {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.ud.bgMask
        view.isUserInteractionEnabled = true
        let ges = UITapGestureRecognizer(target: self, action: #selector(removeMask))
        view.addGestureRecognizer(ges)
        return view
    }()

    /// 分类筛选页面VC
    private weak var categoryPageViewController: AppCenterHomeCategroyViewController?

    /// 操作成功的回调事件
    var actionCallbackToHomePage: (() -> Void)?

    /// 数据model
    // MARK: VC初始化
    init(
        userId: String,
        navigator: UserNavigator,
        showCommonBar: Bool,
        dataManager: AppCenterDataManager,
        openService: WorkplaceOpenService,
        configService: WPConfigService,
        userService: PassportUserService,
        actionCallbackToHomePage: (() -> Void)?
    ) {
        self.userId = userId
        self.navigator = navigator
        self.showMostUsedBar = showCommonBar
        self.dataManager = dataManager
        self.openService = openService
        self.configService = configService
        self.userService = userService
        self.actionCallbackToHomePage = actionCallbackToHomePage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        startLoadData()
    }

    private func setupViews() {
        title = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AddAppTtl
        addCloseItem()
        setRightItem()
        view.backgroundColor = UIColor.ud.bgBody
        /// 所有的元素都在container中（根视图）
        view.addSubview(containerView)
        view.addSubview(stateView)
        /// 第一层是table（只有一个section，该section只有一个cell，cell是分类页面（appListPage））
        containerView.addSubview(mainFrameTable)
        /// 配置table header
        if showMostUsedBar {
            mainTableHeader.addSubview(mostUsedBar)
        }
        mainTableHeader.addSubview(appCategoryHeaderWrapper)
        appCategoryHeaderWrapper.addSubview(appCategoryHeader)

        layoutMainFrame()

        mainFrameTable.reloadData()
    }

    /// layout main frame
    private func layoutMainFrame() {
        containerView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        stateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        /// 限定table的布局框架
        mainFrameTable.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
        /// mostUsedBar
        if showMostUsedBar {
            mostUsedBar.snp.makeConstraints { (make) in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(AppCategoryVCConst.mostUsedAppBarHeight)
            }
        }
        let appCategoryHeaderTopInset = showMostUsedBar ?
            AppCategoryVCConst.interSpaceHeight + AppCategoryVCConst.mostUsedAppBarHeight : 0.0

        appCategoryHeaderWrapper.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(appCategoryHeaderTopInset)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(appCategoryHeader)
        }
        /// all App category
        appCategoryHeader.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(AppCategoryVCConst.allAppHeaderHeight)
        }
    }

    // 适配iPad分/转屏
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let isCategoryClosed = tryCloseCategoryPage(animated: false)
        coordinator.animate(alongsideTransition: nil, completion: { [weak self](_) in
            self?.updateCommonAppBar()  // 更新常用应用列表
            self?.appListPage.refreshPageLayout()   // 刷新分类列表视图（第一个选项有问题）
            if isCategoryClosed, let targetButton = self?.appCategoryHeader.getCategoryButton() {   // 刷新筛选页面
                self?.didSelectCategoryButton(sender: targetButton)
            }
        })
    }

    /// 关闭逻辑
    override func closeBtnTapped() {
        // ipad下，如果是唯一一个VC，则展示Default来关闭VC
        if Display.pad, navigationController?.viewControllers.first == self {
            navigator.showDetail(DefaultDetailController(), from: self)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: Right Button
    @discardableResult
    func setRightItem() -> UIBarButtonItem {
        let image = UDIcon.searchOutlineOutlined.ud.withTintColor(UIColor.ud.iconN1)
        let barItem = LKBarButtonItem(image: image, title: nil)
        barItem.button.addTarget(self, action: #selector(searchClick), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = barItem
        return barItem
    }

    // MARK: Handle Data Update
    private func startLoadData() {
        viewModel.state = .loading
        handleDataUpdate(model: viewModel)
        viewModel.loadRemoteData()
    }

    private func handleDataUpdate(model: AppCategoryViewModel) {
        if model.state == .loading {
            loadingPlaceholderView.isHidden = false
            stateView.state = .hidden
        } else if model.state == .failed {
            loadingPlaceholderView.isHidden = true
            stateView.state = .loadFail(
                .create { [weak self] in
                    self?.startLoadData()
                }
            )
        } else {
            loadingPlaceholderView.isHidden = true
            stateView.state = .hidden
            updateCommonAppBar()
            updateCategoryInfo()
            appListPage.reloadPageList()
            WPMonitor().setCode(WPMCode.workplace_addapp_page_render_success).postSuccessMonitor()
        }
    }

    /// update common app list
    private func updateCommonAppBar() {
        // 触发常用应用栏左侧文案的更新(前提条件：信任后端数据更新成功）
        mostUsedBar.itemList = viewModel.commonAppList ?? []
    }

    /// update Data
    private func updateCategoryInfo() {
        appCategoryHeader.updateHeaderView(with: self.viewModel.categoryNameList)
        if let index = viewModel.selectedIndex, index != appCategoryHeader.selectIndexPath.row {
            appCategoryHeader.scrollToIndexPath(indexPath: IndexPath(row: index, section: 0))
        }
    }

    /// 设置按钮的点击事件，进入「应用排序页面」
    private func mostUsedBarSettingClick() {
        Self.logger.info("user tap setting, navigate to rankPage")
        let badgeEnabled = configService.fgValue(for: .badgeOn)
        let body = WorkplaceSettingBody(showBadge: badgeEnabled, commonItemsUpdate: { [weak self] in
            guard let `self` = self else { return }
            self.viewModel.fetchCommonList()
            self.actionCallbackToHomePage?()
        })
        navigator.push(body: body, from: self)
        WPEventReport(
            name: WPEvent.appcenter_click_settings.rawValue,
            userId: userId,
            tenantId: tenantId
        ).post()
    }

    @objc
    private func searchClick() {
        Self.logger.info("search click")
        let body = AppSearchBody(viewModel: viewModel)
        navigator.push(body: body, from: self)
    }

    /// 整个页面的根视图
    private lazy var containerView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.clear
        return view
    }()
    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: WPAppListCell.cellIdentify) as? WPAppListCell {
            cell.setAppListView(applistView: appListPage)
            return cell
        }
        let cell = WPAppListCell(style: .default, reuseIdentifier: WPAppListCell.cellIdentify)
        cell.setAppListView(applistView: appListPage)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return mainTableHeader
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return heightForMainHeader()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.bdp_height - heightForMainHeader()
    }

    private func heightForMainHeader() -> CGFloat {
        if showMostUsedBar {
            return AppCategoryVCConst.mostUsedAppBarHeight +
            AppCategoryVCConst.allAppHeaderHeight + AppCategoryVCConst.interSpaceHeight
        } else {
            return AppCategoryVCConst.allAppHeaderHeight
        }
    }
    // MARK: - AppCenterAllAppHeaderViewProtocol, AppCenterHomeCategroyProtocol

    /// 刷新筛选页面
    private func tryCloseCategoryPage(animated: Bool) -> Bool {
        Self.logger.info("try close category vc", additionalData: [
            "hasVC": "\(categoryPageViewController != nil)"
        ])
        guard let pageView = self.categoryPageViewController else { return false }
        pageView.closeCategory(animated: animated)
        return true
    }

    /// 添加蒙层
    private func addMask() {
        guard let navView = self.navigationController?.view else {
            return
        }
        navView.addSubview(maskView)
        maskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        maskView.setNeedsUpdateConstraints()
    }

    /// 移除蒙层
    @objc
    private func removeMask() {
        maskView.removeFromSuperview()
    }
    /// 点击分类筛选按钮
    func didSelectCategoryButton(sender: UIButton) {
        let nameArray = viewModel.categoryNameList
        let isPopMode: Bool = Display.pad && isWPWindowRegularSize()
        let categoryPageViewController = AppCenterHomeCategroyViewController(
            with: nameArray,
            selectIndex: appCategoryHeader.selectIndexPath.row,
            isPopMode: isPopMode
        )
        categoryPageViewController.delegate = self
        if isPopMode {
            categoryPageViewController.preferredContentSize = AppCenterHomeCategroyViewController.getPopSize(
                itemCount: nameArray.count
            )
            let sourceRect = sender.convert(sender.bounds, to: view)
            categoryPageViewController.modalPresentationStyle = .popover
            categoryPageViewController.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
            categoryPageViewController.popoverPresentationController?.sourceView = view
            categoryPageViewController.popoverPresentationController?.sourceRect = sourceRect.insetBy(dx: -8, dy: 0)
            categoryPageViewController.popoverPresentationController?.permittedArrowDirections = .right
        } else {
            addMask()
        }
        self.categoryPageViewController = categoryPageViewController
        present(categoryPageViewController, animated: true)
    }
    /// 点击分类选项
    private func didSelectCategory(categoryIndex: Int) {
        viewModel.switchToPageIndex(index: categoryIndex)
        if let page = viewModel.findPageForTag(tagId: categoryIndex) {
            viewModel.fetchCategoryList(tag: page.tag)
            removeMask()
        }
    }

    /// 点击横向滑动列表的cell
    /// - Parameter indexPath: 位置
    func didSelectHorizontalLabelCell(headerView: AppCenterAllAppHeaderView, at indexPath: IndexPath) {
        didSelectCategory(categoryIndex: indexPath.row)
    }

    /// 点击了分类cell
    /// - Parameter indexPath: 位置
    func didSelectAppCenterHomeCategroyCollectionViewCell(
        categoryVC: AppCenterHomeCategroyViewController,
        at indexPath: IndexPath,
        for group: Int
    ) {
        didSelectCategory(categoryIndex: indexPath.row)
        appCategoryHeader.scrollToIndexPath(indexPath: indexPath)
        removeMask()
    }

    /// 点击了空白区域 关闭分类页
    func justCloseAppCenterHomeCategroyViewController(
        categoryVC: AppCenterHomeCategroyViewController,
        for group: Int
    ) {
        removeMask()
    }

    /// 安装应用（是指应用未安装，需要到AppStore中进行安装）
    func installApp(model: WPCategoryItemViewModel) {
        guard let appLink = model.item.appStoreRedirectURL else {
            Self.logger.error("app \(model.item.itemId) \(model.item.name)appLink is empty, install App exit")
            return
        }
        openService.openAppLink(appLink, from: self)
    }

    /// 添加应用为常用应用
    func addCommonApp(model: WPCategoryItemViewModel) {
        Self.logger.info("add common app \(model.item.name)")
        model.state = .addLoading
        dataManager.addCommonApp(
            itemIds: [model.item.itemId],
            success: { [weak self] in
                Self.logger.info("add common app sucessed \(model.item.name)")
                model.state = .alreadyAdd
                guard let `self` = self else {
                    Self.logger.error("Category ViewModel released, append common to commonAppList failed")
                    return
                }
                UDToast.showSuccess(with: BundleI18n.LarkWorkplace.OpenPlatform_Common_AddSuccess, on: self.view)
                /// 更新commonAppList能触发setter
                self.viewModel.commonAppList?.append(model)
                /// 通知到主页，常用应用变化了（只是一个临时通讯管道）
                self.actionCallbackToHomePage?()
            },
            failure: { [weak self] (error) in
                guard let hudview = self?.view else {
                    return
                }
                Self.logger.error("add common app \(model.item.name) failed", error: error)
                model.state = .add
                UDToast.showSuccess(with: BundleI18n.LarkWorkplace.OpenPlatform_Share_NetworkErrMsg, on: hudview)
            }
        )
    }

    /// 移除常用应用
    func removeCommonApp(model: WPCategoryItemViewModel) {
        model.state = .removeLoading
        dataManager.removeCommonApp(
            itemId: model.item.itemId,
            success: { [weak self] in
                Self.logger.info("remove common app sucessed \(model.item.name)")
                model.state = .add
                guard let `self` = self else {
                    Self.logger.error("Category ViewModel released, remove common from commonAppList failed")
                    return
                }
                UDToast.showSuccess(
                    with: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_DeleteSuccess,
                    on: self.view
                )
                if let index = self.viewModel.commonAppList?.firstIndex(of: model) {
                    /// 更新commonAppList能触发setter
                    self.viewModel.commonAppList?.remove(at: index)
                } else {
                    Self.logger.warn(
                        "No item(\(model.item.itemId)) \(model.item.name) found in viewModel's appList"
                    )
                }
                /// 通知到主页，常用应用变化了（只是一个临时通讯管道）
                self.actionCallbackToHomePage?()
            },
            failure: { [weak self] (error) in
                guard let hudview = self?.view else {
                    return
                }
                Self.logger.error("remove common app \(model.item.name) failed", error: error)
                model.state = .alreadyAdd
                UDToast.showSuccess(with: BundleI18n.LarkWorkplace.OpenPlatform_Share_NetworkErrMsg, on: hudview)
            }
        )
    }
}
