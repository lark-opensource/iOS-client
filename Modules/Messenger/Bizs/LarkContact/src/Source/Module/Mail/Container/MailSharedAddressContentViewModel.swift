//
//  MailSharedAddressContentViewModel.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/11/7.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import LarkSDKInterface
import LKCommonsLogging
import LarkSearchCore

final class MailSharedAddressContentViewModel: MailContactsContentViewModel {
    @MailViewModelData<MailContactsContentViewModelState>(defaultValue: .loading) var stateValue

    // MARK: public interface
    var state: Driver<MailContactsContentViewModelState> {
        return stateValue
    }

    // MARK: private property
    static let logger = Logger.log(MailSharedAddressContentViewModel.self, category: "MailSharedAddressContentViewModel")

    private var indexToken: String = ""

    private let disposeBag = DisposeBag()

    private let dataAPI: NamecardAPI

    private let groupId: Int

    private let groupRole: MailGroupRole

    var naviTitle: String {
        return BundleI18n.LarkContact.Mail_MailingList_PublicMailbox
    }

    // 已经在里面的ids
    private var existIds: Set<String> = []

    var hasMore: Bool = false

    let pageSize: Int = 20

    private var isLoading = false

    init(dataAPI: NamecardAPI, groupId: Int, groupRole: MailGroupRole) {
        self.dataAPI = dataAPI
        self.groupId = groupId
        self.groupRole = groupRole
    }
}

extension MailSharedAddressContentViewModel {
    func getMailContactsList(isRefresh: Bool) {
        MailContactsContentViewModelImp.logger.info("MailSharedAddressContentViewModel getMailContactsList",
                                           additionalData: [
                                            "isRefresh": "\(String(describing: isRefresh))",
                                            "indexToken": "\(String(describing: indexToken))"
                                           ])
        if isLoading { return }
        isLoading = true
        if isRefresh {
            indexToken = ""
        }
        let tempHasMore = hasMore
        let tempToken = indexToken
        self.dataAPI.getSharedEmailAccountsList(indexToken: indexToken, pageSize: pageSize, source: .networkFailOver)
            .flatMap({ [weak self] resp -> Observable<(list: [MailSharedEmailAccount], existId: Set<String>)> in
                guard let self = self else { return .empty() }
                let list = resp.2
                self.indexToken = resp.indexToken
                self.hasMore = resp.hasMore
                return self.checkMemberIsExistRequest(account: list).map { set in
                    return (list, set)
                }
            })
            .subscribe(onNext: { [weak self] resp in
                guard let self = self else { return }
                let list = resp.list
                self.isLoading = false
                if isRefresh {
                    self.existIds = resp.existId
                    self.$stateValue.accept(.refresh(list))
                } else {
                    self.existIds = self.existIds.union(resp.existId)
                    self.$stateValue.accept(.loadMore(list))
                }
            }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    self.isLoading = false
                    self.$stateValue.accept(.dataError(error))
            }).disposed(by: self.disposeBag)
    }

    func checkItemSelectState(item: MailContactsItemCellViewModel,
                              selectionSource: SelectionDataSource) -> (selected: Bool, disable: Bool) {
        var canSelect = true
        var isSelected = false
        if existIds.contains(item.entityId) {
            return (true, true)
        }
        if let model = item as? Option {
            let state = selectionSource.state(for: model, from: self)
            isSelected = state.selected
            canSelect = !state.disabled
        }
        return (isSelected, !canSelect)
    }

    func checkMemberIsExistRequest(account: [MailSharedEmailAccount]) -> Observable<Set<String>> {
        var memebers: [MailGroupMember]?
        var managers: [MailGroupManager]?
        var permission: [MailGroupPermissionMember]?
        switch groupRole {
        case .member:
            memebers = account.map({ temp in
                var m = MailGroupMember()
                m.memberID = temp.userID
                m.memberType = .sharedAccount
                return m
            })
        case .manager:
            managers = account.map({ temp in
                var m = MailGroupManager()
                m.userID = temp.userID
                return m
            })
        case .permission:
            permission = account.map({ temp in
                var m = MailGroupPermissionMember()
                m.memberID = temp.userID
                m.memberType = .sharedAccount
                return m
            })
        @unknown default: break
        }

        var obser = self.dataAPI.mailCheckGroupMemberIsExist(groupId: groupId,
                                                             member: memebers,
                                                             manager: managers,
                                                             permissionMember: permission).map { resp -> Set<String> in
                                                                var res: Set<String> = []
                                                                res = resp.existMember.reduce(res, { (set: Set<String>, temp) in
                                                                    return set.union([String(temp.memberID)])
                                                                })
                                                                res = resp.existManager.reduce(res, { (set: Set<String>, temp) in
                                                                    return set.union([String(temp.userID)])
                                                                })
                                                                res = resp.existPermissionMember.reduce(res, { (set: Set<String>, temp) in
                                                                    return set.union([String(temp.memberID)])
                                                                })
                                                                return res
        }
        return obser
    }
}
