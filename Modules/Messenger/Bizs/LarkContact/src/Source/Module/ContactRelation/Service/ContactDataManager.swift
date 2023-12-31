//
//  ContactDataManager.swift
//  LarkContact
//
//  Created by zhenning on 2020/07/20.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import libPhoneNumber_iOS
import LarkExtensions
import LarkSDKInterface
import LarkAddressBookSelector
import LarkAccountInterface
import LKCommonsLogging
import UniverseDesignToast
import LarkFeatureGating
import LarkSensitivityControl

public enum ContactApplyStatus {
    /// 未申请，默认态
    case contactStatusNotFriend
    /// 已申请好友
    case contactStatusRequest
}

public struct ContactItem: Equatable {
    let title: String
    let detail: String?
    let avatarKey: String?
    let contactInfo: ContactPointUserInfo?
    var applyStatus: ContactApplyStatus?
    init(title: String,
         detail: String?,
         avatarKey: String? = nil,
         contactInfo: ContactPointUserInfo? = nil,
          applyStatus: ContactApplyStatus? = .contactStatusNotFriend) {
        self.title = title
        self.detail = detail
        self.avatarKey = avatarKey
        self.contactInfo = contactInfo
        self.applyStatus = applyStatus
    }

    public static func == (lhs: ContactItem, rhs: ContactItem) -> Bool {
        return lhs.title == rhs.title
    }
}

public protocol ContactDataService {
    func getFormatContactPointsAsync(hostProvider: UIViewController?,
                                     limitCount: Int?,
                                     successCallBack: @escaping ([String]?) -> Void,
                                     failedCallBack: @escaping (NSError?) -> Void)
    func getFormatContactDataAsync(hostProvider: UIViewController?,
                                   limitCount: Int?,
                                   successCallBack: @escaping ([AddressBookContact]?) -> Void,
                                   failedCallBack: @escaping (NSError?) -> Void)
    func getLocalContactsAsync(hostProvider: UIViewController?,
                               bizType: BizType?,
                               successCallBack: @escaping ([AddressBookContact]) -> Void,
                               failedCallBack: @escaping (NSError?) -> Void)
    func getContactUserInfosOfContactsAsnyc(hostProvider: UIViewController?,
                                            limitCount: Int?,
                                            successCallBack: @escaping ([ContactItem]) -> Void,
                                            failedCallBack: @escaping (Error?) -> Void)
    func getLocalContactsAsyncForOnboarding(hostProvider: UIViewController,
                                            successCallBack: @escaping ([AddressBookContact]) -> Void,
                                            failedCallBack: @escaping (NSError?) -> Void)
}

public final class ContactDataManager: ContactDataService {
    static let logger = Logger.log(ContactDataManager.self, category: "ContactDataManager")

    private let verificationViewModel: VerificationBaseViewModel
    private let phoneUtil = NBPhoneNumberUtil()
    private let contactAPI: ContactAPI
    private let disposeBag: DisposeBag = DisposeBag()
    private var isUploadCPRequestLoading: Bool = false

    public init(contactAPI: ContactAPI,
                isOversea: Bool) {
        self.verificationViewModel = VerificationBaseViewModel(isOversea: isOversea)
        self.contactAPI = contactAPI
    }

    /// 通过CP获取联系人信息
    private func getUserInfosByContactPointsAsnyc(contactPoints: [String],
                                                  successCallBack: @escaping ([ContactPointUserInfo]) -> Void,
                                                  failedCallBack: @escaping (Error) -> Void) {
        self.contactAPI.getUserInfoByContactPointsRequest(contactPoints: contactPoints)
            .subscribe(onNext: { (contactPointUserInfos) in
                successCallBack(contactPointUserInfos)
                ContactDataManager.logger.debug("contactPointUserInfos = \(contactPointUserInfos)")
            }, onError: { (error) in
                failedCallBack(error)
                ContactDataManager.logger.error("getContactPointUserInfos error!", error: error)
            }).disposed(by: self.disposeBag)
    }

