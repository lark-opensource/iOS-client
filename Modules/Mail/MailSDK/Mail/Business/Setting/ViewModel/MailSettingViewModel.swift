//
//  MailSettingViewModel.swift
//  Action
//
//  Created by TangHaojin on 2019/7/29.
//

import UIKit
import RxSwift
import RxCocoa
import LarkUIKit
import LKCommonsLogging
import RustPB
import Homeric
import EENavigator
import LarkAlertController
import UniverseDesignToast

class MailAccountSetting {
    weak var delegate: MailAccountSettingDelegate?
    var account: MailAccount
    var settingSections: [MailSettingSectionModel]?
    var setting: MailSetting {
        return account.mailSetting
    }
    var loadingToast: UDToast?
    var isAccountDetailSetting: Bool = false

    init(account: MailAccount) {
        self.account = account
    }

    func updateSettings(_ settings: MailSettingAction..., onSuccess: (() -> Void)? = nil) {
        updateSettings(settings, onSuccess: onSuccess)
    }

    func updateSettings(_ settings: [MailSettingAction], onSuccess: (() -> Void)? = nil) {

        Store.settingData.updateSettings(settings,
                                         of: &account,
                                         onSuccess: onSuccess,
                                         onError: { [weak self] _ in
            // 失败后，需要重新拉取下数据，纠正状态
            guard let `self` = self else { return }
            if let view = self.delegate?.getHUDView() {
                if self.loadingToast != nil {
                    MailRoundedHUD.remove(on: view)
                    self.loadingToast = nil
                }
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_EmailSettingFailed,
                                           on: view,
                                           event: ToastErrorEvent(event: .mail_setting_update_fail))
            }
            self.delegate?.resetData()
        })
    }
}

protocol MailAccountSettingDelegate: AnyObject {
    func resetData()
    func getHUDView() -> UIView?
}

class MailSettingViewModel {
    static let logger = Logger.log(MailSettingViewModel.self, category: "Module.MailSettingViewModel")
    private var cacheSettingRes: [String: Email_Client_V1_MailGetPreloadConfigResponse] = [:]
    private var attachmentManageSettingRes: [String: MailLargeAttachmentCapacityResp] = [:]
    private var disposeBag: DisposeBag = DisposeBag()
    private var settingBag: DisposeBag = DisposeBag()
    private var signatureBag: DisposeBag = DisposeBag()
    private let notifyBag: DisposeBag = DisposeBag()
    private var networkSettingBag: DisposeBag = DisposeBag()
    private let refreshPublish: PublishSubject<Void> = PublishSubject<Void>()

    weak var viewController: MailBaseViewController?
    var refreshDriver: Driver<()> {
        return refreshPublish.asDriver(onErrorJustReturn: ())
    }
    var reloadLocalDataPublish: PublishSubject<Void> = PublishSubject<Void>()

    /// 账号设置结构如下：
    /// primaryAccount
    ///    - setting
    ///    - shareAccount
    ///        - setting
    var primaryAccountSetting: MailAccountSetting?
    var accountListSettings: [MailAccountSetting]?
    var pushSettings: [MailSettingPushModel] = []
    var pushTypeSettings: [MailSettingPushTypeModel] = []
    var pushSwitchModel: MailSettingSwitchModel?
    var markDirty: Bool = false // 标记脏数据
    var strangerModel: MailSettingStrangerModel?
    var strangerModelSwitchConfirm: Bool = true
    var hasSharedAccounts: Bool {
        return !(primaryAccountSetting?.account.sharedAccounts.isEmpty ?? true)
    }
    var showFreeBind: Bool = false

