//
//  MailAddSenderAliasViewController.swift
//  MailSDK
//
//  Created by Raozhongtao on 2023/11/28.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import RustPB
import UniverseDesignInput
import FigmaKit

protocol MailAddSenderAliasDelegate: AnyObject {
    func didAddAliasAndDismiss()
}

enum StatusType {
    case overLimit
    case emptyName
    case valid
    case unEditMailGroup
    case unEditMailBox
}

class MailAddSenderAliasViewController: MailBaseViewController, UDTextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    private weak var viewModel: MailSettingViewModel?
    weak var delegate: MailAddSenderAliasDelegate?
    private let disposeBag = DisposeBag()
    private let limitLength = 200
    private let accountContext: MailAccountContext
    private var currentAddress: MailAddress
    private var availableAddress: [MailAddress]
    private var accountSetting: MailAccountSetting?
    private var accountId: String
    private var sendNameStatus = BehaviorSubject<StatusType>(value: .valid)

    // MARK: - Views
    lazy var tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.lu.register(cellSelf: MailSettingAliasAvailableAddressCell.self)
        tableView.lu.register(cellSelf: MailSettingEditableCell.self)
        return tableView
    }()

    lazy var aliasLimitWarningLabel: UILabel = {
        let warningLabel = UILabel()
        warningLabel.text = ""
        warningLabel.font = UIFont.systemFont(ofSize: 14)
        warningLabel.textColor = UIColor.ud.functionDangerContentDefault
        warningLabel.numberOfLines = 0
        return warningLabel
    }()

    let saveBtn = UIButton(type: .custom)

    init(viewModel: MailSettingViewModel?, 
         accountContext: MailAccountContext,
         accountId: String,
         availableAddress: [MailAddress]) {
        self.viewModel = viewModel
        self.accountContext = accountContext
        self.accountId = accountId
        self.availableAddress = availableAddress
        self.currentAddress = availableAddress[0]
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase, tintColor: UIColor.ud.textTitle)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.shouldRecordMailState = false
        setupViews()
        setupModel()
        reloadData()
    }

    private func setupModel() {
        self.viewModel?.viewController = self
        if let accountSetting = viewModel?.getAccountSetting(of: accountId) {
            self.accountSetting = accountSetting
            self.accountSetting?.delegate = viewModel
        }

        self.viewModel?.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_SETTING_CHANGED_BYSELF)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)

        self.sendNameStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{ type in
            switch type {
            case .overLimit:
                self.aliasLimitWarningLabel.text = BundleI18n.MailSDK.Mail_ManageSenders_NameTooLong_Error(self.limitLength)
                self.aliasLimitWarningLabel.textColor = UIColor.ud.functionDangerContentDefault
                self.saveBtn.isEnabled = false
            case .emptyName:
                self.aliasLimitWarningLabel.text = BundleI18n.MailSDK.Mail_ManageSenders_NameEmpty_Error
                self.aliasLimitWarningLabel.textColor = UIColor.ud.functionDangerContentDefault
                self.saveBtn.isEnabled = false
            case .valid:
                self.saveBtn.isEnabled = true
                self.aliasLimitWarningLabel.text = ""
            case .unEditMailBox:
                self.aliasLimitWarningLabel.text =  BundleI18n.MailSDK.Mail_ManageSenders_PublicMailboxDoesNotSupportCustomizingSenderNameContactAdministratorIfNeeded_Text
                self.aliasLimitWarningLabel.textColor = UIColor.ud.textPlaceholder
                self.saveBtn.isEnabled = true
            case .unEditMailGroup:
                self.aliasLimitWarningLabel.text = BundleI18n.MailSDK.Mail_ManageSenders_MailingListDoesNotSupportCustomizingSenderNameContactAdministratorIfNeeded_Text
                self.aliasLimitWarningLabel.textColor = UIColor.ud.textPlaceholder
                self.saveBtn.isEnabled = true
            }
            self.aliasLimitWarningLabel.setNeedsLayout()
        }).disposed(by: disposeBag)
    }

    func reloadData() {
        tableView.reloadData()

    }

    func setupViews() {
        view.backgroundColor = ModelViewHelper.bgColor(vc: self)
        saveBtn.isEnabled = true
        saveBtn.addTarget(self, action: #selector(saveAlias), for: .touchUpInside)
        saveBtn.setTitle(BundleI18n.MailSDK.Mail_ThirdClient_SaveMobile, for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        saveBtn.setTitleColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        saveBtn.setTitleColor(UIColor.ud.textDisable, for: .disabled)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveBtn)

        let cancelBtn = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_Common_Cancel)
        cancelBtn.button.tintColor = UIColor.ud.textTitle
        cancelBtn.addTarget(self, action: #selector(cancelDidClick), for: .touchUpInside)
        navigationItem.leftBarButtonItem = cancelBtn
        title = BundleI18n.MailSDK.Mail_ManageSenders_AddressesInUse_Add_Button
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // 是否可以编辑
        let type = currentAddress.type
        let text = textField.text ?? ""
        if type != .sharedMailbox, type != .enterpriseMailGroup {
            textField.textColor = UIColor.ud.textTitle
            _ = checkIsTextValid(text: text)
            return true
        }
        if type == .sharedMailbox {
            sendNameStatus.onNext(.unEditMailBox)
            textField.tintColor = UIColor.ud.functionInfoContentDefault
        } else if type == .enterpriseMailGroup {
            sendNameStatus.onNext(.unEditMailGroup)
        }
        textField.textColor = UIColor.ud.iconDisabled
        return false
    }

    private func checkIsTextValid(text: String) -> Bool {
        let limitLength = 200
        let processedText = text.replacingOccurrences(of: " ", with: "")
        if processedText.isEmpty {
            sendNameStatus.onNext(.emptyName)
            return false
        }
        if text.count > limitLength {
            sendNameStatus.onNext(.overLimit)
            return false
        }
        sendNameStatus.onNext(.valid)
        currentAddress.name = text
        return true
    }

    private var saveDate: TimeInterval = 0
    private func saveRepeated() -> Bool {
        let currentDate = Date().timeIntervalSince1970 * 1000
        if (currentDate - saveDate) > 500 {
            saveDate = currentDate
            return false
        }
        MailLogger.info("[Mail_Alias_Setting] save button repeated true")
        return true
    }

    @objc
    func saveAlias() {
        if saveRepeated() { return }
        accountSetting?.loadingToast = MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Normal_Loading, on: self.view)
        accountSetting?.updateSettings(.appendAlias(currentAddress.toPBModel())) { [weak self] in
            guard let `self` = self else { return }
            self.accountSetting?.loadingToast = nil
            self.dismissSelf(animated: true, completion: { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.didAddAliasAndDismiss()
            })
        }
    }

    private func dismissSelf(animated: Bool, completion: (() -> Void)? = nil) {
        asyncRunInMainThread { [weak self] in
            self?.dismiss(animated: animated, completion: completion)
        }
    }

    @objc
    func cancelDidClick() {
        dismissSelf(animated: true, completion: nil)
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let item = MailSettingItemFactory.createMailAliasAvailableAddressModel(address: currentAddress.address)
            if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? MailSettingAliasAvailableAddressCell {
                cell.item = item
                cell.dependency = self
                return cell
            }

        }
        if indexPath.section == 1 {
            let item = MailSettingItemFactory.createMailSettingEditableModel(alias: currentAddress.name, placeHolder: BundleI18n.MailSDK.Mail_ManageSenders_SenderName_Enter_Placeholder)
            if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? MailSettingEditableCell {
                cell.item = item
                cell.delegate = self
                return cell
            }
        }
        return UITableViewCell()

    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 40 : 48
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 1 ? UITableView.automaticDimension : .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var text = ""
        if section == 0 {
            text = BundleI18n.MailSDK.Mail_ManageSenders_SenderAddress_Text
        } else if section == 1 {
            text = BundleI18n.MailSDK.Mail_ManageSenders_SenderName_Text
        }
        let view: UIView = UIView()
        let detailLabel = UILabel()
        detailLabel.text = text
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

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == 1 else { return nil }
        let footerView = UITableViewHeaderFooterView()
        footerView.contentView.addSubview(aliasLimitWarningLabel)
        aliasLimitWarningLabel.isHidden = false
        aliasLimitWarningLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-14)
            make.top.equalTo(3)
        }
        return footerView
    }

}

