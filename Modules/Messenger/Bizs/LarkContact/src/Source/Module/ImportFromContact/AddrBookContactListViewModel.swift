//
//  SingleRelationContactListViewModel.swift
//  LarkContact
//
//  Created by mochangxing on 2020/7/14.
//

import UIKit
import Foundation
import RxCocoa
import LarkAddressBookSelector
import RustPB
import LarkContainer
import LarkSDKInterface
import LarkAccountInterface
import RxSwift
import LarkAppConfig
import AppReciableSDK
import LarkStorage
import LarkSensitivityControl

typealias AddressBookContactTuple = (String, AddressBookContact, ContactContentType)
final class AddrBookContactListViewModel: UserResolverWrapper {

    enum ViewStatus {
        case loading  // 加载中
        case loadFinish //加载完成
        case meetError //加载失败
    }
    private let disposeBag = DisposeBag()
    private let addContactScene: AddContactScene
    private let vmVariable = BehaviorRelay<[AddrBookContactSubViewModel]>(value: [])
    var userResolver: LarkContainer.UserResolver
    private let passportService: PassportService?
    @ScopedProvider private var chatApplicationAPI: ChatApplicationAPI?
    @ScopedProvider private var appConfiguration: AppConfiguration?
    private lazy var userStore = udkv(domain: contactDomain)
    let contactTypes: [ContactType]

    var reloadDriver: Driver<Int> {
        return vmVariable.asDriver().map { (subViewModels) -> Int in
            if self.addContactScene == .onBoarding && subViewModels.count > 1 {
                return 1
            }
            let firstNoEmptyIndex = subViewModels.firstIndex { !$0.isEmpty() }
            return firstNoEmptyIndex ?? 0
        }
    }

    private var statusVariable = BehaviorRelay<ViewStatus>(value: .loading)

    var statusDirver: Driver<ViewStatus> {
        return statusVariable.asDriver()
    }

    var subViewModels: [AddrBookContactSubViewModel] {
        return vmVariable.value
    }

    private var apprecibleTrackFlag = true

    // server 请求完成标志位
    private var serverReqFinished = false

    // local 数据刷新标志位
    private var localReqFinished = false

    init(addContactScene: AddContactScene,
         resolver: UserResolver) {
        self.addContactScene = addContactScene
        self.userResolver = resolver
        self.passportService = try? resolver.resolve(assert: PassportService.self)
        switch addContactScene {
        case .importFromContact, .onBoarding, .newContact:
            self.contactTypes = [.using, .notYet]
        }
    }

    func searchContact(_ searchkey: String) {
        vmVariable.value.forEach { (viewModel) in
            viewModel.searchContact(searchkey)
        }
    }

    func fetchContactList() {
        self.statusVariable.accept(.loading)
        getContactsAsync()
    }

    private func tryToTrackAppreciblePoint(cost: CFTimeInterval, memberCount: Int, isNeedNet: Bool) {
        guard apprecibleTrackFlag else { return }
        apprecibleTrackFlag = false
        AddressBookAppReciableTrack.updateAddressBookPageTrackData(sdkCost: cost, memberCount: memberCount)
        AddressBookAppReciableTrack.addressBookPageLoadingTimeEnd(isNeedNet: isNeedNet)
    }

    func getContactsAsync() {
        ContactService.getContactsAsync(token: Token("LARK-PSDA-contact_address_book_list"),
                                        successCallback: { [weak self] (contacts) in
            guard let self = self else { return }
            let tuples = self.getAddressBookContactTupleList(contacts.allContacts)
            self.getServerAddressBookContactList(tuples)
            self.getLocalAddressBookContactList(tuples)
        }) { (error) in
            AddressBookAppReciableTrack.addressBookPageError(isNewPage: true,
                                                  errorCode: error.error?.code ?? -1,
                                                  errorType: .Other,
                                                  errorMessage: error.error?.localizedDescription)
            self.statusVariable.accept(.meetError)
        }
    }

