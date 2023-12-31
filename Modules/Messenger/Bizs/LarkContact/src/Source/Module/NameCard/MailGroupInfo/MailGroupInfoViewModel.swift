//
//  MailGroupInfoViewModel.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/19.
//

import Foundation
import RxCocoa
import RxSwift
import LarkSDKInterface
import RustPB
import LarkContainer
import LarkMessengerInterface

enum MailGroupInfoViewModelState {
    case loading
    case infoData(items: [GroupInfoSectionModel])
    case error
}

enum GroupInfoViewModelRouter {
    case none
    case addMemberPicker(groupId: Int, accountId: String, type: MailGroupRole, maxCount: Int? = nil, callback: (ContactPickerResult) -> Void)
    case memberList(viewModel: MailGroupMemberTableVM, isRemove: Bool)
    case permission(viewModel: MailGroupPermissionViewModel)
    case remark(groupId: Int, groupDescription: String, nameCardAPI: NamecardAPI)
    case reachManagerLimit(limitItems: [GroupInfoMemberItem])
    case mailError(MailGroupReqError)
    case toast(msg: String)
    case noDepartmentPermission
}

enum GroupInfoViewModelExceptionType {
    case none
    case errToast(message: String, error: Error?)
}

protocol MailGroupInfoViewModel {
    ///  如果是disable状态，所以编辑不可以
    var isDisable: Bool { get }

    var state: Driver<MailGroupInfoViewModelState> { get }

    var router: Driver<GroupInfoViewModelRouter> { get }

    var exception: Driver<GroupInfoViewModelExceptionType> { get }

    var accountId: String { get }

    // action
    func loadGroupInfo()

    func refreshGroupInfo()
}

final class MailGroupInfoViewModelImp: MailGroupInfoViewModel, UserResolverWrapper {
    private var _state: BehaviorRelay<MailGroupInfoViewModelState> // 在第一次被人订阅的时候会先吐默认值
    var state: Driver<MailGroupInfoViewModelState> {
        return _state.asDriver()
    }

    private var _router: PublishSubject<GroupInfoViewModelRouter> = PublishSubject<GroupInfoViewModelRouter>()
    var router: Driver<GroupInfoViewModelRouter> {
        return _router.asDriver(onErrorJustReturn: .none)
    }

    private var _exception: PublishSubject<GroupInfoViewModelExceptionType> = PublishSubject<GroupInfoViewModelExceptionType>()
    var exception: Driver<GroupInfoViewModelExceptionType> {
        return _exception.asDriver(onErrorJustReturn: .none)
    }

    @ScopedInjectedLazy var nameCardAPI: NamecardAPI?
    var userResolver: LarkContainer.UserResolver
    let groupId: Int
    let accountId: String

    private let disposeBag = DisposeBag()

    var isDisable: Bool = false

    private var groupInfoRaw: RustPB.Email_Client_V1_MailGroupDetailResponse? {
        didSet {
            if let resp = groupInfoRaw {
                let sections = handleResponseData(resp: resp)
                isDisable = resp.mailGroup.status == .deactive
                _state.accept(.infoData(items: sections))
                MailGroupEventBus.shared.fireMailGroupInfoRaw(raw: resp)
            }
        }
    }

    init(groupId: Int, accountId: String, resolver: UserResolver) {
        self.groupId = groupId
        self.accountId = accountId
        self.userResolver = resolver
        _state = BehaviorRelay<MailGroupInfoViewModelState>(value: .loading)
        observeData()
    }

    func observeData() {
        MailGroupEventBus.shared.refreshRequest.subscribe(onNext: { [weak self] req in
            switch req {
            case .mailGroupDetail:
                self?.refreshGroupInfo()
            @unknown default: break
            }
        }).disposed(by: disposeBag)
    }

    func loadGroupInfo() {
        nameCardAPI?.getMailGroupDetail(groupId, source: .local).flatMap { [weak self] res -> Observable<RustPB.Email_Client_V1_MailGroupDetailResponse> in
            guard let self = self, let nameCardAPI = self.nameCardAPI else { return .empty() }
            self.groupInfoRaw = res // 通过didSet去做数据解析
            return nameCardAPI.getMailGroupDetail(self.groupId, source: .network)
        }.subscribe(onNext: { [weak self] resp in
            guard let self = self else { return }
            self.groupInfoRaw = resp // 通过didSet去做数据解析
        }) { [weak self] _ in
            self?._state.accept(.error)
        }.disposed(by: disposeBag)
    }

