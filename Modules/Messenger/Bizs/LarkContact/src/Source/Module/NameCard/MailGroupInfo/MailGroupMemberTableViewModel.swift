//
//  MailGroupMemberTableViewModel.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/27.
//

import UIKit
import Foundation
import RustPB
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

// swiftlint:disable empty_count

protocol MailGroupMemberTableVMDelegate: AnyObject {
    // 是否支持左滑
    func canLeftSlide() -> Bool
    func onRemoveEnd(_ error: Error?)
    // picker添加了一些用户
    func didAddMembers(_ error: Error?)
    // 用户超限
    func didLimitMembers(member: [GroupInfoMemberItem])
    // 用户没有添加部门的权限
    func noDepartmentPermission()
}

@frozen
public enum MailGroupMemberTableViewStatus {
    case loading
    case error(Error)
    case viewStatus(MailGroupMemberBaseTable.Status)
}

// 抽象基类，不要直接使用
class MailGroupMemberTableVM {
    struct Config {
        let dataPageSize = 20
        let pageIndex = 0
        var pageToken = ""
        var hasMore = true
    }

    static let logger = Logger.log(MailGroupMemberTableVM.self, category: "MailGroupMemberTableVM")

    public typealias ChatterFliter = (_ chatter: GroupInfoMemberItem) -> Bool

    /// 追加自定义Tag
    public typealias AppendTagProvider = (_ chatter: GroupInfoMemberItem) -> [TagType]?

    var disposeBag = DisposeBag()
    private var searchDisposeBag = DisposeBag()

    // 默认选择的列表
    public var defaultSelectedIds: [String]?
    // 默认选中，无法取消选中的列表
    public var defaultUnableCancelSelectedIds: [String]? {
        return enableDeleteMe ? nil : [passportUserService?.user.userID ?? ""]
    }

    // MARK: data config
    fileprivate var config = Config()

    // MARK: data property
    var groupId: Int
    var accountId: String

    var nameCardAPI: NamecardAPI
    var passportUserService: PassportUserService?

    public weak var delegate: MailGroupMemberTableVMDelegate?

    var datas: [GroupInfoMemberItem] {
        get { _datas.value }
        set { _datas.value = newValue }
    }
    private var _datas: SafeAtomic<[GroupInfoMemberItem]> = [] + .readWriteLock

    var datasHasMore: Bool {
        return config.hasMore
    }

    private var isFirstDataLoaded: Bool = false
    private(set) var shouldShowTipView: Bool = false

    var onLoadDefaultSelectedItems: ((_ items: [GroupInfoMemberItem]) -> Void)?

    private let statusBehavior = BehaviorSubject<MailGroupMemberTableViewStatus>(value: .loading)
    public var statusVar: Driver<MailGroupMemberTableViewStatus> {
        return statusBehavior.asDriver(onErrorRecover: { .just(.error($0)) })
    }
    weak var targetVC: UIViewController?

    var showSelectedView: Bool = true
    // $0: 最大选择人数，$1: 选择超出限制的文案
    var maxSelectModel: (Int, String)?
    private let schedulerType: SchedulerType

    public init(groupId: Int,
                accountId: String,
                nameCardAPI: NamecardAPI,
                resolver: UserResolver,
                maxSelectModel: (Int, String)? = nil) {
        self.groupId = groupId
        self.accountId = accountId
        self.nameCardAPI = nameCardAPI
        self.passportUserService = try? resolver.resolve(assert: PassportUserService.self)
        self.maxSelectModel = maxSelectModel

        let queue = DispatchQueue.global()
        schedulerType = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: queue.label)
    }

    // MARK: - 需要被子类实现的方法 -------------------- start
    // 声明自己的type
    var groupRole: MailGroupRole {
        assert(false, "@liutefeng")
        return .member
    }

    var needDeleteCheck: Bool {
        return true
    }

    var enableDeleteMe: Bool {
        return true
    }

    // 组装左滑item
    func structureActionItems(tapTask: @escaping () -> Void,
                              indexPath: IndexPath) -> [UIContextualAction]? {
        return nil
    }

    // tag的处理方法
    func itemTags(for member: GroupInfoMemberItem) -> [Tag]? {
        return nil
    }

    // 添加
    func handlePickerResult(res: ContactPickerResult) {
        assert(false, "@liutefeng")
    }

    // delete的时候调用的数据方法
    func removeMemberItems(items: [GroupInfoMemberItem]) {
        // override
        assert(false, "@liutefeng")
    }
    // MARK: - 需要被子类实现的方法 -------------------- end

    func refreshWithRemoveItems(_ items: [GroupInfoMemberItem]) {
        let idMap = Set(items.map({ $0.itemId }))
        let newItems = _datas.value.filter { temp in
            return !idMap.contains(temp.itemId)
        }
        _datas.value = newItems
        statusBehavior.onNext(.viewStatus(.display))
    }

    func handleRemoveResult(error: Error?) {
        self.delegate?.onRemoveEnd(error)
        if let window = targetVC?.view.window {
            var msg = error == nil ? BundleI18n.LarkContact.Mail_MailingList_Removed
            : BundleI18n.LarkContact.Mail_MailingList_FailedToRemove
            UDToast.showTips(with: msg, on: window)
        }
    }
}

