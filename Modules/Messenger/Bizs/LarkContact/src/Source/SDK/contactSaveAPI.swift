//
//  ProfileContactSaveUtils.swift
//  LarkProfile
//
//  Created by ByteDance on 2023/2/1.
//

import UIKit
import Foundation
import ContactsUI
import LarkBizAvatar
import LKCommonsLogging
import LarkAlertController
import LarkSensitivityControl

class ContactSaveUtil: NSObject, CNContactPickerDelegate, CNContactViewControllerDelegate {
    var fromVC: UIViewController?
    var phoneNumber: String?
    static let contactSaveUtilSharedInstance = ContactSaveUtil()
    private let logger = Logger.log(ContactSaveUtil.self)
    private override init() {}

    func createContact(phoneNumber: String, fromVC: UIViewController) {
        requestSystemContactAuthorization(token: "LARK-PSDA-telephone_create_contact", rootVc: fromVC, authorizedHandler: {
            self.createNewContact(phoneNumber: phoneNumber, fromVC: fromVC)
        })
    }

    func pickerContact(phoneNumber: String, fromVC: UIViewController) {
        self.fromVC = fromVC
        self.phoneNumber = phoneNumber
        requestSystemContactAuthorization(token: "LARK-PSDA-telephone_show_contact", rootVc: fromVC, authorizedHandler: {
            self.pickerExistContact(phoneNumber: phoneNumber, fromVC: fromVC)})
    }

    private func createNewContact(phoneNumber: String, fromVC: UIViewController) {
        let newContact = CNMutableContact()
        let mobileNumber = CNPhoneNumber(stringValue: phoneNumber)
        let mobileValue = CNLabeledValue(label: CNLabelPhoneNumberMobile,
                                         value: mobileNumber)
        newContact.phoneNumbers = [mobileValue]
        self.logger.info("ContactSaveUtil to create Contact")
        let contactCreateVC = CNContactViewController(forNewContact: newContact)
        contactCreateVC.contactStore = CNContactStore()
        contactCreateVC.delegate = self
        let navigationController = UINavigationController(rootViewController: contactCreateVC)
        fromVC.present(navigationController, animated: true)
    }

    private func pickerExistContact(phoneNumber: String, fromVC: UIViewController) {
        self.logger.info("ContactSaveUtil to picker Exist Contact")
        let picker = CNContactPickerViewController()
        picker.delegate = self
        fromVC.present(picker, animated: true, completion: nil)
    }

    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true)
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let mutableContact = contact.mutableCopy() as? CNMutableContact
        guard let mutableContact = mutableContact, let phoneNumber = phoneNumber,
                                                       let fromVC = fromVC else { return }
        //设置电话
        let mobileNumber = CNPhoneNumber(stringValue: phoneNumber)
        let mobileValue = CNLabeledValue(label: CNLabelPhoneNumberMobile,
                                         value: mobileNumber)
        mutableContact.phoneNumbers.append(mobileValue)
        let contactCreateVC = CNContactViewController(forNewContact: mutableContact)
        contactCreateVC.contactStore = CNContactStore()
        contactCreateVC.delegate = self
        let navigationController = UINavigationController(rootViewController: contactCreateVC)
        DispatchQueue.main.async {
            fromVC.present(navigationController, animated: true)
        }
    }

    func requestSystemContactAuthorization(token: String,
                                           rootVc: UIViewController,
                                           authorizedHandler: (() -> Void)?) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        switch authorizationStatus {
        case CNAuthorizationStatus.denied, CNAuthorizationStatus.restricted:
            DispatchQueue.main.async { self.showRequestAuthorizationAlert(rootVc) }
        case CNAuthorizationStatus.notDetermined:
            do {
                let tk = Token(token)
                try ContactsEntry.requestAccess(forToken: tk, contactsStore: CNContactStore(), forEntityType: .contacts, completionHandler: { (granted, error) -> Void in
                    DispatchQueue.main.async {
                        if granted {
                            authorizedHandler?()
                        } else {
                            self.logger.error("ContactSaveUtil createContact\(String(describing: error))")
                        }
                    }
                })
            } catch {
                ContactLogger.shared.error(module: .action, event: "\(Self.self) no request contact token \(token): \(error.localizedDescription)")
            }
        case  CNAuthorizationStatus.authorized:
            DispatchQueue.main.async { authorizedHandler?() }
        @unknown default:
            fatalError("unknown")
        }
    }

    func showRequestAuthorizationAlert(_ rootVc: UIViewController) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkContact.Lark_Legacy_Hint)
        alertController.setContent(text: BundleI18n.LarkContact.Lark_Invitation_AddMembersContactsPermission)
        alertController.addSecondaryButton(text: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberImportContactsCancel, dismissCompletion: {
            self.logger.info("ContactSaveUtil RequestAuthorizationAlert dismiss ")
        })
        alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberImportContactsSettings,
                                  dismissCompletion: {
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        })
        rootVc.present(alertController, animated: false)
    }

}
