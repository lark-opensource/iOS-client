//
//  FocusListController.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/25.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import FigmaKit
import LarkKeyCommandKit
import LarkUIKit
import LarkEmotion
import EENavigator
import LarkFeatureGating
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkContainer

public final class FocusListController: UIViewController, UserResolverWrapper {

    @ScopedInjectedLazy private var focusManager: FocusManager?

    enum State {
        case normal
        case loading
        case error
    }

    var state: State = .normal {
        didSet {
            switch state {
            case .normal:
                emptyView.isHidden = true
                tableView.isHidden = false
                tableFooterView.isHidden = false
                tableHeaderView.addButton.isHidden = false
            case .loading:
                emptyView.isHidden = true
                tableView.isHidden = false
                tableFooterView.isHidden = true
                tableHeaderView.addButton.isHidden = true
            case .error:
                emptyView.isHidden = false
                tableView.isHidden = true
            }
        }
    }

    /// 页面关闭方向，默认向右关闭（会根据手势滑动方向、点击位置改变关闭方向）
    private var dismissDirection: DismissDirection = .right

    // Focus 状态变化的回调，收到后需要重新拉取状态
    public var onFocusStatusChanged: (() -> Void)?

    private var dataService: FocusDataService {
        return focusManager?.dataService ?? .init(userResolver: userResolver)
    }

    private var transitionManager = FocusListTransitionManager()

    private var shouldAutoExpandStatus: Bool = true

    private var isRefreshStatusManually: Bool = false
    private var hasAutoExpandAndScroll: Bool = false

    // 恢复上次展开的状态，并滑动到当前生效状态的位置
    private lazy var isAutoExpandAndScrollEnabled: Bool = {
        // TODO: Remove this FG.
        return true
    }()

    private var shouldAutoExpandAndScroll: Bool {
        isAutoExpandAndScrollEnabled && !hasAutoExpandAndScroll
    }

    /// 当前生效的状态（nil 为没有生效状态）
    var activeStauts: UserFocusStatus?
    var activeIndexPath: IndexPath?

    /// 当前展示的状态列表
    lazy var focusStatus: [UserFocusStatus] = dataService.dataSource {
        didSet {
            // 这里不能立即 tableView.reloadData()，因为要做动画
            // 在 performBatchUpdate 之后手动调 reloadData()
            activeStauts = focusStatus.topActive
            specialStatus = getSpecialStatus()
            generalStatus = getGeneralStatus()

            if let activeStatus = activeStauts {
                activeIndexPath = getIndexPath(for: activeStatus)
            } else {
                activeIndexPath = nil
            }

            adjustAddButtonState()
            tableViewDidFinishAnimating()
        }
    }

    private lazy var specialStatus: [UserFocusStatus] = getSpecialStatus()

    private lazy var generalStatus: [UserFocusStatus] = getGeneralStatus()

    private func getSpecialStatus() -> [UserFocusStatus] {
        return focusStatus.filter { $0.isSystemStatus && $0.isInEffectivePeriod }
    }

    private func getGeneralStatus() -> [UserFocusStatus] {
        return focusStatus.filter { !$0.isSystemStatus }
    }

    private var canCreateNewStatus: Bool {
        dataService.canCreateNewStatus
    }

    private func adjustAddButtonState() {
        tableHeaderView.addButton.tintColor = canCreateNewStatus
            ? UIColor.ud.iconN1
            : UIColor.ud.iconDisabled
    }

    /// 保存现有的所有 Cell，不使用 tableView 复用机制，Key 是 FocusStatus 的 id。
    private var focusCellsHolder: [Int64: FocusModeCell] = [:]

    private let disposeBag = DisposeBag()