    private let accountContext: MailAccountContext // 为当前账号 context，用于push vc等操作，公共设置项要用主账号 id，不能用这里面的 id，一定要注意！

    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
        self.reloadData()
        self.addNotification()
        self.reloadLocalDataPublish.debounce(.seconds(1), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.getEmailPrimaryAccount()
        }).disposed(by: disposeBag)

    }

    func reloadData() {
       DispatchQueue.main.async {  [weak self] in
           guard let `self` = self else { return }
           self.getEmailPrimaryAccount()  // local data
           self.getEmailPrimaryAccount(fetchDb: false) // server data
       }
    }

    func getEmailPrimaryAccount(fetchDb: Bool = true) {
        if let account = Store.settingData.getCachedPrimaryAccount(), fetchDb {
            Store.settingData.updateClientStatusIfNeeded()
            self.updateViewModel(by: account)
            return
        }
        Store.settingData.getPrimaryAccount(fetchDb: fetchDb)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                MailSettingViewModel.logger.info("getEmailPrimaryAccount fetchDb: \(fetchDb) accID: \(response.account.mailAccountID)")
                Store.settingData.updateClientStatusIfNeeded()
                self.updateViewModel(by: response.account)
        }, onError: { (error) in
            MailSettingViewModel.logger.error("getEmailPrimaryAccount failed", error: error)
        }).disposed(by: settingBag)
    }

    func addNotification() {
        /// status change  please re fetch
        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_SETTING_AUTH_STATUS_CHANGED)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] noti in
            guard let `self` = self else { return }
            self.reloadLocalDataPublish.onNext(())
        }).disposed(by: notifyBag)

        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let self = self else { return }
                if case .accountChange(let change) = push {
                    // 本地乐观更新，远端 change 立即刷新，本地 change 先标记为脏数据，等待重新进入页面再刷新
                    if !change.fromLocal {
                        Store.settingData.updatePrimaryAccountCacheIfNeeded(change.account)
                        Store.settingData.updateClientStatusIfNeeded()
                        self.reloadLocalDataPublish.onNext(())
                        MailSettingViewModel.logger.info("mail setting - get account changed from remote")
                    } else {
                        self.markDirty = true
                        MailSettingViewModel.logger.info("mail setting - get account changed from local")
                    }
                }
            }).disposed(by: notifyBag)

        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let self = self else { return }
                if case .shareAccountChange(let change) = push {
                    self.sharedAccountChange(change: change)
                }
            }).disposed(by: notifyBag)

        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_SETTING_UPDATE_RESP)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.reloadLocalDataPublish.onNext(())
        }).disposed(by: disposeBag)
    }

    func getPrimaryAccountSetting() -> MailAccountSetting? {
        return primaryAccountSetting
    }

    func getAccountSetting(of accountId: String?) -> MailAccountSetting? {
        guard let accountId = accountId else {
            return primaryAccountSetting
        }
        if let accountList = accountListSettings, accountList.count > 1 || Store.settingData.clientStatus == .coExist {
            return accountList.first { $0.account.mailAccountID == accountId }
        } else if accountId == primaryAccountSetting?.account.mailAccountID {
            return primaryAccountSetting
        }
        return nil
    }
    
    enum updateSwitchType {
        case typeUndo
        case typePush
        case typeAttachment
        case typeSignature
        case typeOOO
        case typeDraftLanguage
        case typeWebImage
        case typeAutoCC
    }
    private func checkItemType(item: MailSettingItemProtocol, type: updateSwitchType) -> Bool {
        if type == .typeUndo {
            return (item as? MailSettingUndoModel) != nil
        } else if type == .typePush {
            return (item as? MailSettingPushModel) != nil
        } else if type == .typeAttachment {
            return (item as? MailSettingAttachmentModel) != nil
        } else if type == .typeSignature {
            return (item as? MailSettingSignatureModel) != nil
        } else if type == .typeOOO {
            return (item as? MailSettingOOOModel) != nil
        } else if type == .typeDraftLanguage {
            return (item as? MailDraftLangModel) != nil
        } else if type == .typeWebImage {
            return (item as? MailSettingWebImageModel) != nil
        } else if type == .typeAutoCC {
            return (item as? MailSettingAutoCCModel) != nil
        }
        
        return false
    }
    private func updatePrimarySection(sectionIndex: Int, itemIndex: Int, type: updateSwitchType, enable: Bool) -> Bool {
        var updated = false
        var item = primaryAccountSetting?.settingSections?[sectionIndex].items[itemIndex]
        if type == .typePush, var pushItem = item as? MailSettingPushModel {
            updated = true
            pushItem.status = enable
            primaryAccountSetting?.settingSections?[sectionIndex].items[itemIndex] = pushItem
        } else if type == .typeAttachment, var attachmentItem = item as? MailSettingAttachmentModel {
            updated = true
            attachmentItem.location = enable ? .top : .bottom
            primaryAccountSetting?.settingSections?[sectionIndex].items[itemIndex] = attachmentItem
        } else if type == .typeUndo, var undoItem = item as? MailSettingUndoModel {
            updated = true
            undoItem.status = enable
            primaryAccountSetting?.settingSections?[sectionIndex].items[itemIndex] = undoItem
        } else if type == .typeSignature, var sigItem = item as? MailSettingSignatureModel {
            updated = true
            sigItem.status = enable
            primaryAccountSetting?.settingSections?[sectionIndex].items[itemIndex] = sigItem
        } else if type == .typeOOO, var oooItem = item as? MailSettingOOOModel {
            updated = true
            oooItem.status = enable
            primaryAccountSetting?.settingSections?[sectionIndex].items[itemIndex] = oooItem
        } else if type == .typeWebImage, var webImageItem = item as? MailSettingWebImageModel {
            updated = true
            webImageItem.shouldIntercept = !enable
            primaryAccountSetting?.settingSections?[sectionIndex].items[itemIndex] = webImageItem
        } else if type == .typeAutoCC, var autoCCItem = item as? MailSettingAutoCCModel {
            updated = true
            autoCCItem.status = enable
            primaryAccountSetting?.settingSections?[sectionIndex].items[itemIndex] = autoCCItem
        }
        return updated
    }

    private func updateMailClientSyncRangeSettingSection(accountId: String?, detail: String) {
        guard let accountListSettings = accountListSettings, accountListSettings.count > 1 else {
            return
        }
        for (index, setting) in accountListSettings.enumerated() where
            !setting.account.mailAccountID.isEmpty && setting.account.mailAccountID == accountId {
            guard let settingSections = setting.settingSections else {
                continue
            }
            for (sectionIndex, section) in settingSections.enumerated() {
                if var model = section.items.first as? MailSettingSyncRangeModel {
                    model.detail = detail
                    self.accountListSettings?[index].settingSections?[sectionIndex].items[0] = model
                    refreshPublish.onNext(())
                }
            }
        }
    }

    private func updateSettingSection(accountId: String?, sectionIndex: Int, itemIndex: Int, type: updateSwitchType, enable: Bool) -> Bool {
        guard let accountId = accountId else {
            return false
        }
        var updated = false
        var item = getAccountSetting(of: accountId)?.settingSections?[sectionIndex].items[itemIndex]
        if type == .typePush, var pushItem = item as? MailSettingPushModel {
            updated = true
            pushItem.status = enable
            getAccountSetting(of: accountId)?.settingSections?[sectionIndex].items[itemIndex] = pushItem
        } else if type == .typeUndo, var undoItem = item as? MailSettingUndoModel {
            updated = true
            undoItem.status = enable
            getAccountSetting(of: accountId)?.settingSections?[sectionIndex].items[itemIndex] = undoItem
        } else if type == .typeSignature, var sigItem = item as? MailSettingSignatureModel {
            updated = true
            sigItem.status = enable
            getAccountSetting(of: accountId)?.settingSections?[sectionIndex].items[itemIndex] = sigItem
        } else if type == .typeOOO, var oooItem = item as? MailSettingOOOModel {
            updated = true
            oooItem.status = enable
            getAccountSetting(of: accountId)?.settingSections?[sectionIndex].items[itemIndex] = oooItem
        }
        return updated
    }
    private func updateMultiOOOAndSig(type: updateSwitchType, enable: Bool, accountId: String) {
        guard type == .typeOOO || type == .typeSignature else {
            return
        }
        guard accountListSettings != nil && accountListSettings!.count > 1 else {
            return
        }
        for (index, setting) in accountListSettings!.enumerated() where
            !setting.account.mailAccountID.isEmpty && setting.account.mailAccountID == accountId {
            guard setting.settingSections != nil else {
                continue
            }
            for (sectionIndex, section) in setting.settingSections!.enumerated() {
                if type == .typeSignature,
                   var model = section.items.first as? MailSettingSignatureModel {
                    model.status = enable
                    accountListSettings?[index].settingSections?[sectionIndex].items[0] = model
                    refreshPublish.onNext(())
                } else if type == .typeOOO,
                          var oooModel = section.items.first as? MailSettingOOOModel {
                        oooModel.status = enable
                     accountListSettings?[index].settingSections?[sectionIndex].items[0] = oooModel
                    refreshPublish.onNext(())
                }
            }
        }
    }
    func getEmailAndName(_ accountId: String) -> (String?, String?) {
        let setting = accountListSettings?.first(where: { setting in
            setting.account.mailAccountID == accountId
        })
        var email = setting?.account.accountAddress ?? ""
        var name = setting?.account.accountName ?? ""
        return (email, name)
    }

    private func updateSwitch(_ enable: Bool, _ type: updateSwitchType, _ language: MailReplyLanguage? = nil, _ accountId: String? = nil) {
        var sectionIndex = -1
        var itemIndex = -1
        for (sectionIdx, section) in (primaryAccountSetting?.settingSections ?? []).enumerated() {
            for (itemIdx, item) in (section.items ?? []).enumerated()
            where  checkItemType(item: item, type: type) {
                sectionIndex = sectionIdx
                itemIndex = itemIdx
                break
            }
        }
        for (sectionIdx, section) in (getAccountSetting(of: accountId)?.settingSections ?? []).enumerated() {
            for (itemIdx, item) in (section.items ?? []).enumerated()
            where  checkItemType(item: item, type: type) {
                sectionIndex = sectionIdx
                itemIndex = itemIdx
                break
            }
        }
        if sectionIndex != -1, itemIndex != -1 {
            let needUpdate = updatePrimarySection(sectionIndex: sectionIndex, itemIndex: itemIndex, type: type, enable: enable) ||
            updateSettingSection(accountId: accountId, sectionIndex: sectionIndex, itemIndex: itemIndex, type: type, enable: enable)
            // 乐观刷新
            if needUpdate {
                refreshPublish.onNext(())
            }
            // 语言刷新
            if let lan = language, type == .typeDraftLanguage {
                var item = primaryAccountSetting?.settingSections?[sectionIndex].items[itemIndex]
                if var draftItem = item as? MailDraftLangModel {
                    draftItem.currentLanguage = lan
                    primaryAccountSetting?.settingSections?[sectionIndex].items[itemIndex] = draftItem
                    refreshPublish.onNext(())
                }
            }
        }
        // 多账号刷新
        if let accountId = accountId {
            updateMultiOOOAndSig(type: type, enable: enable, accountId: accountId)
        } else if let accountId = primaryAccountSetting?.account.mailAccountID {
            updateMultiOOOAndSig(type: type, enable: enable, accountId: accountId)
        }

    }

    // 临时增加的乐观操作，Setting的数据流转有问题，待梳理
    func updateUndoSwitch(_ enable: Bool) {
        updateSwitch(enable, .typeUndo)
    }

    func updatePushSwitch(_ enable: Bool) {
        updateSwitch(enable, .typePush)
    }

    func updateAttachmentSwitch(_ enable: Bool) {
        updateSwitch(enable, .typeAttachment)
    }

    func updateSignatureSwitch(_ enable: Bool, _ accountId: String) {
        updateSwitch(enable, .typeSignature, nil, accountId)
    }

    func updateOOOSwitch(_ enable: Bool, _ accountId: String) {
        updateSwitch(enable, .typeOOO, nil, accountId)
    }
    
    func updateWebImageSwitch(enable: Bool) {
        updateSwitch(enable, .typeWebImage)
    }

    func updateAutoCCSwitch(enable: Bool) {
        updateSwitch(enable, .typeAutoCC)
    }

    func updateDraftLanguage(_ language: MailReplyLanguage?) {
        if let len = language {
            updateSwitch(false, .typeDraftLanguage, len)
        }
    }

    func updateAttachmentSetting(_ location: MailAttachmentLocation) {
        let event = NewCoreEvent(event: .email_lark_setting_click)
        event.params = ["target": "none",
                        "click": "network_image",
                        "attachment_position": location == .top ? "message_top" : "message_bottom"]
        event.post()
        if var account = Store.settingData.getCachedPrimaryAccount() {
            Store.settingData.updateSettings(.attachmentLocation(location), of: &account)
        }
    }
    
    func updateWebImageSetting(shouldIntercept: Bool) {
        let event = NewCoreEvent(event: .email_lark_setting_click)
        event.params = ["target": "none",
                        "click": "network_image",
                        "switch_status": shouldIntercept ? "ask_me" : "always_display"]
        event.post()
        if var account = Store.settingData.getCachedPrimaryAccount() {
            Store.settingData.updateSettings(.webImageDisplay(enable: !shouldIntercept), of: &account)
        }
    }

    func updateUndoSetting(enable: Bool, time: Int64) {
        if var account = Store.settingData.getCachedPrimaryAccount() {
            Store.settingData.updateSettings(.undoSend(enable: enable, undoTime: time), of: &account)
        }
    }

    func updateAutoCCSetting(enable: Bool, type: MailAutoCCType) {
        if var account = Store.settingData.getCachedPrimaryAccount() {
            Store.settingData.updateSettings(.autoCC(enable: enable, type: type), of: &account)
        }
    }

    func updateViewModel(by account: MailAccount) {
        if let primaryAccountId = Store.settingData.getCachedPrimaryAccount()?.mailAccountID,
           primaryAccountId != account.mailAccountID {
            mailAssertionFailure("[MailSetting] should updateViewModel with primary account.")
        }
        markDirty = false
        let userType = account.mailSetting.userType
        showFreeBind  = accountContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) && userType == .newUser

        primaryAccountSetting = MailAccountSetting(account: account)
        primaryAccountSetting?.settingSections = createPrimaryAccountSettingSection(by: account)
        primaryAccountSetting?.delegate = self
        primaryAccountSetting?.isAccountDetailSetting = false
        accountListSettings = createAccountListSettings(in: account)
        refreshPublish.onNext(())
    }

    func createAccountListSettings(in account: MailAccount?) -> [MailAccountSetting] {
        guard let account = account else { return [] }
        let primaryAccountSetting = MailAccountSetting(account: account)
        primaryAccountSetting.settingSections = createAccountSettingSections(by: account)
        primaryAccountSetting.isAccountDetailSetting = true
        var tempSettings: [MailAccountSetting] = [primaryAccountSetting]
        account.sharedAccounts.forEach { (shareAccount) in
            let sharedAccountSetting = MailAccountSetting(account: shareAccount)
            sharedAccountSetting.settingSections = createAccountSettingSections(by: shareAccount)
            sharedAccountSetting.delegate = self
            sharedAccountSetting.isAccountDetailSetting = true
            tempSettings.append(sharedAccountSetting)
        }
        return tempSettings
    }
}