    /// 异步获取通讯录的合法联系人Data信息
    /// params: successCallBack 响应回调
    public func getFormatContactDataAsync(hostProvider: UIViewController? = nil,
                                          limitCount: Int? = nil,
                                          successCallBack: @escaping ([AddressBookContact]?) -> Void,
                                          failedCallBack: @escaping (NSError?) -> Void) {
        self.getLocalContactsAsync(hostProvider: hostProvider, successCallBack: { contacts in
            var handledContacts = contacts
            if let limitCount = limitCount {
                handledContacts = [AddressBookContact](contacts.prefix(limitCount))
            }
            successCallBack(handledContacts)
            ContactDataManager.logger.debug("get format Contact Data", additionalData: [
                "handledContacts": "\(handledContacts)",
                "limitCount": "\(String(describing: limitCount))"])
        }, failedCallBack: { error in
            failedCallBack(error)
        })
    }

    /// 异步获取通讯录的合法联系人CP信息
    /// params: successCallBack 响应回调
    public func getFormatContactPointsAsync(hostProvider: UIViewController? = nil,
                                            limitCount: Int? = nil,
                                            successCallBack: @escaping ([String]?) -> Void,
                                            failedCallBack: @escaping (NSError?) -> Void) {
        self.getLocalContactsAsync(hostProvider: hostProvider, successCallBack: { [weak self] contacts in
            guard let self = self else {
                successCallBack(nil)
                return
            }

            let contactPoints: [String] = self.transformContactsToCPs(contacts: contacts)
            var handledContactPoints: [String] = contactPoints
            if let limitCount = limitCount {
                handledContactPoints = [String](contactPoints.prefix(limitCount))
            }
            successCallBack(handledContactPoints)
            Tracer.trackFetchCPTotalCountHandled(count: handledContactPoints.count)
            ContactDataManager.logger.debug("get format Contact Point", additionalData: [
                "handledContactPoints count": "\(handledContactPoints.count)",
                "limitCount": "\(String(describing: limitCount))"])
        }, failedCallBack: { error in
            failedCallBack(error)
        })
    }

    public func getLocalContactsAsync(hostProvider: UIViewController? = nil,
                                      bizType: BizType? = nil,
                                      successCallBack: @escaping ([AddressBookContact]) -> Void,
                                      failedCallBack: @escaping (NSError?) -> Void) {
        var alertInfo: ContactAuthorityAlertInfo?
        if let hostProvider = hostProvider {
            alertInfo = ContactAuthorityAlertInfo(hostProvider: hostProvider)
        }
        ContactService.getContactsAsync(
            token: Token("LARK-PSDA-contact_some_might_know"),
            authorityAlertInfo: alertInfo,
            bizType: bizType,
            successCallback: { contactsDataInfo in
                successCallBack(contactsDataInfo.allContacts)
                ContactDataManager.logger.debug("getLocalContactsAsync allContacts = \(contactsDataInfo.allContacts)")
            }) { failedInfo in
            failedCallBack(failedInfo.error)
            ContactDataManager.logger.error("getLocalContactsAsync failedInfo = \(failedInfo)")
        }
    }
}

/// Biz
public extension ContactDataManager {

    /// 异步获取联系人列表
    func getContactUserInfosOfContactsAsnyc(hostProvider: UIViewController? = nil,
                                            limitCount: Int? = nil,
                                            successCallBack: @escaping ([ContactItem]) -> Void,
                                            failedCallBack: @escaping (Error?) -> Void) {
        getFormatContactDataAsync(hostProvider: hostProvider,
                                  limitCount: limitCount,
                                  successCallBack: {  [weak self] contacts in
                guard let self = self, let contacts = contacts else {
                    failedCallBack(nil)
                    return
                }

                let contactPoints: [String] = self.transformContactsToCPs(contacts: contacts)
                var handledContactPoints: [String] = contactPoints
                if let limitCount = limitCount {
                    handledContactPoints = [String](contactPoints.prefix(limitCount))
                }
                Tracer.trackStartOnbardingCNUploadTimingMs()
                let disposeKey = Tracer.trackOnbardingFetchRecUserStart()
                self.getUserInfosByContactPointsAsnyc(
                    contactPoints: handledContactPoints,
                    successCallBack: { [weak self] cpUserInfos in
                        guard let self = self else { return }
                        let contactItems = self.transformContactDataToItems(cpUserInfos: cpUserInfos, contacts: contacts)
                        successCallBack(contactItems)
                        Tracer.trackOnbardingCNUploadSuccess()
                        Tracer.trackOnbardingFetchRecUserEnd(disposeKey: disposeKey)
                    }, failedCallBack: { error in
                        failedCallBack(error)
                        Tracer.trackEndOnbardingCNUploadTimingMs()
                        if let error = error.underlyingError as? APIError {
                            Tracer.trackOnbardingCNUploadFail(errorCode: error.code, errorMsg: error.debugDescription)
                        }
                    })
        }) { (error) in
            failedCallBack(error)
        }
    }