    lazy var backgroundBlurView: VisualBlurView = {
        let blurView = VisualBlurView()
        blurView.blurRadius = Cons.blurRadius
        blurView.fillColor = Cons.blurColor
        blurView.fillOpacity = Cons.blurOpacity
        return blurView
    }()

    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(cellWithClass: FocusModeCell.self)
        table.register(headerFooterViewClassWith: FocusListSectionHeader.self)
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.estimatedRowHeight = 80
        table.estimatedSectionHeaderHeight = UITableView.automaticDimension
        table.estimatedSectionFooterHeight = 0
        table.rowHeight = UITableView.automaticDimension
        table.sectionHeaderHeight = .leastNonzeroMagnitude
        table.sectionFooterHeight = .leastNonzeroMagnitude
        table.clipsToBounds = true
        table.showsVerticalScrollIndicator = false
        if #available(iOS 15.0, *) {
            table.allowsFocus = true
        }
        return table
    }()

    private lazy var emptyView: UDEmpty = {
        let config = UDEmptyConfig(
            titleText: BundleI18n.LarkFocus.Lark_Profile_LoadFailedRetry,
            font: UIFont.systemFont(ofSize: 14),
            description: nil,
            imageSize: 96,
            spaceBelowImage: 14,
            spaceBelowTitle: 16,
            type: .loadingFailure,
            primaryButtonConfig: (BundleI18n.LarkFocus.Lark_Profile_Refresh, {
                [weak self] _ in
                self?.didTapRetryButton()
            }),
            secondaryButtonConfig: (BundleI18n.LarkFocus.Lark_Profile_GoBack, {
                [weak self] _ in
                self?.close()
            }))
        let emptyView = UDEmpty(config: config)
        return emptyView
    }()

    private lazy var tableHeaderView = FocusListHeaderView()

    private lazy var tableFooterView = FocusListFooterView()

    public let userResolver: UserResolver
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionManager
        self.bindViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Shadow 需要响应 DarkMode 变化，所以在此设置
        tableView.layer.dropShadow(
            color: Cons.shadowColor,
            alpha: 0.09, x: 0, y: 4, blur: 8, spread: 0
        )
        // 恢复上次展开的状态，并滑动到当前生效状态的位置
        if isAutoExpandAndScrollEnabled {
            tableView.reloadDataWithAutoSizingBugFixing()
            if !isRefreshStatusManually, let activeIndexPath = activeIndexPath {
                tableView.scrollToRow(at: activeIndexPath, at: .bottom, animated: false)
                isRefreshStatusManually = true
            }
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isAutoExpandAndScrollEnabled {
            tableView.reloadDataWithAutoSizingBugFixing()
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        FocusTracker.isFirstLoadFocusList = true
        dataService.reloadData(onFailure: { [weak self] _ in
            self?.state = .error
        })
        view.addSubview(backgroundBlurView)
        backgroundBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.addSubview(tableView)
        view.addSubview(emptyView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
            if Display.pad {
                make.centerX.equalToSuperview()
                make.width.lessThanOrEqualTo(420)
                make.leading.trailing.equalToSuperview().priority(.medium)
            } else {
                make.leading.trailing.equalToSuperview()
            }
        }
        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        view.backgroundColor = .clear
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView(_:))))
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTableView(_:))))
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterView
        tableHeaderView.frame.size = CGSize(width: UIScreen.main.bounds.width, height: 91)
        tableFooterView.frame.size = CGSize(width: UIScreen.main.bounds.width, height: 76)
        tableFooterView.settingButton.addTarget(self, action: #selector(didTapSettingButton), for: .touchUpInside)

        tableHeaderView.addButton.addTarget(self, action: #selector(didTapAddButton), for: .touchUpInside)
        adjustAddButtonState()
        addPanGesture()
        FocusManager.logger.debug("user did open focus list page.")
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // bugfix: iPad 旋转屏幕之后，有极小概率 Cell 展不开，重新 reload 一次。
        // https://meego.feishu.cn/larksuite/issue/detail/4702544?parentUrl=%2Flarksuite%2FissueView%2FTAPqHveng
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView.reloadDataWithAutoSizingBugFixing()
        }
    }

    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + self.selectFocusKeyCommand()
    }

    private func bindViewModel() {
        self.state = .normal
        dataService.dataSourceObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] statusList in
                guard let self = self else { return }
                self.focusStatus = statusList
                self.showOnboardingIfNeeded()
                self.state = .normal
                self.tableView.reloadDataWithAutoSizingBugFixing()
                if !self.isRefreshStatusManually, self.isAutoExpandAndScrollEnabled, let activeIndex = self.activeIndexPath {
                    self.tableView.scrollToRow(at: activeIndex, at: .none, animated: false)
                }
                FocusTracker.didShowFocusList(focusList: statusList, activeStatus: self.activeStauts)
                FocusManager.logger.debug("\(#function), line: \(#line): receive status list update: \(statusList).")
            }).disposed(by: disposeBag)
        dataService.canCreateNewStatusObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isAllowed in
                self?.adjustAddButtonState()
            }).disposed(by: disposeBag)
    }

    @objc
    private func didTapRetryButton() {
        dataService.reloadData(onFailure: { [weak self] _ in
            self?.state = .error
        })
    }

    @objc
    private func close() {
        dismiss(animated: true)
    }

    @objc
    private func didTapTableView(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: tableView)
        dismissDirection = (location.x < tableView.bounds.width / 2) ? .left : .right
        if let tappedPath = tableView.indexPathForRow(at: location),
           let cell = tableView.cellForRow(at: tappedPath) as? FocusModeCell {
            // 点击了 Cell 的空白区域
            let pointInCell = tableView.convert(location, to: cell)
            if !cell.roundedContainer.frame.contains(pointInCell) {
                close()
            }
        } else {
            // 点击了 TableView 的空白区域
            close()
        }
    }

    @objc
    private func didTapBackgroundView(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        dismissDirection = (location.x < view.bounds.width / 2) ? .left : .right
        close()
    }

    // iOS 12 中，Cell 展开/收起动画会导致 tableView 的 contentOffset
    // 瞬间变为 0，记录下动画开始前的 offset 避免跳屏
    private var isAnimating: Bool = false
    private var animatingContentOffset: CGPoint = .zero

    // 记录是否正在打开/关闭个人状态，loading 期间禁止其他交互
    private var isOperating: Bool = false
}