extension MailAddSenderAliasViewController: MailSettingEditableCellDelegate, 
                                            AvailableAddressCellDependency,
                                            AliasListDelegate {
    func cancel() { }

    func showAliasEditPage() { }

    func handleEditingChange(sender: UITextField) {
        // 是否展示提示label
        let text = sender.text ?? ""
        saveBtn.isEnabled = self.checkIsTextValid(text: text)

    }

    func showAvailableAddress() {
        var availableAddressesPB: [MailClientAddress] = []
        for availableAddress in self.availableAddress {
            availableAddressesPB.append(availableAddress.toPBModel())
        }
        let aliasList = AliasListController(availableAddressesPB, currentAddress, type: .addAlias)
        aliasList.delegate = self
        accountContext.navigator.present(aliasList, from: self)
    }

    func selectedAlias(address: RustPB.Email_Client_V1_Address) {
        self.currentAddress = MailAddress(with: address)
        self.reloadData()
    }

}

protocol AvailableAddressCellDependency: AnyObject {
    func showAvailableAddress()
}

class MailSettingAliasAvailableAddressCell: MailSettingBaseCell {

    weak var dependency: AvailableAddressCellDependency?

    override func setCellInfo() {
        guard let item = item as? MailAliasAvailableAddressModel else { return }
        titleLabel.text = item.address
    }

    override func didClickCell() {
        dependency?.showAvailableAddress()
    }
}