// Load方法
extension MailGroupMemberTableVM {
    func observeData() {

    }

    // 首次加载数据，需要加载默认选中的数据，所以单独拉出来处理
    func loadFirstScreenData() {
        nameCardAPI.getMailGroupMembersList(groupId,
                                            pageSize: config.dataPageSize,
                                            indexToken: "",
                                            role: groupRole,
                                            source: .local)
            .flatMap { [weak self] resp -> Observable<RustPB.Email_Client_V1_MailGroupMembersResponse> in
                guard let self = self else { return .empty() }
                self.handleMembersResponse(isLoadMore: false, groupRole: self.groupRole, resp: resp)
                self.statusBehavior.onNext(self._datas.value.count > 0 ? .viewStatus(.display) : .loading)
                return self.nameCardAPI.getMailGroupMembersList(self.groupId,
                                                                pageSize: self.config.dataPageSize,
                                                                indexToken: "",
                                                                role: self.groupRole, source: .network)
            }.subscribe(onNext: { [weak self] resp in
                guard let self = self else { return }
                self.handleMembersResponse(isLoadMore: false, groupRole: self.groupRole, resp: resp)
                self.statusBehavior.onNext(.viewStatus(.display))
            }) { [weak self] error in
                self?.statusBehavior.onNext(.error(error))
            }.disposed(by: disposeBag)
    }

    // 刷新页面数据
    func refreshListData() {
        nameCardAPI.getMailGroupMembersList(groupId,
                                            pageSize: config.dataPageSize,
                                            indexToken: "",
                                            role: groupRole,
                                            source: .network).subscribe(onNext: { [weak self] resp in
                                                guard let self = self else { return }
                                                self.handleMembersResponse(isLoadMore: false, groupRole: self.groupRole, resp: resp)
                                                self.statusBehavior.onNext(.viewStatus(.display))
                                            }) { [weak self] _ in
                                                self?.statusBehavior.onNext(.viewStatus(.display))
        }.disposed(by: disposeBag)
    }

    // 上拉加载更多
    func loadMoreData() {
        nameCardAPI.getMailGroupMembersList(groupId,
                                            pageSize: config.dataPageSize,
                                            indexToken: config.pageToken,
                                            role: groupRole, source: .networkFailOver).subscribe(onNext: { [weak self] resp in
                                                guard let self = self else { return }
                                                self.handleMembersResponse(isLoadMore: true, groupRole: self.groupRole, resp: resp)
                                                self.statusBehavior.onNext(.viewStatus(.display))
                                            }, onError: { [weak self] _ in
                                                self?.statusBehavior.onNext(.viewStatus(.display))
                                            }).disposed(by: disposeBag)
    }
}

// 数据加载和处理
extension MailGroupMemberTableVM {
    // load数据
    func loadData(isFirst: Bool = false) -> Observable<[GroupInfoMemberItem]> {
        return .empty()
    }
}

// MARK: 具体不同的业务场景的VM实例
/// 邮件组普通成员
final class MailGroupMemberTableMemberVM: MailGroupMemberTableVM {
    lazy var pickerHandler = MailGroupPickerMemberHandler(groupId: groupId, accountId: accountId, nameCardAPI: nameCardAPI)

    override var groupRole: MailGroupRole {
        return .member
    }

    override func removeMemberItems(items: [GroupInfoMemberItem]) {
        let members: [Email_Client_V1_MailGroupMember] = items.compactMap { temp in
            if let pb = temp as? Email_Client_V1_MailGroupMember {
                return pb
            }
            assert(false, "@liutefeng")
            return nil
        }
        nameCardAPI.updateMailGroupInfo(groupId,
                                        accountID: accountId,
                                        permission: nil,
                                        addMember: nil,
                                        deletedMember: members,
                                        addManager: nil,
                                        deletedManager: nil,
                                        addPermissionMember: nil,
                                        deletePermissionMember: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self ] _ in
                                            self?.refreshWithRemoveItems(items)
                                            self?.handleRemoveResult(error: nil)
                                        }) { [weak self] error in
                                            self?.handleRemoveResult(error: error)
            }.disposed(by: disposeBag)
    }

    override func handlePickerResult(res: ContactPickerResult) {
        pickerHandler.handleContactPickResult(res) { [weak self] (error, _, noPermi) in
            // 重新请求刷新列表
            self?.refreshListData()
            // 通知外面
            self?.delegate?.didAddMembers(error)
            if noPermi {
                self?.delegate?.noDepartmentPermission()
            }
        }
    }
}