extension FocusListController: UITableViewDelegate, UITableViewDataSource {

    private func tableViewWillBeginAnimating() {
        isAnimating = true
        animatingContentOffset = tableView.contentOffset
    }

    private func tableViewDidFinishAnimating() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isAnimating = false
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 解决 iOS12 跳屏问题
        if #available(iOS 13, *) {} else {
            // Hold content offset during animation.
            if isAnimating {
                scrollView.contentOffset = animatingContentOffset
            }
        }
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return allSectionNumber
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case sectionIndexOfSpecialStatus:
            return specialStatus.count
        case sectionIndexOfGeneralStatus:
            return generalStatus.count
        default:
            return 0
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let focus = getFocusStatus(at: indexPath)
        let cell = focusCellsHolder[focus.id] ?? FocusModeCell(userResolver: userResolver)
        focusCellsHolder[focus.id] = cell
        let isActive = activeStauts == focus
        let isExpaneded = focus.id == (focusManager?.expandStatusID ?? 0)
        cell.configure(with: focus, isActive: isActive, isExpanded: isExpaneded)
        cell.delegate = self
        return cell
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if hasSpecialStatus {
            return UITableView.automaticDimension
        } else {
            return CGFloat.leastNonzeroMagnitude
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard hasSpecialStatus else { return nil }
        let header = tableView.dequeueReusableHeaderFooterView(withClass: FocusListSectionHeader.self)
        switch section {
        case sectionIndexOfSpecialStatus:
            header.configure(
                withTitle: BundleI18n.LarkFocus.Lark_Status_SystemStatus_SubTitle,
                description: BundleI18n.LarkFocus.Lark_Status_SystemStatus_Description
            )
        case sectionIndexOfGeneralStatus:
            header.configure(
                withTitle: BundleI18n.LarkFocus.Lark_Status_GeneralStatus_SubTitle,
                description: nil
            )
        default:
            break
        }
        return header
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 12
    }
}

extension FocusListController {

    private var hasSpecialStatus: Bool {
        return !specialStatus.isEmpty
    }

    private var allSectionNumber: Int {
        return hasSpecialStatus ? 2 : 1
    }

    private var sectionIndexOfSpecialStatus: Int {
        // -1 代表不存在 SpecialStatus section
        return hasSpecialStatus ? 0 : -1
    }

