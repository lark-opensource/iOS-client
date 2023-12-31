//
//  MailSwipeActionsSettingViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/1/29.
//

import Foundation
import FigmaKit
import RxSwift

final class MailSwipeActionsSettingViewController: MailBaseViewController, UITableViewDelegate, UITableViewDataSource, MailSwipeActionsConfigDelegate {
    var viewModel: MailSettingViewModel?
    var accountId: String?

    private let disposeBag = DisposeBag()
    private var dataSource: [MailSettingSwipeOrientationModel] = []
    private let userContext: MailUserContext

    var viewWidth: CGFloat = 0
    var needShowOnboard: Bool = true

    init(userContext: MailUserContext, viewModel: MailSettingViewModel?, accountId: String) {
        self.viewModel = viewModel
        self.accountId = accountId
        self.userContext = userContext
        super.init(nibName: nil, bundle: nil)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        userContext
    }
    
    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewWidth = view.bounds.width - 32
        setupViews()
        setupViewModel()

        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_CACHED_CURRENT_SETTING_CHANGED)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)
    }
    
    func showOnboardIfNeeded() {
        let needOnboard = userContext.provider.guideServiceProvider?.guideService?.checkShouldShowGuide(key: "mobile_email_threadlist_swipe_setting") ?? false
        guard needOnboard else { return }
        let delayTime: Double = 1.0
        UIView.animate(withDuration: timeIntvl.short, delay: delayTime, options: .curveEaseInOut) {
            for (index, _) in self.dataSource.enumerated() {
                if let cell = self.tableView.cellForRow(at: IndexPath.init(row: 0, section: index)) as? MailSettingSwipeActionsPreviewCell {
                    cell.showOnboard()
                }
            }
        }
        userContext.provider.guideServiceProvider?.guideService?.didShowedGuide(guideKey: "mobile_email_threadlist_swipe_setting")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showOnboardIfNeeded()
    }
    
    func setupViews() {
        view.backgroundColor = UIColor.ud.bgFloatBase
        title = BundleI18n.MailSDK.Mail_Settings_EmailSwipeActions_Text
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(0)
        }

    }
    
    func setupViewModel() {
        if viewModel == nil {
            viewModel = MailSettingViewModel(accountContext: userContext.getAccountContextOrCurrent(accountID: accountId))
        }
        reloadData()
        self.viewModel?.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)
    }
    
    func reloadData() {
        if let account = Store.settingData.getCachedPrimaryAccount() {
            accountId = account.mailAccountID
            dataSource = createSwipeOrientationSettingSection(by: account)
        }
        tableView.reloadData()
    }
    
    private func createSwipeOrientationSettingSection(by account: MailAccount) -> [MailSettingSwipeOrientationModel] {
        let accountId = account.mailAccountID
        let slideAction = account.mailSetting.slideAction
        let leftActions: [MailThreadCellSwipeAction] = slideAction.rightSlideAction.removeUnsupport().convertToSwipeAction()
        let rightActions: [MailThreadCellSwipeAction] = slideAction.leftSlideAction.removeUnsupport().convertToSwipeAction()
        let mailSwipeOrientationSettings: [MailSettingSwipeOrientationModel] =
        [MailSettingSwipeOrientationModel(cellIdentifier: MailSettingSwipeActionsPreviewCell.lu.reuseIdentifier, accountId: accountId, actions: leftActions, orientation: .left, status: slideAction.rightSlideActionOn, switchHandler: { [weak self] status in
            if let leftVM = self?.dataSource.first {
                self?.jumpToSwipeActionConfigPage(leftVM, accountId: accountId)
            }
        }),
         MailSettingSwipeOrientationModel(cellIdentifier: MailSettingSwipeActionsPreviewCell.lu.reuseIdentifier, accountId: accountId, actions: rightActions.reversed(), orientation: .right, status: slideAction.leftSlideActionOn, switchHandler: { [weak self] status in
            if let rightVM = self?.dataSource.last {
                self?.jumpToSwipeActionConfigPage(rightVM, accountId: accountId)
            }
        })
        ]
        return mailSwipeOrientationSettings
    }
    
    private func jumpToSwipeActionConfigPage(_ viewModel: MailSettingSwipeOrientationModel, accountId: String) {
        let configVC = MailSwipeActionsConfigViewController(userContext: userContext, accountId: accountId, viewModel: viewModel)
        configVC.delegate = self
        navigator?.push(configVC, from: self)
    }

    func updateAction(_ account: MailAccount) {
        accountId = account.mailAccountID
        dataSource = createSwipeOrientationSettingSection(by: account)
        tableView.reloadData()
        if var priAcc = Store.settingData.getCachedPrimaryAccount() {
            Store.settingData.updateSettings(.swipeAction(account.mailSetting.slideAction), of: &priAcc)
        }
    }
    
    lazy var tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.lu.register(cellSelf: MailSettingSwipeActionsPreviewCell.self)
        return tableView
    }()
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: MailSettingSwipeActionsPreviewCell.lu.reuseIdentifier) as? MailSettingSwipeActionsPreviewCell {
            let item = dataSource[indexPath.section]
            cell.item = item
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return UIView() }
        let view = UITableViewHeaderFooterView()
        let detailLabel = UILabel()
        detailLabel.text = BundleI18n.MailSDK.Mail_Settings_EmailSwipeActions_Desc
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.ud.textCaption
        detailLabel.numberOfLines = 0
        view.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.equalTo(18)
            make.right.equalTo(-16)
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
