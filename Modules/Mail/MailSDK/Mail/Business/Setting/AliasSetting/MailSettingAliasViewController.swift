//
//  MailSettingAliasViewController.swift
//  MailSDK
//
//  Created by raozhongtao on 2023/11/19.
//

import Foundation
import RxSwift
import UIKit
import FigmaKit
import RustPB
import UniverseDesignActionPanel
import LarkAlertController
import LarkUIKit

/// accountContext
///     -mailAccount?
///         -mailSetting
///             -emailAlias
///                 -allAddresses, primaryAddress, grantedAddresses)

struct AliasAddressList {
    var currentAddressList: [MailAddress]
    var grantedAddressList: [MailAddress]
    var defaultAddress: MailAddress
    var primaryAddress: MailAddress
    init() {
        currentAddressList = []
        grantedAddressList = []
        defaultAddress = MailAddress(name: "",
                                     address: "",
                                     larkID: "",
                                     tenantId: "",
                                     displayName: "",
                                     type: nil)
        primaryAddress = defaultAddress
    }
    init(currentAddressList: [MailAddress], 
         grantedAddressList: [MailAddress],
         primaryAddress: MailAddress,
         defaultAddress: MailAddress) {
        self.currentAddressList = currentAddressList
        self.grantedAddressList = grantedAddressList
        self.primaryAddress = primaryAddress
        self.defaultAddress = defaultAddress
    }
}

class MailSettingAliasViewController: MailBaseViewController, UITableViewDelegate, UITableViewDataSource {

    private var viewModel: MailSettingViewModel?
    private var accountContext: MailAccountContext
    private let disposeBag = DisposeBag()
    override var navigationBarTintColor: UIColor {
        return ModelViewHelper.bgColor(vc: self)
    }
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase, tintColor: UIColor.ud.textTitle)
    }
    private var addressList: AliasAddressList {
        didSet {
            addressList.currentAddressList = addressList.currentAddressList.sorted(by:{ (addressOne, addressTwo) -> Bool in
                return addressOne.address < addressTwo.address
            })
        }
    }

    private lazy var availableAddress = {
        let grantedList = addressList.grantedAddressList
        let currentList = addressList.currentAddressList
        return grantedList.filter{!currentList.contains($0)}
    }()
    private var accountId: String
    private var accountSetting: MailAccountSetting?

    private var footerView: UIView {
        let item = MailSettingAddOperationModel(cellIdentifier: MailSettingAddOperationCell.lu.reuseIdentifier,
                                               accountId: accountId,
                                               title: BundleI18n.MailSDK.Mail_ManageSenders_AddressesInUse_Add_Button)
        let cell = MailSettingAddOperationCell.init(style: .default, reuseIdentifier: item.cellIdentifier)
        cell.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10.0)
        cell.item = item
        cell.dependency = self
        let borderLineHeight: CGFloat = 0.25
        cell.addTopBorder(inset: .zero, lineHeight: borderLineHeight, bgColor: UIColor.ud.lineDividerDefault)
        return cell
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10.0)
        tableView.lu.register(cellSelf: MailSettingAliasAccountCell.self)
        tableView.lu.register(cellSelf: MailSettingAddOperationCell.self)
        return tableView
    }()

    init(accountContext: MailAccountContext, viewModel: MailSettingViewModel?, accountId: String) {
        self.accountContext = accountContext
        self.addressList = AliasAddressList()
        self.viewModel = viewModel
        self.accountId = accountId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViewModel() {
        self.viewModel?.viewController = self
        self.viewModel?.refreshDriver.drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            MailLogger.info("[Mail_Alias_Setting] refreshDriver.drive")
            self.reloadData()
        }).disposed(by: disposeBag)
        
        if let accountSetting = viewModel?.getAccountSetting(of: accountId) {
            self.accountSetting = accountSetting
            self.accountSetting?.delegate = viewModel
        }

        reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = BundleI18n.MailSDK.Mail_ManageSenders_Popover_Title
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-40)
        }

        setupViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        viewModel?.viewController = self
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    private func reloadData() {
        accountSetting = self.viewModel?.getAccountSetting(of: accountId)
        accountSetting?.delegate = viewModel
        addressList = self.loadAliasAddress()
        tableView.reloadData()
    }
    
    private func loadAliasAddress() -> AliasAddressList {
        guard let mailAlias = accountSetting?.setting.emailAlias else {
            MailLogger.info("[Mail_Alias_Setting] loadAliasAddress accountSetting NOT Found")
            return AliasAddressList()
        }
        let allClientAddresses = mailAlias.allAddresses
        let grantedClientAddresses = mailAlias.grantedAddresses
        let defaultAddress = MailAddress(with: mailAlias.defaultAddress)
        let primaryAddress = MailAddress(with: mailAlias.primaryAddress)
        var grantedAddresses: [MailAddress] = []
        var allAddresses: [MailAddress] = []

        for address in grantedClientAddresses {
            grantedAddresses.append(MailAddress(with: address))
        }
        for address in allClientAddresses {
            allAddresses.append(MailAddress(with: address))
        }
        self.availableAddress = grantedAddresses.filter{!allAddresses.contains($0)}

        let aliasList = AliasAddressList(currentAddressList: allAddresses,
                                         grantedAddressList: grantedAddresses,
                                         primaryAddress: primaryAddress,
                                         defaultAddress: defaultAddress)
        return aliasList
    }

    private func presentAliasVC(vc: MailBaseViewController) {
        let aliasNav = LkNavigationController(rootViewController: vc)
        aliasNav.modalPresentationStyle = .fullScreen
        self.accountContext.navigator.present(aliasNav, from: self)
    }

    private func setDefaultAddress(for address: MailAddress) {
        let clientAddress = address.toPBModel()
        accountSetting?.updateSettings(.setDefaultAlias(clientAddress)) { [weak self] in
            guard let `self` = self else { return }
            self.reloadData()
            DispatchQueue.main.async() {
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ManageSenders_SetAsDefaultAddress_Toast, on: self.view)
            }
        }
    }

    private func deleteAddress(for address: MailAddress) {
        let clientAddress = address.toPBModel()
        accountSetting?.updateSettings(.deleteAlias(clientAddress)) { [weak self] in
            guard let `self` = self else { return }
            self.reloadData()
            DispatchQueue.main.async() {
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ManageSenders_RemoveAddress_Toast, on: self.view)
            }
        }
    }

    private func getAliasNumber() -> Int {
        guard let accountSetting = self.accountSetting else { return 0 }
        let emailAlias = accountSetting.setting.emailAlias
        let allAddresses = emailAlias.allAddresses
        return allAddresses.count
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = self.getAliasNumber()
        return numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row <= addressList.currentAddressList.count else {
            return UITableViewCell()
        }
        if indexPath.row < addressList.currentAddressList.count {
            var mailAddress = addressList.currentAddressList[indexPath.row]
            let defaultAddress = addressList.defaultAddress
            let isDefault = mailAddress == defaultAddress
            let item = MailSettingItemFactory.createAliasAccountCellModel(accountId: accountId,
                                                                          mailAddress: mailAddress,
                                                                          isDefault: isDefault)
            let cell = MailSettingAliasAccountCell.init(style: .default, reuseIdentifier: item.cellIdentifier)
            cell.item = item
            cell.delegate = self
            cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingAccountAliasCellKey
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            if indexPath.row == 0 {
                cell.roundCorners(corners: [.topLeft, .topRight], radius: 10.0)
            } else {
                cell.layer.masksToBounds = false

            }
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return footerView
    }

}