    private var sectionIndexOfGeneralStatus: Int {
        return hasSpecialStatus ? 1 : 0
    }

    private func getFocusStatus(at indexPath: IndexPath) -> UserFocusStatus {
        switch indexPath.section {
        case sectionIndexOfSpecialStatus:
            return specialStatus[indexPath.row]
        case sectionIndexOfGeneralStatus:
            return generalStatus[indexPath.row]
        default:
            fatalError()
        }
    }

    private func getIndexPath(for focusStatus: UserFocusStatus) -> IndexPath? {
        if focusStatus.isSystemStatus, let row = specialStatus.firstIndex(of: focusStatus) {
            return IndexPath(row: row, section: sectionIndexOfSpecialStatus)
        } else if !focusStatus.isSystemStatus, let row = generalStatus.firstIndex(of: focusStatus) {
            return IndexPath(row: row, section: sectionIndexOfGeneralStatus)
        } else {
            return nil
        }
    }
}

// MARK: -

extension FocusListController: FocusModeCellDelegate {

    private func showFailureToast(_ message: String) {
        UDToast.autoDismissFailure(message, on: view)
    }

    private func hasNoLoadingCell() -> Bool {
        return focusCellsHolder.values.filter({
            $0.selectionState.isLoading
        }).isEmpty
    }

    // MARK: Onboarding

    private func showOnboardingIfNeeded() {
        guard let focusManager, !focusManager.isOnboardingShown else { return }
        guard !focusStatus.isEmpty else { return }
        let onboarding = FocusOnboardingController(userResolver: userResolver)
        onboarding.onSyncSettingTapped = { [weak self] in
            self?.didTapSettingButton()
        }
        userResolver.navigator.present(onboarding, from: self)
        focusManager.isOnboardingShown = true
        FocusManager.logger.debug("\(#function), line: \(#line): onboarding page did shown.")
    }

    // MARK: Expand status

    func focusCellDidTapExpandButton(_ cell: FocusModeCell) {
        guard let focusManager, let status = cell.focusStatus else { return }
        // 上报埋点
        if cell.isExpanded {
            FocusTracker.didTapFoldButton(status)
            focusManager.expandStatusID = -1
            FocusManager.logger.debug("\(#function), line: \(#line): user did fold status \(status) from list.")
        } else {
            FocusTracker.didTapExpandButton(status)
            focusManager.expandStatusID = status.id
            FocusManager.logger.debug("\(#function), line: \(#line): user did fold status \(status) from list.")
        }
        // 展开/折叠当前 Cell
        cell.toggleExpandWithAnimation()
        tableViewWillBeginAnimating()
        // 折叠其他 Cell
        for otherCell in focusCellsHolder.values where otherCell !== cell && otherCell.isExpanded {
            otherCell.setExpandWithAnimation(false)
        }
        tableView.performBatchUpdates(nil) { [weak self] _ in
            guard let self = self else { return }
            self.tableViewDidFinishAnimating()
            /*
            guard let indexPath = self.tableView.indexPath(for: cell) else { return }
            guard cell.isExpanded else { return }
            if cell.frame.maxY > self.view.bounds.maxY {
                self.tableView.safeScrollToRow(at: indexPath, at: .bottom, animated: true)
            }
            */
        }
    }

    // MARK: Turn on status

    func focusCellDidSelect(_ cell: FocusModeCell, period: FocusPeriod) {
        guard let status = cell.focusStatus else { return }
        guard hasNoLoadingCell() else { return }
        isRefreshStatusManually = true
        dataService.turnOnFocusStatus(
            status,
            period: period,
            onFailure: { [weak self] in
                self?.showFailureToast(BundleI18n.LarkFocus.Lark_Profile_EnableFailedRetry)
                self?.tableView.reloadData()
                FocusManager.logger.error("\(#function), line: \(#line): turn on status \(status) failed.")
            }, onSuccess: { [weak self] in
                TapticEngine.notification.feedback(.success)
                self?.onFocusStatusChanged?()
                FocusManager.logger.info("\(#function), line: \(#line): turn on status \(status) succeed.")
            })
        if cell.selectionState == .opened {
            cell.selectionState = .reopening
        } else {
            cell.selectionState = .opening
        }
        FocusManager.logger.debug("\(#function), line: \(#line): user will turn on status \(status) with period \(period).")
    }

