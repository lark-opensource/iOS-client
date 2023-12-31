//
//  MailContactListViewModel.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/13.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkUIKit
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import ThreadSafeDataStructure
import LarkFeatureGating
import LarkMessengerInterface
import RustPB
import EENavigator
import LarkTag
import AppReciableSDK

extension NameCardInfo: NameCardListCellViewModel {
    var tagText: String {
        ""
    }

    var displayTitle: String {
        return name
    }

    var displaySubTitle: String {
        return companyName
    }

    var avatarImage: UIImage? {
        return avatarKey.isEmpty
        ? MailGroupHelper.generateAvatarImage(withNameString: name, shouldPrefix: true)
        : nil
    }

    var itemTags: [Tag]? {
        return nil
    }

    // action
    func didSelect(fromVC: UIViewController, accountID: String, resolver: UserResolver) {
        let body = NameCardProfileBody(accountId: accountID, namecardId: self.namecardId)
        resolver.navigator.presentOrPush(body: body,
                                       wrap: LkNavigationController.self,
                                       from: fromVC,
                                       prepareForPresent: { (vc) in
           vc.modalPresentationStyle = .formSheet
        })
    }
}

final class MailContactListViewModel: NameCardListViewModel {
    static let logger = Logger.log(NameCardListViewModel.self, category: "NameCardList")

    private let nameCardAPI: NamecardAPI
    private let accountType: String
    private let disposeBag = DisposeBag()
    private var lastNameCardId: String? = "0"
    private var accountInfo: MailAccountBriefInfo

    private var datasource: [NameCardInfo] = [] {
        didSet {
            if datasource.isEmpty {
                self.datasourceSubject.onNext(.empty)
            } else {
                self.datasourceSubject.onNext(.success(datasource: datasource))
            }
        }
    }

    var headerTitle: String? {
        if accountInfo == MailAccountBriefInfo.empty {
            return nil
        } else {
            let count = accountInfo.nameCardTotalCount > datasource.count ? accountInfo.nameCardTotalCount : datasource.count
            return BundleI18n.LarkContact.Mail_ThirdClient_NumContacts(count)
        }
    }

    var canLeftDelete: Bool {
        return true
    }

    var mailAddress: String {
        return accountInfo.displayAddress
    }

    var accountID: String {
        return accountInfo.accountID
    }

    var mailAccountType: String {
        return accountType
    }

    // 首次加载服务端数据是否完成
    private(set) var serverRequestFinished: Bool = false

    public var hasMore: Bool = false
    private let itemRemoveSubject: BehaviorSubject<Int> = BehaviorSubject<Int>(value: 0)
    private let datasourceSubject: BehaviorSubject<NameCardListResult> = BehaviorSubject<NameCardListResult>(value: .empty)
    let pageSize: Int = 20
    private var isLoading = false

    // 区分是嵌套在一级界面还是push出来的
    let asChildList: Bool

    var datasourceDriver: Driver<NameCardListResult> {
        return datasourceSubject.asDriver(onErrorJustReturn: .empty).skip(1)
    }

    var itemRemoveDriver: Driver<Int>? {
        return itemRemoveSubject.asDriver(onErrorJustReturn: 0).skip(1)
    }

    init(nameCardAPI: NamecardAPI, accountType: String, accountInfo: MailAccountBriefInfo, asChildList: Bool = false) {
        self.nameCardAPI = nameCardAPI
        self.accountType = accountType
        self.accountInfo = accountInfo
        self.asChildList = asChildList
    }