/// 邮件组管理员
final class MailGroupMemberTableManagerVM: MailGroupMemberTableVM {
    lazy var pickerHandler = MailGroupPickerManagerHandler(groupId: groupId, accountId: accountId, nameCardAPI: nameCardAPI)

    override var groupRole: MailGroupRole {
        return .manager
    }

    override var enableDeleteMe: Bool {
        return false
    }

    override func removeMemberItems(items: [GroupInfoMemberItem]) {
        let members: [Email_Client_V1_MailGroupManager] = items.compactMap { temp in
            if let pb = temp as? Email_Client_V1_MailGroupManager {
                return pb
            }
            assert(false, "@liutefeng")
            return nil
        }
        nameCardAPI.updateMailGroupInfo(groupId,
                                        accountID: accountId,
                                        permission: nil,
                                        addMember: nil,
                                        deletedMember: nil,
                                        addManager: nil,
                                        deletedManager: members,
                                        addPermissionMember: nil,
                                        deletePermissionMember: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self ] _ in
                                            self?.refreshWithRemoveItems(items)
                                            self?.handleRemoveResult(error: nil)
                                        }) { [weak self] error in
                                            self?.handleRemoveResult(error: error)
            }.disposed(by: disposeBag)
    }

    override func handlePickerResult(res: ContactPickerResult) {
        pickerHandler.handleContactPickResult(res) { [weak self] (error, limits, noPermi) in
            // 重新请求刷新列表
            self?.refreshListData()
            // 通知外面
            self?.delegate?.didAddMembers(error)
            if let m = limits {
                self?.delegate?.didLimitMembers(member: m)
            }
            if noPermi {
                self?.delegate?.noDepartmentPermission()
            }
        }
    }
}

/// 邮件组权限成员
final class MailGroupPermissionMemberTableManagerVM: MailGroupMemberTableVM {
    lazy var pickerHandler = MailGroupPickerPermissionHandler(groupId: groupId, accountId: accountId, nameCardAPI: nameCardAPI)

    override var groupRole: MailGroupRole {
        return .permission
    }

    override func removeMemberItems(items: [GroupInfoMemberItem]) {
        let members: [Email_Client_V1_MailGroupPermissionMember] = items.compactMap { temp in
            if let pb = temp as? Email_Client_V1_MailGroupPermissionMember {
                return pb
            }
            assert(false, "@liutefeng")
            return nil
        }
        nameCardAPI.updateMailGroupInfo(groupId,
                                        accountID: accountId,
                                        permission: .custom,
                                        addMember: nil,
                                        deletedMember: nil,
                                        addManager: nil,
                                        deletedManager: nil,
                                        addPermissionMember: nil,
                                        deletePermissionMember: members)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self ] _ in
                                            self?.refreshWithRemoveItems(items)
                                            self?.handleRemoveResult(error: nil)
                                        }) { [weak self] error in
                                            self?.handleRemoveResult(error: error)
            }.disposed(by: disposeBag)
    }

    override func handlePickerResult(res: ContactPickerResult) {
        pickerHandler.handleContactPickResult(res) { [weak self] (error, _, noPermi) in
            // 重新请求刷新列表
            self?.refreshListData()
            // 通知外面
            self?.delegate?.didAddMembers(error)
            if noPermi {
                self?.delegate?.noDepartmentPermission()
            }
        }
    }
}

// MARK: private func
extension MailGroupMemberTableVM {
    private func handleMembersResponse(isLoadMore: Bool,
                                       groupRole: MailGroupRole,
                                       resp: RustPB.Email_Client_V1_MailGroupMembersResponse) {
        var data: [GroupInfoMemberItem] = []
        switch groupRole {
        case .manager:
            data = resp.managers
        case .member:
            data = resp.members
        case .permission:
            data = resp.permissionMembers
        @unknown default: break
        }
        if isLoadMore {
            _datas.value.append(contentsOf: data)
        } else {
            _datas.value = data
        }
        config.hasMore = resp.hasMore_p
        config.pageToken = resp.pageToken
    }
}

// swiftlint:enable empty_count