    func getAddressBookContactTupleList(_ allContacts: [AddressBookContact]) -> [AddressBookContactTuple] {
        var tuples: [AddressBookContactTuple] = []
        guard let passportService = self.passportService else { return tuples }
        let isOversea = passportService.isOversea
        let verification = VerificationBaseViewModel(isOversea: isOversea)

        // 记录已添加的手机号
        var addedPhoneNumber: [String: Bool] = [:]
        allContacts.forEach({ (addressContact) in
            if let email = addressContact.email,
                !email.isEmpty,
                verification.verifyEmailValidation(email) {
                tuples.append((verification.getPureEmail(email), addressContact, .email))
            }
            if let phoneNumber = addressContact.phoneNumber,
                !phoneNumber.isEmpty,
                verification.verifyPhoneNumberValidation(phoneNumber) {
                let (countryCode, phoneNumber) = verification.getDisassemblePhoneNumber(content: phoneNumber)
                let fullPhoneNumber = countryCode + phoneNumber

                // 手机号去重
                if !(addedPhoneNumber[fullPhoneNumber] ?? false) {
                    tuples.append((fullPhoneNumber, addressContact, .phone))
                    addedPhoneNumber[fullPhoneNumber] = true
                }
            }
        })
        return tuples
    }

    func getServerAddressBookContactList(_ addressBookContactTuple: [AddressBookContactTuple]) {
        let timelineMark = userStore[KVKeys.Contact.uploadServerTimelineMark].map { Int64($0) }
        Tracer.trackStartContactListFetchTimingMs()
        let startTime = CACurrentMediaTime()
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              event: .contactOptFetchContactList,
                                              page: nil)