    /// for onboarding
    func getLocalContactsAsyncForOnboarding(hostProvider: UIViewController,
                                            successCallBack: @escaping ([AddressBookContact]) -> Void,
                                            failedCallBack: @escaping (NSError?) -> Void) {
        let title = BundleI18n.LarkContact.Lark_NewContacts_OnboardingPeopleYouMayKnowLoading
        let hud = UDToast.showLoading(with: title, on: hostProvider.view, disableUserInteraction: true)
        let bizType = BizType.onboarding
        self.getLocalContactsAsync(hostProvider: hostProvider, bizType: bizType, successCallBack: { contacts in
            DispatchQueue.main.async {
                hud.remove()
                successCallBack(contacts)
            }
        }, failedCallBack: { error in
            DispatchQueue.main.async {
                hud.remove()
                failedCallBack(error)
            }
        })
    }
}

/// Util
extension ContactDataManager {

    private func transformContactsToCPs(contacts: [AddressBookContact]) -> [String] {
        var contactPoints: [String] = []
        var phoneCount = 0
        var emailCount = 0
        contacts.forEach { addressBookContact in
            if let email = addressBookContact.email,
                let verifyEmail = self.getVerifyContactPoint(contactPoint: email) {
                contactPoints.lf_appendIfNotContains(verifyEmail)
                emailCount += 1
            }
            if let phoneNumber = transformPhoneNumber(phoneNumber: addressBookContact.phoneNumber) {
                contactPoints.lf_appendIfNotContains(phoneNumber)
                phoneCount += 1
            }
        }
        Tracer.trackFetchPhoneCountHandled(count: phoneCount)
        Tracer.trackFetchEmailCountHandled(count: emailCount)
        return contactPoints
    }

    private func transformPhoneNumber(phoneNumber: String?) -> String? {
        if let phoneNumber = phoneNumber,
            let verifyPhoneNumber = self.getVerifyContactPoint(contactPoint: phoneNumber),
            let defaultRegion = self.getPhoneRegionCode(phoneNumber: verifyPhoneNumber),
            let result = try? self.phoneUtil.parse(verifyPhoneNumber, defaultRegion: defaultRegion),
            let qualifiedPhoneNumber = try? self.phoneUtil.format(result, numberFormat: .E164) {
            return qualifiedPhoneNumber
        }
        return nil
    }

    private func transformContactDataToItems(cpUserInfos: [ContactPointUserInfo],
                                             contacts: [AddressBookContact]) -> [ContactItem] {

        let contactItems = cpUserInfos.map({ cpUserInfo -> ContactItem in
            let userInfo = cpUserInfo.userInfo
            /// 找到对应CP的通讯录联系人的名字
            let detail: String = contacts.first { contact -> Bool in
                let phoneNumber = self.transformPhoneNumber(phoneNumber: contact.phoneNumber) ?? contact.phoneNumber
                return [phoneNumber, contact.email].contains(cpUserInfo.contactPoint)
            }?.fullName ?? ""
            return ContactItem(title: userInfo.userName,
                               detail: detail,
                               avatarKey: userInfo.avatarKey,
                               contactInfo: cpUserInfo)
        })
        return contactItems
    }

    private func getVerifyContactPoint(contactPoint: String) -> String? {
        let isMail = contactPoint.contains("@")
        if isMail {
            let pureMail = self.verificationViewModel.getPureEmail(contactPoint)
            if self.verificationViewModel.verifyEmailValidation(pureMail) {
                return pureMail
            }
        } else {
            // phone
            let purePhoneInfo = self.verificationViewModel.getDisassemblePhoneNumber(content: contactPoint)
            let purePhone = purePhoneInfo.countryCode + purePhoneInfo.phoneNumber
            if self.verificationViewModel.verifyPhoneNumberValidation(purePhone) {
                return purePhone
            }
        }
        return nil
    }

    private func getPhoneRegionCode(phoneNumber: String) -> String? {
        let purePhoneInfo = self.verificationViewModel.getDisassemblePhoneNumber(content: phoneNumber)
        if let countryCode = Int(purePhoneInfo.countryCode),
            let defaultRegion = self.phoneUtil.getRegionCode(forCountryCode: NSNumber(value: countryCode)) {
            return defaultRegion
        }
        return nil
    }
}
