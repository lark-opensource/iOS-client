//
//  ContactService.swift
//  LarkAddressBookSelector
//
//  Created by zhenning on 2020/7/10.
//

import UIKit
import Foundation
import Contacts
import libPhoneNumber_iOS
import LarkAlertController
import LKCommonsLogging
import LKCommonsTracker
import Homeric
import LarkSensitivityControl

public final class ContactService {

    public static let DummyCountryCode = "-1"

    private static let logger = Logger.log(ContactService.self, category: "LarkAddressBookSelector.ContactService")

    /// 异步获取通讯录的联系人信息
    /// params: dataType 获取联系人类型, 默认为全部
    /// params: authorityAlertInfo 是否在权限被禁止时弹出提示弹窗, 不传则不显示
    /// params: bizType 业务类型 Onboarding等
    /// params: successCallback 获取成功的回调
    /// params: failedCallback 获取失败的回调，权限被deny
    public static func getContactsAsync(token: Token,
                                        dataType: AddressBookDataType? = .all,
                                        authorityAlertInfo: ContactAuthorityAlertInfo? = nil,
                                        bizType: BizType? = nil,
                                        successCallback: AuthorityReqSuccessCallback?,
                                        failedCallback: AuthorityReqFailedCallback?) {
        DispatchQueue.global().async {
            self.getContactsDataFromStore(token: token,
                                          dataType: dataType,
                                          authorityAlertInfo: authorityAlertInfo,
                                          bizType: bizType,
                                          successCallback: successCallback,
                                          failedCallback: failedCallback)
        }
    }

    /// 获取通讯录的联系人信息
    /// params: dataType 获取联系人类型, 默认为全部
    /// params: authorityAlertInfo 是否在权限被禁止时弹出提示弹窗, 不传则不显示
    /// params: bizType 业务类型 Onboarding等
    /// params: successCallback 获取成功的回调
    /// params: failedCallback 获取失败的回调，权限被deny
    private static func getContactsDataFromStore(token: Token,
                                                 dataType: AddressBookDataType? = .all,
                                                 authorityAlertInfo: ContactAuthorityAlertInfo? = nil,
                                                 bizType: BizType? = nil,
                                                 successCallback: AuthorityReqSuccessCallback?,
                                                 failedCallback: AuthorityReqFailedCallback?) {
        // 查询权限
        let authorizationStatus = getContactAuthorizationStatus()

        let failedHandler: ((_ error: NSError?) -> Void) = { error in
            if let authorityAlertInfo = authorityAlertInfo {
                showContactAuthoritySettingGuide(
                    authorityAlertInfo: authorityAlertInfo,
                    dismissCallback: { status in
                        if let failedCallback = failedCallback {
                            failedCallback((status, error))
                        }
                    })
            } else {
                if let failedCallback = failedCallback {
                    failedCallback((CNAuthorizationStatus.denied, error))
                }
            }
            if self.isBizTypeOnboarding(bizType: bizType) {
                ABSTracker.trackOnbardingSystemAddressRequestAgree()
                ABSTracker.trackMetricOnbardingSystemAddressRequestAllow()
            }
        }
        let successHandler = {
            if let successCallback = successCallback {
                requestContacts(token: token, dataType: dataType ?? .all, successCallback: { contactsResponceInfo in
                    let orderedContacts = contactsResponceInfo.orderedContacts
                    let allContacts = contactsResponceInfo.allContacts
                    let sortedContactKeys = contactsResponceInfo.sortedContactKeys
                    successCallback(contactsResponceInfo)
                    ContactService.logger.debug("request contacts success", additionalData: [
                                                    "orderedContactsCount": "\(orderedContacts.count)",
                                                    "allContactsCount": "\(allContacts.count)",
                                                    "sortedContactKeys": "\(sortedContactKeys)"])
                }) { (error) in
                    ContactService.logger.error("获取通讯录数据发生错误！", error: error)
                }
            }
            if self.isBizTypeOnboarding(bizType: bizType) {
                ABSTracker.trackOnbardingSystemAddressRequestDisagree()
                ABSTracker.trackMetricOnbardingSystemAddressRequestDeny()
            }
        }

        // 处理status
        switch authorizationStatus {
        case CNAuthorizationStatus.denied:
            failedHandler(nil)
        case CNAuthorizationStatus.restricted,
             CNAuthorizationStatus.notDetermined:
            requestContactsStoreAccess(token: token) { (permitted, error) in
                if permitted, error == nil {
                    successHandler()
                } else {
                    failedHandler(error as NSError?)
                }
            }
            if self.isBizTypeOnboarding(bizType: bizType) {
                ABSTracker.trackOnbardingSystemAddressRequstShow()
                ABSTracker.trackMetricOnbardingSystemAddressRequstShow()
            }
        case CNAuthorizationStatus.authorized:
            successHandler()
        @unknown default:
            failedHandler(nil)
        }
    }
}