// MARK: MailAccountSettingDelegate
extension MailSettingViewModel: MailAccountSettingDelegate {
    func resetData() {
        self.reloadLocalDataPublish.onNext(())
    }

    func getHUDView() -> UIView? {
        if let vc = viewController {
            return vc.view
        }
        return nil
    }
}

extension MailSettingViewModel: MailApmHolderAble {}

// MARK: Mail Client Helper
extension MailSettingViewModel {
    /// 解除绑定
    private func didClickUnbindBtn() {
        guard let vc = viewController else { return }
        vc.alertHelper?.showUnbindConfirmAlert(keepUsing: {},
                                                     unbindEmail: { [weak self] in
            guard let `self` = self else { return }
            self.updateMailClientTabStatus(false)
        }, fromVC: vc)
    }

    private func didClickDeleteBtn(accountID: String, provider: MailTripartiteProvider) {
        guard let vc = viewController else { return }
        vc.alertHelper?.showDeleteConfirmAlert(keepUsing: {},
                                                     deleteEmail: { [weak self] in
            guard let `self` = self else { return }
            self.updateMailClientStatus(accountID, provider: provider)
            let kvStore = MailKVStore(space: .user(id: self.accountContext.user.userID), mSpace: .global)
            kvStore.removeValue(forKey: "mail_client_account_onboard_\(accountID)")
        }, fromVC: vc)
    }

