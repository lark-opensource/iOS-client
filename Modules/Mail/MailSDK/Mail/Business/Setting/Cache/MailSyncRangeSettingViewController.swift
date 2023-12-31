//
//  MailCacheSettingViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/3/28.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import RxDataSources
import RustPB
import Homeric
import FigmaKit
import UniverseDesignCheckBox
import UniverseDesignFont

protocol MailSyncRangeSettingDelegate: AnyObject {
    func updateSyncRangeSuccess(accountId: String)
}

extension Email_Client_V1_SyncRange {
    func title() -> String {
        switch self {
        case .oneDay:
            return BundleI18n.MailSDK.Mail_Shared_AddEAS_Sync1Day_DropdownList
        case .threeDays:
            return BundleI18n.MailSDK.Mail_Shared_AddEAS_Sync3Days_DropdownList
        case .oneWeek:
            return BundleI18n.MailSDK.Mail_Shared_AddEAS_Sync1Week_DropdownList
        case .twoWeeks:
            return BundleI18n.MailSDK.Mail_Shared_AddEAS_Sync2Weeks_DropdownList
        case .oneMonth:
            return BundleI18n.MailSDK.Mail_Shared_AddEAS_Sync1Month_DropdownList
        case .all:
            return BundleI18n.MailSDK.Mail_Shared_AddEAS_SyncAll_DropdownList
        @unknown default:
            return BundleI18n.MailSDK.Mail_Shared_AddEAS_Sync1Week_DropdownList
        }
    }
}

class MailSyncRangeSettingViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate {
    private weak var viewModel: MailSettingViewModel?
    private let disposeBag = DisposeBag()
    private let rangeOptions: [Email_Client_V1_SyncRange] = [.oneDay, .threeDays, .oneWeek, .twoWeeks, .oneMonth, .all]

    var accountSetting: MailAccountSetting?
    let accountContext: MailAccountContext
    weak var delegate: MailSyncRangeSettingDelegate?
    private var selectedSyncRange: Email_Client_V1_SyncRange = .oneWeek
    private var originSyncRange: Email_Client_V1_SyncRange = .oneWeek
    private let saveBtn = UIButton(type: .custom)

    init(viewModel: MailSettingViewModel?, accountContext: MailAccountContext) {
        self.viewModel = viewModel
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateNavAppearanceIfNeeded()
        showLoading()
        Store.fetcher?.getSyncRange(accountID: accountContext.accountID)
            .subscribe(onNext: { [weak self] response in
                guard let `self` = self else { return }
                MailLogger.info("[mail_client_eas] getSyncRange success! selected range: \(response.range)")
                self.selectedSyncRange = response.range
                self.originSyncRange = response.range
                self.hideLoading()
                self.tableView.reloadData()
        }, onError: { (error) in
            MailLogger.error("[mail_client_eas] getSyncRange fail", error: error)
        }).disposed(by: self.disposeBag)
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    func setupViews() {
        self.title = BundleI18n.MailSDK.Mail_Shared_AddEAS_EmailSync_Title
        view.backgroundColor = UIColor.ud.bgFloatBase

        saveBtn.addTarget(self, action: #selector(saveSyncRange), for: .touchUpInside)
        saveBtn.setTitle(BundleI18n.MailSDK.Mail_Settings_EmailSwipeActions_Done_Actions, for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        saveBtn.setTitleColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        saveBtn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveBtn)
        saveBtn.isEnabled = false

        let cancelBtn = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_Common_Cancel)
        cancelBtn.button.tintColor = UIColor.ud.textTitle
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        navigationItem.leftBarButtonItem = cancelBtn

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(0)
        }
    }

    @objc func saveSyncRange() {
        Store.fetcher?.setSyncRange(accountID: accountContext.accountID, range: selectedSyncRange)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                MailLogger.info("[mail_client_eas] setSyncRange success! selected range: \(self.selectedSyncRange)")
                self.dismiss(animated: true) {
                    self.delegate?.updateSyncRangeSuccess(accountId: self.accountContext.accountID)
                    Store.settingData.$easSyncRangeChanges.accept(())
                }
        }, onError: { (error) in
            MailLogger.error("[mail_client_eas] getSyncRange fail", error: error)
        }).disposed(by: self.disposeBag)
    }

    @objc func cancel() {
        dismiss(animated: true)
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rangeOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MailBaseSettingOptionCell.lu.reuseIdentifier) as? MailBaseSettingOptionCell else {
            return UITableViewCell()
        }
        let syncRange: Email_Client_V1_SyncRange = rangeOptions[indexPath.row]
        cell.titleLabel.text = syncRange.title()
        cell.isSelected = syncRange == selectedSyncRange
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let syncRange: Email_Client_V1_SyncRange = rangeOptions[indexPath.row]
        saveBtn.isEnabled = syncRange != self.originSyncRange
        selectedSyncRange = syncRange
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView()
        let detailLabel = UILabel()
        detailLabel.text = BundleI18n.MailSDK.Mail_Shared_AddEAS_SyncMailDays_SelectTitle
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.ud.textCaption
        detailLabel.numberOfLines = 0
        view.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView()
        let detailLabel = UILabel()
        detailLabel.text = BundleI18n.MailSDK.Mail_Shared_AddEAS_TakeUpSpace_HelperText
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.ud.textCaption
        detailLabel.numberOfLines = 0
        view.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.equalTo(32)
            make.right.equalTo(-32)
        }
        return view
    }

    func reloadData() {
        if let accountSetting = viewModel?.getAccountSetting(of: accountContext.accountID) {
            self.accountSetting = accountSetting
            self.tableView.reloadData()
        }
    }

    lazy var tableView: InsetTableView = {
        let t = InsetTableView(frame: .zero)
        t.dataSource = self
        t.delegate = self
        t.lu.register(cellSelf: MailBaseSettingOptionCell.self)
        t.separatorColor = UIColor.ud.lineDividerDefault
        t.rowHeight = 48
        t.backgroundColor = UIColor.ud.bgFloatBase
        return t
    }()
}
