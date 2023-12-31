//
//  MailGroupListViewModel.swift
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
import LarkAccountInterface
import LarkMessengerInterface
import RustPB
import EENavigator
import LarkTag

extension MailContactGroup: NameCardListCellViewModel {
    var tagText: String {
        ""
    }

    var avatarKey: String {
        return ""
    }

    var displayTitle: String {
        return self.displayName
    }

    var displaySubTitle: String {
        return self.mailAddress
    }

    var entityId: String {
        return ""
    }

    var avatarImage: UIImage? {
        return MailGroupHelper.generateAvatarImage(withNameString: String(displayName.prefix(2)).uppercased())
    }

    var itemTags: [Tag]? {
       return MailGroupHelper.createTag(status: self.status,
                                        external: self.includeExternal,
                                        company: self.includeCompany)
    }

    func didSelect(fromVC: UIViewController, accountID: String, resolver: UserResolver) {
        let vm = MailGroupInfoViewModelImp(groupId: Int(self.groupID), accountId: accountID, resolver: resolver)
        let vc = MailGroupInfoViewController(viewModel: vm, resolver: resolver)
        if Display.pad {
            resolver.navigator.present(vc,
                                     wrap: LkNavigationController.self,
                                     from: fromVC,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            resolver.navigator.presentOrPush(vc, from: fromVC)
        }

        // statitics
        MailGroupStatistics.groupListClick()
    }
}

final class MailGroupListViewModel: NameCardListViewModel {
    static let logger = Logger.log(MailGroupListViewModel.self, category: "NameCardList")

    private let nameCardAPI: NamecardAPI
    private let disposeBag = DisposeBag()
    private let accountInfo: MailAccountBriefInfo

    private var datasource: [MailContactGroup] = [] {
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
            return BundleI18n.LarkContact.Mail_MailingList_NumMailingList(datasource.count)
        } else {
            return BundleI18n.LarkContact.Mail_MailingList_NumMailingList(accountInfo.mailGroupTotalCount)
        }
    }

    var canLeftDelete: Bool {
        return false
    }

    var accountID: String {
        return accountInfo.accountID
    }

    var mailAddress: String {
        return accountInfo.displayAddress
    }

    var mailAccountType: String {
        return ""
    }

    // 首次加载服务端数据是否完成
    private(set) var serverRequestFinished: Bool = false

    public var hasMore: Bool = false
    private let datasourceSubject: BehaviorSubject<NameCardListResult> = BehaviorSubject<NameCardListResult>(value: .empty)
    let pageSize: Int = 20
    private var isLoading = false

    var datasourceDriver: Driver<NameCardListResult> {
        return datasourceSubject.asDriver(onErrorJustReturn: .empty).skip(1)
    }

    var itemRemoveDriver: Driver<Int>? {
        return nil
    }

    init(nameCardAPI: NamecardAPI, accountInfo: MailAccountBriefInfo) {
        self.nameCardAPI = nameCardAPI
        self.accountInfo = accountInfo
    }

    func fetchNameCardList(isRefresh: Bool) {
        guard isRefresh else { // 邮件组为全量拉取
            return
        }

        if !serverRequestFinished { //
            loadFirstScreenData()
        } else {
            nameCardAPI.getMailManagedGroups(source: .network)
                .subscribe(onNext: { [weak self] (list, _) in
                    self?.datasource = list
                }) { _ in

                }.disposed(by: disposeBag)
        }
    }

    func removeData(deleteNameCardInfo: NameCardListCellViewModel, atIndex: Int) {

    }

    func enableRemveAction(item: NameCardListCellViewModel) -> Bool {
        return false
    }

    func pageDidView() {
        MailGroupStatistics.groupListView()
    }
}

extension MailGroupListViewModel {
    private func loadFirstScreenData() {
        nameCardAPI.getMailManagedGroups(source: .local)
            .flatMap { [weak self] (list, _) -> Observable<([Email_Client_V1_MailGroup], MailContactRequestSource)> in
                guard let self = self else { return .empty() }
                self.datasource = list
                return self.nameCardAPI.getMailManagedGroups(source: .network)
            }.subscribe(onNext: { [weak self] (list, _) in
                guard let self = self else { return }
                self.datasource = list
            }) { [weak self] error in
                self?.datasourceSubject.onNext(.failure(error: error))
            }.disposed(by: disposeBag)
    }
}