    func refreshGroupInfo() {
        nameCardAPI?.getMailGroupDetail(self.groupId, source: .network).subscribe(onNext: { [weak self] resp in
            self?.groupInfoRaw = resp // 通过didSet去做数据解析
        }) { _ in
            // 刷新失败 要重试？ TODO
        }.disposed(by: disposeBag)
    }
}

extension MailGroupInfoViewModelImp {
    private func handleResponseData(resp: RustPB.Email_Client_V1_MailGroupDetailResponse) -> [GroupInfoSectionModel] {
        var datas: [GroupInfoCellItem] = []
        // 基本信息
        datas.append(MailGroupInfoNameModel(name: resp.mailGroup.displayName,
                                            entityId: resp.mailGroup.entityId,
                                            avatarKey: resp.mailGroup.avatarKey,
                                            email: resp.mailGroup.mailAddress,
                                            tags: MailGroupHelper.createTag(status: resp.mailGroup.status,
                                                                            external: resp.mailGroup.includeExternal,
                                                                            company: resp.mailGroup.includeCompany)))

        // 管理员
        datas.append(MailGroupInfoMemberModel(title: MailGroupHelper.createTitle(role: .manager),
                                              memberItems: resp.managerMembers,
                                              memberCount: Int(resp.managerCount),
                                              hasAccess: !isDisable,
                                              isShowDeleteButton: !isDisable,
                                              separaterStyle: .auto,
                                              enterMemberList: { [weak self] _ in
                                                self?.enterMemberList(delete: false, type: .manager)
                                              }, tapHandler: { [weak self] _ in
                                                self?.enterMemberList(delete: false, type: .manager)
                                              }, addNewMember: { [weak self] _ in
                                                  MailGroupStatistics
                                                      .groupEditClick(value: "edit_group_admin")
                                                self?.enterMemperPicker(type: .manager)
                                              }, selectedMember: { _ in

                                              }, deleteMember: { [weak self] _ in
                                                self?.enterMemberList(delete: true, type: .manager)
                                              }))
        // 成员
        datas.append(MailGroupInfoMemberModel(title: MailGroupHelper.createTitle(role: .member),
                                              memberItems: resp.members,
                                              memberCount: Int(resp.memberCount),
                                              hasAccess: !isDisable,
                                              isShowDeleteButton: !isDisable,
                                              separaterStyle: .none,
                                              enterMemberList: { [weak self] _ in
                                                self?.enterMemberList(delete: false, type: .member)
                                              }, tapHandler: { [weak self] _ in
                                                self?.enterMemberList(delete: false, type: .member)
                                              }, addNewMember: { [weak self] _ in
                                                self?.enterMemperPicker(type: .member)
                                              }, selectedMember: { _ in

                                              }, deleteMember: { [weak self] _ in
                                                self?.enterMemberList(delete: true, type: .member)
                                              }))
        let section1 = GroupInfoSectionModel(title: nil, items: datas)

        let tips = MailGroupHelper.createPermissionTitle(permission: resp.mailGroup.permissionType)

        // 谁可以发邮件
        let permission = GroupInfoSectionModel(title: nil,
                                               items: [MailGroupInfoCommonModel(type: .whoCanSend,
                                                                                style: .none,
                                                                                title: MailGroupHelper
                                                                                    .createTitle(role: .permission),
                                                                                descriptionText: tips,
                                                                                enterAble: true,
                                                                                enterDetail: { [weak self] _ in
                                                                                    self?.enterPermissionSettingPage()
                                                                                          })])

        // 备注
        let remark = GroupInfoSectionModel(title: nil,
                                           items: [MailGroupInfoCommonModel(type: .remark,
                                                                            style: .none,
                                                                            title: BundleI18n.LarkContact.Mail_MailingList_Note,
                                                                            descriptionText: resp.mailGroup.description_p,
                                                                            enterAble: true,
                                                                            enterDetail: { [weak self] _ in
                                                                                self?.enterRemark()
                                                                            })])

        return [section1, permission, remark]
    }

