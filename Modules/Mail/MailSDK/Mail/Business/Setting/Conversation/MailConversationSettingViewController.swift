//
//  MailConversationSettingViewController.swift
//  MailSDK
//
//  Created by li jiayi on 2021/10/15.
//

import Foundation
import UIKit
import RustPB
import FigmaKit
import UniverseDesignCheckBox
import RxSwift
import LarkDatePickerView
import LarkAlertController

class MailConversationSettingOptionCell: MailBaseSettingOptionCell {
    lazy var contentLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textColor = UIColor.ud.textPlaceholder
        l.font = UIFont.systemFont(ofSize: 14)
        return l
    }()
    
    override func setupViews() {
        super.setupViews()
        contentView.addSubview(contentLabel)
        selectView.snp.makeConstraints { (make) in
            make.height.width.equalTo(20)
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(14)
            make.left.equalTo(16)
            make.right.equalToSuperview().offset(-48)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalTo(titleLabel.snp.right)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }
    }
}

class MailConversationSettingViewController: MailBaseViewController, UITableViewDelegate, UITableViewDataSource {
    private weak var viewModel: MailSettingViewModel?
    var accountId: String?
    var accountSetting: MailAccountSetting?
    var converSationModeIndex: Int = 1
    var converSationModeSort: Int = 0
    private var disposeBag = DisposeBag()
    private let accountContext: MailAccountContext

