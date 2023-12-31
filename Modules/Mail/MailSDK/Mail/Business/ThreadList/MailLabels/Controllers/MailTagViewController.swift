//
//  MailTagViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/12/6.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import EENavigator
import Reachability
import Homeric
import RustPB
import SnapKit
import RxCocoa
import RxDataSources
import LarkGuideUI

protocol MailTagListDelegate: AnyObject {
    func tagMenu(_ dropMenu: MailTagViewController, didSelect label: MailLabelModel)
    func tagMenu(_ dropMenu: MailTagViewController, retryReload labelId: String)
    func tagMenu(_ dropMenu: MailTagViewController, isShowing: Bool)
    func tagMenu(_ dropMenu: MailTagViewController, touchesEndedAt location: CGPoint)
    func tagMenu(_ dropMenu: MailTagViewController, showManage: Bool)
    func delegateViewSize() -> CGSize
    // 根据smart inbox开关 & 文件夹未读数 & Setting通知开关 修改未读提示
    func updateUnreadDot(isHidden: Bool, isRed: Bool)
}

enum DisplayMode {
    case normalMode
    case popoverMode
}

class MailTagViewController: MailBaseViewController, MailDropMenuTransitionDelegate,
                             GuideSingleBubbleDelegate, MailTagDelegate,
                             MailLabelsSettingViewDelegate, UITableViewDelegate,
                             UIViewControllerTransitioningDelegate {
    struct Layout {
        static var menuHideTransform: CGAffineTransform = CGAffineTransform.identity.translatedBy(x: 0, y: -Display.height)
        static let menuShowTransform: CGAffineTransform = CGAffineTransform.identity
        static let cellHeight: CGFloat = 48
        static let sectionHeaderHeight: CGFloat = 26
        static let minHeight: CGFloat = 0.01
        static let topPadding: CGFloat = 8
        static var trickyHeight: CGFloat = 10.0
        static var bottomSpace: CGFloat {
            return 64 + Display.realTabbarHeight()
        }
        static let popWidth: CGFloat = 375
    }

    // MARK: - Data
    private(set) var viewModel = MailTagViewModel()
    weak var delegate: MailTagListDelegate?
    private var disposeBag = DisposeBag()
    private let accountContext: MailAccountContext
    private var loadingDisposeBag = DisposeBag()

    // MARK: - Status
    private var didReload = false
    private var status: MailHomeEmptyCell.EmptyCellStatus = .none {
        didSet {
            if oldValue == .canRetry, status == .none {
                didReload = true
            } else {
                didReload = false
            }
        }
    }
    private var reachability: Reachability? = Reachability()
    private var connection: Reachability.Connection?

    var fgDataError = false {
        didSet {
            viewModel.fgDataError = fgDataError
        }
    }
    var smartInboxModeEnable = false {
        didSet {
            viewModel.smartInboxModeEnable = smartInboxModeEnable
        }
    }
    var strangerModeEnable = false {
        didSet {
            viewModel.strangerModeEnable = strangerModeEnable
        }
    }
    var displayMode: DisplayMode = .normalMode

    func smartInboxEnable() -> Bool {
        return smartInboxModeEnable && !fgDataError
    }
    var didAppear: Bool {
        return viewModel.didAppear
    }
    


    // MARK: - menu
    let bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0)
        view.clipsToBounds = true
        return view
    }()

    let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    let bgMask: UIControl = {
        let view = UIControl()
        view.addTarget(self, action: #selector(_didClickBgView(_:)), for: .touchUpInside)
        return view
    }()

    lazy var mainTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.separatorStyle = .none
        table.separatorColor = .clear
        table.showsHorizontalScrollIndicator = false
        table.showsVerticalScrollIndicator = false
        table.backgroundColor = UIColor.ud.bgBody
        // table.lu.register(cellSelf: MailFilterLabelCell.self)
        table.register(MailFilterLabelCell.self, forCellReuseIdentifier: MailFilterLabelCell.identifier)
        table.accessibilityIdentifier = MailAccessibilityIdentifierKey.TableViewLabelMenuKey
        table.contentInsetAdjustmentBehavior = .never
        table.contentInset = .zero
        return table
    }()

    lazy var settingView: MailLabelsSettingView = {
       let settingView = MailLabelsSettingView(frame: CGRect(x: 0,
                                                             y: 0,
                                                             width: view.bounds.width,
                                                             height: Layout.cellHeight))
       settingView.delegate = self
       return settingView
    }()

    lazy var loadFailView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        let container = UIView()
        view.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        let errorIcon = UIImageView()
        errorIcon.image = Resources.feed_error_icon
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.MailSDK.Mail_Common_NetworkError
        label.numberOfLines = 0
        label.textAlignment = .center
        [errorIcon, label].forEach {
            container.addSubview($0)
        }
        errorIcon.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(125)
            make.height.equalTo(125)
        }
        label.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(errorIcon.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
            make.width.lessThanOrEqualTo(250)
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickRetry))
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        view.isHidden = true
        return view
    }()

    lazy var dataSource = RxTableViewSectionedReloadDataSource<MailTagSection>(
            configureCell: { [weak self] (datasource, tv, indexPath, element) in
                guard let cell = tv.dequeueReusableCell(withIdentifier: MailFilterLabelCell.identifier, for: indexPath) as? MailFilterLabelCell else {
                    return UITableViewCell()
                }
                guard let `self` = self else { return UITableViewCell() }
//                cell.separatorInset = .zero
                switch datasource[indexPath] {
                case let .label(labelModel):
                    cell.config(labelModel)
                    cell.accessibilityIdentifier = tv.cellAccessIdentifier(labelId: labelModel.labelId)
                    cell.isSelectedItem = self.viewModel.selectedID == labelModel.labelId
                    cell.enableNotify = self.viewModel.enableNotification()
                case let .folder(folderModel):
                    cell.config(folderModel, isFolder: true)
                    cell.accessibilityIdentifier = tv.cellAccessIdentifier(labelId: folderModel.labelId)
                    cell.isSelectedItem = self.viewModel.selectedID == folderModel.labelId
                    cell.enableNotify = self.viewModel.enableNotification()
                }
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].header
            }
        )

    init(_ selected: Int = 0, accountContext: MailAccountContext, delegate: MailTagListDelegate? = nil, _ displayMode: DisplayMode) {
        self.delegate = delegate
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    // MLeaksFinder
    @objc
    func willDealloc() -> Bool {
        return false
    }

    func updateSelectedIDAndRefresh(_ selectedID: String) {
        viewModel.selectedID = selectedID
    }

    func updateLabels(_ labels: [MailFilterLabelCellModel]) {
        viewModel.updateLabels(labels)
    }

    func fetchDataAndRefreshMark(apmEvent: MailAPMEvent.LabelListLoaded? = nil) {
        viewModel.apmMarkRefresh()
        viewModel.fetchData(apmEvent: apmEvent)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        smartInboxModeEnable = Store.settingData.getCachedCurrentSetting()?.smartInboxMode ?? false
        viewModel.apmMarkColdStart()
        setupViews()
        bindViewModel()
        viewModel.fetchData()
        if let reach = reachability {
            connection = reach.connection
            reach.notificationCenter.addObserver(self, selector: #selector(networkChanged), name: Notification.Name.reachabilityChanged, object: nil)
            do {
                try reachability?.startNotifier()
            } catch {
                MailLogger.info("could not start reachability notifier")
            }
        }
//        showFolderGuideIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if viewModel.shouldForceReload {
            viewModel.retryFetchData()
            viewModel.shouldForceReload = false
        }
        if displayMode == .popoverMode {
            delegate?.tagMenu(self, isShowing: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.didAppear = true
        viewModel.refresh()
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) { // 因为Onboard依赖Frame，需要下一个runloop获取
            self.showFolderGuideIfNeeded()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if displayMode == .popoverMode {
            delegate?.tagMenu(self, isShowing: false)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.didAppear = false
    }

    override func viewDidTransition(to size: CGSize) {
        if displayMode == .normalMode {
            dismissMenu()
        }
    }

    func showFolderGuideIfNeeded() {
        if !Store.settingData.folderOpen() {
            return
        }
        let guideKey = "all_email_managefolder"
        guard let guide = accountContext.provider.guideServiceProvider?.guideService,
              guide.checkShouldShowGuide(key: guideKey) else {
            return
        }
        let targetAnchor = TargetAnchor(targetSourceType: .targetView(settingView))
        let textConfig = TextInfoConfig(title: BundleI18n.MailSDK.Mail_Folder_FolderManagement,
                                        detail: BundleI18n.MailSDK.Mail_Folder_FolderManagementDesc)
        let bubbleConfig = SingleBubbleConfig(delegate: self, bubbleConfig: BubbleItemConfig(guideAnchor: targetAnchor, textConfig: textConfig))
        accountContext.provider.guideServiceProvider?.guideService?.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                                                            bubbleType: .single(bubbleConfig),
                                                                                            dismissHandler: nil,
                                                                                            didAppearHandler: nil,
                                                                                            willAppearHandler: nil)
    }

    @objc
    func networkChanged() {
        guard let reachablility = reachability else {
            return
        }
        guard connection != reachablility.connection else {
            MailLogger.info("mail network changed repeat at labels")
            return
        }
        MailLogger.info("mail network changed at labels")
        if reachablility.connection != .none, viewModel.labels.isEmpty, viewModel.didAppear {
            viewModel.retryFetchData()
        }
    }

    func bindViewModel() {
        let dataSource = self.dataSource

        viewModel.tagCellVMs.asObservable()
            .bind(to: mainTableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        mainTableView.rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let `self` = self else { return }
                let tagItem = dataSource.sectionModels[indexPath.section].items[indexPath.row]
                switch tagItem {
                case let .label(labelModel):
                    self.viewModel.selectedID = labelModel.labelId
                    self.delegate?.tagMenu(self, didSelect: labelModel)
                case let .folder(folderModel):
                    self.viewModel.selectedID = folderModel.labelId
                    self.delegate?.tagMenu(self, didSelect: folderModel)
                }
                self.dismissMenu()
            })
            .disposed(by: disposeBag)

        mainTableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        viewModel.showLoading
            .drive(onNext: { [weak self] (showLoading) in
                guard let `self` = self else { return }
                if showLoading {
                    self.toggleErrorView(show: false)
                    self.showLoading()
                } else {
                    self.hideLoading()
                }
            }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposeBag)

        viewModel.showError
            .drive(onNext: { [weak self] (showError) in
                self?.toggleErrorView(show: showError)
                self?.updateStatus()
            })
            .disposed(by: disposeBag)

        viewModel.showUnreadDot
            .drive(onNext: { [weak self] (showUnreadDot) in
                self?.delegate?.updateUnreadDot(isHidden: showUnreadDot.0, isRed: showUnreadDot.1)
                self?.reloadTableView()
            })
            .disposed(by: disposeBag)

        viewModel.delegate = self

        EventBus.threadListEvent.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .reloadLabelMenu:
                    self.reloadTableView()
                case .updateLabelsCellVM(labels: let labels):
                    self.updateLabels(labels)
                default: break
                }
            }).disposed(by: disposeBag)
    }

    private func toggleErrorView(show: Bool) {
        if show {
            hideLoading()
            showError()
            loadFailView.alpha = 1
            InteractiveErrorRecorder.recordError(event: .labellist_error_page,
                                                 errorCode: .rust_error,
                                                 tipsType: .error_page)
        } else {
            hideError()
            UIView.animate(withDuration: timeIntvl.uiAnimateNormal, animations: {
                self.loadFailView.alpha = 0.0
            })
        }
    }

    @objc
    func onClickRetry() {
        viewModel.retryFetchData()
    }

    func updateInit(selectedLabelId: String, selectedFilter: MailThreadFilterType) {
        viewModel.selectedID = selectedLabelId
    }

    override func showLoading(frame: CGRect? = nil, duration: Int = 0) {
        if displayMode == .normalMode {
            contentView.addSubview(loadingView)
            loadingView.snp.remakeConstraints({ (make) in
                make.top.equalTo(16)
                make.leading.equalToSuperview()
                make.width.equalToSuperview()
                make.bottom.equalToSuperview().offset(-54)
            })
            contentView.bringSubviewToFront(loadingView)
        } else {
            self.view.addSubview(loadingView)
            loadingView.snp.remakeConstraints({ (make) in
                make.edges.equalToSuperview()
            })
            self.view.bringSubviewToFront(loadingView)
        }

        loadingView.alpha = 1.0
        loadingView.isHidden = false
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(duration), execute: { [weak self] in
                self?.hideLoading()
            })
        }
    }

    func showError() {
        if displayMode == .normalMode {
            contentView.addSubview(loadFailView)
            loadFailView.snp.remakeConstraints({ (make) in
                make.top.equalTo(16)
                make.leading.equalToSuperview()
                make.width.equalToSuperview()
                make.bottom.equalToSuperview().offset(-54)
            })
            contentView.bringSubviewToFront(loadFailView)
        } else {
            self.view.addSubview(loadFailView)
            loadFailView.snp.remakeConstraints({ (make) in
                make.edges.equalToSuperview()
            })
            self.view.bringSubviewToFront(loadFailView)
        }
        loadFailView.isHidden = false
        MailTracker.log(event: "email_page_fail", params: ["scene": "messagelist"])
    }

    func hideError() {
        loadFailView.isHidden = true
        loadFailView.removeFromSuperview()
    }

    override func mailCurrentAccountUnbind() {
        guard displayMode == .normalMode else { return }
        dismissMenu()
    }
    // MARK: - MailDropMenuTransitionDelegate
    func showMenuContent() {
        guard displayMode == .normalMode else { return }
        contentView.transform = Layout.menuShowTransform
        bgMask.backgroundColor = UIColor.ud.bgMask
        delegate?.tagMenu(self, isShowing: true)
    }

    func dismissMenuContent() {
        guard displayMode == .normalMode else { return }
        contentView.transform = Layout.menuHideTransform
        bgMask.backgroundColor = UIColor.clear
        delegate?.tagMenu(self, isShowing: false)
    }

    func getMenuContentView() -> UIView {
        return self.contentView
    }

    func dismissMenu() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Private  MailTagDelegate
    func didSelectedTag(_ selectedLabel: MailLabelModel) {
        delegate?.tagMenu(self, didSelect: selectedLabel)
    }

    func retryReload(_ labelId: String) {
        // 加载异常后接收push重新刷新的case
        if didReload {
            viewModel.selectedID = smartInboxEnable() ? Mail_LabelId_Important : Mail_LabelId_Inbox
            delegate?.tagMenu(self, retryReload: labelId)
            didReload = false
        }
    }

    @objc
    private func _didClickBgView(_ sender: UIControl) {
        guard displayMode == .normalMode else { return }
        dismissMenu()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard displayMode == .normalMode else { return }
        guard viewModel.didAppear else { return }
        dismissMenu()
        if let window = self.view.window, let point = touches.first?.location(in: window) {
            delegate?.tagMenu(self, touchesEndedAt: point)
        }
    }

    func updateStatus() {
        if let reachability = reachability {
            updateStaus(reachability)
        }
    }

    func updateStaus(_ reachability: Reachability) {
        status = reachability.connection != .none ? ( viewModel.labels.isEmpty ? .canRetry : .none ) : .noNet
    }

    func reloadTableView() {
        viewModel.refresh()
    }
    // MARK: - MailLabelsSettingViewDelegate
    func didClickManageLabelsButton() {
        if #available(iOS 13.0, *) {
            dismiss(animated: false, completion: nil)
            self.delegate?.tagMenu(self, showManage: false)
        } else {
            if Store.settingData.folderOpen() || Store.settingData.mailClient {
                let manageVC = MailManageTagViewController(accountContext: accountContext)
                presentVC(manageVC)
            } else {
                let manageVC = MailManageLabelsController(accountContext: accountContext, showCreateButton: true)
                manageVC.scene = .setting
                presentVC(manageVC)
            }
        }
    }

    func presentVC(_ vc: MailBaseViewController) {
        let nav = LkNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        if #available(iOS 13.0, *) {
            nav.modalPresentationStyle = .automatic
        }
        navigator?.present(nav, from: self)
    }
    // MARK: - TableView  UITableViewDelegate

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 12.0)
        title.text = dataSource[section].header
        title.textColor = UIColor.ud.textPlaceholder
        header.backgroundColor = UIColor.ud.bgBody
        header.addSubview(title)
        title.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.top.equalTo(4)
            make.bottom.equalTo(-4)
        }
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if dataSource[section].header.isEmpty {
            return Layout.minHeight
        } else {
            return Layout.sectionHeaderHeight
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if dataSource.sectionModels.isEmpty {
            return tableView.frame.size.height
        } else {
            return 52
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    // MARK: - Transition  UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController, source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return MailDropMenuTransition(.show)
    }
    func animationController(forDismissed dismissed: UIViewController )
        -> UIViewControllerAnimatedTransitioning? {
            return MailDropMenuTransition(.dismiss)
    }
}

extension UITableView {
    func cellAccessIdentifier(labelId: String) -> String {
        if labelId == Mail_LabelId_Inbox {
            return MailAccessibilityIdentifierKey.LabelCellInboxKey
        } else if labelId == Mail_LabelId_Draft {
            return MailAccessibilityIdentifierKey.LabelCellDraftKey
        } else if labelId == Mail_LabelId_Spam {
            return MailAccessibilityIdentifierKey.LabelCellSpamKey
        } else if labelId == Mail_LabelId_Sent {
            return MailAccessibilityIdentifierKey.LabelCellSentKey
        } else if labelId == Mail_LabelId_Trash {
            return MailAccessibilityIdentifierKey.LabelCellTrashKey
        } else if labelId == Mail_LabelId_Archived {
            return MailAccessibilityIdentifierKey.LabelCellArchivedKey
        }
        return MailAccessibilityIdentifierKey.LabelCellCustomKey
    }
}
