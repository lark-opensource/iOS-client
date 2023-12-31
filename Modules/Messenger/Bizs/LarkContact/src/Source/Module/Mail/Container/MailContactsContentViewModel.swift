//
//  MailContactsContentViewModel.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/8/21.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import RxRelay
import LarkSDKInterface
import LKCommonsLogging
import LarkTag
import LarkSearchCore
import RustPB

public typealias NewUserProfile = RustPB.Contact_V2_GetUserProfileResponse
public typealias I18nVal = Contact_V2_GetUserProfileResponse.I18nVal

protocol MailContactsItemCellViewModel {
    var entityId: String { get }

    var avatarKey: String { get }

    var customAvatar: UIImage? { get }

    var title: String { get }

    var subTitle: String { get }

    var tag: Tag? { get }
}

enum MailContactsContentViewModelState {
    case loading
    case refresh([MailContactsItemCellViewModel])
    case dataError(Error)
    case loadMore([MailContactsItemCellViewModel])
}

protocol MailContactsContentViewModel {
    var state: Driver<MailContactsContentViewModelState> { get }

    var hasMore: Bool { get }

    var naviTitle: String { get }

    /// query
    func checkItemSelectState(item: MailContactsItemCellViewModel, selectionSource: SelectionDataSource) -> (selected: Bool, disable: Bool)

    /// action
    func getMailContactsList(isRefresh: Bool)
}

final class MailContactsContentViewModelImp: MailContactsContentViewModel {
    @MailViewModelData<MailContactsContentViewModelState>(defaultValue: .loading) var stateValue

    // MARK: public interface
    var state: Driver<MailContactsContentViewModelState> {
        return stateValue
    }

    // MARK: private property
    static let logger = Logger.log(MailContactsContentViewModelImp.self, category: "MailContactsContentViewModelImp")

    private var lastNameCardId: String? = "0"

    private let disposeBag = DisposeBag()

    private let dataAPI: NamecardAPI

    private let accountID: String

    var hasMore: Bool = false

    let pageSize: Int = 20

    private var isLoading = false

    var naviTitle: String {
        return BundleI18n.LarkContact.Lark_Contacts_EmailContacts
    }

    init(dataAPI: NamecardAPI, accountID: String) {
        self.dataAPI = dataAPI
        self.accountID = accountID
    }
}

extension MailContactsContentViewModelImp {
    func getMailContactsList(isRefresh: Bool) {
        MailContactsContentViewModelImp.logger.info("MailContactsContentViewModelImp getMailContactsList",
                                           additionalData: [
                                            "isRefresh": "\(String(describing: isRefresh))",
                                            "lastNamecardId": "\(String(describing: self.lastNameCardId))"
                                           ])
        if isLoading { return }
        isLoading = true
        if isRefresh {
            self.lastNameCardId = "0"
        }
        self.dataAPI.getNamecardList(namecardId: self.lastNameCardId ?? "0",
                                     accountID: self.accountID,
                                     limit: self.pageSize)
            .subscribe(onNext: { [weak self] nameCardListData in
                guard let self = self else { return }
                self.isLoading = false
                let list = nameCardListData.list
                self.lastNameCardId = list.last?.namecardId
                self.hasMore = nameCardListData.hasMore
                if isRefresh {
                    self.$stateValue.accept(.refresh(list))
                } else {
                    self.$stateValue.accept(.loadMore(list))
                }
                MailContactsContentViewModelImp.logger.info("NameCardList fetch success!",
                                                  additionalData: [
                                                    "nameCardList count": "\(nameCardListData.list.count)",
                                                    "isRefresh": "\(String(describing: isRefresh))",
                                                    "hasMore": "\(self.hasMore)",
                                                    "lastNamecardId": "\(String(describing: self.lastNameCardId))"
                                                  ])
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    self.isLoading = false
                    self.$stateValue.accept(.dataError(error))
                    MailContactsContentViewModelImp.logger.info("MailContactsContentViewModelImp getMailContactsList failed",
                                                       additionalData: [
                                                        "isRefresh": "\(String(describing: isRefresh))",
                                                        "lastNamecardId": "\(String(describing: self.lastNameCardId))"
                                                       ])
            }).disposed(by: self.disposeBag)
    }

    func checkItemSelectState(item: MailContactsItemCellViewModel,
                              selectionSource: SelectionDataSource) -> (selected: Bool, disable: Bool) {
        var canSelect = true
        var isSelected = true
        if let model = item as? NameCardInfo {
            let state = selectionSource.state(for: model, from: self)
            isSelected = state.selected
            canSelect = !state.disabled && !model.email.isEmpty
        }
        return (isSelected, !canSelect)
    }
}

// MARK: DataManager Property
@propertyWrapper
struct MailViewModelData<Value> {
    private var _wrappedValue: BehaviorRelay<Value>
    var wrappedValue: Driver<Value> {
        return _wrappedValue.asDriver(onErrorJustReturn: _wrappedValue.value)
    }

    // 通过$符号可以访问到
    @inlinable var projectedValue: MailViewModelData {
        return self
    }

    init(defaultValue: Value) {
        _wrappedValue = BehaviorRelay<Value>(value: defaultValue)
    }

    func accept(_ value: Value) {
        _wrappedValue.accept(value)
    }

    func value() -> Value {
        return _wrappedValue.value
    }
}
