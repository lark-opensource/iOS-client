//
//  WaysToReachMeModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/7/6.
//

import Foundation
import LarkOpenSetting
import EENavigator
import LarkSDKInterface
import LarkAccountInterface
import RxSwift
import LarkContainer
import RustPB
import UniverseDesignToast
import UniverseDesignDialog
import UIKit
import LarkActionSheet
import LarkSetting
import LarkSettingUI
import LarkMessengerInterface

extension Settings_V1_WayToFindMeSettingItem {
    var contactType: ContactType {
        switch type {
        case .mobile: return .phone
        case .email: return .mail
        case .unknown:
            assertionFailure("unknown type")
            return .phone
        @unknown default:
            assertionFailure("default type")
            return .phone
        }
    }
}

let waysToReachMeEntryModuleProvider: ModuleProvider = { userResolver in
    return GeneralBlockModule(
        userResolver: userResolver,
        title: BundleI18n.LarkMine.Lark_NewSettings_HowToAddMe) { (userResolver, from) in
        userResolver.navigator.push(body: AddMeWaySettingBody(), from: from)
    }
}

let waysToReachMeSettingModuleProvider: ModuleProvider = { userResolver in
    return WaysToReachMeModule(userResolver: userResolver)
}

final class WaysToReachMeModule: BaseModule, UITextViewDelegate {
    private var configurationAPI: ConfigurationAPI?
    private var addFriendConfig: RustPB.Settings_V1_GetAddFriendPrivateConfigResponse = RustPB.Settings_V1_GetAddFriendPrivateConfigResponse()
    private var urgentConfig: RustPB.Settings_V1_SmsPhoneUrgentSetting = RustPB.Settings_V1_SmsPhoneUrgentSetting()
    private var updated = false

    override func createSectionProp(_ key: String) -> SectionProp? {
        if key == ModulePair.WaysToReachMe.canModify.createKey {
            return canModifySection()
        } else if key == ModulePair.WaysToReachMe.findMeVia.createKey {
            return findMeViaSection()
        } else if key == ModulePair.WaysToReachMe.addMeVia.createKey {
            return addMeViaSection()
        } else if key == ModulePair.WaysToReachMe.addMeFrom.createKey {
            return addMeFromSection()
        }
        return nil
    }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        if let configurationAPI = try? self.userResolver.resolve(assert: ConfigurationAPI.self) {
            self.configurationAPI = configurationAPI
            Observable.combineLatest(
                configurationAPI.fetchSmsPhoneSetting(strategy: .local),
                configurationAPI.getAddFriendPrivateConfig())
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (urgentConfig, addFriendConfig) in
                    guard let self = self, !self.updated else { return }
                    self.updateConfig(urgentConfig: urgentConfig, addFriendConfig: addFriendConfig)
                }).disposed(by: self.disposeBag)

                /// 远程获取
            Observable.combineLatest(
                configurationAPI.fetchSmsPhoneSetting(strategy: .forceServer),
                configurationAPI.fetchAddFriendPrivateConfig())
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (urgentConfig, addFriendConfig) in
                    self?.updated = true
                    self?.updateConfig(urgentConfig: urgentConfig,
                                       addFriendConfig: addFriendConfig)
                }).disposed(by: self.disposeBag)
        }
    }

    private func updateConfig(urgentConfig: RustPB.Settings_V1_SmsPhoneUrgentSetting,
                              addFriendConfig: RustPB.Settings_V1_GetAddFriendPrivateConfigResponse) {
        self.addFriendConfig = addFriendConfig
        self.urgentConfig = urgentConfig
        self.context?.reload()
    }

    private func createFooterView() -> UITableViewHeaderFooterView {
        let view = UITableViewHeaderFooterView()
        guard self.addFriendConfig.loginCpdiff else { return view }
        let textview = UITextView()
        let str = self.addFriendConfig.v2Fg ?
            BundleI18n.LarkMine.Lark_PrivacySettings_NotContactNumberEmail_Desc :
            BundleI18n.LarkMine.Lark_PrivacySettings_ContactInfovsLoginCredentials_Difference
        let attrStr = NSMutableAttributedString(string: str,
                                                attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                             .foregroundColor: UIColor.ud.textPlaceholder])
        if let docUrl = URL(string: self.addFriendConfig.docLink) {
            attrStr.append(NSAttributedString(string: BundleI18n.LarkMine.Lark_PrivacySettings_NotContactNumberEmail_ViewDifference,
                                              attributes: [.link: docUrl]))
        }
        textview.linkTextAttributes = [.font: UIFont.systemFont(ofSize: 14),
                                       .foregroundColor: UIColor.ud.textLinkNormal]
        textview.attributedText = attrStr
        textview.backgroundColor = .clear
        textview.isEditable = false
        textview.isSelectable = true
        textview.textDragInteraction?.isEnabled = false
        textview.isScrollEnabled = false
        textview.showsVerticalScrollIndicator = false
        textview.showsHorizontalScrollIndicator = false
        textview.delegate = self
        textview.textContainerInset = UIEdgeInsets(top: 4, left: 10, bottom: 8, right: 10)
        view.contentView.addSubview(textview)
        textview.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        return view
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            guard let vc = self.context?.vc else { return false }
            self.userResolver.navigator.push(URL, from: vc)
            MineTracker.trackPrivacyViewDifferenceClick()
        }
        return false
    }
}

