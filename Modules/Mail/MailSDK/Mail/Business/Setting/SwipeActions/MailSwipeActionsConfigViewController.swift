//
//  MailSwipeActionsConfigViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/2/6.
//

import Foundation
import RxSwift
import LarkSwipeCellKit
import FigmaKit

protocol MailSwipeActionsConfigDelegate: AnyObject {
    func updateAction(_ account: MailAccount)
}

final class MailSwipeActionsConfigViewController: MailBaseViewController, MailSettingSwitchDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var viewModel: MailSettingSwipeOrientationModel
    var accountId: String
    var reachLimit: Bool = false
    weak var delegate: MailSwipeActionsConfigDelegate?

    private let disposeBag = DisposeBag()
    private var accountSetting: MailAccountSetting?
    private var settingSwitchModel: MailSettingSwitchModel?
    private var actionDataSource: [MailSettingSwipeActionModel] = []
    private var allSwitch: Bool = false
    private let userContext: MailUserContext
    private var updateAccount: MailAccount?
    
    lazy var tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.lu.register(cellSelf: MailSettingSwitchCell.self)
        tableView.lu.register(cellSelf: MailSettingSwipeActionCell.self)
        return tableView
    }()
    
    init(userContext: MailUserContext, accountId: String, viewModel: MailSettingSwipeOrientationModel) {
        self.viewModel = viewModel
        self.userContext = userContext
        self.accountId = accountId
        super.init(nibName: nil, bundle: nil)
    }

    override var serviceProvider: MailSharedServicesProvider? {
        userContext
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupViews()
    }
    
    func setupViews() {
        view.backgroundColor = UIColor.ud.bgFloatBase
        title = viewModel.orientation.oriTitle()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(0)
        }
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let updateAccount = updateAccount {
            delegate?.updateAction(updateAccount)
        }
    }
    
    func changeActions() {
        // update Setting
        MailLogger.info("[mail_swipe_actions] changeActions: \(actionDataSource.filter({ $0.status }).map({ $0.action })) orientation: \(viewModel.orientation)")
        let currentAccount: MailAccount? = {
            if let account = Store.settingData.getCachedAccountList()?.first(where: { $0.mailAccountID == accountId }) {
                return account
            } else if let primaryAccount = Store.settingData.getCachedPrimaryAccount() {
                return primaryAccount
            } else {
                return nil
            }
        }()
        guard var account = currentAccount else {
            return
        }
        var slideAction = account.mailSetting.slideAction
        if viewModel.orientation == .right {
            slideAction.leftSlideActionOn = viewModel.status
            slideAction.leftSlideAction = actionDataSource.filter({ $0.status }).map({ $0.action }).convertToSlideAction()
        } else {
            slideAction.rightSlideActionOn = viewModel.status
            slideAction.rightSlideAction = actionDataSource.filter({ $0.status }).map({ $0.action }).convertToSlideAction()
        }

        Store.settingData.updateSwipeActions(slideAction)
        account.mailSetting.slideAction = slideAction
        self.updateAccount = account
    }
    
    func setupViewModel() {
        var allActionsTuples: [(String, Bool)] = [(MailThreadCellSwipeAction.read.rawValue, false),
                                                  (MailThreadCellSwipeAction.archive.rawValue, false),
                                                  (MailThreadCellSwipeAction.trash.rawValue, false),
                                                  (MailThreadCellSwipeAction.moveTo.rawValue, false),
                                                  (MailThreadCellSwipeAction.changeLabels.rawValue, false),
                                                  (MailThreadCellSwipeAction.spam.rawValue, false)]
        if Store.settingData.clientStatus == .mailClient {
            allActionsTuples = [(MailThreadCellSwipeAction.read.rawValue, false),
                                (MailThreadCellSwipeAction.trash.rawValue, false),
                                (MailThreadCellSwipeAction.moveTo.rawValue, false)]
        }
        for (index, actionTuple) in allActionsTuples.enumerated() {
            if let action = MailThreadCellSwipeAction(rawValue: actionTuple.0), viewModel.actions.contains(action) {
                allActionsTuples[index].1 = true
            }
        }
        actionDataSource = allActionsTuples.map({
            MailSettingSwipeActionModel(cellIdentifier: MailSettingSwipeActionCell.lu.reuseIdentifier,
                                        accountId: accountId, action: MailThreadCellSwipeAction(rawValue: $0.0) ?? .archive,
                                        status: $0.1, switchHandler: { status in })
        })
        settingSwitchModel = MailSettingSwitchModel(cellIdentifier: MailSettingSwitchCell.lu.reuseIdentifier,
                                                    accountId: accountId,
                                                    title: viewModel.orientation == .left ? BundleI18n.MailSDK.Mail_EnableRightSwipe_Toggle : BundleI18n.MailSDK.Mail_EnableLeftSwipe_Toggle,
                                                    status: viewModel.status, switchHandler: { status in })
        reachLimit = actionDataSource.reduce(0, { $0 + ($1.status ? 1 : 0) }) >= 3
    }
    
    func didChangeSettingSwitch(_ status: Bool) {
        settingSwitchModel?.status = status
        viewModel.status = status
        tableView.reloadData()
        changeActions()
    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return actionDataSource.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 48
        } else {
            return (indexPath.row == 0 || indexPath.row == actionDataSource.count - 1) ? 60 : 48
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return (settingSwitchModel?.status ?? false) ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailSettingSwitchCell.lu.reuseIdentifier) as? MailSettingSwitchCell,
                  let item = self.settingSwitchModel else {
                return UITableViewCell()
            }
            cell.item = item
            cell.settingSwitchDelegate = self
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailSettingSwipeActionCell.lu.reuseIdentifier) as? MailSettingSwipeActionCell else {
                return UITableViewCell()
            }
            let actionItem = actionDataSource[indexPath.row]
            cell.aliginDown = indexPath.row != actionDataSource.count - 1
            cell.item = actionItem
            let disableSelected = reachLimit && !actionItem.status
            cell.updateStatus(isSelected: actionItem.status, isEnabled: !disableSelected)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        let selectTotalCount = actionDataSource.reduce(0, { $0 + ($1.status ? 1 : 0) })
        let oldStatus = actionDataSource[indexPath.row].status
        reachLimit = selectTotalCount >= 3
        if reachLimit && !oldStatus {
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_EmailSwipeActions_UpTo3_Text, on: self.view)
        } else {
            actionDataSource[indexPath.row].status = !oldStatus
            reachLimit = actionDataSource.reduce(0, { $0 + ($1.status ? 1 : 0) }) >= 3
            tableView.reloadData()
            changeActions()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else { return UIView() }
        let view = UITableViewHeaderFooterView()
        let detailLabel = UILabel()
        detailLabel.text = BundleI18n.MailSDK.Mail_EmailSwipeActions_UpTo3_Text
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.ud.textCaption
        detailLabel.numberOfLines = 0
        view.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.equalTo(18)
            make.right.equalTo(-16)
            make.height.equalTo(20)
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 12
        }
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