// MARK: - contacts authority

extension ContactService {

    // 获取系统通讯录权限状态
    public static func getContactAuthorizationStatus() -> CNAuthorizationStatus {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        return authorizationStatus
    }

    // 查询系统通讯录权限
    /// @param: completionHandler 权限申请结果回调
    public static func requestContactsStoreAccess(token: Token, completionHandler: @escaping (Bool, Error?) -> Void) {
        let contactsStore = CNContactStore()
        let safeCompletionHandler: ContactRequestAccessCompletionHandler = { granted, error in
            DispatchQueue.main.async {
                completionHandler(granted, error)
            }
            if granted {
                ABSTracker.trackContactPermissionAllow()
            } else {
                ABSTracker.trackContactPermissionDeny()
            }
        }
        do {
            try ContactsEntry.requestAccess(forToken: token,
                                            contactsStore: contactsStore,
                                            forEntityType: CNEntityType.contacts,
                                            completionHandler: safeCompletionHandler)
        } catch {
            DispatchQueue.main.async {
                completionHandler(false, error)
            }
        }
    }

    /// 请求系统权限
    /// @param: hostProvider 代表权限关闭时，是否需要弹出引导提示，为空则不显示提示
    /// @param: completionHandler 权限申请结果回调
    public static func requestSystemContactAuthorization(token: Token,
                                                         hostProvider: UIViewController?,
                                                         completionHandler: @escaping (Bool, Error?) -> Void) {
        let authorizationStatus = getContactAuthorizationStatus()
        let safeCompletionHandler: ContactRequestAccessCompletionHandler = { granted, error in
            DispatchQueue.main.async {
                completionHandler(granted, error)
            }
        }
        switch authorizationStatus {
        case CNAuthorizationStatus.denied:
            if let hostProvider = hostProvider {
                let authorityAlertInfo = ContactAuthorityAlertInfo(hostProvider: hostProvider)
                showContactAuthoritySettingGuide(
                    authorityAlertInfo: authorityAlertInfo,
                    dismissCallback: { _ in
                        safeCompletionHandler(false, nil)
                    })
            }
            safeCompletionHandler(false, nil)
        case CNAuthorizationStatus.restricted,
             CNAuthorizationStatus.notDetermined:
            requestContactsStoreAccess(token: token, completionHandler: safeCompletionHandler)
        case CNAuthorizationStatus.authorized:
            safeCompletionHandler(true, nil)
        @unknown default: break
        }
    }

    // 提示用户前往系统设置授权弹窗
    private static func showContactAuthoritySettingGuide(authorityAlertInfo: ContactAuthorityAlertInfo,
                                                         dismissCallback: @escaping (CNAuthorizationStatus) -> Void) {
        let safeDismissCallback: (CNAuthorizationStatus) -> Void = { status in
            DispatchQueue.main.async {
                dismissCallback(status)
            }
        }
        let alertController = LarkAlertController()
        let title = authorityAlertInfo.textInfo?.title
            ?? BundleI18n.LarkAddressBookSelector.Lark_NewContacts_EnableMobileContactsAccessTitle
        let message = authorityAlertInfo.textInfo?.message
            ?? BundleI18n.LarkAddressBookSelector
            .Lark_NewContacts_EnableMobileContactsAccess()
        alertController.setTitle(text: title, alignment: .center)
        alertController.setContent(text: message, alignment: .center)
        alertController.addCancelButton(dismissCompletion: {
            safeDismissCallback(CNAuthorizationStatus.denied)
            ABSTracker.trackContactPermissionSettingsCancel()
        })
        alertController.addPrimaryButton(text: BundleI18n.LarkAddressBookSelector.Lark_NewContacts_EnableMobileContactsAccessGoToSettings,
                                  dismissCompletion: {
            alertController.setTitle(text: title, alignment: .center)
            let url = URL(string: UIApplication.openSettingsURLString) ?? .init(fileURLWithPath: "")
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            safeDismissCallback(CNAuthorizationStatus.denied)
            ABSTracker.trackContactPermissionSettingsJump()
        })
        DispatchQueue.main.async {
            authorityAlertInfo.hostProvider.present(alertController, animated: true)
        }
    }
}