    init(viewModel: MailSettingViewModel?, accountContext: MailAccountContext) {
        self.viewModel = viewModel
        self.accountContext = accountContext
        self.accountId = accountContext.accountID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadData()
        self.viewModel?.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)
        tableView.reloadData()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupViews()
    }

    override var navigationBarTintColor: UIColor {
            return UIColor.ud.bgFloatBase
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    func setupViews() {
        view.backgroundColor = UIColor.ud.bgFloatBase
        self.title = BundleI18n.MailSDK.Mail_Settings_EmailOrganize
        view?.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(0)
        }
    }

    // MARK: tableView
    func numberOfSections(in tableView: UITableView) -> Int {
        if accountSetting?.setting.enableConversationMode == true {
            return 2
        } else {
            return 1
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 12 : 40
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MailConversationSettingOptionCell.reuseIdentifier) as? MailConversationSettingOptionCell, indexPath.row < 2 else {
            return UITableViewCell()
        }
        if indexPath.section == 0 {
            let cellMode = indexPath.row == converSationModeIndex
            cell.isSelected = cellMode == accountSetting?.setting.enableConversationMode
            cell.titleLabel.text = cellMode ? BundleI18n.MailSDK.Mail_Settings_ChatModeOption : BundleI18n.MailSDK.Mail_Settings_ChatModeOther
            cell.contentLabel.text = cellMode ? BundleI18n.MailSDK.Mail_Settings_ChatModeOptionDesc : ""
        }else {
            //sortType指的是当前的cell的type，true for 在顶部
            let sortType = indexPath.row == converSationModeSort
            cell.isSelected = sortType == accountSetting?.setting.mobileMessageDisplayRankMode
            //mobileMessageDisplayRankMode为true表示在顶部
            cell.titleLabel.text = sortType ? BundleI18n.MailSDK.Mail_Order_RecentEmailsTop : BundleI18n.MailSDK.Mail_Order_RecentEmailsButtom
            cell.contentLabel.text = ""
        }
        var topOffset = 0
        if let text = cell.contentLabel.text, !text.isEmpty {
            topOffset = 4
        }
        cell.contentLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(cell.titleLabel.snp.bottom).offset(topOffset)
            make.left.equalTo(cell.titleLabel.snp.left)
            make.right.equalTo(cell.titleLabel.snp.right)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        guard indexPath.row < 2 else { return }
        if indexPath.section == 0 {
            if let accoundID = accountId, accountSetting?.setting.enablePreload ?? false { // 开启缓存情况下
                Store.fetcher?.mailGetPreloadTimeStamp(accountID: accoundID)
                 .subscribe(onNext: { [weak self] response in
                     guard let `self` = self else { return }
                     MailLogger.info("[mail_cache_preload] conversationMode getPreloadTimeStamp success! accountId: \(accoundID) selected: \(response.timeStamp)")
                     if response.timeStamp != .preloadClosed && response.timeStamp != .preloadStUnspecified {
                         // 需要二次弹窗确认
                         let alert = LarkAlertController()
                         alert.setTitle(text: BundleI18n.MailSDK.Mail_Setting_AdjustViewMode_Title)
                         alert.setContent(text: BundleI18n.MailSDK.Mail_Setting_AdjustViewMode_Desc, alignment: .center)
                         alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
                         alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Setting_AdjustViewMode_Switch_Button, dismissCompletion: {
                             MailTracker.log(event: "email_offline_cache_confirm_click", params: ["click": "confirm", "target": "none"])
                             self.changeConversationMode(indexPath)
                         })
                         self.accountContext.navigator.present(alert, from: self)
                         MailTracker.log(event: "email_offline_cache_confirm_view", params: [:])
                     } else {
                         self.changeConversationMode(indexPath)
                     }
                }, onError: { [weak self] (error) in
                    MailLogger.error("[mail_cache_preload] conversationMode getPreloadTimeStamp fail accountId: \(accoundID)", error: error)
                    self?.changeConversationMode(indexPath)
                }).disposed(by: self.disposeBag)
            } else {
                changeConversationMode(indexPath)
            }
        } else {
            let nowConversationSort = accountSetting?.setting.mobileMessageDisplayRankMode
            let toConversationSort = indexPath.row == converSationModeSort
            if nowConversationSort != toConversationSort {
                accountSetting?.updateSettings(.conversationRankMode(atBottom: indexPath.row == converSationModeSort))
                tableView.reloadData()
            }
        }
    }

    func changeConversationMode(_ indexPath: IndexPath) {
        let nowConversationMode = accountSetting?.setting.enableConversationMode
        let toConversationMode = indexPath.row == converSationModeIndex
        if nowConversationMode != toConversationMode {
            MailTracker.log(event: MailTracker.MailSettingType.mailSettingClick.rawValue,
                            params: [MailTracker.getMailSettingConversationClickParamKey(): MailTracker.getMailSettingConversationClickParamValue(),
                                     MailTracker.getMailSettingConversationStatusParamKey(): MailTracker.getMailSettingConversationStatusParmaValue(isConversation: toConversationMode),
                                     "target": "none"])
            accountSetting?.updateSettings(.conversationMode(enable: indexPath.row == converSationModeIndex))
            tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return UIView()
        } else {
            let view: UIView = UIView()
            let detailLabel = UILabel()
            detailLabel.text = BundleI18n.MailSDK.Mail_Order_DisplayOrderMobile
            detailLabel.font = UIFont.systemFont(ofSize: 14)
            detailLabel.textColor = UIColor.ud.textCaption
            detailLabel.textAlignment = .justified
            detailLabel.numberOfLines = 0
            view.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { (make) in
                make.bottom.equalTo(-4)
                make.left.equalTo(4)
                make.right.equalTo(-16)
                make.height.equalTo(20)
            }
            return view
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func reloadData() {
        if let accountSetting = viewModel?.getPrimaryAccountSetting() {
            self.accountSetting = accountSetting
            accountId = accountSetting.account.mailAccountID
            tableView.reloadData()
        }
    }

    lazy var tableView: InsetTableView = {
        let t = InsetTableView(frame: .zero)
        t.dataSource = self
        t.delegate = self
        t.contentInsetAdjustmentBehavior = .never
        t.separatorColor = UIColor.ud.lineDividerDefault
        t.backgroundColor = UIColor.ud.bgFloatBase
        t.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        t.showsVerticalScrollIndicator = false
        t.showsHorizontalScrollIndicator = false

        t.register(MailConversationSettingOptionCell.self, forCellReuseIdentifier: MailConversationSettingOptionCell.reuseIdentifier)
        return t
    }()
}
