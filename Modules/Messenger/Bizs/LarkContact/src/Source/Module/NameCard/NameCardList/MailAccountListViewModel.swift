//
//  MailAccountListViewModel.swift
//  LarkContact
//
//  Created by Quanze Gao on 2022/4/18.
//

import Foundation
import RxSwift
import UIKit
import UniverseDesignIcon
import LarkSDKInterface
import LKCommonsLogging
import EENavigator
import RustPB
import LarkFeatureGating
import LarkContainer
import LarkSetting

extension MailAccountBriefInfo {
    var displayAddress: String {
        // 没有绑定邮箱账号的联系人统一归到默认账号下
        if userType == Email_Client_V1_Setting.UserType.noPrimaryAddressUser.rawValue || userType == Email_Client_V1_Setting.UserType.newUser.rawValue {
            return BundleI18n.LarkContact.Mail_ThirdClient_MyContacts
        } else {
            return address
        }
    }

    func toSectionModel(fgService: FeatureGatingService) -> MailAccountListSectionModel {
        var models: [MailAccountDetailCellModel] = []
        /// 联系人为 0 时也需要显示
        models.append(MailAccountDetailCellModel(type: .contact,
                                                 icon: UDIcon.contactsOutlined.withRenderingMode(.alwaysTemplate),
                                                 title: "\(BundleI18n.LarkContact.Mail_ThirdClient_AddToAccountContacts) (\(nameCardTotalCount))"))
        if mailGroupTotalCount > 0 && fgService.staticFeatureGatingValue(with: "larkmail.contact.mail_group") {
            models.append(MailAccountDetailCellModel(type: .mailGroup,
                                                     icon: UDIcon.allmailOutlined.withRenderingMode(.alwaysTemplate),
                                                     title: "\(BundleI18n.LarkContact.Mail_ThirdClient_MailingList) (\(mailGroupTotalCount))"))
        }

        return MailAccountListSectionModel(emailAddress: displayAddress, cellModels: models)
    }
}

struct MailAccountListSectionModel {
    var emailAddress: String
    let cellModels: [MailAccountDetailCellModel]
}

struct MailAccountDetailCellModel {
    enum `Type` {
        case contact
        case mailGroup
    }

    let type: `Type`
    let icon: UIImage
    let title: String
}

final class MailAccountListViewModel: UserResolverWrapper {
    static let logger = Logger.log(MailAccountListViewModel.self, category: "NameCardList")

    private let nameCardAPI: NamecardAPI
    private let accountType: String
    private let disposeBag = DisposeBag()
    private let datasourceSubject: BehaviorSubject<[MailAccountBriefInfo]>
    var datasourceObservable: Observable<[MailAccountListSectionModel]> {
        let fgService = userResolver.fg
        return datasourceSubject
            .asObservable()
            .observeOn(MainScheduler.instance)
            .map { details in
                return details.map { $0.toSectionModel(fgService: fgService) }
            }
    }

    weak var contactListVM: MailContactListViewModel?
    var userResolver: LarkContainer.UserResolver
    init(nameCardAPI: NamecardAPI, accountType: String, accountInfos: [MailAccountBriefInfo], resolver: UserResolver) {
        self.nameCardAPI = nameCardAPI
        self.accountType = accountType
        self.userResolver = resolver
        self.datasourceSubject = BehaviorSubject<[MailAccountBriefInfo]>(value: accountInfos)
    }

    func fetchMailAccountDetail() {
        Self.logger.info("Fetch mail account detail")
        nameCardAPI.getAllMailAccountDetail(latest: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] list in
                guard let self = self else { return }
                self.datasourceSubject.onNext(list)
                Self.logger.info("Fetch mail account success")
            })
    }

    func updateMailAccountDetail(_ accountInfos: [MailAccountBriefInfo]) {
        datasourceSubject.onNext(accountInfos)
    }

    func updateContactListAccountIfNeeded(notification: Notification) {
        guard let contactListVM = contactListVM,
              let userInfo = notification.userInfo,
              let accountID = userInfo["accountID"] as? String,
              var accountInfo = (try? datasourceSubject.value())?.first(where: { $0.accountID == accountID })
        else {
            return
        }
        if notification.name == .LKNameCardDeleteNotification {
            accountInfo.nameCardTotalCount -= 1
        } else if (userInfo["isAdded"] as? Bool) == true {
            accountInfo.nameCardTotalCount += 1
        }
        contactListVM.changeAccount(accountInfo)
    }

    func didTapAddNameCard(from viewController: UIViewController) {
        let fetchedList = (try? datasourceSubject.value()) ?? []
        let nameCardEditBody = NameCardEditBody(source: "contact", accountID: "", accountList: fetchedList)
        navigator.push(body: nameCardEditBody, from: viewController)
        NameCardTrack.trackClickAddInList()
        MailContactStatistics.addContact(accountType: accountType)
    }

    func didiSelectCell(type: MailAccountDetailCellModel.`Type`, section: Int, from viewController: UIViewController) {
        guard let accountInfo = try? datasourceSubject.value()[safe: section] else {
            Self.logger.error("Failed to get account info at index: \(section)")
            return
        }
        let destinationVC: UIViewController
        switch type {
        case .contact:
            let contactVM = MailContactListViewModel(nameCardAPI: nameCardAPI, accountType: accountType, accountInfo: accountInfo)
            contactListVM = contactVM
            destinationVC = NameCardListViewController(viewModel: contactVM, resolver: userResolver)
        case .mailGroup:
            let groupVM = MailGroupListViewModel(nameCardAPI: nameCardAPI, accountInfo: accountInfo)
            destinationVC = NameCardListViewController(viewModel: groupVM, resolver: userResolver)
        }
        navigator.push(destinationVC, from: viewController)
    }
}