    func enterMemberList(delete: Bool, type: MailGroupRole) {
        guard let nameCardAPI = self.nameCardAPI else { return }
        var vm: MailGroupMemberTableVM = MailGroupMemberTableMemberVM(groupId: groupId, accountId: accountId, nameCardAPI: nameCardAPI, resolver: userResolver)
        if type == .manager {
            vm = MailGroupMemberTableManagerVM(groupId: groupId, accountId: accountId, nameCardAPI: nameCardAPI, resolver: userResolver)
        }
        vm.delegate = self
        _router.onNext(.memberList(viewModel: vm, isRemove: delete))
    }

    func enterPermissionSettingPage() {
        guard let info = groupInfoRaw, let nameCardAPI = self.nameCardAPI else {
            return
        }
        let vm = MailGroupPermissionViewModelImp(groupId: groupId,
                                                 accountId: accountId,
                                                 dataAPI: nameCardAPI,
                                                 currentPermission: info.mailGroup.permissionType,
                                                 permissionMembers: info.permissionMembers,
                                                 membersCount: Int(info.permissionMemberCount))
        vm.isDisable = isDisable
        _router.onNext(.permission(viewModel: vm))
    }

    func enterMemperPicker(type: MailGroupRole) {
        guard let info = groupInfoRaw, let nameCardAPI = self.nameCardAPI else { return }
        var handler: MailGroupPickerAddHandler
        var maxCount: Int?
        switch type {
        case .member:
            handler = MailGroupPickerMemberHandler(groupId: groupId, accountId: accountId, nameCardAPI: nameCardAPI)
        case .manager:
            handler = MailGroupPickerManagerHandler(groupId: groupId, accountId: accountId, nameCardAPI: nameCardAPI)
            // 管理员人数上限为1000
            maxCount = 1000 - Int(info.managerCount)
        case .permission:
            handler = MailGroupPickerPermissionHandler(groupId: groupId, accountId: accountId, nameCardAPI: nameCardAPI)
        @unknown default:
            fatalError("must have case")
        }
        _router.onNext(.addMemberPicker(groupId: groupId,
                                        accountId: accountId,
                                        type: type,
                                        maxCount: maxCount,
                                        callback: { [weak self] result in
            guard let self = self else { return }
            handler.handleContactPickResult(result) { [weak self] (error, limit, noPerm) in
                guard let self = self else { return }
                if let error = error { // 提示错误
                    self._exception.onNext(.errToast(message: BundleI18n.LarkContact.Mail_MailingList_AddFailed, error: error))
                } else if let member = limit {
                    self._router.onNext(.reachManagerLimit(limitItems: member))
                    self.refreshGroupInfo()
                } else if noPerm {
                    self._router.onNext(.noDepartmentPermission)
                } else {
                    self._router.onNext(.toast(msg: BundleI18n.LarkContact.Mail_MailingList_Added))
                    self.refreshGroupInfo()
                }
                self.addMemberStatitics(result: result)
            }
        }))
    }

    private func addMemberStatitics(result: ContactPickerResult) {
        if !result.departments.isEmpty || !result.chatterInfos.isEmpty {
            MailGroupStatistics.groupEditClick(value: "select_member")
        }
        if result.mailContacts.first(where: { item in
            item.type == .sharedMailbox
        }) != nil {
            MailGroupStatistics.groupEditClick(value: "select_public")
        }

        if !result.mails.isEmpty {
            MailGroupStatistics.groupEditClick(value: "input_mail_address")
        }
    }

    func enterRemark() {
        guard let nameCardAPI = self.nameCardAPI else { return }
        _router.onNext(.remark(groupId: groupId,
                               groupDescription: groupInfoRaw?.mailGroup.description_p ?? "",
                               nameCardAPI: nameCardAPI))
    }
}

extension MailGroupInfoViewModelImp: MailGroupMemberTableVMDelegate {
    func canLeftSlide() -> Bool {
        return false
    }

    func onRemoveEnd(_ error: Error?) {
        refreshGroupInfo()
    }

    func didAddMembers(_ error: Error?) {
        refreshGroupInfo()
    }

    func didLimitMembers(member: [GroupInfoMemberItem]) {
        _router.onNext(.reachManagerLimit(limitItems: member))
    }

    func noDepartmentPermission() {
        _router.onNext(.noDepartmentPermission)
    }
}