// can Modify
extension WaysToReachMeModule {
    private func canModifySection() -> SectionProp? {
        guard self.urgentConfig.canModify else { return nil }
        let item = SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_buzz_AllowOtherUsers,
                                        isOn: self.urgentConfig.accept) { [weak self] _, status in
            self?.setSmsUrgent(accept: status)
        }
        return SectionProp(items: [item])
    }

    private func setSmsUrgent(accept: Bool) {
        guard let vc = self.context?.vc else { return }

        func changeSmsUrgent(accept: Bool) {
            let originAccept = self.urgentConfig.accept
            self.urgentConfig.accept = accept
            self.context?.reload()
            let logger = SettingLoggerService.logger(.module(self.key))
            self.configurationAPI?.setSmsPhoneUrgent(accept: accept)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {
                    logger.info("api/setSmsPhoneUrgent/req: accept: \(accept); res: ok")
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    if let window = self.context?.vc?.view.window {
                        UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Setting_PrivacySetupFailed,
                                            on: window,
                                            error: error)
                    }
                    self.urgentConfig.accept = originAccept
                    self.context?.reload()
                    logger.error("api/setSmsPhoneUrgent/req: accept: \(accept); res: error: \(error)")
                }).disposed(by: self.disposeBag)
        }

        if self.urgentConfig.needConfirm && accept {
            let alertController = UDDialog()
            alertController.setTitle(text: BundleI18n.LarkMine.Lark_buzz_AreYouSure)
            alertController.setContent(text: BundleI18n.LarkMine.Lark_buzz_SubjectToLocal)
            alertController.addSecondaryButton(text: BundleI18n.LarkMine.Lark_buzz_Cancel, dismissCompletion: { [weak self] in
                self?.context?.reload()
            })
            alertController.addPrimaryButton(text: BundleI18n.LarkMine.Lark_buzz_Confirm, dismissCompletion: {
                changeSmsUrgent(accept: accept)
            })
            self.userResolver.navigator.present(alertController, from: vc)
        } else {
            changeSmsUrgent(accept: accept)
        }
    }
}

// find me
extension WaysToReachMeModule {
    private func findMeViaSection() -> SectionProp? {
        let items = self.addFriendConfig.findMeSetting.filter { $0.hasVerified_p }.enumerated().compactMap { (index, item) -> CellProp? in
            let cellTitle: String
            switch item.type {
            case .mobile:
                cellTitle = self.addFriendConfig.v2Fg ?
                    (self.addFriendConfig.loginCpdiff ?
                     BundleI18n.LarkMine.Lark_PrivacySettings_LoginPhoneNumber_Title :
                        BundleI18n.LarkMine.Lark_PrivacySettings_MobileNumber) :
                    (self.addFriendConfig.loginCpdiff ?
                     BundleI18n.LarkMine.Lark_PrivacySettings_ContactMobileNumber :
                     BundleI18n.LarkMine.Lark_PrivacySettings_MobileNumber)
            case .email:
                cellTitle = self.addFriendConfig.v2Fg ?
                    (self.addFriendConfig.loginCpdiff ?
                        BundleI18n.LarkMine.Lark_PrivacySettings_LoginEmail_Title :
                        BundleI18n.LarkMine.Lark_PrivacySettings_EmailAddress) :
                    (self.addFriendConfig.loginCpdiff ?
                        BundleI18n.LarkMine.Lark_PrivacySettings_ContactEmailAddress :
                        BundleI18n.LarkMine.Lark_PrivacySettings_EmailAddress)
            @unknown default:
                return nil
            }
            return SwitchNormalCellProp(title: cellTitle, detail: item.displayContact, isOn: item.enable) { [weak self] view, status in
                guard let self = self else { return }
                switch item.type {
                case .email:
                    MineTracker.trackSettingPrivacytabClick(type: "email", enable: status)
                case .mobile:
                    MineTracker.trackSettingPrivacytabClick(type: "phone", enable: status)
                @unknown default:
                    break
                }
                if !item.needCpVerify || !status { // 如果 不需要验证 或者是 关闭
                    self.setWayToFindMeSetting(id: item.id, index: index, enable: status)
                } else { // 否则 弹窗警告
                    let alertTitle: String
                    switch item.type {
                    case .email:
                        alertTitle = BundleI18n.LarkMine.Lark_Passport_PrivacySettings_BeforeChanging_VerifyEmail
                    case .mobile:
                        alertTitle = BundleI18n.LarkMine.Lark_Passport_PrivacySettings_BeforeChanging_VerifyPhoneNumber
                    @unknown default:
                        alertTitle = ""
                    }
                    self.showAlert(alertTitle: alertTitle, sourceView: view, item: item, index: index)
                }
            }
        }
        guard !items.isEmpty else { return nil }
        return SectionProp(items: items, header: .title(BundleI18n.LarkMine.Lark_NewSettings_FindMeVia), footer: .custom({ self.createFooterView() }))
    }