    func fetchNameCardList(isRefresh: Bool) {
        MailContactListViewModel.logger.info("NameCardList start fetch",
                                             additionalData: [
                                                "isRefresh": "\(String(describing: isRefresh))",
                                                "lastNamecardId": "\(String(describing: self.lastNameCardId))"
                                             ])
        if isLoading { return }
        isLoading = true
        if isRefresh {
            self.lastNameCardId = "0"
            self.checkContactsCount()
        }
        self.nameCardAPI.getNamecardList(namecardId: self.lastNameCardId ?? "0",
                                         accountID: self.accountInfo.accountID,
                                         limit: self.pageSize)
            .subscribe(onNext: { [weak self] nameCardListData in
                guard let self = self else { return }
                self.isLoading = false
                self.serverRequestFinished = true
                let list = nameCardListData.list
                var datasource = self.datasource
                if isRefresh {
                    datasource = list
                } else {
                    datasource.append(contentsOf: list)
                }
                self.lastNameCardId = datasource.last?.namecardId
                self.datasource = datasource
                self.hasMore = nameCardListData.hasMore
                MailContactListViewModel.logger.info("NameCardList fetch success!",
                                                     additionalData: [
                                                        "nameCardList count": "\(nameCardListData.list.count)",
                                                        "isRefresh": "\(String(describing: isRefresh))",
                                                        "hasMore": "\(self.hasMore)",
                                                        "lastNamecardId": "\(String(describing: self.lastNameCardId))"
                                                     ])
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    self.isLoading = false
                    self.datasourceSubject.onNext(.failure(error: error))
                    MailContactListViewModel.logger.error("NameCardList fetch failed!",
                                                          additionalData: [
                                                            "serverRequestFinished": "\(self.serverRequestFinished)",
                                                            "isRefresh": "\(String(describing: isRefresh))",
                                                            "lastNamecardId": "\(String(describing: self.lastNameCardId))"],
                                                          error: error)
            }).disposed(by: self.disposeBag)
    }

    func checkContactsCount() {
        nameCardAPI.getAllMailAccountDetail(latest: true)
            .subscribe(onNext: { [weak self] infos in
                guard let self = self,
                      let info = infos.first(where: { $0.accountID == self.accountID }),
                      info.nameCardTotalCount != self.accountInfo.nameCardTotalCount
                else { return }
                self.changeAccount(info)
                NotificationCenter.default.post(name: .LKNameCardEditNotification, object: nil)
            }).disposed(by: disposeBag)
    }

    func changeAccount(_ accountInfo: MailAccountBriefInfo) {
        self.accountInfo = accountInfo
        self.lastNameCardId = "0"
        self.fetchNameCardList(isRefresh: true)
    }

    func removeData(deleteNameCardInfo: NameCardListCellViewModel, atIndex: Int) {
        guard let info = deleteNameCardInfo as? NameCardInfo else {
            return
        }
        itemRemoveSubject.onNext(atIndex)
        let nameCardId = info.namecardId
        self.nameCardAPI
            .deleteSingleNamecard(nameCardId, accountID: accountInfo.accountID, address: info.email)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if nameCardId == self.lastNameCardId {
                    self.lastNameCardId = self.datasource.last?.namecardId
                }
                self.datasource.remove(at: atIndex)
                if self.datasource.count <= self.pageSize, self.hasMore {
                    self.fetchNameCardList(isRefresh: false)
                }
                NotificationCenter.default.post(name: .LKNameCardDeleteNotification,
                                                object: nil,
                                                userInfo: ["id": nameCardId, "accountID": self.accountID])
                MailContactListViewModel.logger.info("NameCardList delete success namecardId = \(nameCardId)")
            }, onError: { (error) in
                MailContactListViewModel.logger.error("NameCardList delete failed namecardId = \(nameCardId)", error: error)
                let reciableError = ErrorParams(biz: .Mail, scene: .Unknown, eventable: MailContactEvent.contactDeleteFail,
                                                errorType: .Unknown, errorLevel: .Exception, errorCode: 0, userAction: nil,
                                                page: "mailContact", errorMessage: "NameCardList delete failed namecardId = \(nameCardId) error: \(error)", extra: nil)
                AppReciableSDK.shared.error(params: reciableError)
            }).disposed(by: self.disposeBag)
    }

    func handleContactRemovePush(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let nameCardID = userInfo["id"] as? String,
              let index = datasource.firstIndex(where: { $0.namecardId == nameCardID })
        else { return }
        itemRemoveSubject.onNext(index)
    }

    func enableRemveAction(item: NameCardListCellViewModel) -> Bool {
        return true
    }

    func pageDidView() {}
}