// MARK: - Util

extension ContactService {

    public static func getAddressBookDataType(contentType: ContactContentType) -> AddressBookDataType {
        switch contentType {
        case .phone:
            return AddressBookDataType.phone
        case .email:
            return AddressBookDataType.email
        }
    }

    /// 是否是onboarding业务
    private static func isBizTypeOnboarding(bizType: BizType?) -> Bool {
        guard let bizType = bizType, bizType == .onboarding else {
            return false
        }
        return true
    }
}

// MARK: - Contacts Data

extension ContactService {

    /// 获取通讯录的联系人列表
    /// params: dataType 获取联系人类型
    /// params: successCallback 获取成功的回调
    /// params: failedCallback 获取失败的回调
    private static func requestContacts(token: Token,
                                        dataType: AddressBookDataType,
                                        successCallback: ContactsReqSuccessCallback?,
                                        failedCallback: ContactsReqFailedCallback?) {

        let contactsStore: CNContactStore = CNContactStore()
        var allContacts = [AddressBookContact]()
        var orderedContacts = [String: [AddressBookContact]]()
        var sortedContactKeys = [String]()
        let contactFetchRequest = CNContactFetchRequest(keysToFetch: self.allowedContactKeys())
        contactFetchRequest.sortOrder = .userDefault

        ABSTracker.trackStartContactLocalFetchTimingMs()
        let disposedKey = ABSTracker.trackStartAppReciableContactLocalFetchTimingMs()
        do {
            try ContactsEntry.enumerateContacts(forToken: token, contactsStore: contactsStore, withFetchRequest: contactFetchRequest) { (contact, _) -> Void in
                let contactModels = self.createContactModels(dataType: dataType, from: contact)
                guard !contactModels.isEmpty else { return }

                allContacts.append(contentsOf: contactModels)

                var key: String = "#"
                if let firstLetter = contact.familyName[0..<1] {
                    if firstLetter.first!.canTransformToPinyinHead() {
                        key = firstLetter.transformToPinyinHead()
                    }
                } else if let firstLetter = contact.givenName[0..<1] {
                    if firstLetter.first!.canTransformToPinyinHead() {
                        key = firstLetter.transformToPinyinHead()
                    }
                }

                var contacts = [AddressBookContact]()
                if let segregatedContact = orderedContacts[key] {
                    contacts = segregatedContact
                }
                contacts.append(contentsOf: contactModels)
                orderedContacts[key] = contacts
            }
            sortedContactKeys = Array(orderedContacts.keys).sorted(by: <)
            if sortedContactKeys.first == "#" {
                sortedContactKeys.removeFirst()
                sortedContactKeys.append("#")
            }
            if let successCallback = successCallback {
                let contactsResponceInfo = ContactsDataInfo(allContacts: allContacts,
                                                            orderedContacts: orderedContacts,
                                                            sortedContactKeys: sortedContactKeys)
                successCallback(contactsResponceInfo)
                ABSTracker.trackEndContactLocalFetchTimingMs()
                ABSTracker.trackEndAppReciableContactLocalFetchTimingMs(disposedKey: disposedKey)
            }
            let contactOfPhones = allContacts.filter { return $0.contactPointType == .phone }
            let contactOfEmails = allContacts.filter { return $0.contactPointType == .email }
            ABSTracker.trackFetchCPTotalCountRaw(count: allContacts.count)
            ABSTracker.trackFetchPhoneCountRaw(count: contactOfPhones.count)
            ABSTracker.trackFetchEmailCountRaw(count: contactOfEmails.count)
        } catch let error as NSError {
            if let failedCallback = failedCallback {
                failedCallback(error)
                ABSTracker.trackEndContactLocalFetchTimingMs()
                ABSTracker.trackEndAppReciableContactLocalFetchTimingMs(disposedKey: disposedKey)
            }
        }
    }

