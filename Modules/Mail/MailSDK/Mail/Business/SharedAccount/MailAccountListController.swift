//
//  MailAccountListController.swift
//  MailSDK
//
//  Created by majx on 2020/6/1.
//

import Foundation
import LarkUIKit
import RxSwift
import Homeric

protocol MailAccountListControllerDelegate: AnyObject {
    func accountListMenu(_ menu: MailAccountListController, touchesEndedAt location: CGPoint)
    func delegateViewSize() -> CGSize
    func didClickSwitchAccount()
}

class MailAccountListController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate,
                                 MailDropMenuTransitionDelegate, UIViewControllerTransitioningDelegate {
    override var modalPresentationStyle: UIModalPresentationStyle {
        didSet {
            setupViews()
        }
    }
    var isPopover: Bool {
        return modalPresentationStyle == .popover
    }
    var topMargin: CGFloat = Display.realTopBarHeight()
    struct Layout {
        static var menuHideTransform: CGAffineTransform = CGAffineTransform.identity.translatedBy(x: 0, y: -Display.height)
        static let menuShowTransform: CGAffineTransform = CGAffineTransform.identity
        static let cellHeight: CGFloat = 46
        static let minHeight: CGFloat = 0.01
        static let maxHeight: CGFloat = 300
        static let topPadding: CGFloat = 8
        static var trickyHeight: CGFloat = 16.0
//        static var topOffset: CGFloat {
//            return // + trickyHeight + MailThreadListConst.mulitAccountViewHeight
//        }
    }
    weak var delegate: MailAccountListControllerDelegate?
    private var didAppear = false
    private var disposeBag = DisposeBag()
    private var dataSource: [MailAccountInfo] = []
    private var unreadCounts: [String: Int64] = [:]
    private var currentAccountId: String?
    private var selectedAccountId: String?
    private var canScroll = false
    private let userContext: MailUserContext

    init(userContext: MailUserContext) {
        self.userContext = userContext
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        userContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadData()
        setupObserver()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didAppear = true
    }

    private func setupViews() {
        title = BundleI18n.MailSDK.Mail_SharedEmail_AccountsTitle
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = .clear
        if tableView.superview == nil {
            contentView.addSubview(tableView)
        }
        contentView.removeFromSuperview()
        bgView.removeFromSuperview()
        bgMask.removeFromSuperview()
        trickyView.removeFromSuperview()
        getMenuContentView().isHidden = false

        if isPopover {
            contentView.transform = Layout.menuShowTransform
            view.addSubview(contentView)
            tableView.snp.remakeConstraints { (make) in
                make.leading.trailing.bottom.top.equalToSuperview()
            }
            contentView.snp.remakeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(getContentHeight())
            }
        } else {
            if let size = self.delegate?.delegateViewSize() {
                view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            }
            view.addSubview(bgView)
            bgView.addSubview(bgMask)
            bgView.addSubview(trickyView)
            bgView.addSubview(contentView)

//            contentView.addSubview(separator)
//            separator.snp.makeConstraints { make in
//                make.top.equalTo(Layout.trickyHeight)
//                make.leading.trailing.equalToSuperview()
//                make.height.equalTo(0.5)
//            }
            tableView.snp.remakeConstraints { (make) in
                make.top.equalToSuperview() //(Layout.trickyHeight)
                make.leading.trailing.bottom.equalToSuperview()
            }
            let y = topMargin + MailThreadListConst.mulitAccountViewHeight
            bgView.snp.remakeConstraints { (make) in
               make.leading.trailing.equalToSuperview()
               make.top.equalToSuperview().offset(y)
               make.bottom.equalToSuperview()
            }
            trickyView.snp.makeConstraints { make in
                make.top.width.equalToSuperview()
                make.height.equalTo(Layout.cellHeight)
            }
            bgMask.snp.remakeConstraints { (make) in
               make.edges.equalToSuperview()
            }
            contentView.snp.remakeConstraints { (make) in
                make.top.equalTo(bgView)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(getContentHeight())
            }
        }
    }

    override func viewDidTransition(to size: CGSize) {
        super.viewDidTransition(to: size)
        setupViews()
    }

    private func setupObserver() {
        /// shared account changed
        Store.settingData
            .accountInfoChanges
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.loadData()
        }).disposed(by: disposeBag)
    }

    private func loadData() {
        self.dataSource = Store.settingData.getAccountInfos()
            .sorted{ $0.userType.priorityValue() > $1.userType.priorityValue() }
        if let accountId = self.dataSource.first(where: { $0.isSelected })?.accountId {
            self.currentAccountId = accountId
            self.selectedAccountId = accountId
        }
        self.tableView.reloadData()
        self.updateContentHeight()
        /// if is single account , dismiss account list
        if self.dataSource.count < 2 {
            self.dismissMenu()
        }
    }

    private func getContentHeight() -> CGFloat {
        canScroll = CGFloat(dataSource.count) * Layout.cellHeight > Layout.maxHeight
        if isPopover {
            return min(CGFloat(dataSource.count) * Layout.cellHeight, Layout.maxHeight)
        } else {
            return min(CGFloat(dataSource.count) * Layout.cellHeight, Layout.maxHeight)
        }
    }

    private func updateContentHeight() {
        let height = getContentHeight()
        contentView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
        tableView.showsVerticalScrollIndicator = (height == Layout.maxHeight)
        tableView.isScrollEnabled = canScroll
    }

    func switchAccount(to accountId: String) {
        delegate?.didClickSwitchAccount()
        /// show toast
        Store.settingData.switchMailAccount(to: accountId)
            .subscribe(onNext: { [weak self](resp) in
            guard let `self` = self else { return }
            if resp.account.mailAccountID == accountId {
                MailLogger.info("mail accout list did switch to account id \(accountId)")
                let target = resp.account.isShared ? "PublicMailbox" : "BusinessEmail"
                NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
                MailTracker.log(event: Homeric.EMAIL_PUBLIC_MAILBOX_SWITCH, params: ["target": target])
                self.dismissMenu()
            }
        }).disposed(by: self.disposeBag)
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = Layout.cellHeight
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.separatorStyle = .none
        /// registerCell
        tableView.lu.register(cellSelf: MailAccountListCell.self)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }()

    private let bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0)
        view.clipsToBounds = true
        return view
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.4)
        return view
    }()

    private let bgMask: UIControl = {
        let view = UIControl()
        view.addTarget(self, action: #selector(_didClickBgView(_:)), for: .touchUpInside)
        return view
    }()

    // 用于弹性动画的过渡背景
    private let trickyView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody//.withAlphaComponent(0.4)
        return view
    }()