    // MARK: requset
    private func updateMailClientTabStatus(_ status: Bool) {
        guard let vc = viewController else { return }
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Setting_Unbinding, on: vc.view, disableUserInteraction: false)
        MailDataServiceFactory
            .commonDataService?
            .updateMailClientTabSetting(status: status)
            .subscribe(onNext: { [weak self] (resp) in
                guard let `self` = self else { return }
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Setting_UnbindSuccess, on: vc.view)
                if resp.hasAccount {
                    self.updateViewModel(by: resp.account)
                } else {
                    self.reloadLocalDataPublish.onNext(())
                }
            }, onError: { (error) in
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Setting_UnbindFailed, on: vc.view)
                MailSettingViewModel.logger.error("updateMailClientTabStatus fail error:\(error)")
            }).disposed(by: disposeBag)
    }

    private func updateMailClientStatus(_ accountID: String, provider: MailTripartiteProvider) {
        guard let vc = viewController else { return }
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Normal_Loading, on: vc.view, disableUserInteraction: false)
        let event = MailAPMEvent.MailClientDeleteAccount()
        event.markPostStart()
        apmHolder[MailAPMEvent.MailClientDeleteAccount.self] = event
        MailDataServiceFactory
            .commonDataService?
            .deleteTripartiteAccount(accountID: accountID)
            .subscribe(onNext: { [weak self] (resp) in
                guard let `self` = self else { return }
                let provider = MailAPMEvent.MailClientDeleteAccount.EndParam.provider(provider.apmValue())
                event.endParams.append(provider)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                event.postEnd()
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Setting_UnbindSuccess, on: vc.view)
                self.reloadLocalDataPublish.onNext(())
                Store.settingData.deleteAccountFromList(accountID)
                if Store.settingData.getCachedCurrentAccount()?.mailAccountID != accountID {
                    vc.navigator?.pop(from: vc)
                }
            }, onError: { (error) in
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Setting_UnbindFailed, on: vc.view)
                MailSettingViewModel.logger.error("updateMailClientTabStatus fail error:\(error)")
                let provider = MailAPMEvent.MailClientDeleteAccount.EndParam.provider(provider.apmValue())
                event.endParams.append(provider)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                event.postEnd()
            }).disposed(by: disposeBag)
    }

    private func createPrimaryAccountSettingSection(by account: MailAccount) -> [MailSettingSectionModel] {
        let setting = account.mailSetting
        let accountId = account.mailAccountID
        var settingSections: [MailSettingSectionModel] = []

        let hasSharedAccount = !(Store.settingData.getCachedAccountList()?.filter({ $0.mailAccountID != accountId }).isEmpty ?? true)
        let showDetail: Bool = Store.settingData.clientStatus == .saas ? !account.sharedAccounts.isEmpty : true
        let accountStatus = account.mailSetting.emailClientConfigs.first?.configStatus
        let userType = account.mailSetting.userType
        let mailClient = Store.settingData.hasMailClient()  // lms搬家orgc未认证均为mailClient
        let onlyMailClient = Store.settingData.clientStatus == .mailClient
        /// 有三方+非法主账号，显示主账号，设置项与纯三方保持一致

        /// - 1. Account List
        var mailAccountModels = [MailSettingItemProtocol]()
        var primaryAccountModel = MailSettingItemFactory.createAccountModel(name: account.accountName,
                                                                            address: account.accountAddress,
                                                                            accountId: account.mailAccountID,
                                                                            isShared: false,
                                                                            showDetail: showDetail,
                                                                            showTag: hasSharedAccount,
                                                                            userType: userType,
                                                                            status: accountStatus)
        let hasSaas = (Store.settingData.clientStatus == .saas || Store.settingData.clientStatus == .coExist) && (primaryAccountModel.type == .accountAvailable || primaryAccountModel.type == .exchangeAvailable)
        let isFreeBindNoAccount = accountContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) && userType == .newUser
        if (!mailClient || (mailClient && userType != .noPrimaryAddressUser && !Store.settingData.isInIMAPFlow(account))) && !isFreeBindNoAccount {
            mailAccountModels.append(primaryAccountModel)
        }

        var sharedAccounts = account.sharedAccounts
        if Store.settingData.clientStatus == .saas {
            sharedAccounts = sharedAccounts.filter({ $0.mailSetting.userType != .tripartiteClient })
        }
        if hasSharedAccount {
            mailAccountModels.append(contentsOf: sharedAccounts
                                        .sorted{ $0.mailSetting.userType.priorityValue() > $1.mailSetting.userType.priorityValue() }
                                        .map {
                return MailSettingItemFactory.createAccountModel(name: $0.accountName,
                                                                  address: $0.accountAddress,
                                                                  accountId: $0.mailAccountID,
                                                                  isShared: true,
                                                                  showDetail: true,
                                                                  userType: $0.mailSetting.userType,
                                                                  status: $0.mailSetting.emailClientConfigs.first?.configStatus)
            })
        }
        if mailClient {
            let title = BundleI18n.MailSDK.Mail_ThirdClient_AddEmailAccounts
            mailAccountModels.append(MailSettingAddOperationModel(cellIdentifier: MailSettingAddOperationCell.lu.reuseIdentifier,
                                                               accountId: account.mailAccountID,
                                                               title: title))
        }
        var mailAccountSectionModel = MailSettingSectionModel(items: mailAccountModels)
        mailAccountSectionModel.headerText = BundleI18n.MailSDK.Mail_SharedEmail_AccountsTitle
        if !mailClient {
            if hasSharedAccount {
                mailAccountSectionModel.footerText = BundleI18n.MailSDK.Mail_Mailbox_PublicMailboxSettingSync
            } else {
                if userType == .oauthClient && !accountContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) {
                    mailAccountSectionModel.footerText = BundleI18n.MailSDK.Mail_Client_AccountTip()
                } else if userType == .exchangeClient {
                    mailAccountSectionModel.footerText = BundleI18n.MailSDK.Mail_Outlook_OperationWillSynchronizedToOutlook()
                }
            }
        }
        settingSections.append(mailAccountSectionModel)

        if (primaryAccountModel.type == .accountAvailable ||
            primaryAccountModel.type == .exchangeAvailable ||
            hasSharedAccount) && (!Store.settingData.isInIMAPFlow(account) && Store.settingData.getCachedCurrentAccount() != nil) {
            if !mailClient, !hasSharedAccount, accountContext.featureManager.open(FeatureKey(fgKey: .sendMailNameSetting, openInMailClient: true)) {
                let aliasSettingModel = MailSettingItemFactory.createAliasSettingModel(accountId: accountId)
                var aliasSection = MailSettingSectionModel(items: [aliasSettingModel])
                settingSections.append(aliasSection)
            }

            /// 非会话模式
            settingSections = conversationSettingConfig(account: account, settingSections: settingSections, hasSaas: hasSaas)

            /// - Attachment Location
            if accountContext.featureManager.open(.attachmentLocation, openInMailClient: true) {
                let attachmentModel = MailSettingItemFactory.createAttachmentModel(accountId: accountId, location: setting.attachmentLocation)
                let attachmentSectionModel = MailSettingSectionModel(items: [attachmentModel])
                settingSections.append(attachmentSectionModel)
            }

            /// - 2. Push Notification
            let pushSwitchStatus = setting.allNewMailNotificationSwitch
            // 未打开fg，主账号或公共账号任一开关打开都展示已开启
            let mailPushModel = MailSettingItemFactory.createMailPushModel(status: pushSwitchStatus,
                                                                           accountId: accountId,
                                                                           hasMore: true) { [weak self] status in
                self?.getAccountSetting(of: Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? "")?.updateSettings(.newMailNotification(enable: status))
                self?.getAccountSetting(of: accountId)?.updateSettings(.newMailNotification(enable: status))
            }
            let mailPushSectionModel = MailSettingSectionModel(items: [mailPushModel])
            settingSections.append(mailPushSectionModel)
            
            if accountContext.featureManager.open(.interceptWebImage, openInMailClient: true) {
                /// - Intercept Web Image
                let webImageModel =  MailSettingItemFactory.createWebImageModel(accountId: accountId, shouldIntercept: !setting.webImageDisplay)
                let webImageSectionModel = MailSettingSectionModel(items: [webImageModel])
                settingSections.append(webImageSectionModel)
            }
            
            /// - 3. Smart Inbox
            if setting.smartInboxVisible && !accountContext.featureManager.open(.aiBlock) && hasSaas {
                let smartInboxModel = MailSettingItemFactory.createSmartInboxModel(status: setting.smartInboxMode,
                                                                                   accountId: accountId) { [weak self] status in
                    guard let self = self else { return }
                    self.getAccountSetting(of: accountId)?.updateSettings(.smartInboxMode(enable: status))
                    MailTracker.log(event: Homeric.EMAIL_SMARTINBOX_USABLE_CHANGE, params: ["enable": status ? "enable" : "disable"])
                }
                var smartInboxSection = MailSettingSectionModel(items: [smartInboxModel])
                smartInboxSection.footerText = mailClient ? BundleI18n.MailSDK.Mail_ThirdClient_SmartInboxWontApply : BundleI18n.MailSDK.Mail_SmartInbox_OnboardingSettingTipContentMobile
                settingSections.append(smartInboxSection)
            }
            settingSections = strangerSettingConfig(account: account, settingSections: settingSections, hasSaas: hasSaas)

            /// - 5. undo
            if hasSaas {
                let undoModel = MailSettingItemFactory.createUndoModel(status: setting.undoSendEnable, accountId: accountId)
                var undoSection = MailSettingSectionModel(items: [undoModel])
                if mailClient {
                    undoSection.footerText = BundleI18n.MailSDK.Mail_ThirdClient_SettingsWontApplyToConnectedAccounts
                }
                settingSections.append(undoSection)
            }

            /// - 回复前缀
            let lastSection = MailSettingSectionModel(
                items: [
                    MailDraftLangModel(
                        cellIdentifier: MailSettingDraftLandCell.lu.reuseIdentifier,
                        accountId: accountId,
                        title: BundleI18n.MailSDK.Mail_Setting_SubjectPrefix,
                        currentLanguage: setting.replyLanguage)
                ])
            settingSections.append(lastSection)

            /// - 自动抄送或密送自己
            if accountContext.featureManager.realTimeOpen(.autoCC, openInMailClient: true) {
                let autoCCModel = MailSettingItemFactory.createAutoCCModel(status: setting.autoCcAction.autoCcEnable, accountId: accountId)
                var autoCCSection = MailSettingSectionModel(items: [autoCCModel])
                autoCCSection.footerText = BundleI18n.MailSDK.Mail_Settings_AutoCcOrBcc_Desc
                settingSections.append(autoCCSection)
            }
        }

        /// show in single account
        settingSections = singleAccountSettingConfig(account: account, hasSharedAccount: hasSharedAccount, settingSections: settingSections, primaryAccountModel: primaryAccountModel)

        return settingSections
    }
    private func singleAccountSettingConfig(account: MailAccount,
                                            hasSharedAccount: Bool,
                                            settingSections: [MailSettingSectionModel],
                                            primaryAccountModel: MailSettingAccountModel) -> [MailSettingSectionModel] {
        var sections = settingSections
        let setting = account.mailSetting
        let accountId = account.mailAccountID
        let userType = account.mailSetting.userType
        let mailClient = Store.settingData.hasMailClient()  // lms搬家orgc未认证均为mailClient
        
        if !hasSharedAccount && !mailClient {
            if primaryAccountModel.type == .accountAvailable ||
                primaryAccountModel.type == .exchangeAvailable ||
                hasSharedAccount {

                /// - 6. Signature
                let signatureModel = MailSettingItemFactory.createSignatureModel(status: setting.signature.enabled, accountId: accountId)
                var signatureSection = MailSettingSectionModel(items: [signatureModel])
                var tipsText = ""
                if userType == .tripartiteClient {
                    tipsText = BundleI18n.MailSDK.Mail_ThirdClient_SignatureInTheEnd
                } else {
                    tipsText = BundleI18n.MailSDK.Mail_Setting_Signatureguide
                }
                signatureSection.footerText = tipsText
                sections.append(signatureSection)
                
                /// - 7. OOO
                let oooModel = MailSettingItemFactory.createOOOModel(status: setting.vacationResponder.enable, accountId: accountId)
                var oooSection = MailSettingSectionModel(items: [oooModel])
                oooSection.footerText = BundleI18n.MailSDK.Mail_OOO_Title_Tip
                sections.append(oooSection)
                
                /// - 8. Cache
                if accountContext.featureManager.open(.offlineCache, openInMailClient: false), setting.enablePreload {
                    let cacheModel = MailSettingItemFactory.createCacheModel(accountId: accountId,
                                                                             detail: cacheSettingRes[accountId]?.timeStamp.detail() ?? "")
                    var cacheSection = MailSettingSectionModel(items: [cacheModel])
                    cacheSection.footerText = BundleI18n.MailSDK.Mail_EmailCache_Setting_Hover
                    sections.append(cacheSection)
                    updateCacheRangeStatus(model: cacheModel)
                }
                
                /// - 8.AttachmentsManager 需要下发是否放开
                if accountContext.featureManager.open(.largeAttachmentManagePhase2) {
                    let attachmentModel = MailSettingItemFactory.createAttachmentsModel(accountId: accountId,
                                                                                        byte: attachmentManageSettingRes[accountId]?.capacity ?? 0) // 超大附件走独立入口
                    let attachmentsSection = MailSettingSectionModel(items: [attachmentModel])
                    sections.append(attachmentsSection)
                    updateAttachmentsCapacity(model: attachmentModel)
                }
                /// 8. UnLink or ReLink
                sections = bindSettingConfig(account: account, settingSections: sections, primaryAccountModel: primaryAccountModel)
            }
        }
        return sections
    }
    
    private func bindSettingConfig(account: MailAccount, settingSections: [MailSettingSectionModel], primaryAccountModel: MailSettingAccountModel) -> [MailSettingSectionModel] {
        var sections = settingSections
        let setting = account.mailSetting
        let accountId = account.mailAccountID
        let mailClient = Store.settingData.hasMailClient()  // lms搬家orgc未认证均为mailClient
        if setting.userType != .larkServer &&
            setting.userType != .gmailApiClient &&
            setting.userType != .exchangeApiClient && !mailClient {
            /// - 8. UnLink or ReLink
            if primaryAccountModel.type == .accountAvailable ||
                primaryAccountModel.type == .exchangeAvailable {
                let title = accountContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) ?   BundleI18n.MailSDK.Mail_Settings_UnlinkAccount_Button : BundleI18n.MailSDK.Mail_Setting_UnlinkEmail
                let unlinkModel = MailSettingItemFactory.createUnlinkModel(accountId: accountId, subTitle: title) {
                    if let accountSetting = self.getAccountSetting(of: accountId) {
                        if accountSetting.account.isShared {
                            /// 解绑共享账号
                            assertionFailure("shared account can't unbind")
                        } else {
                            /// 解绑主账户
                            self.didClickUnbindBtn()
                        }
                    }
                }
                let unlinkSection = MailSettingSectionModel(items: [unlinkModel])
                sections.append(unlinkSection)
            } else if primaryAccountModel.type == .refreshAccount {
                // relink
                var type: MailSettingRelinkModel.LinkType = primaryAccountModel.type == .refreshAccount ? .gmail : .exchange
                if accountContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false), let mailType = setting.emailClientConfigs.first?.mailType {
                    switch mailType {
                    case .gmail:
                        type = .gmail
                    case .exchange:
                        type = .exchange
                    case .imap:
                        type = .mailClient
                    @unknown default:
                        type = .gmail
                    }
                }
                let relinkModel = MailSettingItemFactory.createRelinkModel(accountId: accountId, type: type, provider: .other)
                let relinkSection = MailSettingSectionModel(items: [relinkModel])
                sections.append(relinkSection)
            }
        }
        return sections
    }
    private func conversationSettingConfig(account: MailAccount, settingSections: [MailSettingSectionModel], hasSaas: Bool) -> [MailSettingSectionModel] {
        var sections = settingSections
        let setting = account.mailSetting
        let accountId = account.mailAccountID
        let mailClient = Store.settingData.hasMailClient()  // lms搬家orgc未认证均为mailClient
        if hasSaas {
            let hasMore = FeatureManager.open(.conversationSetting)
            var footerText = ""
            if !hasMore {
                footerText = BundleI18n.MailSDK.Mail_Settings_ChatsModeDescMobile
            }
            if mailClient {
                footerText = BundleI18n.MailSDK.Mail_ThirdClient_SettingsWontApplyToConnectedAccounts
            }
            var conversationModeModel = MailSettingItemFactory.createConversationModeModel(status: setting.enableConversationMode,
                                                                                           accountId: accountId,
                                                                                           hasMore: hasMore,
                                                                                           detail: footerText) { [weak self] status in
                self?.getAccountSetting(of: accountId)?.updateSettings(.conversationMode(enable: status))
            }
            if accountContext.featureManager.open(FeatureKey(fgKey: .threadCustomSwipeActions, openInMailClient: true)) {
                let swipeActionsModel = MailSettingItemFactory.createMailSwipeActionsModel(accountId: accountId)

                var conversationAndSwipeActionSection = MailSettingSectionModel(items: [conversationModeModel, swipeActionsModel])
                sections.append(conversationAndSwipeActionSection)
            } else {
                conversationModeModel.detail = ""
                var conversationSection = MailSettingSectionModel(items: [conversationModeModel])
                if !footerText.isEmpty {
                    conversationSection.footerText = footerText
                }
                sections.append(conversationSection)
            }
        } else if accountContext.featureManager.open(FeatureKey(fgKey: .threadCustomSwipeActions, openInMailClient: true)) {
            let swipeActionsModel = MailSettingItemFactory.createMailSwipeActionsModel(accountId: accountId)
            sections.append(MailSettingSectionModel(items: [swipeActionsModel]))
        }
        return sections
    }

    private func strangerSettingConfig(account: MailAccount, settingSections: [MailSettingSectionModel], hasSaas: Bool) -> [MailSettingSectionModel] {
        var sections = settingSections
        let setting = account.mailSetting
        let accountId = account.mailAccountID
        if accountContext.featureManager.open(FeatureKey(fgKey: .stranger, openInMailClient: true)) && hasSaas {
            MailLogger.info("[mail_stranger] settingvm stranger enable: \(setting.enableStranger)")
            strangerModel = MailSettingItemFactory.createStrangerModel(status: setting.enableStranger,
                                                                           accountId: accountId) { [weak self] status in
                guard let self = self else { return status }
                MailLogger.info("[mail_stranger] setting modify stranger enable: \(status) switchConfirm: \(self.strangerModel?.switchConfirm) strangerModelSwitchConfirm: \(self.strangerModelSwitchConfirm)")
                if !status && self.strangerModelSwitchConfirm == true {
                    // 二次确认弹窗
                    let alert = LarkAlertController()
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_StrangerInbox_TurnOffStrangerEmailScreen_Title)
                    alert.setContent(text: BundleI18n.MailSDK.Mail_StrangerInbox_TurnOffStrangerEmailScreen_Desc, alignment: .center)
                    alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_StrangerInbox_TurnOffStrangerEmailScreen_Cancel_Button) {
                        self.strangerModelSwitchConfirm = true
                        (self.viewController as? MailSettingViewController)?.updateStrangerModelSwitch(true)
                    }
                    alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_StrangerInbox_TurnOffStrangerEmailScreen_TurnOff_Button, dismissCompletion: {
                        self.strangerModelSwitchConfirm = false
                        // UI也要更新一道
                        (self.viewController as? MailSettingViewController)?.updateStrangerModelSwitch(false)
                    })
                    if let vc = self.viewController {
                        vc.navigator?.present(alert, from: vc)
                    }
                    return setting.enableStranger
                } else {
                    if var priAcc = Store.settingData.getCachedPrimaryAccount(), priAcc.mailSetting.enableStranger != status {
                        MailLogger.info("[mail_stranger] setting modify stranger enable: \(status) -- request sent")
                        Store.settingData.updateSettings(.strangerMode(enable: status), of: &priAcc, onSuccess: { [weak self] in
                            self?.strangerModelSwitchConfirm = true
                        }, onError: { [weak self] _ in
                            self?.strangerModelSwitchConfirm = true
                        })
                    }
                    return status
                }
            }
            if let strangerModel = strangerModel {
                var strangerSection = MailSettingSectionModel(items: [strangerModel])
                strangerSection.footerText = BundleI18n.MailSDK.Mail_StrangerInbox_Setting_Desc
                sections.append(strangerSection)
            }
        }
        return sections
    }
    private func createAccountSettingSections(by account: MailAccount) -> [MailSettingSectionModel] {
        let setting = account.mailSetting
        let accountId = account.mailAccountID
        var settingSections: [MailSettingSectionModel] = []
        let mailClient = Store.settingData.hasMailClient()
        /// Sections:
        /// - Account Info
        /// - MailAlias
        /// - Signature
        /// - OOO
        /// - Unlink

        /// ---------------
        /// - 1. Account Info
        let accountInfoModel = MailSettingItemFactory.createAccountInfoModel(name: account.accountName,
                                                                             address: account.accountAddress,
                                                                             accountId: account.mailAccountID,
                                                                             isShared: account.isShared,
                                                                             type: account.mailSetting.userType,
                                                                             status: account.mailSetting.emailClientConfigs.first?.configStatus)
        let accountInfoSection = MailSettingSectionModel(items: [accountInfoModel])
        settingSections.append(accountInfoSection)
        // 账号过期
        if accountInfoModel.type == .refreshAccount {
            // relink
            let relinkModel = MailSettingItemFactory.createRelinkModel(accountId: accountId, type: MailSettingRelinkModel.LinkType.gmail, provider: .other)
            let relinkSection = MailSettingSectionModel(items: [relinkModel])
            settingSections.append(relinkSection)
            return settingSections
        } else if accountInfoModel.type == .reVerify {
            // reVerify
            let reVerifyModel = MailSettingItemFactory.createRelinkModel(accountId: accountId, type: MailSettingRelinkModel.LinkType.mailClient, provider: account.provider)
            let reVerifySection = MailSettingSectionModel(items: [reVerifyModel])
            settingSections.append(reVerifySection)
            let deleteModel = MailSettingItemFactory.createUnlinkModel(accountId: accountId,
                                                                       subTitle: BundleI18n.MailSDK.Mail_ThirdClient_DeleteAccount) { [weak self] in
                if self?.getAccountSetting(of: accountId) != nil {
                    /// 删除三方账户
                    self?.didClickDeleteBtn(accountID: accountId, provider: account.provider)
                }
            }
            let deleteSection = MailSettingSectionModel(items: [deleteModel])
            settingSections.append(deleteSection)
            return settingSections
        }

        if mailClient && setting.userType == .tripartiteClient && account.protocol != .exchange {
            let senderAliasModel = MailSettingSenderAliasModel(cellIdentifier: MailSettingStatusCell.lu.reuseIdentifier,
                                                               accountId: accountId, title: BundleI18n.MailSDK.Mail_ThirdClient_AccountNameMobile)
            let senderAliasSection = MailSettingSectionModel(items: [senderAliasModel])
            settingSections.append(senderAliasSection)
        } else if setting.userType != .tripartiteClient, accountContext.featureManager.open(FeatureKey(fgKey: .sendMailNameSetting, openInMailClient: true)) {
            /// ---------------
            /// - 2. MailAlias
            let aliasSettingModel = MailSettingItemFactory.createAliasSettingModel(accountId: accountId)
            var aliasSection = MailSettingSectionModel(items: [aliasSettingModel])
            settingSections.append(aliasSection)
        }

        /// ---------------
        /// - 3. Signature
        let signatureModel = MailSettingItemFactory.createSignatureModel(status: setting.signature.enabled, accountId: accountId)
        var signatureSection = MailSettingSectionModel(items: [signatureModel])
        var tipsText = ""
        if setting.userType == .tripartiteClient {
            signatureSection.footerText = BundleI18n.MailSDK.Mail_ThirdClient_SignatureInTheEnd
        } else {
            signatureSection.footerText = BundleI18n.MailSDK.Mail_Setting_Signatureguide
        }
        settingSections.append(signatureSection)

        /// ---------------
        /// - 4. OOO
        if setting.userType != .tripartiteClient {
            let oooModel = MailSettingItemFactory.createOOOModel(status: setting.vacationResponder.enable, accountId: accountId)
            var oooSection = MailSettingSectionModel(items: [oooModel])
            oooSection.footerText = BundleI18n.MailSDK.Mail_OOO_Title_Tip
            settingSections.append(oooSection)
        }
        
        
        /// - 8. Cache
        if accountContext.featureManager.open(FeatureKey(fgKey: .offlineCache, openInMailClient: true)) && setting.userType != .tripartiteClient && setting.enablePreload {
            let cacheModel = MailSettingItemFactory.createCacheModel(accountId: accountId,
                                                                     detail: cacheSettingRes[accountId]?.timeStamp.detail() ?? "")
            var cacheSection = MailSettingSectionModel(items: [cacheModel])
            cacheSection.footerText = BundleI18n.MailSDK.Mail_EmailCache_Setting_Hover
            settingSections.append(cacheSection)
            updateCacheRangeStatus(model: cacheModel)
        }
        /// - 5. AttachmentsManager
        if accountContext.featureManager.open(.largeAttachmentManagePhase2) {
            if setting.userType != .tripartiteClient {
                let attachmentModel = MailSettingItemFactory.createAttachmentsModel(accountId: accountId,
                                                                                    byte: attachmentManageSettingRes[accountId]?.capacity ?? 0) // 超大附件走独立入口
                let attachmentsSection = MailSettingSectionModel(items: [attachmentModel])
                        settingSections.append(attachmentsSection)
                updateAttachmentsCapacity(model: attachmentModel)
            }
        }
        
        if mailClient && setting.userType == .tripartiteClient {
            if account.loginPassType == .password { // 5.18 token登录屏蔽设置页
                let serverConfigModel = MailSettingServerConfigModel(cellIdentifier: MailSettingStatusCell.lu.reuseIdentifier,
                                                                     accountId: accountId, title: BundleI18n.MailSDK.Mail_ThirdClient_AccountSettings)
                let serverConfigSection = MailSettingSectionModel(items: [serverConfigModel])
                settingSections.append(serverConfigSection)
            }

            /// - EAS设置项
            if accountContext.featureManager.open(.eas, openInMailClient: true), account.protocol == .exchange {
                let syncRangeModel = MailSettingItemFactory.createSyncRangeModel(accountId: accountId, detail: "")
                var syncRangeSection = MailSettingSectionModel(items: [syncRangeModel])
                syncRangeSection.footerText = BundleI18n.MailSDK.Mail_Shared_AddEAS_AccessMoreEmailsAfterSync_Tooltip
                settingSections.append(syncRangeSection)
                updateMailClientSyncRangeStatus(accountId: accountId)
            }

            let deleteModel = MailSettingItemFactory.createUnlinkModel(accountId: accountId,
                                                                       subTitle: BundleI18n.MailSDK.Mail_ThirdClient_DeleteAccount) { [weak self] in
                if self?.getAccountSetting(of: accountId) != nil {
                    /// 删除三方账户
                    self?.didClickDeleteBtn(accountID: accountId, provider: account.provider)
                }
            }
            let deleteSection = MailSettingSectionModel(items: [deleteModel])
            settingSections.append(deleteSection)
        }

        /// ---------------
        /// - 6. UnLink
        if (!mailClient || (mailClient && setting.userType != .tripartiteClient))
            && !account.isShared && setting.userType != .larkServer
            && setting.userType != .gmailApiClient && setting.userType != .exchangeApiClient {
            let unlinkModel = MailSettingItemFactory.createUnlinkModel(accountId: accountId, subTitle: BundleI18n.MailSDK.Mail_Setting_UnlinkEmail) {
                if let accountSetting = self.getAccountSetting(of: accountId) {
                    if accountSetting.account.isShared {
                        /// 解绑共享账号
                        assertionFailure("shared account can't unbind")
                    } else {
                        /// 解绑主账户
                        self.didClickUnbindBtn()
                    }
                }
            }
            let unlinkSection = MailSettingSectionModel(items: [unlinkModel])
            settingSections.append(unlinkSection)
        }
        return settingSections
    }

    func requestAttachmentsCapacity(model: MailSettingAttachmentsModel) {
        guard accountContext.featureManager.open(.largeAttachmentManagePhase2, openInMailClient: true),
              let account = Store.settingData.getCachedAccountList()?.first(where: { $0.mailAccountID == model.accountId }),
              account.mailSetting.userType != .tripartiteClient else { return }
        Store.fetcher?.largeAttachmentCapacityRequest(accountID: model.accountId).subscribe{ [weak self] resp in
            guard resp.capacity >= 0 else {
                return
            }
            self?.attachmentManageSettingRes[model.accountId] = resp
            model.byte = resp.capacity
            model.$capacityChange.accept(.refresh)
        } onError: { err in
            MailLogger.debug("[attachment_large] requestCapacity err \(err)")
        }.disposed(by: self.disposeBag)
    }

    func updateAttachmentsCapacity(model: MailSettingAttachmentsModel, forceUpdate: Bool = false) {
        guard accountContext.featureManager.open(.largeAttachmentManagePhase2, openInMailClient: true),
              let account = Store.settingData.getCachedAccountList()?.first(where: { $0.mailAccountID == model.accountId }),
              account.mailSetting.userType != .tripartiteClient else { return }
        if !forceUpdate, let resp = attachmentManageSettingRes[model.accountId] {
            model.byte = resp.capacity
            model.$capacityChange.accept(.refresh)
        } else {
            self.requestAttachmentsCapacity(model: model)
        }
    }

    func getCacheRangeStatus(model: MailSettingCacheModel) {
        guard accountContext.featureManager.open(.offlineCache, openInMailClient: true),
              let account = Store.settingData.getCachedAccountList()?.first(where: { $0.mailAccountID == model.accountId }),
              account.mailSetting.userType != .tripartiteClient else { return }
        Store.fetcher?.mailGetPreloadTimeStamp(accountID: model.accountId)
            .subscribe(onNext: { [weak self] response in
                guard let `self` = self else { return }
                MailLogger.info("[mail_preload_cache] settingvm getSyncRange success! selected range: \(response.timeStamp)")
                self.cacheSettingRes[model.accountId] = response
                model.detail = response.timeStamp.detail()
                model.$cacheStatusChange.accept(())
        }, onError: { (error) in
            MailLogger.error("[mail_preload_cache] settingvm getSyncRange fail", error: error)
        }).disposed(by: self.disposeBag)
    }

    func updateCacheRangeStatus(model: MailSettingCacheModel, forceUpdate: Bool = false) {
         guard accountContext.featureManager.open(.offlineCache, openInMailClient: true),
               let account = Store.settingData.getCachedAccountList()?.first(where: { $0.mailAccountID == model.accountId }),
               account.mailSetting.userType != .tripartiteClient else { return }
         // 需要异步接口更新到详情
        if !forceUpdate, let response = cacheSettingRes[model.accountId] {
            model.detail = response.timeStamp.detail()
            model.$cacheStatusChange.accept(())
        } else {
            self.getCacheRangeStatus(model: model)
        }
    }

    func updateMailClientSyncRangeStatus(accountId: String) {
        guard accountContext.featureManager.open(.eas, openInMailClient: true) else { return }
        // 需要异步接口更新到详情
        Store.fetcher?.getSyncRange(accountID: accountId)
            .subscribe(onNext: { [weak self] response in
                guard let `self` = self else { return }
                MailLogger.info("[mail_client_eas] getSyncRange success! selected range: \(response.range)")
                self.updateMailClientSyncRangeSettingSection(accountId: accountId, detail: response.range.title())
        }, onError: { (error) in
            MailLogger.error("[mail_client_eas] getSyncRange fail", error: error)
        }).disposed(by: self.disposeBag)
    }
}
    

