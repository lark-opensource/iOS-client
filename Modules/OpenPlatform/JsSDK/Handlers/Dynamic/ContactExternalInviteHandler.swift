//
//  ContactExternalInviteHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/31.
//

import LKCommonsLogging
import LarkAlertController
import LarkMessengerInterface
import WebBrowser
import EENavigator
import Contacts
import LarkAddressBookSelector
import OPFoundation
public typealias AddressBookDataSourceType = LarkAddressBookSelector.ContactContentType

class ContactExternalInviteHandler: JsAPIHandler {

    private static let logger = Logger.log(ContactExternalInviteHandler.self, category: "ContactExternalInviteHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        if let dataSourceTypeRaw = args["dataSourceType"] as? Int {
            var dataSourceTypeStr = AddressBookDataSourceType.phone.rawValue
            if dataSourceTypeRaw == 0 {
                dataSourceTypeStr = AddressBookDataSourceType.email.rawValue
            }
            guard let dataSourceType = AddressBookDataSourceType(rawValue: dataSourceTypeStr) else {
                ContactExternalInviteHandler.logger.error("ContactExternalInviteHandler failed, dataSourceType not vaild!)")
                return
            }
            self.pushToContactsImportViewController(dataSourceType: dataSourceType)
        } else {
            if let onFailed = args["onFailed"] as? String {
                let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
                callbackWith(api: api, funcName: onFailed, arguments: arguments)
            }
            ContactExternalInviteHandler.logger.error("ContactExternalInviteHandler failed, dataSourceType is nil!)")
        }
    }

    func pushToContactsImportViewController(dataSourceType: AddressBookDataSourceType) {
        guard let currentVC = Navigator.shared.mainSceneWindow?.fromViewController,
              currentVC.navigationController != nil else {
            ContactExternalInviteHandler.logger.error("cannot find currentvc, navigator has no topviewcontroller!")
            return
        }

        let block = {
            let addressBookDest = SelectContactListController(
                contactContentType: dataSourceType,
                contactTableSelectType: .multiple,
                naviBarTitle: BundleI18n.JsSDK.Lark_UserGrowth_InviteMemberImportContactsTitle
            )
            Navigator.shared.push(addressBookDest, from: currentVC) // Global
        }

        self.requestSystemContactAuthorization(rootVc: currentVC, userOperationHandler: { (granted) in
            if granted {
                block()
            }
        }, authorizedHandler: {
            block()
        }) {
            self.showRequestAuthorizationAlert(currentVC, cancelCompletion: {
                ContactExternalInviteHandler.logger.debug("request SystemContact Authorization, access deny)")
            }, goSettingCompletion: {
                ContactExternalInviteHandler.logger.debug("request SystemContact Authorization, goto setting)")
            })
        }
    }

    func requestSystemContactAuthorization(rootVc: UIViewController,
                                           userOperationHandler: ((Bool) -> Void)?,
                                           authorizedHandler: (() -> Void)?,
                                           deniedHandler: (() -> Void)?) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        switch authorizationStatus {
        case CNAuthorizationStatus.denied, CNAuthorizationStatus.restricted:
            DispatchQueue.main.async { deniedHandler?() }
        case CNAuthorizationStatus.notDetermined:
            let contactStore = CNContactStore()
            do {
                try OPSensitivityEntry.ContactsEntry_requestAccess(forToken: .ContactExternalInviteHandler_requestSystemContactAuthorization_ContactsEntry_requestAccess, contactsStore: contactStore , forEntityType: CNEntityType.contacts, completionHandler: { (granted, _) -> Void in
                    DispatchQueue.main.async { userOperationHandler?(granted) }
                })
            } catch {
                ContactExternalInviteHandler.logger.debug("OPSensitivityEntry.ContactsEntry_requestAccess error:\(error)")
                DispatchQueue.main.async { userOperationHandler?(false) }
            }
          
        case  CNAuthorizationStatus.authorized:
            DispatchQueue.main.async { authorizedHandler?() }
        @unknown default:
            fatalError("unknown")
        }
    }

    func showRequestAuthorizationAlert(_ rootVc: UIViewController,
                                       cancelCompletion: (() -> Void)? = nil,
                                       goSettingCompletion: (() -> Void)? = nil) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.JsSDK.Lark_Legacy_Hint)
        alertController.setContent(text: BundleI18n.JsSDK.Lark_Invitation_AddMembersContactsPermission)
        alertController.addSecondaryButton(text: BundleI18n.JsSDK.Lark_UserGrowth_InviteMemberImportContactsCancel, dismissCompletion: {
            cancelCompletion?()
        })
        alertController.addPrimaryButton(text: BundleI18n.JsSDK.Lark_UserGrowth_InviteMemberImportContactsSettings, dismissCompletion: {
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
            goSettingCompletion?()
        })
        Navigator.shared.present(alertController, from: rootVc) // Global
    }

}
