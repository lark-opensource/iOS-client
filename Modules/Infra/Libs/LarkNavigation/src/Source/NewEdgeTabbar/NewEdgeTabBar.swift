//
//  NewEdgeTabBar.swift
//  LarkNavigation
//
//  Created by Yaoguoguo on 2023/6/21.
//

import Foundation
import AnimatedTabBar
import SnapKit
import LarkSetting
import LarkBadge
import LarkContainer
import LarkTab
import LKCommonsLogging
import LarkInteraction
import LarkSwipeCellKit
import RustPB
import UniverseDesignToast
import UniverseDesignIcon
import UIKit
import UniverseDesignColor
import UniverseDesignShadow
import UniverseDesignDialog
import LarkQuickLaunchInterface

final class NewEdgeTabBar: UIView, EdgeTabBarProtocol, UserResolverWrapper {

    //imtoken-bg-Aurora-Horizon
    static let bgColor = UDColor.rgb(0xecedee) & UDColor.rgb(0x0c0c0c)

    public let userResolver: UserResolver

    static let logger = Logger.log(NewEdgeTabBar.self, category: "LarkNavigation.NewEdgeTabBar")
    static let clearTemporaryDelay: TimeInterval = 3.2

    weak var delegate: EdgeTabBarDelegate?
    weak var refreshEdgeBarDelegate: EdgeTabBarRefreshDelegate?

    /// 一键清空临时区功能FG
    private lazy var clearTemporaryTabsFG = userResolver.fg.staticFeatureGatingValue(with: "lark.navigation.clear_tabs")
    // 兜底关闭刷新临时区数据优化FG
    var reloadTemporaryTabsOptimizeCloseFG: Bool {
        let optimizeFG = userResolver.fg.dynamicFeatureGatingValue(with: "lark.navigation.reload.temporary_tabs.optimize")
        Self.logger.info("reload temporary tabs optimize closeFG: \(optimizeFG)")
        return optimizeFG
    }

    private let queue = OperationQueue.main

    static let token = "LARK-PSDA-edgeTabBar_copyURL"
    @ScopedInjectedLazy var temporaryTabService: TemporaryTabService?
    

    var tabbarWidth: CGFloat {
        switch tabbarLayoutStyle {
        case .vertical:
            return 76
        case .horizontal:
            return 240
        }
    }