// MARK: - SharedAccountChange
extension MailSettingViewModel {
    func sharedAccountChange(change: MailSharedAccountChange) {
        if change.isBind {
            bindSharedAccount(account: change.account)
        } else {
            revokeSharedAccount(account: change.account)
        }
        refreshPublish.onNext(())
    }

    /// 新增共享账号
    func bindSharedAccount(account: MailAccount) {
        let didBind = primaryAccountSetting?.account.mailSetting.sharedAccounts.contains(where: { $0.mailAccountID == account.mailAccountID }) ?? false
        if !didBind {
            let sharedAccounts: [MailAccount] = (primaryAccountSetting?.account.mailSetting.sharedAccounts ?? []) + [account]
            primaryAccountSetting?.account.mailSetting.sharedAccounts = sharedAccounts
        }
        accountListSettings = createAccountListSettings(in: primaryAccountSetting?.account)
        MailLogger.info("bindSharedAccount count: \(String(describing: accountListSettings?.count))")
    }

    /// 解绑共享账号
    func revokeSharedAccount(account: MailAccount) {
        if let sharedAccounts = primaryAccountSetting?.account.mailSetting.sharedAccounts.filter({ $0.mailAccountID != account.mailAccountID }) {
            primaryAccountSetting?.account.mailSetting.sharedAccounts = sharedAccounts
        }
        accountListSettings = createAccountListSettings(in: primaryAccountSetting?.account)
        MailLogger.info("revokeSharedAccount count: \(String(describing: accountListSettings?.count))")
    }
}


