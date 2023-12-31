//
//  MailGroupPermissionViewModel.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/26.
//

import Foundation
import UIKit
import RxSwift
import LarkTag
import RxCocoa
import LarkModel
import EENavigator
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import LarkFeatureGating
import UniverseDesignToast
import LarkAccountInterface
import UniverseDesignDialog
import LarkMessengerInterface
import ThreadSafeDataStructure

enum MailGroupPermissionType {
    case unknown
    case groupMembers
    case organizationMembers
    case all
    case specificUser // 部分组织内成员可以发信
    case pickerRouter

    var title: String {
        if self == .pickerRouter {
            return BundleI18n.LarkContact.Mail_MailingList_AddMembers
        }
        let pb = self.toPB
        return MailGroupHelper.createPermissionTitle(permission: pb)
    }

    var toPB: MailContactGroup.PermissionType {
        switch self {
        case .all:
            return .all
        case .groupMembers:
            return .groupMember
        case .organizationMembers:
            return .internalMember
        case .specificUser:
            return .custom
        case .unknown, .pickerRouter:
            return .unknownPermissionType
        @unknown default: break
        }
    }
}

extension MailContactGroup.PermissionType {
    var toVMType: MailGroupPermissionType {
        switch self {
        case .all:
            return .all
        case .groupMember:
            return .groupMembers
        case .internalMember:
            return .organizationMembers
        case .custom:
            return .specificUser
        case .unknownPermissionType:
            return .unknown
        @unknown default: return .unknown
        }
    }
}

enum MailGroupPermissionViewModelRouter {
    case none
    case showLoading
    case hideLoading
    case errorToast(String?, Error?)
    case dialog(content: String)
}

protocol MailGroupPermissionViewModel {
    var dataAPI: NamecardAPI { get }

    var groupId: Int { get }

    var accountId: String { get }

    var reloadData: Driver<Void> { get }

    var router: Driver<MailGroupPermissionViewModelRouter> { get }

    var dataItemsCount: Int { get }

    var isDisable: Bool { get }

    func refreshData()

    func fetchData()

    // DataSource
    func getItemCellHeight(indexPath: IndexPath) -> CGFloat
    func getItemBaseInfo(indexPath: IndexPath) -> (title: String, isSelected: Bool)
    func getItemMemberInfo(indexPath: IndexPath) -> (count: Int, memberInfos: [MailGroupInfoMemberViewItem])?
    func getPermissionType(indexPath: IndexPath) -> MailGroupPermissionType
    func checkShowShouldMembersView(indexPath: IndexPath) -> Bool
    // 是否调整选项
    func isRouterCell(indexPath: IndexPath) -> Bool
    func enableBackCheck() -> Bool

    // action
    func requestUpdatePermission(_ type: MailGroupPermissionType)
    func handlePickerResult(res: ContactPickerResult)
}

final class MailGroupPermissionViewModelImp: MailGroupPermissionViewModel {

    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()

    private var _router: PublishSubject<MailGroupPermissionViewModelRouter> = PublishSubject<MailGroupPermissionViewModelRouter>()
    var router: Driver<MailGroupPermissionViewModelRouter> {
        return _router.asDriver(onErrorJustReturn: .none)
    }

    let indexDataArrayNoRouter: [MailGroupPermissionType] = [
        .all,
        .organizationMembers,
        .groupMembers,
        .specificUser
    ]

    let indexDataArrayWithRouter: [MailGroupPermissionType] = [
        .all,
        .organizationMembers,
        .groupMembers,
        .specificUser,
        .pickerRouter
    ]

    var indexDataArray: [MailGroupPermissionType] {
        return !isDisable && selectedPermission == .custom && membersCount == 0 ?
        indexDataArrayWithRouter : indexDataArrayNoRouter
    }

    var dataItemsCount: Int {
        return indexDataArray.count
    }

    var groupId: Int {
        return _groupId
    }

    var dataAPI: NamecardAPI
    var accountId: String
    lazy var pickerHandler = MailGroupPickerPermissionHandler(groupId: groupId, accountId: accountId, nameCardAPI: dataAPI)
    let _groupId: Int
    var selectedPermission: MailContactGroup.PermissionType
    var permissionMembers: [GroupInfoMemberItem]
    var membersCount: Int
    var isDisable: Bool = false
    let disposeBag = DisposeBag()