    var tabbarLayoutStyle: EdgeTabBarLayoutStyle = .vertical {
        didSet {
            Self.logger.info("Set Tabbar Layout Style :\(tabbarLayoutStyle)")
            self.infoView.tabbarLayoutStyle = tabbarLayoutStyle
            self.headerView.tabbarLayoutStyle = tabbarLayoutStyle
            self.moreCell.tabbarLayoutStyle = tabbarLayoutStyle
            self.pinView.tabbarLayoutStyle = tabbarLayoutStyle
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            if #available(iOS 13, *) {
                // 宽窄变化时，more 位置有可能发生变化，可能会超出屏幕
                self.dismissPopoverIfMoreInvisible()
            } else {
                // 13 以下系统 popover 无法动态跟随 sourceView，在宽度改变时 dismiss popover
                dismissPopoverIfNeeded(animated: true)
            }
        }
    }

    enum Position: Equatable {
        case main(index: Int)
        case hidden(index: Int)
        case temporary(index: Int)
    }

    // MARK: Items

    // 外部设置好数据层之后，会通过 `divideItems` 将 items 分给显示层

    // 数据层

    var mainTabItems: [AbstractTabBarItem] = [] {
        didSet {
            let ids = self.mainTabItems.map {
                return $0.tab.key
            }

            Self.logger.info("Set Main TabItems ids: \(ids)")
            needsUpdateItemViews = true
            isContainsNonTemporaryDataUpdate = true
            setNeedsLayout()
        }
    }

    /// 数据层的隐藏导航 items，不会立即在 UI 上生效，需要 layoutIfNeeded 来生效
    var hiddenTabItems: [AbstractTabBarItem] = [] {
        didSet {
            let ids = self.hiddenTabItems.map {
                return $0.tab.key
            }

            Self.logger.info("Set Hidden TabItems ids: \(ids)")
            needsUpdateItemViews = true
            isContainsNonTemporaryDataUpdate = true
            setNeedsLayout()
        }
    }

    var temporaryTabItems: [AbstractTabBarItem] = [] {
        didSet {
            let ids = self.temporaryTabItems.map {
                return $0.tab.key
            }
            Self.logger.info("Set Temporary TabItems ids: \(ids)")
            //如果已经有非临时区数据刷新了，则直接全局刷新，不单独对临时区进行刷新
            if !reloadTemporaryTabsOptimizeCloseFG, !needsUpdateItemViews {
                Self.logger.info("Set Temporary NeedsUpdate Temporary Items")
                needsUpdateTemporaryItemViews = true
            }
            needsUpdateItemViews = true
            setNeedsLayout()
        }
    }

    // 显示层
    var moreItem: AbstractTabBarItem? {
        didSet {
            let key: String = moreItem?.tab.key ?? ""
            Self.logger.info("Set More TabItems id: \(key)")
            moreCell.moreItem = moreItem
            updateItemViewsIfNeeded()
        }
    }
    

    var refreshTabItem: UIView? {
        return self.headerView.refreshTabItem
    }

    var showRefreshTabIcon: Bool = false {
        didSet {
            Self.logger.info("Set showRefreshTabIcon: \(showRefreshTabIcon)")
            needsUpdateItemViews = true
            isContainsNonTemporaryDataUpdate = true
            updateItemViewsIfNeeded()
        }
    }

    var pagekeeperService: PageKeeperService?

    // MARK: Views
    private var infoView: EdgeTabBarInfoView = EdgeTabBarInfoView()

    private lazy var headerView: EdgeTabBarTableViewHeaderView = EdgeTabBarTableViewHeaderView(frame: .zero, showClearTemporaryTabs: self.clearTemporaryTabsFG)

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.alwaysBounceHorizontal = false
        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.clipsToBounds = false
        tableView.layer.masksToBounds = false
        tableView.lu.register(cellWithClass: EdgeTabBarTableViewCell.self)
        tableView.lu.register(cellWithClass: EdgeTabBarTableViewMoreCell.self)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -8)
        return tableView
    }()

    private var lastOffsetY: CGFloat = 0
    private let temporaryTabSection: Int = 1
    
    /// 暂时关闭标记
    private var forTheMomentCloseTemporary: Bool = false

    lazy var pinView: HeaderPinView = HeaderPinView()

    private var contaionerView = UIView()

    private var moreCell = EdgeTabBarTableViewMoreCell() {
        didSet {
            // 解决重用时，Popover source view 指向不准确的问题
            popover?.popoverPresentationController?.sourceView = moreCell
        }
    }

    func tabWindowRect(for index: Int) -> CGRect? {
        guard  0..<self.mainTabItems.count ~= index else { return nil }
        if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
            return cell.convert(cell.bounds, to: nil)
        }
        return nil
    }

    private(set) weak var popover: NewEdgeTabBarPopover?

    private lazy var navigationDependency: NavigationDependency? = {
        return try? self.userResolver.resolve(assert: NavigationDependency.self)
    }()

    // MARK: Attributes

    private var lastHeight: CGFloat = -1

    private var needsUpdateItemViews: Bool = false
    // 刷新临时区数据
    private var needsUpdateTemporaryItemViews: Bool = false
    // 记录是否包含非临时区数据更新，如果同时有其他区域数据更新直接刷新全局，避免更新问题
    private var isContainsNonTemporaryDataUpdate: Bool = false

    private var selectedIndexPath: IndexPath?

    private let bgTapRecognizer = UITapGestureRecognizer()

    // MARK: Drag & Drop Reorder

    @InjectedLazy var navigationConfigService: NavigationConfigService

    /// TabKey: AppInfo 这个一定要是计算属性，不能懒加载，每次访问的时候从Service里面取最新的值，不然如果遇到导航有更新就会有数据不同步的问题
    var tabInfo: [String: Basic_V1_NavigationAppInfo] {
        // CRMode数据统一GA后删除重复代码
        let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
        if !crmodeDisable {
            if let iPad = navigationConfigService.originalAllTabsinfo?.iPad {
                let infos = iPad.main + iPad.quick
                return infos.reduce([:], { (result, info) -> [String: Basic_V1_NavigationAppInfo] in
                    var result = result
                    result[info.key] = info
                    return result
                })
            } else {
                return [:]
            }
        } else {
            if let edge = navigationConfigService.originalAllTabsinfo?.edge {
                let infos = edge.main + edge.quick
                return infos.reduce([:], { (result, info) -> [String: Basic_V1_NavigationAppInfo] in
                    var result = result
                    result[info.key] = info
                    return result
                })
            } else {
                return [:]
            }
        }
    }

    let maxAreaTempItemCount: Int = 200
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.pagekeeperService = try? userResolver.resolve(type: PageKeeperService.self)
        super.init(frame: .zero)
        self.setupCollectionView()

        self.backgroundColor = NewEdgeTabBar.bgColor
        self.clipsToBounds = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(dismissPopoverImmediately),
            name: AnimatedTabBarController.styleChangeNotification, object: nil
        )
        self.lastOffsetY = self.tableView.contentOffset.y
        setupQueue()

        self.layer.ud.setShadow(type: UDShadowType.s4Left)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Self.logger.info("NewEdgeTabBar deinit")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if lastHeight != bounds.height || needsUpdateItemViews {
            lastHeight = bounds.height
            updateItemViewsIfNeeded()
            // 需要禁用动画并立即布局，避免图标的缩放效果
            UIView.performWithoutAnimation {
                layoutIfNeeded()
            }
            dismissPopoverIfMoreInvisible()
        }
    }

    func setupCollectionView() {
        self.addSubview(infoView)
        infoView.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        self.addSubview(self.contaionerView)
        self.contaionerView.clipsToBounds = true
        self.contaionerView.layer.masksToBounds = true
        contaionerView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.top.equalTo(infoView.snp.bottom).offset(16)
        }

        self.addSubview(pinView)
        pinView.snp.makeConstraints { (maker) in
            maker.top.equalTo(infoView.snp.bottom).offset(16)
            maker.left.equalToSuperview().offset(8)
            maker.right.equalToSuperview().offset(-8)
        }

        pinView.didSelectCallback = { [weak self] (item) in
            guard let self = self else { return }
            self.delegate?.edgeTabBar(self, didSelectItem: item)
            self.popover?.dismiss(animated: true, completion: nil)
        }

        contaionerView.addSubview(self.tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(8)
            maker.right.equalToSuperview().offset(-8)
            maker.bottom.equalToSuperview()
            maker.top.equalToSuperview()
        }

        bgTapRecognizer.addTarget(self, action: #selector(dismissPopover))
        bgTapRecognizer.delegate = self
        tableView.addGestureRecognizer(bgTapRecognizer)

        headerView.tabbarLayoutStyle = self.tabbarLayoutStyle
        headerView.refreshCallBack = { [weak self] in
            guard let self else { return }
            // 如果正在展示 Popover，需要先 Dismiss 才能正常展示 ActionSheet 菜单
            self.dismissPopoverIfNeeded(animated: true, completion: { [weak self] in
                guard let self else { return }
                self.refreshEdgeBarDelegate?.edgeTabBarRefreshItemDidClick(self)
            })
        }
        headerView.closeTagCallBack = { [weak self] in
            guard let self, let window = self.userResolver.navigator.mainSceneWindow else { return }
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkNavigation.Lark_Navbar_CloseAllTabsBelow_Popup_Title)
            dialog.addCancelButton()
            dialog.addPrimaryButton(text: BundleI18n.LarkNavigation.Lark_Navbar_CloseAllTabsBelow_PopupClose_Button, dismissCompletion: {
                self.closeAllTemporaryTab()
                NavigationTracker.closeTemporary(by: false)
            })
            self.userResolver.navigator.present(dialog, from: window)
        }
        moreCell.moreItem = self.moreItem
        moreCell.tabbarLayoutStyle = self.tabbarLayoutStyle
    }

    private func closeAllTemporaryTab() {
        closeTemporary(by: true)
        self.tableView.reloadData()
        self.tableView.layoutIfNeeded()
        var tabKeys = temporaryTabItems.map { $0.tab.key }
        var tabIds = temporaryTabItems.map { $0.tab.appid }
        guard let window = self.userResolver.navigator.mainSceneWindow else { return }
        let promptText = BundleI18n.LarkNavigation.Lark_Navbar_NumTabsClosed_Toast(temporaryTabItems.count)
        UDToast.showSuccess(with: promptText, operationText: BundleI18n.LarkNavigation.Lark_Navbar_NumTabsClosed_Undo_Button, on: window) { _ in
            // 撤销不做删除
            Self.logger.info("revocation close all temporary tabKeys:\(tabKeys.count)")
            tabKeys = []
            self.closeTemporary(by: false)
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            NavigationTracker.closeTemporary(by: true)
        } dismissCallBack: {
            Self.logger.info("close all temporary dismiss call back")
            self.closeTemporary(by: false)
            guard !tabKeys.isEmpty else { return }
            self.temporaryTabItems.removeAll()
            self.temporaryTabService?.removeTab(ids: tabKeys)
            self.removeKeepPages(tabIds)
        }
        //补充兜底，UDToast存在没有dismissCallBack的情况，已跟UD组件反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.clearTemporaryDelay) { [weak self] in
            guard let self = self else { return }
            Self.logger.info("close all temporary asyncAfter tabKeys count: \(tabKeys.count)")
            self.closeTemporary(by: false)
            guard !tabKeys.isEmpty else { return }
            self.temporaryTabItems.removeAll()
            self.temporaryTabService?.removeTab(ids: tabKeys)
            self.removeKeepPages(tabIds)
        }
    }

    func removeKeepPages(_ tabIds: [String?]) {
        for tabId in tabIds {
            if let tId = tabId {
               _ = self.pagekeeperService?.popCachePage(id: tId, scene: "PageKeeperScene.temporary")
            }
        }
    }

    func closeTemporary(by forTheMoment: Bool) {
        Self.logger.info("close temporary forTheMoment:\(forTheMoment)")
        self.forTheMomentCloseTemporary = forTheMoment
    }

    private func updateItemViewsIfNeeded() {
        guard needsUpdateItemViews else { return }
        // Create Main Tab Views
        self.infoView.tabbarLayoutStyle = self.tabbarLayoutStyle
        self.headerView.tabbarLayoutStyle = self.tabbarLayoutStyle
        self.moreCell.tabbarLayoutStyle = self.tabbarLayoutStyle
        if needsUpdateTemporaryItemViews, !temporaryTabItems.isEmpty, !isContainsNonTemporaryDataUpdate {
            // 只需要刷新临时区,避免刷临时区数据时导致mainTab数据刷新的闪动
            UIView.performWithoutAnimation {
                self.tableView.beginUpdates()
                self.tableView.reloadSections(IndexSet(integer: temporaryTabSection), with: .automatic)
                self.tableView.endUpdates()
            }
        } else {
            self.tableView.reloadData()
        }
        self.popover?.reloadDataAndViews()
        self.delegate?.edgeTabBarMoreItemsDidChange(self, moreItems: self.hiddenTabItems)
        self.needsUpdateItemViews = false
        self.needsUpdateTemporaryItemViews = false
        self.isContainsNonTemporaryDataUpdate = false
    }

    func refreshTabbarCustomView() {
        self.tableView.visibleCells.forEach { cell in
            guard let cell = cell as? EdgeTabBarTableViewCell else { return }
            cell.refreshCustomView()
        }
    }

    func addAvatar(_ container: UIView) {
        Self.logger.info("Set Avatar")
        self.infoView.addAvatar(container)
    }

    func addFocus(_ container: UIView) {
        Self.logger.info("Set Focus")
        self.infoView.addFocus(container)
    }

    func addSearchEntrenceOnPad() {
        Self.logger.info("Set Search Entrance For Pad")
        guard let navigationDependency = navigationDependency, navigationDependency.enableUseNewSearchEntranceOnPad() else { return }
        let searchEntranceView = navigationDependency.getSearchOnPadEntranceView()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(searchEntranceForPadTapped(_:)))
        searchEntranceView.addGestureRecognizer(gesture)
        self.infoView.addSearchEntrenceOnPad(searchEntranceView)
    }

    func removeSearchEntrenceOnPad() {
        guard let navigationDependency = navigationDependency, navigationDependency.enableUseNewSearchEntranceOnPad() else { return }
        self.infoView.removeSearchEntrenceOnPad()
    }

    @objc func searchEntranceForPadTapped(_ gesture: UITapGestureRecognizer) {
        guard let navigationDependency = navigationDependency, navigationDependency.enableUseNewSearchEntranceOnPad() else { return }
        self.delegate?.searchItemTapped()
    }

    func removeFocus() {
        Self.logger.info("Remove Focus")
        self.infoView.removeFocus()
    }

    func setupQueue() {
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
    }

    /// index: start from 0
    func switchMainTab(to index: Int) {
        Self.logger.info("Switch Main Tab index: \(index)")

        if (0..<mainTabItems.count).contains(index) {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
            self.tableView(tableView, didSelectRowAt: indexPath)
        } else if mainTabItems.count == index {
            openMoreFromKeyCommand()
        }
    }

    // MARK: More & Popover

    func openMoreFromKeyCommand() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self else { return }
            self.tableView.scrollToRow(at: IndexPath(row: self.mainTabItems.count, section: 0),
                                       at: .bottom,
                                       animated: true)
        } completion: { [weak self] _ in
            self?.togglePopover()
        }
    }

    func togglePopover() {
        // 偶现的 Popover 已经消失了，但一直没有被释放，这里多判断下是否还在 Window 上
        if let popover, popover.view.window != nil {
            popover.dismiss(animated: true)
        } else {
            showPopover()
        }
    }

    func showPopover() {
        let vc = NewEdgeTabBarPopover(userResolver: self.userResolver)
        popover = vc
        vc.edgeTabBar = self
        // 防止 popover 找不到 sourceRect，等一个 runloop 执行
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            let sourceView = self.moreCell.moreView
            vc.view.backgroundColor = .clear
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.passthroughViews = [self.tableView]
            vc.popoverPresentationController?.backgroundColor = .clear
            vc.popoverPresentationController?.sourceView = sourceView
            if #unavailable(iOS 13) {
                // 13 以下不设置会导致位置异常
                // 以上设置了会导致 Popover 无法跟随 View 大小变化移动
                vc.popoverPresentationController?.sourceRect = sourceView.bounds
            }
            vc.popoverPresentationController?.permittedArrowDirections = [.left]
            self.nodeViewController?.present(vc, animated: true)
        }
    }

    @objc
    func dismissPopover() {
        popover?.dismiss(animated: true)
    }

    @objc
    private func dismissPopoverImmediately() {
        popover?.dismiss(animated: false)
    }

    private func dismissPopoverIfNeeded(animated: Bool, completion: (() -> Void)? = nil) {
        if let popover, popover.view.window != nil {
            popover.dismiss(animated: animated, completion: completion)
        } else {
            completion?()
        }
    }

    // More 滚出屏幕时关闭 Popover
    private func dismissPopoverIfMoreInvisible() {
        let morePath = IndexPath(row: mainTabItems.count, section: 0)
        let moreRect = tableView.rectForRow(at: morePath)
        if !tableView.bounds.intersects(moreRect) {
            dismissPopover()
        }
    }

    func selectedTab(_ tab: Tab) {
        guard !self.pinView.tabItems.contains(where: {
            $0.tab.key == tab.key
        }) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let position = self.findPosition(tab) else { return }
            var indexPath: IndexPath?
            switch position {
            case .main(index: let index):
                indexPath = IndexPath(row: index, section: 0)
            case .hidden(_):
                break
            case .temporary(index: let index):
                indexPath = IndexPath(row: index, section: 1)
            }

            guard let indexPath = indexPath,
                  self.tableView.numberOfRows(inSection: indexPath.section) > indexPath.row,
                  let first = self.tableView.indexPathsForVisibleRows?.first,
                  let last = self.tableView.indexPathsForVisibleRows?.last else { return }

            var newIndexPath = indexPath
            if indexPath <= first, let pre = self.indexPathOfCell(before: indexPath) {
                newIndexPath = pre
            } else if indexPath >= last, let next = self.indexPathOfCell(after: indexPath) {
                newIndexPath = next
            }

            if newIndexPath.section == (self.tableView.numberOfSections - 1),
                newIndexPath.row == (self.tableView.numberOfRows(inSection: newIndexPath.section) - 1) {
                self.tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
            } else {
                self.tableView.scrollToRow(at: newIndexPath, at: .none, animated: true)
            }
        }
    }

    private func indexPathOfCell(after indexPath: IndexPath) -> IndexPath? {
        var row = indexPath.row + 1
        for section in indexPath.section..<tableView.numberOfSections {
            if row < tableView.numberOfRows(inSection: section) {
                return IndexPath(row: row, section: section)
            }
            row = 0
        }
        return nil
    }

    private func indexPathOfCell(before indexPath: IndexPath) -> IndexPath? {
        var row = indexPath.row - 1
        for section in (0...indexPath.section).reversed() {
            if row >= 0 {
                return IndexPath(row: row, section: section)
            }
            if section > 0 {
                row = tableView.numberOfRows(inSection: section - 1) - 1
            }
        }
        return nil
    }

    private func findPosition(_ tab: Tab) -> Position? {
        var position: Position?
        mainTabItems.enumerated().forEach { (index, item) in
            if item.tab == tab {
                position = .main(index: index)
            }
        }

        hiddenTabItems.enumerated().forEach { (index, item) in
            if item.tab == tab {
                position = .hidden(index: index)
            }
        }

        temporaryTabItems.enumerated().forEach { (index, item) in
            if item.tab == tab {
                position = .temporary(index: index)
            }
        }
        return position
    }
}