    // MARK: Turn off status

    func focusCellDidDeselect(_ cell: FocusModeCell) {
        guard let status = cell.focusStatus else { return }
        guard hasNoLoadingCell() else { return }
        isRefreshStatusManually = true
        dataService.turnOffFocusStatus(
            status,
            onFailure: { [weak self] in
                self?.showFailureToast(BundleI18n.LarkFocus.Lark_Profile_CloseFailedRetry)
                self?.tableView.reloadData()
                FocusManager.logger.error("\(#function), line: \(#line): turn off status \(status) failed.")
            }, onSuccess: { [weak self] in
                TapticEngine.impact.feedback(.light)
                self?.onFocusStatusChanged?()
                FocusManager.logger.info("\(#function), line: \(#line): turn off status \(status) succeed.")
            })
        cell.selectionState = .closing
        FocusManager.logger.debug("\(#function), line: \(#line): user will turn off status \(status).")
    }

    // MARK: Edit status

    func focusCellDidTapConfigButton(_ cell: FocusModeCell) {
        guard let status = cell.focusStatus else { return }
        let editVC = EditViewControllerGenerator.generateEditViewController(userResolver: userResolver, focusStatus: status) { [weak self] (deletedStatus, updateList) in
            guard let self = self else { return }
            // 同步删除状态
            // NOTE：PM 要求删除个人状态成功下掉 Toast
            // UDToast.autoDismissSuccess(BundleI18n.LarkFocus.Lark_Profile_Saved, on: self.view)
            guard let deleteIndex = self.focusStatus.firstIndex(where: {
                $0.id == deletedStatus.id
            }) else {
                return
            }
            // 删除状态
            let deleteStatus = self.focusStatus[deleteIndex]
            // 要先计算 indexPath 之后再删除，否则结果为 nil
            let deleteIndexPath = self.getIndexPath(for: deleteStatus)
            self.focusStatus.remove(at: deleteIndex)
            if let deleteIndexPath = deleteIndexPath {
                self.tableView.performBatchUpdates({
                    self.tableView.deleteRows(at: [deleteIndexPath], with: .fade)
                }, completion: { [weak self] _ in
                    // UGLY: VM data sync
                    self?.dataService.removeDataSource(at: deleteIndex)
                    self?.dataService.updateDataSource(with: updateList)
                    self?.onFocusStatusChanged?()
                })
            } else {
                self.tableView.reloadData()
                self.dataService.removeDataSource(at: deleteIndex)
                self.dataService.updateDataSource(with: updateList)
                self.onFocusStatusChanged?()
            }
        } onUpdatingSuccess: { [weak self] newFocusStatus in
            // 同步更新状态
            guard let self = self else { return }
            UDToast.autoDismissSuccess(BundleI18n.LarkFocus.Lark_Profile_Saved, on: self.view)
            guard let changeIndex = self.focusStatus.firstIndex(where: {
                $0.id == newFocusStatus.id
            }) else {
                return
            }
            // 替换状态
            self.focusStatus[changeIndex] = newFocusStatus
            self.tableView.reloadData()
            self.onFocusStatusChanged?()
        }
        userResolver.navigator.present(
            editVC,
            wrap: LkNavigationController.self,
            from: self) { vc in
            vc.modalPresentationStyle = .formSheet
        }
        FocusTracker.didTapFocusEditButton(status)
        FocusManager.logger.debug("\(#function), line: \(#line): user did tap edit button of status \(status).")
    }

    // MARK: Create new status

    @objc
    private func didTapAddButton() {
        guard canCreateNewStatus else {
            UDToast.autoDismissWarning(BundleI18n.LarkFocus.Lark_Profile_CustomStatusLimit, on: view)
            return
        }
        let focusManager = try? userResolver.resolve(assert: FocusManager.self)

        let creatingVC = (focusManager?.isStatusNoteEnabled ?? false) ? getNewViewController() : getOldViewController()
        userResolver.navigator.present(creatingVC, wrap: LkNavigationController.self, from: self) { vc in
            vc.modalPresentationStyle = .formSheet
        }
        FocusTracker.didTapAddNewFocusButton()
        FocusManager.logger.debug("\(#function), line: \(#line): user did tap create new status button.")
    }

