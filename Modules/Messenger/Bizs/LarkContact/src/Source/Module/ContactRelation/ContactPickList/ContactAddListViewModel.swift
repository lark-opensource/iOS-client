//
//  ContactAddListViewModel.swift
//  LarkContact
//
//  Created by zhenning on 2020/07/10.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkAddressBookSelector
import libPhoneNumber_iOS
import LarkExtensions
import LKCommonsLogging
import LarkModel
import LarkAccountInterface
import LarkContainer
import LarkStorage

public struct ContactAddTextInfo {
    var title: String?
    var skipText: String?
    var confirmText: String?
    public init(title: String? = nil,
         skipText: String? = nil,
         confirmText: String? = nil) {
        self.title = title
        self.confirmText = confirmText
        self.skipText = skipText
    }
}

enum ContactAddLoadingStatus {
    case none       // 未开始
    case emptyData  // 空数据
    case start      // 开始，显示loading
    case finish     // 结束，隐藏loading
    case error      // 加载出错，显示retry界面
}

public final class ContactAddListViewModel: UserResolverWrapper {
    static let logger = Logger.log(ContactAddListViewModel.self, category: "LarkContact")

    var contacts: [ContactItem] = [] {
        didSet {
            reloadDataSubject.onNext(())
        }
    }
    private var applyedContacts: [ContactItem] {
        /// 已发送好友申请
        return self.contacts
            .filter { return $0.applyStatus == .contactStatusRequest }
    }

    private var limitCount: Int = 200
    private let isOversea: Bool
    var isShowBehaviorPush: Bool = false
    private lazy var externalInviteAPI: ExternalInviteAPI = {
        return ExternalInviteAPI(resolver: self.userResolver)
    }()

    var textInfo: ContactAddTextInfo {
        didSet {
            textInfo.title = textInfo.title ?? BundleI18n.LarkContact.Lark_NewContacts_OnboardingPeopleYouMayKnow
            textInfo.skipText = textInfo.skipText ?? BundleI18n.LarkContact.Lark_NewContacts_OnboardingPeopleYouMayKnowSkip
            textInfo.confirmText = textInfo.confirmText ?? BundleI18n.LarkContact.Lark_Legacy_Completed
        }
    }
    /// 导航右边按钮文案
    var rightNaviItemText: String {
        let hasApplyedContacts = !applyedContacts.isEmpty
        return (hasApplyedContacts ? self.textInfo.confirmText : self.textInfo.skipText) ?? ""
    }
    private lazy var userStore = udkv(domain: contactDomain)

    let disposeBag: DisposeBag = DisposeBag()

    private(set) var loadingStatusSubject = PublishSubject<ContactAddLoadingStatus>()
    private(set) lazy var loadingStatusDriver: Driver<ContactAddLoadingStatus> = {
        return loadingStatusSubject.asDriver(onErrorJustReturn: .error)
    }()

    private let reloadDataSubject: PublishSubject<Void> = PublishSubject()
    var reloadDataDriver: Driver<Void> {
        return reloadDataSubject.asDriver(onErrorJustReturn: ())
    }

    @ScopedProvider private var dataManager: ContactDataService?
    @ScopedInjectedLazy var router: ContactAddListRouter?
    public var userResolver: LarkContainer.UserResolver

    init(isOversea: Bool,
         resolver: UserResolver,
         isShowBehaviorPush: Bool? = false,
         contacts: [ContactItem]? = nil,
         textInfo: ContactAddTextInfo? = nil) {
        self.isOversea = isOversea
        self.userResolver = resolver
        self.isShowBehaviorPush = isShowBehaviorPush ?? false
        let defaultTextInfo = ContactAddTextInfo(
            title: BundleI18n.LarkContact.Lark_NewContacts_OnboardingPeopleYouMayKnow,
            skipText: BundleI18n.LarkContact.Lark_NewContacts_OnboardingPeopleYouMayKnowSkip,
            confirmText: BundleI18n.LarkContact.Lark_Legacy_Completed)
        self.textInfo = textInfo ?? defaultTextInfo

        if let onboardingUploadContactsMaxNum = self.userStore[KVKeys.Contact.onboardingUploadContactsMaxNum] {
            self.limitCount = onboardingUploadContactsMaxNum
            ContactAddListViewModel.logger.debug("userStore", additionalData: [
                "onboardingUploadContactsMaxNum": "\(onboardingUploadContactsMaxNum)"
            ])
        }
        self.contacts = contacts ?? []
    }

    func fetchContactData(callback: ((Error?) -> Void)? = nil) {
        /// start loading request
        self.loadingStatusSubject.onNext(.start)
        self.getRecommandUserInfosAsync(limitCount: self.limitCount,
                                        successCallBack: { [weak self] contactItems in
            guard let self = self else { return }

            self.contacts = contactItems
            self.loadingStatusSubject.onNext(self.contacts.isEmpty ? .emptyData : .finish)
            ContactAddListViewModel.logger.debug("getRecommandUserInfosAsync success!",
                                                 additionalData: ["contactItems count": "\(contactItems.count)"])
            Tracer.trackOnbardingFetchRecUserCount(count: self.contacts.count)
            callback?(nil)
        }, failedCallBack: { error in
            self.loadingStatusSubject.onNext(.error)
            ContactAddListViewModel.logger.error("getRecommandUserInfosAsync failed!", error: error)
            callback?(error)
        })
    }
    /// 获取Onboarding推荐用户列表
    func getRecommandUserInfosAsync(hostProvider: UIViewController? = nil,
                                    limitCount: Int? = nil,
                                    successCallBack: @escaping ([ContactItem]) -> Void,
                                    failedCallBack: @escaping (Error?) -> Void) {

        self.dataManager?.getContactUserInfosOfContactsAsnyc(hostProvider: hostProvider,
                                                             limitCount: limitCount,
                                                             successCallBack: { contactItems in
            successCallBack(contactItems)
        }, failedCallBack: { error in
            failedCallBack(error)
            ContactAddListViewModel.logger.error("getContactUserInfosOfContactsAsnyc failed", error: error)
        })
    }

    func updateContact(contact: ContactItem) {
        if self.contacts.contains(contact),
            let index = self.contacts.firstIndex(where: { $0.contactInfo == contact.contactInfo }) {
            var tmpContacts = self.contacts
            tmpContacts[index] = contact
            self.contacts = tmpContacts
            ContactAddListViewModel.logger.debug("updateContact index = \(index)")
        }
        ContactAddListViewModel.logger.debug("updateContact contact = \(contact)")
    }

    // 获取邀请信息
    func fetchInviteLinkInfo() -> Observable<InviteAggregationInfo> {
        return self.externalInviteAPI.fetchInviteAggregationInfoFromServer()
    }
}

// track
extension ContactAddListViewModel {

    func trackOnboardingSystemInvite() {
        Tracer.trackOnboardingSystemInvite()
    }

    func trackOnbardingAddContactShow() {
        Tracer.trackOnbardingAddContactShow()
    }

    func trackOnbardingAddContactSkip() {
        Tracer.trackOnbardingAddContactSkip()
    }

    func trackOnbardingAddContactConfirm() {
        Tracer.trackOnbardingAddContactConfirm()
    }
}