extension NewEdgeTabBar {
    enum Cons {
        static let dragPreviewRadius: CGFloat = 11
        static var tabBarColor: UIColor {
            // UIColor.ud.bgFloatOverlay
            return makeDynamicColor(
                light: UIColor.ud.N100,
                dark: UIColor.ud.N200
            )
        }

        static var popoverColor: UIColor {
            // UIColor.ud.bgFloat
            return makeDynamicColor(
                light: UIColor.ud.N00,
                dark: UIColor.ud.N100
            )
        }

        static func makeDynamicColor(light: UIColor, dark: UIColor) -> UIColor {
            if #available(iOS 13.0, *) {
                return UIColor { trait -> UIColor in
                    switch trait.userInterfaceStyle {
                    case .dark: return dark.resolvedColor(with: trait)
                    default:    return light.resolvedColor(with: trait)
                    }
                }
            } else {
                return light
            }
        }
    }
}

// MARK: TableView

extension NewEdgeTabBar: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return mainTabItems.count + 1 // 「更多」按钮
        case temporaryTabSection:
            return self.forTheMomentCloseTemporary ? 0 : temporaryTabItems.count
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NewEdgeTabView.Layout.getHeightBy(self.tabbarLayoutStyle)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Self.logger.info("Select Row At indexPath: \(indexPath)")

        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0, indexPath.row == mainTabItems.count {
            togglePopover()
            return
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? EdgeTabBarTableViewCell,
              let item = cell.item else { return }
        self.delegate?.edgeTabBar(self, didSelectItem: item)
        self.popover?.dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case 0:
            if indexPath.row < mainTabItems.count {
                let tabCell = tableView.lu.dequeueReusableCell(withClass: EdgeTabBarTableViewCell.self, for: indexPath)
                tabCell.swipeView.backgroundColor = .clear
                tabCell.delegate = self
                tabCell.canclose = false
                tabCell.update(item: mainTabItems[indexPath.row], style: self.tabbarLayoutStyle)
                cell = tabCell
            } else if indexPath.row == mainTabItems.count { // 「更多」按钮
                moreCell = tableView.lu.dequeueReusableCell(withClass: EdgeTabBarTableViewMoreCell.self, for: indexPath)
                moreCell.moreItem = self.moreItem
                moreCell.tabbarLayoutStyle = self.tabbarLayoutStyle
                cell = moreCell
            } else {
                return EdgeTabBarTableViewCell()
            }
        case 1:
            guard indexPath.row < temporaryTabItems.count else { return EdgeTabBarTableViewCell() }
            let tabCell = tableView.lu.dequeueReusableCell(withClass: EdgeTabBarTableViewCell.self, for: indexPath)
            tabCell.closeCallback = { [weak self] (item) in
                guard let self = self,
                      let item = item,
                      indexPath.section == 1 else { return }
                self.delegate?.edgeTabBar(self, removeTemporaryItems: [item])
            }
            tabCell.canclose = true
            tabCell.delegate = self
            tabCell.swipeView.backgroundColor = .clear
            tabCell.update(item: temporaryTabItems[indexPath.row], style: self.tabbarLayoutStyle)
            cell = tabCell
        default:
            return EdgeTabBarTableViewCell()
        }
        cell.selectionStyle = .none
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        dismissPopoverIfMoreInvisible()
        guard self.tableView.frame.height < self.tableView.contentSize.height else {
            self.lastOffsetY = self.tableView.contentOffset.y
            pinView.update(progress: 0)
            return
        }

        if let index = self.tableView.indexPathsForVisibleRows?.first,
           let item = mainTabItems.enumerated().first(where: {
               $0.element.tab.key == Tab.feed.key
           }),
            index > IndexPath(row: item.offset, section: 0) {
            pinView.addTabItem(item.element)
            pinView.update(progress: 1)
        } else {
            for cell in self.tableView.visibleCells {
                /// 目前只固定消息，所以没有PB上的更改，暂时写死 conversation
                if let pinCell = cell as? EdgeTabBarTableViewCell, let item = pinCell.item, item.tab.key == Tab.feed.key {

                    if pinCell.frame.minY < self.tableView.contentOffset.y {

                        if pinView.tabItems.isEmpty {
                            NavigationTracker.pinTab(main: self.mainTabItems.count,
                                                     temporary: self.temporaryTabItems.count)
                        }
                        pinView.addTabItem(item)
                        pinView.update(progress: 1)
                    } else {
                        pinView.removeTabItem(item)
                    }
                }
            }
        }

        self.lastOffsetY = self.tableView.contentOffset.y
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        var position: Position?
        switch indexPath.section {
        case 0:
            position = .main(index: indexPath.row)
        case 1:
            position = .temporary(index: indexPath.row)
        default:
            break
        }

        var menu: [UIMenu] = []
        var titles: [[String]] = []

        if let newPosition = position {
            let actions = self.getActions(position: newPosition)
            titles = actions.map {
                return $0.map {
                    return $0.title
                }
            }
            menu = actions.map({
                return UIMenu(title: "", options: .displayInline, children: $0)
            })
        }
        let identifier = indexPath as NSCopying

        Self.logger.info("Get Context Menu identifier: \(identifier), actions: \(titles)")
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider: { _ in
            return UIMenu(title: "", children: menu)
        })
    }

    // 定制 ContextMenu Preview，不定制会有操作白屏的现象
    @available(iOS 13, *)
    func tableView(_ tableView: UITableView,
                   previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        targetPreview(for: tableView, with: configuration)
    }

    @available(iOS 13, *)
    func tableView(_ tableView: UITableView,
                   previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        // 这里返回 nil 是有可能用户选择固定/移除等会改变数据，导致 reloadData 的情况
        // 会导致 Context menu 关闭之后，Cell 发生重用，导致关闭动画的结束位置偏移问题
        // 这里暂时不定制关闭动画以回避问题
        nil
    }

    @available(iOS 13, *)
    func tableView(_ tableView: UITableView, willDisplayContextMenu configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        queue.isSuspended = true
    }

    @available(iOS 13, *)
    func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        queue.isSuspended = false
    }

    @available(iOS 13.0, *)
    private func targetPreview(for tableView: UITableView, with configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = tableView.cellForRow(at: indexPath) as? EdgeTabBarTableViewCell,
              tableView.window != nil else { return nil }
        cell.setHighlighted(false, animated: false)
        guard let copy = cell.swipeView.snapshotView(afterScreenUpdates: true) else {
            return nil
        }
        let parameter = UIPreviewParameters()
        parameter.visiblePath = UIBezierPath(roundedRect: cell.swipeView.bounds, cornerRadius: NewEdgeTabBar.Cons.dragPreviewRadius)
        return UITargetedPreview(view: copy, parameters: parameter,
                                 target: UIPreviewTarget(container: tableView, center: cell.center))
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0.1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else { return nil }
        headerView.tabbarLayoutStyle = self.tabbarLayoutStyle
        headerView.showRefreshTabIcon = self.showRefreshTabIcon
        if self.forTheMomentCloseTemporary {
            headerView.showBottomBorder = false
        } else {
            headerView.showBottomBorder = !self.temporaryTabItems.isEmpty
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 1 else { return 0.1 }
        return EdgeTabBarTableViewHeaderView.getHeight(self.tabbarLayoutStyle, showRefreshTabIcon: showRefreshTabIcon)
    }
}