    func showAlert(alertTitle: String, sourceView: UIView, item: RustPB.Settings_V1_WayToFindMeSettingItem, index: Int) {
        guard let from = self.context?.vc else { return }
        let actionSheetAdapter = ActionSheetAdapter()
        let source = ActionSheetAdapterSource(sourceView: sourceView,
                                              sourceRect: sourceView.bounds,
                                              arrowDirection: [.right])
        let actionSheet = actionSheetAdapter.create(level: .normal(source: source),
                                                    title: alertTitle,
                                                    titleColor: UIColor.ud.primaryContentDefault)
        actionSheetAdapter.addItem(
            title: BundleI18n.LarkMine.Lark_Passport_PrivacySettings_BeforeChanging_VerifyButton,
            textColor: UIColor.ud.textTitle,
            action: { [weak self] in
                guard let self = self, let view = self.context?.vc?.view else { return }
                let hud = UDToast.showLoading(on: view)
                if let passportUserService = try? self.userResolver.resolve(assert: PassportUserService.self) {
                    passportUserService.verifyContactPoint(
                        scope: VerifyScope.contactVerify,
                        contact: item.displayContact,
                        contactType: item.contactType,
                        viewControllerHandler: { [weak self] result in
                            hud.remove()
                            guard let targetVC = self?.context?.vc else { return }
                            switch result {
                            case .success(let verifyVC):
                                self?.userResolver.navigator.push(verifyVC, from: targetVC)
                            case .failure(let error):
                                hud.showFailure(with: error.localizedDescription, on: targetVC.view)
                            }
                        },
                        completionHandler: { [weak self] result in
                            self?.context?.vc?.navigationController?.popViewController(animated: true)
                            self?.enableWayToFindMeSettingByVerify(id: item.id, index: index, result: result)
                        })
                }
            }
        )
        actionSheetAdapter.addCancelItem(
            title: BundleI18n.LarkMine.Lark_Passport_PrivacySettings_BeforeChanging_CancelButton,
            textColor: UIColor.ud.textTitle
        )
        self.userResolver.navigator.present(actionSheet, from: from)
    }

    private func enableWayToFindMeSettingByVerify(id: String, index: Int, result: Result<VerifyToken, Error>) {
        switch result {
        case .success(let token):
            self.setWayToFindMeSetting(id: id, index: index, enable: true, verifyToken: token, success: { [weak self] in
                guard let window = self?.context?.vc?.view.window else { return }
                UDToast.showSuccess(with: BundleI18n.LarkMine.Lark_PrivacySettings_EnableSuccessfully_Toast, on: window)
            })
        case .failure(let error):
            guard let window = self.context?.vc?.view.window else { return }
            UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Setting_PrivacySetupFailed,
                                on: window,
                                error: error)
        }
    }

    private func setWayToFindMeSetting(id: String, index: Int, enable: Bool, verifyToken: String = "", success: (() -> Void)? = nil) {
        self.addFriendConfig.findMeSetting[index].enable = enable
        self.context?.reload()
        let logger = SettingLoggerService.logger(.module(self.key))
        self.configurationAPI?
            .setWayToFindMeSetting(id: id, enable: enable, verifyToken: verifyToken)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                logger.info("api/setSmsPhoneUrgent/req: id: \(id), enable: \(enable); res: ok")
                success?()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if let window = self.context?.vc?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Setting_PrivacySetupFailed,
                                        on: window,
                                        error: error)
                }
                self.addFriendConfig.findMeSetting[index].enable = !enable
                self.context?.reload()
                logger.error("api/setSmsPhoneUrgent/req: id: \(id), enable: \(enable); res: error: \(error)")
            }).disposed(by: self.disposeBag)
    }
}