    // MARK: Open setting page

    @objc
    private func didTapSettingButton() {
        let settingVC = FocusSettingController(userResolver: userResolver)
        userResolver.navigator.present(settingVC, wrap: LkNavigationController.self, from: self) { vc in
            vc.modalPresentationStyle = .formSheet
        }
        FocusTracker.didTapFocusSettingButton()
        FocusManager.logger.debug("\(#function), line: \(#line): user did tap focus setting button.")
    }

    func getOldViewController() -> UIViewController {
        let creatingVC = FocusCreationNoStatusDescController(userResolver: userResolver)
        // 同步新增状态
        creatingVC.onCreatingSuccess = { [weak self] newStatus in
            guard let self = self else { return }
            UDToast.autoDismissSuccess(BundleI18n.LarkFocus.Lark_Profile_Saved, on: self.view)
            // 获取插入位置，根据服务端返回的 orderWeight 找出合适位置
            let insertIndex = self.focusStatus.firstIndex(where: {
                $0.orderWeight >= newStatus.orderWeight
            }) ?? self.focusStatus.count
            // 插入状态
            self.focusStatus.insert(newStatus, at: insertIndex)
            if let insertIndexPath = self.getIndexPath(for: newStatus) {
                self.tableView.performBatchUpdates({
                    self.tableView.insertRows(at: [insertIndexPath], with: .fade)
                }, completion: { [weak self] _ in
                    // UGLY: VM data sync
                    self?.dataService.addDataSource(newStatus, at: insertIndex)
                })
            } else {
                self.tableView.reloadData()
                self.dataService.addDataSource(newStatus, at: insertIndex)
            }
        }
        return creatingVC
    }

    func getNewViewController() -> UIViewController {
        let creatingVC = FocusCreationController(userResolver: userResolver)
        // 同步新增状态
        creatingVC.onCreatingSuccess = { [weak self] newStatus in
            guard let self = self else { return }
            UDToast.autoDismissSuccess(BundleI18n.LarkFocus.Lark_Profile_Saved, on: self.view)
            // 获取插入位置，根据服务端返回的 orderWeight 找出合适位置
            let insertIndex = self.focusStatus.firstIndex(where: {
                $0.orderWeight >= newStatus.orderWeight
            }) ?? self.focusStatus.count
            // 插入状态
            self.focusStatus.insert(newStatus, at: insertIndex)
            if let insertIndexPath = self.getIndexPath(for: newStatus) {
                self.tableView.performBatchUpdates({
                    self.tableView.insertRows(at: [insertIndexPath], with: .fade)
                }, completion: { [weak self] _ in
                    // UGLY: VM data sync
                    self?.dataService.addDataSource(newStatus, at: insertIndex)
                })
            } else {
                self.tableView.reloadData()
                self.dataService.addDataSource(newStatus, at: insertIndex)
            }
        }
        return creatingVC
    }
}

extension FocusListController {

    enum Cons {

        static var blurRadius: CGFloat { 60 }
        static var blurOpacity: CGFloat { 0.2 }
        static var blurColor: UIColor {
            UIColor.ud.primaryOnPrimaryFill
        }
        static var shadowColor: UIColor {
            UIColor.ud.N900 & UIColor.ud.staticBlack
        }
    }
}

// MARK: - Drag dismiss

extension FocusListController {

    enum DismissDirection {
        case left, right
    }

    private func addPanGesture() {
        guard !Display.pad else { return }
        // Pan to close
        let panGesture = DirectionalPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGesture.allowedDirections = [.left, .right]
        view.addGestureRecognizer(panGesture)
    }