    init(groupId: Int,
         accountId: String,
         dataAPI: NamecardAPI,
         currentPermission: MailContactGroup.PermissionType,
         permissionMembers: [GroupInfoMemberItem],
         membersCount: Int) {
        selectedPermission = currentPermission
        self.permissionMembers = permissionMembers
        self.membersCount = membersCount
        self._groupId = groupId
        self.dataAPI = dataAPI
        self.accountId = accountId
        observeData()
    }

    private func observeData() {
        MailGroupEventBus
            .shared
            .detailChange
            .observeOn(MainScheduler.instance).map { [weak self] change in
                switch change {
                case .groupInfo(let group):
                    self?.selectedPermission = group.permissionType
                case .permissionMember(let member):
                    self?.permissionMembers = member
                case .permissionMemberCount(let count):
                    self?.membersCount = count
                default: break
                }
            }
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.refreshData()
                self?._router.onNext(.hideLoading)
            }).disposed(by: disposeBag)
    }

    func refreshData() {
        _reloadData.onNext(())
    }

    func fetchData() {
        MailGroupEventBus.shared.fireRequestGroupDetail()
    }

    func getItemCellHeight(indexPath: IndexPath) -> CGFloat {
        let item = indexDataArray[indexPath.row]
        if item == .specificUser && membersCount > 0 {
            return UITableView.automaticDimension
        }
        return 46
    }

    func checkShowShouldMembersView(indexPath: IndexPath) -> Bool {
        let item = indexDataArray[indexPath.row]
        if item == .specificUser && membersCount > 0 {
            return true
        }
        return false
    }

    func getItemBaseInfo(indexPath: IndexPath) -> (title: String, isSelected: Bool) {
        let item = indexDataArray[indexPath.row]
        return (item.title, item == selectedPermission.toVMType)
    }

    func getItemMemberInfo(indexPath: IndexPath) -> (count: Int, memberInfos: [MailGroupInfoMemberViewItem])? {
        let item = indexDataArray[indexPath.row]
        if item == .specificUser {
            if let mems = permissionMembers as? [MailGroupInfoMemberViewItem] {
                return (membersCount, mems)
            }
        }
        return nil
    }

    func getPermissionType(indexPath: IndexPath) -> MailGroupPermissionType {
        return indexDataArray[indexPath.row]
    }

    func isRouterCell(indexPath: IndexPath) -> Bool {
        return indexDataArray[indexPath.row] == .pickerRouter
    }

    func enableBackCheck() -> Bool {
        if selectedPermission == .custom && membersCount == 0 {
            _router.onNext(.dialog(content: BundleI18n.LarkContact.Mail_MailingList_AddMembersOrSwitchOtherMobile))
            return false
        }

        return true
    }

    func requestUpdatePermission(_ type: MailGroupPermissionType) {
        // statitics
        MailGroupStatistics.groupEditClick(value: "input_mail_address")

        if type == .specificUser && membersCount == 0 {
            selectedPermission = .custom
            _reloadData.onNext(())
            return
        }

        let current = selectedPermission
        self._router.onNext(.showLoading)
        dataAPI.updateMailGroupInfo(groupId,
                                    accountID: accountId,
                                    permission: type.toPB,
                                    addMember: nil,
                                    deletedMember: nil,
                                    addManager: nil,
                                    deletedManager: nil,
                                    addPermissionMember: nil,
                                    deletePermissionMember: nil).subscribe(onNext: { [weak self] _ in
            MailGroupEventBus.shared.fireRequestGroupDetail()
            self?._router.onNext(.hideLoading)
                                    }, onError: { [weak self] error in
                                        self?.selectedPermission = current
                                        self?._router.onNext(.hideLoading)
                                        self?._router.onNext(.errorToast(nil, error))
                                        self?._reloadData.onNext(())
                                    }).disposed(by: disposeBag)
    }

    func handlePickerResult(res: ContactPickerResult) {
        _router.onNext(.showLoading)
        pickerHandler.handleContactPickResult(res) { [weak self] (error, _, noPermi) in
            self?._router.onNext(.hideLoading)
            if noPermi {
                self?._router.onNext(.dialog(content: BundleI18n.LarkContact.Mail_MailingList_UnableToAddDepartmentsIOS))
            } else if let error = error {
                self?._router.onNext(.errorToast(BundleI18n.LarkContact.Mail_MailingList_AddFailed, error))
            } else {
                MailGroupEventBus.shared.fireRequestGroupDetail()
            }
        }
    }
}
