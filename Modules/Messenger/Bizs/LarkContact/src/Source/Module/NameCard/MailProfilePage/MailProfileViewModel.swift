//
//  MailProfileViewModel.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/27.
//

import Foundation
import RxCocoa
import RxSwift
import LarkSDKInterface
import RustPB
import LarkContainer
import LarkMessengerInterface
import LKCommonsLogging
import SwiftProtobuf
import LarkLocalizations
import AppReciableSDK

enum MailProfileViewModelState {
    case loading
    case infoData(userProfile: NameCardUserProfile)
    case error
}

enum MailProfileViewModelRouter {
    case none
}

protocol MailProfileViewModel: AnyObject {
    var displayEmail: String { get }

    var namecardId: String { get }

    var userName: String { get }

    var accountID: String { get }

    var accountType: String { get }

    var callback: ((Bool) -> Void)? { get }

    var state: Driver<MailProfileViewModelState> { get }

    var router: Driver<MailProfileViewModelRouter> { get }

    func loadProfileInfo()

    func removeNameCard()

    func fetchAccountTypeAndTrack()
}

final class MailProfileViewModelImp: MailProfileViewModel, UserResolverWrapper {
    static let logger = Logger.log(MailProfileViewModelImp.self, category: "MailProfile")

    var userResolver: LarkContainer.UserResolver
    // MARK: property
    @ScopedInjectedLazy var nameCardAPI: NamecardAPI?

    var namecardID: String

    var userName: String

    let accountID: String

    let email: String

    var accountType: String = "None"

    var callback: ((Bool) -> Void)?

    let disposeBag = DisposeBag()

    // MARK: public property
    var displayEmail: String {
        return email
    }

    var namecardId: String {
        return namecardID
    }

    private var _state: BehaviorRelay<MailProfileViewModelState> // 在第一次被人订阅的时候会先吐默认值
    var state: Driver<MailProfileViewModelState> {
        return _state.asDriver()
    }

    private var _router: PublishSubject<MailProfileViewModelRouter> = PublishSubject<MailProfileViewModelRouter>()
    var router: Driver<MailProfileViewModelRouter> {
        return _router.asDriver(onErrorJustReturn: .none)
    }

    init(namecardID: String, email: String, accountID: String, resolver: UserResolver, userName: String = "", callback: ((Bool) -> Void)? = nil) {
        self.namecardID = namecardID
        self.email = email
        self.userName = userName
        self.accountID = accountID
        self.callback = callback
        self.userResolver = resolver
        self._state = BehaviorRelay<MailProfileViewModelState>(value: .loading)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshNameCardData), name: .LKNameCardEditNotification, object: nil)
    }

    func loadProfileInfo() {
        getNameCardProfileInformation()
        fetchNameCardInformation()
    }

    @objc
    func refreshNameCardData() {
        fetchNameCardInformation()
    }

    func fetchAccountTypeAndTrack() {
        fetchAccountType()
    }
}

// MARK: data
extension MailProfileViewModelImp {
    private func getNameCardProfileInformation() {
        /// 名片夹信息获取本地缓存
        self.nameCardAPI?.getLocalNamecardProfile(self.namecardID, email: self.email, accountID: self.accountID)
            .subscribe(onNext: { [weak self] (localData) in
                self?.updateNameCardData(localData)
            }, onError: { [weak self] (e) in
                guard let self = self else {
                    return
                }
                self.handleInfoError(error: e)
            }).disposed(by: disposeBag)
    }

    private func fetchNameCardInformation() {
        self.nameCardAPI?.getRemoteNamecardProfile(self.namecardID, email: self.email, accountID: self.accountID)
            .subscribe(onNext: { [weak self] (remoteData) in
                self?.updateNameCardData(remoteData)
            }, onError: { [weak self] (e) in
                guard let self = self else {
                    return
                }
                self.handleInfoError(error: e)
            }).disposed(by: disposeBag)
    }

    /// 删除名片夹联系人
    func removeNameCard() {
        self.nameCardAPI?
            .deleteSingleNamecard(self.namecardID, accountID: self.accountID, address: self.email)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if !self.namecardID.isEmpty {
                    NotificationCenter.default.post(name: .LKNameCardEditNotification, object: nil, userInfo: ["id": self.namecardID])
                }
                NotificationCenter.default.post(name: .LKNameCardDeleteNotification,
                                                object: nil,
                                                userInfo: ["id": self.namecardID, "accountID": self.accountID])
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                MailProfileViewModelImp.logger.error("mail profile delete failed namecardId = \(self.namecardId)", error: error)
                let reciableError = ErrorParams(biz: .Mail, scene: .Unknown, eventable: MailContactEvent.contactDeleteFail,
                                                errorType: .Unknown, errorLevel: .Exception, userAction: nil,
                                                page: "mailContact", errorMessage: "mail profile delete failed namecardId = \(self.namecardId) error: \(error)", extra: nil)
                AppReciableSDK.shared.error(params: reciableError)
            }).disposed(by: self.disposeBag)
    }

    private func fetchAccountType() {
        nameCardAPI?.getCurrentMailAccountType()
            .subscribe(onNext: { [weak self] type in
                guard let self = self else { return }
                self.accountType = type
                MailProfileStatistics.view(accountType: type)
            }, onError: { _ in
                MailProfileStatistics.view(accountType: "None")
            }).disposed(by: disposeBag)
    }

    // MARK: 懒了 不想抽
    private func updateNameCardData(_ nameCardProfile: NameCardUserProfile) {
        // 一些兜底兼容逻辑
        if nameCardProfile.userInfo.namecardID != "0" {
            self.namecardID = nameCardProfile.userInfo.namecardID
        }
        var temp = nameCardProfile
        _state.accept(.infoData(userProfile: temp))
    }

    private func handleInfoError(error: Error) {
        _state.accept(.error)
    }

    private func setI18NVal(_ i18Names: I18nVal) -> String {
        let i18NVal = i18Names.i18NVals
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        if let result = i18NVal[currentLocalizations],
            !result.isEmpty {
            return result
        } else {
            return i18Names.defaultVal
        }
    }
}

enum MailContactEvent: String, ReciableEventable {
    var eventKey: String {
        return self.rawValue
    }
    /// when you dont need end. you can use it
    case contactDeleteFail = "concat_delete_fail"
    case contactSaveFail = "concat_save_fail"
}
