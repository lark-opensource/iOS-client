//
//  ProfileContactSaveUtils.swift
//  LarkProfile
//
//  Created by ByteDance on 2023/2/1.
//

import UIKit
import Foundation
import ContactsUI
import LKCommonsLogging
import LarkAlertController
import LarkSensitivityControl

class ProfileContactSaveUtil: NSObject, CNContactPickerDelegate, CNContactViewControllerDelegate {
    var phoneItem: ProfileFieldPhoneNumberItem
    var mutableContact: CNMutableContact? = nil
    var fromVC: UIViewController
    var image: UIImage?
    private let logger = Logger.log(ProfileContactSaveUtil.self)

    init(phoneItem: ProfileFieldPhoneNumberItem, fromVC: UIViewController, image: UIImage?) {
        self.phoneItem = phoneItem
        self.fromVC = fromVC
        self.image = image
        super.init()
        if image == nil {
            logger.info("ProfileContact image is nil")
        }
    }

    func createContact() {
        requestSystemContactAuthorization(rootVc: self.fromVC, authorizedHandler: { self.createNewContact() })
    }

    private func createNewContact() {
        let newContact = transferToContact(phoneItem: self.phoneItem)
        let store = CNContactStore()
        self.logger.info("ProfileContact to create Contact")
        let contactCreateVC = CNContactViewController(forNewContact: newContact)
        contactCreateVC.contactStore = store
        contactCreateVC.delegate = self
        let navigationController = UINavigationController(rootViewController: contactCreateVC)
        DispatchQueue.main.async {
            self.fromVC.present(navigationController, animated: true)
        }
    }

    private func pickerExistContact() {
        self.logger.info("ProfileContact to picker Exist Contact")
        let picker = CNContactPickerViewController()
        picker.delegate = self
        fromVC.present(picker, animated: true, completion: nil)
    }

    func pickerContact() {
        requestSystemContactAuthorization(rootVc: fromVC, authorizedHandler: { self.pickerExistContact() })
    }

    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true)
    }

    func transferToContact(phoneItem: ProfileFieldPhoneNumberItem) -> CNContact {
        let contact = CNMutableContact()
        contact.givenName = phoneItem.getDisplayName()
        //设置电话
        let mobileNumber = CNPhoneNumber(stringValue: phoneItem.phoneNumber)
        let mobileValue = CNLabeledValue(label: CNLabelPhoneNumberMobile,
                                         value: mobileNumber)
        contact.phoneNumbers = [mobileValue]
        contact.imageData = self.image?.pngData()
        contact.departmentName = phoneItem.departmentName
        contact.organizationName = phoneItem.tenantName
        return contact
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        mutableContact = contact.mutableCopy() as? CNMutableContact
        guard let mutableContact = mutableContact else { return }
        if mutableContact.givenName.isEmpty && mutableContact.familyName.isEmpty {
            mutableContact.givenName = phoneItem.getDisplayName()
        }
        mutableContact.isKeyAvailable(CNContactImageDataKey)
        if mutableContact.imageData == nil {
            let image = self.image
            mutableContact.imageData = image?.pngData()
        }
        if mutableContact.organizationName.isEmpty {
            mutableContact.organizationName = phoneItem.tenantName
        }
        if mutableContact.departmentName.isEmpty {
            mutableContact.departmentName = phoneItem.departmentName
        }
        //设置电话
        let mobileNumber = CNPhoneNumber(stringValue: phoneItem.phoneNumber)
        let mobileValue = CNLabeledValue(label: CNLabelPhoneNumberMobile,
                                         value: mobileNumber)
        mutableContact.phoneNumbers.append(mobileValue)
        self.logger.info("ProfileContact to picker Exist Contact and edit")
        let contactCreateVC = CNContactViewController(forNewContact: self.mutableContact)
        contactCreateVC.contactStore = CNContactStore()
        contactCreateVC.delegate = self
        let navigationController = UINavigationController(rootViewController: contactCreateVC)
        DispatchQueue.main.async {
            self.fromVC.present(navigationController, animated: true)
        }
    }

    // nolint: duplicated_code - 后续修改
    func requestSystemContactAuthorization(rootVc: UIViewController,
                                           authorizedHandler: (() -> Void)?) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        switch authorizationStatus {
        case CNAuthorizationStatus.denied, CNAuthorizationStatus.restricted:
            DispatchQueue.main.async { self.showRequestAuthorizationAlert(rootVc) }
        case CNAuthorizationStatus.notDetermined:
            do {
                let token = Token("LARK-PSDA-lark_profile_access_contact")
                try ContactsEntry.requestAccess(forToken: token, contactsStore: CNContactStore(), forEntityType: CNEntityType.contacts) { (granted, error) -> Void in
                    DispatchQueue.main.async {
                        if granted {
                            authorizedHandler?()
                        } else {
                            self.logger.error("ProfileContact createContact \(String(describing: error))")
                        }
                    }
                }
            } catch {
                self.logger.error("due PSDA control requestAccess failure")
            }
        case  CNAuthorizationStatus.authorized:
            DispatchQueue.main.async { authorizedHandler?() }
        @unknown default:
            fatalError("unknown")
        }
    }

    func showRequestAuthorizationAlert(_ rootVc: UIViewController) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkProfile.Lark_Legacy_Hint)
        alertController.setContent(text: BundleI18n.LarkProfile.Lark_Invitation_AddMembersContactsPermission)
        alertController.addSecondaryButton(text: BundleI18n.LarkProfile.Lark_UserGrowth_InviteMemberImportContactsCancel, dismissCompletion: {
            self.logger.info("ProfileContact showRequestAuthorizationAlert dismiss")
        })
        alertController.addPrimaryButton(text: BundleI18n.LarkProfile.Lark_UserGrowth_InviteMemberImportContactsSettings, dismissCompletion: {
            if let appSettings = try? URL.forceCreateURL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
            
        })
        self.fromVC.present(alertController, animated: false)
    }

}