// add me
extension WaysToReachMeModule {
    private func addMeViaSection() -> SectionProp? {
        let headerStr = BundleI18n.LarkMine.Lark_NewSettings_AddMeVia
        let items = [(BundleI18n.LarkMine.Lark_NewSettings_AddMeViaNameCard, .nameCard, "namecard"),
                     (BundleI18n.LarkMine.Lark_NewSettings_AddMeViaQRCodeOrProfileLink, .contactToken, "qrcode_link")
        ].map(createRow)
        return SectionProp(items: items, header: .title(headerStr))
    }

    private func addMeFromSection() -> SectionProp? {
        let headerStr = BundleI18n.LarkMine.Lark_NewSettings_AddMeFrom
        let arr: [RowType] = [(BundleI18n.LarkMine.Lark_NewSettings_AddMeFromChat, .chat, "chat"),
                              (BundleI18n.LarkMine.Lark_NewSettings_AddMeFromEvent, .calendar, "calendar"),
                              (BundleI18n.LarkMine.Lark_NewSettings_AddMeFromDocs, .docs, "docs"),
                              (BundleI18n.LarkMine.Lark_NewSettings_AddMeFromCallsAndMeetings, .videoConference, "VC")]
        let items = arr.map(createRow)
        let email = SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_Mail_Name,
                                         isOn: getStatusByWayToFindMeType(.email)) { [weak self] ( _, status) in
            guard let self = self else { return }
            self.setWayToAddMeSetting(addMeType: .email, enable: status)
        }
        let featureGatingService = try? self.userResolver.resolve(assert: FeatureGatingService.self)
        let fgValue = featureGatingService?.staticFeatureGatingValue(with: .larkPrivacySettingAddfriendsByMail) ?? false
        let realEmailArr = fgValue ? [email] : []
        let minutes = SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_View_Minutes,
                                           detail: BundleI18n.LarkMine.Lark_MV_TurnedOffSayNoToFriend_Tooltip,
                                          isOn: getStatusByWayToFindMeType(.minutes)) { [weak self] ( _, status) in
             guard let self = self else { return }
             self.setWayToAddMeSetting(addMeType: .minutes, enable: status)
            MineTracker.trackSettingPrivacytabMinutesClick(enable: status)
        }
        return SectionProp(items: items + realEmailArr + [minutes], header: .title(headerStr))
    }

    private typealias RowType = (title: String, type: Settings_V1_WayToAddMeSettingItem.TypeEnum, trackStr: String)

    func createRow(title: String, type: Settings_V1_WayToAddMeSettingItem.TypeEnum, trackStr: String) -> SwitchNormalCellProp {
        SwitchNormalCellProp(title: title,
                             isOn: getStatusByWayToFindMeType(type)) { [weak self] ( _, status) in
            guard let self = self else { return }
            self.setWayToAddMeSetting(addMeType: type, enable: status)
            MineTracker.trackSettingPrivacytabClick(type: trackStr, enable: status)
        }
    }

    private func setWayToAddMeSetting(addMeType: RustPB.Settings_V1_WayToAddMeSettingItem.TypeEnum, enable: Bool) {
        updateStatusByWayToFindMeType(addMeType, enable: enable)
        self.context?.reload()
        let logger = SettingLoggerService.logger(.module(self.key))
        self.configurationAPI?.setWayToAddMeSetting(addMeType: addMeType, enable: enable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                logger.info("api/setSmsPhoneUrgent/req: addMeType: \(addMeType), enable: \(enable); res: ok")
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if let window = self.context?.vc?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Setting_PrivacySetupFailed,
                                        on: window,
                                        error: error)
                }
                if addMeType == .contactToken {
                    self.addFriendConfig.addMeSetting.contactTokenSetting = !enable
                } else {
                    self.addFriendConfig.addMeSetting.chatSetting = !enable
                }
                self.context?.reload()
                logger.error("api/setSmsPhoneUrgent/req: addMeType: \(addMeType), enable: \(enable); res: error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    private func getStatusByWayToFindMeType(_ addMeType: RustPB.Settings_V1_WayToAddMeSettingItem.TypeEnum) -> Bool {
        var enable = false
        self.addFriendConfig
            .addMeSetting
            .wayToAddItems.forEach { (item) in
                if item.type == addMeType {
                    enable = item.enable
                }
            }
        return enable
    }

    private func updateStatusByWayToFindMeType(_ addMeType: RustPB.Settings_V1_WayToAddMeSettingItem.TypeEnum, enable: Bool) {
        for (i, item) in self.addFriendConfig.addMeSetting.wayToAddItems.enumerated() where (addMeType == item.type) {
            self.addFriendConfig.addMeSetting.wayToAddItems[i].enable = enable
        }
    }
}