// MARK: Swipe

extension NewEdgeTabBar: SwipeTableViewCellDelegate {

    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) {
        guard let cell = tableView.cellForRow(at: indexPath) as? EdgeTabBarTableViewCell,
              !(cell.item?.isSelected ?? true)  else { return }
        Self.logger.info("Will Begin Editing Row At indexPath: \(indexPath)")

        cell.swipeView.backgroundColor = UIColor.ud.fillHover
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?, for orientation: SwipeActionsOrientation) {
        guard let indexPath = indexPath,
              let cell = tableView.cellForRow(at: indexPath) as? EdgeTabBarTableViewCell,
              !(cell.item?.isSelected ?? false)  else { return }
        Self.logger.info("Did End Editing Row At indexPath: \(indexPath)")

        cell.swipeView.backgroundColor = .clear
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {

        guard orientation == .left,
              self.tabbarLayoutStyle == .horizontal,
              indexPath.section == 1 else { return nil }

        var item: AbstractTabBarItem?
        switch indexPath.section {
        case 0:
            item = self.mainTabItems[indexPath.row]
        case 1:
            item = self.temporaryTabItems[indexPath.row]
        default:
            break
        }

        let deleteAction = SwipeAction(style: .default, title: BundleI18n.LarkNavigation.Lark_Core_NaviTab_Close_Button) { [weak self] _, _, _ in
            guard let `self` = self, let newItem = item, indexPath.row < self.temporaryTabItems.count else { return }
            self.temporaryTabItems.remove(at: indexPath.row)
            Self.logger.info("SwipeAction Remove Item: \(newItem.tab.key)")
            self.delegate?.edgeTabBar(self, removeTemporaryItems: [newItem])
        }
        deleteAction.backgroundColor = UIColor.ud.functionDanger500
        deleteAction.hidesWhenSelected = true
        deleteAction.textAlignment = .left
        deleteAction.font = UIFont.ud.body1

        return [deleteAction]
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()

        let overscroll: CGFloat = 150
        let style = SwipeExpansionStyle(target: .edgeInset(120),
            additionalTriggers: [.overscroll(overscroll)],
            elasticOverscroll: true,
            completionAnimation: .fill(.manual(timing: .after)))

        options.expansionStyle = style
        options.transitionStyle = .reveal

        let tabbarLayoutStyle = self.tabbarLayoutStyle
        let cell = tableView.cellForRow(at: indexPath)
        options.shouldBegin = { (x, y) in
            guard indexPath.section == 1 else { return false }
            if orientation == .right || tabbarLayoutStyle == .vertical {
                return false
            }
            if orientation == .left,
               tabbarLayoutStyle == .horizontal,
               let cell = cell as? EdgeTabBarTableViewCell,
                !(cell.item?.tab.isCustomType() ?? false) {
                return false
            }
            return abs(y) * 1.4 < abs(x)
        }

        options.backgroundColor = UIColor.ud.functionDanger500
        options.cornerRadius = 10
        options.actionMargin = 8
        return options
    }
}