extension MailSettingAliasViewController: MailSettingAddOperationCellDependency, MailSettingAliasCellDelegate {
    
    func handleAddOperation() {
        guard !availableAddress.isEmpty else {
            MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_ManageSenders_NoAddressToAdd_Toast, on: self.view)
            return
        }
        let addAliasVC = MailAddSenderAliasViewController(viewModel: viewModel,
                                                          accountContext: accountContext,
                                                          accountId: accountId,
                                                          availableAddress: availableAddress)
        addAliasVC.delegate = self
        self.presentAliasVC(vc: addAliasVC)
    }
    
    func showAliasSettingIfNeeded(for address: MailAddress) {
        let isDefaultAddress = addressList.defaultAddress == address
        let isPrimaryAddress = addressList.primaryAddress == address
        let type = address.type

        if isDefaultAddress, isPrimaryAddress, type == .sharedMailbox {
            MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_ManageSenders_UnableToEditPublicMailbox_Toast, on: self.view)
            return
        }

        if isDefaultAddress, isPrimaryAddress, type == .enterpriseMailGroup {
            MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_ManageSenders_UnableToEditMailingList_Toast, on: self.view)
            return
        }

        let config = UDActionSheetUIConfig(isShowTitle: true)
        let actionSheet = UDActionSheet(config: config)

        let titleText = address.name + " <\(address.address)>"
        actionSheet.setTitle(titleText)

        if type != .sharedMailbox, type != .enterpriseMailGroup {
            actionSheet.addDefaultItem(text: BundleI18n.MailSDK.Mail_ManageSenders_EditName_Button) { [weak self] in
                guard let `self` = self else { return }

                let titleText = BundleI18n.MailSDK.Mail_ManageSenders_EditName_Button
                let aliasSettingVC = MailSenderAliasController(viewModel: viewModel,
                                                               accountId: accountId,
                                                               accountContext: accountContext,
                                                               titleText: titleText,
                                                               currentAddress: address)
                aliasSettingVC.delegate = self
                self.presentAliasVC(vc: aliasSettingVC)
            }
        }

        if !isDefaultAddress {
            actionSheet.addDefaultItem(text: BundleI18n.MailSDK.Mail_ManageSenders_SetAsDefaultAddress_Button) { [weak self] in
                guard let `self` = self else { return }
                self.setDefaultAddress(for: address)
            }
        }

        if !isPrimaryAddress {
            actionSheet.addDestructiveItem(text: BundleI18n.MailSDK.Mail_ManageSenders_RemoveAddress_Button) { [weak self] in
                guard let `self` = self else { return }
                let alert = LarkAlertController()
                alert.setContent(text: BundleI18n.MailSDK.Mail_ManageSenders_DeleteEmailAddressConfirmation_Text(address.address))
                alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
                alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_ManageSenders_Delete_Button, dismissCompletion: { [weak self] in
                    guard let `self` = self else { return }
                    self.deleteAddress(for: address)
                })
                self.accountContext.navigator.present(alert, from: self)
            }
        }

        actionSheet.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        self.accountContext.navigator.present(actionSheet, from: self)
    }

}

extension MailSettingAliasViewController: MailSenderAliasDelegate, MailAddSenderAliasDelegate {
    func didAddAliasAndDismiss() {
        asyncRunInMainThread { [weak self] in
            guard let `self` = self else { return }
            MailRoundedHUD.remove(on: self.view)
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ManageSenders_SenderNameAdded_Toast, on: self.view)
        }
        self.reloadData()
    }

    func getAvailableAddress(for accountId: String) -> [MailAddress] {
        return self.availableAddress
    }
    
    func didUpdateAliasAndDismiss(address: MailAddress) {
        asyncRunInMainThread { [weak self] in
            guard let `self` = self else { return }
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ManageSenders_EditName_Toast, on: self.view)
        }
        self.reloadData()
    }

    func shouldShowAliasLimit() -> Bool {
        return true
    }
}