        self.chatApplicationAPI?.getAddressBookContactList(timelineMark: timelineMark,
                                                          contactPoints: addressBookContactTuple.map({ $0.0 }),
                                                          strategy: .forceServer)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else { return }
                self.serverReqFinished = true
                let userCount = response.cpUserInfos.reduce(0) { (result, arg1) -> Int in
                    let (_, cpUserList) = arg1
                    return result + cpUserList.users.count
                }
                AppReciableSDK.shared.end(key: key)
                Tracer.trackEndContactListFetchTimingMs(availableCpCount: response.cpUserInfos.count,
                                                        availableUserCount: userCount)
                self.userStore[KVKeys.Contact.uploadServerTimelineMark] = Double(response.newTimelineMark)
                self.createSubViewModels(addressBookContactTuple: addressBookContactTuple,
                                         cpUserInfos: response.cpUserInfos,
                                         cost: CACurrentMediaTime() - startTime)
            }, onError: { [weak self] (error) in
                if let apiError = error.underlyingError as? APIError {
                    Tracer.trackFetchContactListFail(errorCode: apiError.code, errorMsg: "\(apiError)")
                    AddressBookAppReciableTrack.addressBookPageError(isNewPage: true,
                                                          errorCode: Int(apiError.code),
                                                          errorType: .SDK,
                                                          errorMessage: apiError.localizedDescription)
                } else {
                    AddressBookAppReciableTrack.addressBookPageError(isNewPage: true,
                                                          errorCode: (error as NSError).code,
                                                          errorType: .SDK,
                                                          errorMessage: (error as NSError).localizedDescription)
                }
                // local 有数据, server error 不处理
                guard let self = self, !self.localReqFinished else { return }
                self.serverReqFinished = true
                self.statusVariable.accept(.meetError)

            }).disposed(by: disposeBag)
    }

    private func getOriginalCP(_ addressBookContactTuple: AddressBookContactTuple) -> String {
        switch addressBookContactTuple.2 {
        case .email:
            return addressBookContactTuple.1.email ?? ""
        case .phone:
            return addressBookContactTuple.1.phoneNumber ?? ""
        }
    }

    func createSubViewModels(addressBookContactTuple: [AddressBookContactTuple],
                             cpUserInfos: [String: Contact_V2_ContactPointUserList],
                             cost: CFTimeInterval) {
        var notYetCellVMs: [AddrBookContactCellViewModel] = []
        var usingSectionDataList: [ContactListSectionData] = []

        addressBookContactTuple.forEach { addressBookContactTuple in
            if let cpUserList = cpUserInfos[addressBookContactTuple.0] {
                let cellVMList = cpUserList.users
                    .filter { !$0.shouldHidden }
                    .map { createUsingCellViewModel($0) }

                guard !cellVMList.isEmpty else { return }

                let emailOrPhone = getOriginalCP(addressBookContactTuple)
                let sectionHeader = AddrBookContactSectionHeaderModel(
                        userName: addressBookContactTuple.1.fullName,
                        cp: emailOrPhone)

                let sectionData = (sectionHeader, cellVMList)
                usingSectionDataList.append(sectionData)
            } else {
                notYetCellVMs.append(cearteNotYetCellViewModel(addressBookContactTuple))
            }
        }

        let subViewModels = self.contactTypes.map { (contactType) -> AddrBookContactSubViewModel in
            switch contactType {
            case .notYet:
                return AddrBookContactSubViewModel(viewStyle: self.subViewStyle(contactType),
                                                 sectionDataList: notYetCellVMs.isEmpty ? [] : [(AddrBookContactSectionHeaderModel(userName: "", cp: ""), notYetCellVMs)],
                                                   resolver: userResolver)
            case .using:
                return AddrBookContactSubViewModel(viewStyle: self.subViewStyle(contactType),
                                                     sectionDataList: usingSectionDataList,
                                                   resolver: userResolver)
            }
        }

        self.vmVariable.accept(subViewModels)
        let memberCount = subViewModels.reduce(0) { (result, model) -> Int in
            result + (model.sectionDatas.first?.1.count ?? 0)
        }
        self.tryToTrackAppreciblePoint(cost: cost, memberCount: memberCount, isNeedNet: true)
        self.statusVariable.accept(.loadFinish)
    }

    func cearteNotYetCellViewModel(_ addressBookContactTuple: AddressBookContactTuple) -> AddrBookContactCellViewModel {
        let contactModel = AddrBookContactModel(contactType: .notYet,
                                                   notYetContact: NotYetUsingContact(addressBookContact: addressBookContactTuple.1,
                                                                                     inviteStatus: .invite,
                                                                                     addressBookContactType: addressBookContactTuple.2))
        return AddrBookContactCellViewModel(contactModel: contactModel)
    }

    func createUsingCellViewModel(_ cpUserList: Contact_V2_ContactPointUserInfo) -> AddrBookContactCellViewModel {
        let contactModel = AddrBookContactModel(contactType: .using,
                                                          usingContact: cpUserList)
        return AddrBookContactCellViewModel(contactModel: contactModel)
    }

    func subViewStyle(_ contactType: ContactType) -> AddrBookContactSubViewModel.ViewStyle {
        switch contactType {
        case .using:
            return .multiSection
        case .notYet:
            return .singleSection
        }
    }

    func addContactSuccess(userId: String) {
        self.subViewModels.filter { (subVM) -> Bool in
            subVM.viewStyle == self.subViewStyle(.using)
        }.forEach { (subVM) in
            subVM.addContactSuccess(userId: userId)
        }
    }

    func updateUsingContact(_ userIds: [String]) {
        self.subViewModels.filter { (subVM) -> Bool in
            subVM.viewStyle == self.subViewStyle(.using)
        }.forEach { (subVM) in
            subVM.agreedApplication(userIds)
        }
    }

    func getLocalAddressBookContactList(_ addressBookContactTuple: [AddressBookContactTuple]) {
        let startTime = CACurrentMediaTime()

        self.chatApplicationAPI?.getAddressBookContactList(timelineMark: nil,
                                                          contactPoints: addressBookContactTuple.map({ $0.0 }),
                                                          strategy: .local)
            .subscribe(onNext: { [weak self] (response) in
                // server 未返回，local 不为空
                guard let self = self,
                      !self.serverReqFinished,
                      !response.cpUserInfos.isEmpty else { return }
                self.localReqFinished = true
                self.createSubViewModels(addressBookContactTuple: addressBookContactTuple,
                                          cpUserInfos: response.cpUserInfos,
                                          cost: CACurrentMediaTime() - startTime)
            }).disposed(by: disposeBag)
    }

}