    @objc
    private func didPan(_ gesture: DirectionalPanGestureRecognizer) {

        // 计算滑动进度
        var progress: CGFloat = 0
        switch gesture.state {
        case .began:
            break
        default:
            let direction: CGFloat = dismissDirection == .right ? 1 : -1
            let translation = gesture.translation(in: self.view)
            progress = min(1, max(0, (translation.x / view.bounds.width) * direction))
        }

        // 根据进度处理滑动动画
        switch gesture.state {
        case .began:
            if gesture.currentDirection == .right {
                dismissDirection = .right
            } else {
                dismissDirection = .left
            }
            isAutoExpandAndScrollEnabled = false
        case .changed:
            processDismiss(progress: progress)
            backgroundBlurView.blurRadius = (1 - progress) * Cons.blurRadius
            backgroundBlurView.fillOpacity = (1 - progress) * Cons.blurOpacity
        case .ended:
            let direction: CGFloat = dismissDirection == .right ? 1 : -1
            let velocity = gesture.velocity(in: self.view).x * direction
            if progress >= 0.2 || velocity > 1_000 {
                finishDismiss(from: progress)
            } else {
                cancelDismiss(from: progress)
            }
        case .cancelled, .failed:
            let direction: CGFloat = dismissDirection == .right ? 1 : -1
            let translation = gesture.translation(in: self.view)
            let progress = (translation.x / view.bounds.width) * direction
            cancelDismiss(from: progress)
        default:
            break
        }
    }

    private var animationDuration: TimeInterval { 0.3 }

    func processDismiss(progress: CGFloat) {
        let coefficient: CGFloat = (dismissDirection == .right ? 1 : -1) / 1
        var transform: CGAffineTransform

        if !Display.pad {
            transform = CGAffineTransform(
                translationX: view.bounds.width * coefficient * progress,
                y: 0
            )
        } else {
            let start: CGFloat = 0.7
            let scale = start + animationDuration * (1 - progress)
            transform = CGAffineTransform(scaleX: scale, y: scale)
        }

        tableView.transform = transform
        tableView.alpha = 1 - progress
    }

    private func finishDismiss(from progress: CGFloat) {
        let remainingTime = animationDuration * TimeInterval(1 - progress)
        UIView.animate(withDuration: remainingTime, animations: {
            self.processDismiss(progress: 1.0)
            self.backgroundBlurView.alpha = 0
        }, completion: { _ in
            self.dismiss(animated: false)
        })
        /*
        let loopTimes = Int(remainingTime / 0.02)
        animateBlurEffect(toRadius: 0, opacity: 0, loopTimes: loopTimes)
         */
    }

    private func cancelDismiss(from progress: CGFloat) {
        let remainingTime = animationDuration * TimeInterval(progress)
        UIView.animate(withDuration: remainingTime, animations: {
            self.processDismiss(progress: 0)
        })
        let loopTimes = Int(remainingTime / 0.02)
        animateBlurEffect(toRadius: Cons.blurRadius, opacity: Cons.blurOpacity, loopTimes: loopTimes)
    }

    func animateBlurEffect(toRadius finalRadius: CGFloat, opacity finalOpacity: CGFloat, loopTimes: Int) {
        guard loopTimes > 0 else {
            backgroundBlurView.blurRadius = finalRadius
            backgroundBlurView.fillOpacity = finalOpacity
            return
        }
        let curOpacity = backgroundBlurView.fillOpacity
        let curRadius = backgroundBlurView.blurRadius
        let opacityStep = (finalOpacity - curOpacity) / CGFloat(loopTimes)
        let radiusStep = (finalRadius - curRadius) / CGFloat(loopTimes)
        let nextOpacity = max(0, min(Cons.blurOpacity, curOpacity + opacityStep))
        let nextRadius = max(0, min(Cons.blurRadius, curRadius + radiusStep))
        backgroundBlurView.blurRadius = nextRadius
        backgroundBlurView.fillOpacity = nextOpacity
        if finalOpacity == nextOpacity && finalRadius == nextRadius {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.animateBlurEffect(toRadius: finalRadius, opacity: finalOpacity, loopTimes: loopTimes - 1)
        }
    }
}

extension UITableView {

    func reloadDataWithAutoSizingBugFixing() {
        reloadData()
        setNeedsLayout()
        layoutIfNeeded()
        reloadData()
    }
}