    private static func createContactModels(dataType: AddressBookDataType,
                                            from contact: CNContact) -> [AddressBookContact] {
        var contactFullModels = [AddressBookContact]()
        let familyName = contact.familyName
        let givenName = contact.givenName

        func _fullWords(familyName: String, givenName: String, shouldAddBlank: Bool = false) -> String {
            let splitStr: String = shouldAddBlank ? " " : ""
            if familyName.isLetterString(), givenName.isLetterString() {
                return "\(givenName)\(splitStr)\(familyName)"
            } else {
                return "\(familyName)\(splitStr)\(givenName)"
            }
        }

        let fullName = _fullWords(familyName: familyName, givenName: givenName)
        var pinyinHead: String = ""

        if fullName.isChineseString() {
            /// 如果为中文字符串
            let length = fullName.count
            pinyinHead = length >= 2 ? String(fullName.suffix(2)) : String(fullName.last!)
        } else {
            /// 如果为非中文字符串
            let words = _fullWords(familyName: familyName, givenName: givenName, shouldAddBlank: true).components(separatedBy: " ")
                .filter { !$0.isEmpty }
            if !words.isEmpty {
                let firstChar = words.first!.uppercased().first!
                if words.count >= 2 {
                    let lastChar = words.last!.uppercased().first!
                    pinyinHead = "\(String(firstChar))\(String(lastChar))"
                } else {
                    pinyinHead = String(firstChar)
                }
            }
        }

        var thumbnailProfileImage: UIImage?
        if let imageData = contact.thumbnailImageData {
            thumbnailProfileImage = UIImage(data: imageData)
        }

        switch dataType {
        case .phone:
            contactFullModels.append(contentsOf: getPhoneTypeContacts(contact: contact,
                                                                      pinyinHead: pinyinHead,
                                                                      thumbnailProfileImage: thumbnailProfileImage))
        case .email:
            contactFullModels.append(contentsOf: getEmailTypeContacts(contact: contact,
                                                                      pinyinHead: pinyinHead,
                                                                      thumbnailProfileImage: thumbnailProfileImage))
        case .all:
            contactFullModels.append(contentsOf: getPhoneTypeContacts(contact: contact,
                                                                      pinyinHead: pinyinHead,
                                                                      thumbnailProfileImage: thumbnailProfileImage))
            contactFullModels.append(contentsOf: getEmailTypeContacts(contact: contact,
                                                                      pinyinHead: pinyinHead,
                                                                      thumbnailProfileImage: thumbnailProfileImage))
        }
        return contactFullModels
    }

    private static func getPhoneTypeContacts(contact: CNContact,
                                             pinyinHead: String,
                                             thumbnailProfileImage: UIImage?) -> [AddressBookContact] {
        var contactFullModels = [AddressBookContact]()
        let phoneUtil = NBPhoneNumberUtil()

        for phoneNumber in contact.phoneNumbers {
            var countryCode = DummyCountryCode
            var numberString = phoneNumber.value.stringValue
            if numberString.range(of: "+") != nil {
                var nationalNumber: NSString?
                countryCode = phoneUtil.extractCountryCode(phoneNumber.value.stringValue,
                                                           nationalNumber: &nationalNumber)?.stringValue ?? DummyCountryCode
                if let nationalNumber = nationalNumber {
                    numberString = nationalNumber as String
                }
            }
            let contact = AddressBookContact(firstName: contact.familyName,
                                             lastName: contact.givenName,
                                             phoneNumber: phoneNumber.value.stringValue,
                                             email: nil,
                                             pinyinHead: pinyinHead,
                                             thumbnailProfileImage: thumbnailProfileImage,
                                             countryCode: countryCode,
                                             identifier: contact.identifier)
            contact.contactPointType = .phone
            contactFullModels.append(contact)
        }
        return contactFullModels
    }

    private static func getEmailTypeContacts(contact: CNContact,
                                             pinyinHead: String,
                                             thumbnailProfileImage: UIImage?) -> [AddressBookContact] {
        var contactFullModels = [AddressBookContact]()
        for emailAddress in contact.emailAddresses {
            let email = emailAddress.value as String
            if ContactRexUtil.validateEmail(email: email) {
                let contact = AddressBookContact(firstName: contact.familyName,
                                                 lastName: contact.givenName,
                                                 phoneNumber: nil,
                                                 email: email,
                                                 pinyinHead: pinyinHead,
                                                 thumbnailProfileImage: thumbnailProfileImage,
                                                 countryCode: DummyCountryCode,
                                                 identifier: contact.identifier)
                contact.contactPointType = .email
                contactFullModels.append(contact)
            }
        }
        return contactFullModels
    }

    private static func allowedContactKeys() -> [CNKeyDescriptor] {
        return [CNContactNamePrefixKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactThumbnailImageDataKey as CNKeyDescriptor,
                CNContactImageDataAvailableKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor
        ]
    }
}