// MARK: - Drag & Drop

extension NewEdgeTabBar: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let position = position(of: indexPath, in: tableView),
              // can't get item from `more` button, we don't allow moving it
              let item = item(at: position),
              canDrag(from: position) else { return [] }
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: NewEdgeTabIndexProvider(position)))
        dragItem.localObject = item
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        []
    }

    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameter = UIDragPreviewParameters()
        if let view = tableView.cellForRow(at: indexPath) {
            parameter.visiblePath = UIBezierPath(roundedRect: view.bounds,
                                                 cornerRadius: Cons.dragPreviewRadius)
        }
        return parameter
    }

    func tableView(_ tableView: UITableView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        /// tableview没有endInteractiveMovement
        popover?.collectionView.endInteractiveMovement() // Fix 15 以下系统 Drag End 时 collectionView 可能不恢复初始态的问题
    }
}

extension NewEdgeTabBar: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let sourceItem = coordinator.session.tabItem,
              let sourcePosition = position(of: sourceItem) else { return }


        ///添加临时区到最后
        if coordinator.destinationIndexPath == nil || coordinator.destinationIndexPath == indexPathAndView(of: sourcePosition).0 {
            let row = temporaryTabItems.count - 1 > 0 ? temporaryTabItems.count - 1 : 0
            if let destinationPosition = position(of: IndexPath(row: row, section: 1), in: tableView),
               canDrop(from: sourcePosition, point: coordinator.session.location(in: self.tableView)) {
                insert(from: sourcePosition, to: destinationPosition)
            }
        }

        guard let destinationIndexPath = coordinator.destinationIndexPath,
              let destinationPosition = position(of: destinationIndexPath, in: tableView),
              // DropSessionDidUpdate 返回 .forbidden 的情况下
              // 仍然有可能会调用 performDropWith，这里需要做二次校验
              canDrop(from: sourcePosition, to: destinationPosition) else { return }
         insert(from: sourcePosition, to: destinationPosition)
    }

    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: NewEdgeTabIndexProvider.self)
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard let originItem = session.tabItem,
              let originPosition = position(of: originItem) else {
            return .init(operation: .forbidden)
        }

        // 如果拖动的是主导航上的 Item，如果进入了「更多」，则展示 Popover，否则取消展示 Popover
        switch originPosition {
        case .main, .temporary:
            if let destinationIndexPath, destinationIndexPath == .init(row: mainTabItems.count, section: 0) {
                showPopoverOnEnteringMoreIfNeeded()
                return .init(operation: .forbidden)
            } else {
                dismissPopoverOnExitingMoreLater()
            }
        default: break
        }

        if destinationIndexPath == nil, canDrop(from: originPosition, point: session.location(in: self.tableView)) {
            return .init(operation: .move, intent: .insertAtDestinationIndexPath)
        }

        guard let destinationIndexPath,
              let destinationPosition = position(of: destinationIndexPath, in: tableView),
              canDrop(from: originPosition, to: destinationPosition) else {
            return .init(operation: .forbidden)
        }
        return .init(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

// MARK: Gesture

extension NewEdgeTabBar: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer == bgTapRecognizer else { return true }
        let point = touch.location(in: tableView)
        // bgTapRecognizer 只识别点击空白部分事件，当点击在子 View 上时，不响应
        return tableView.subviews.first(where: { $0.frame.contains(point) }) == nil
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer == bgTapRecognizer
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer != bgTapRecognizer
    }
}