//    lazy var separator: UIView = {
//        let separator = UIView()
//        separator.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
//        return separator
//    }()

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: MailAccountListCell.lu.reuseIdentifier) as? MailAccountListCell {
            if indexPath.row < dataSource.count {
                let account = dataSource[indexPath.row]
                cell.update(account: account)
                let accountId = account.accountId
                let unreadCount = unreadCounts[accountId]
                cell.isPopover = isPopover
                if selectedAccountId == account.accountId {
                    cell.isSelected = true
                } else {
                    cell.isSelected = false
                }
                cell.showSeparator = indexPath.row != dataSource.count - 1
            }
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let cell = tableView.cellForRow(at: indexPath)
        let account = dataSource[indexPath.row]
        let accountId = account.accountId
        if selectedAccountId != accountId {
            selectedAccountId = accountId
            tableView.reloadData()
            switchAccount(to: accountId)
        }
        MailLogger.info("mail account list selected: \(account.address ?? "")")
    }

//    func switchAccount(_ accountId: String) {
//        if selectedAccountId != accountId {
//            selectedAccountId = accountId
//            tableView.reloadData()
//        }
//    }
//
//    func refreshAccountInfo() {
//        if let currentAccount = Store.settingData.getCachedCurrentAccount() {
//            switchAccount(currentAccount.mailAccountID)
//        }
//    }

    func dismissMenu() {
        trickyView.isHidden = true
        dismiss(animated: true, completion: nil)
    }

   @objc
    private func _didClickBgView(_ sender: UIControl) {
       dismissMenu()
   }

   override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
       guard didAppear else { return }
       dismissMenu()
    if let window = self.view.window, let point = touches.first?.location(in: window) {
            delegate?.accountListMenu(self, touchesEndedAt: point)
       }
   }
    // MARK: - Private  MailDropMenuTransitionDelegate
    func getMenuContentView() -> UIView {
        return self.contentView
    }

    func showMenuContent() {
        if isPopover { return }
        contentView.transform = Layout.menuShowTransform
        trickyView.transform = Layout.menuHideTransform
        bgMask.backgroundColor = UIColor.ud.bgMask
    }

    func dismissMenuContent() {
        if isPopover { return }
        contentView.transform = Layout.menuHideTransform
        trickyView.transform = Layout.menuHideTransform
        bgMask.backgroundColor = UIColor(white: 0, alpha: 0)
    }
    // MARK: - Transition  UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if isPopover { return nil }
        bgMask.backgroundColor = .clear
        contentView.transform = Layout.menuHideTransform
        return MailDropMenuTransition(.show)
    }
    func animationController(forDismissed dismissed: UIViewController ) -> UIViewControllerAnimatedTransitioning? {
        if isPopover { return nil }
        return MailDropMenuTransition(.dismiss)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isPopover { return }
        preferredContentSize = contentView.bounds.size
    }
}
