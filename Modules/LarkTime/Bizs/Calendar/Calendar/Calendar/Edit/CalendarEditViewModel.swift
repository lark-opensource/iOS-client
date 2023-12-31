//
//  CalendarEditViewModel.swift
//  Calendar
//
//  Created by Hongbin Liang on 3/10/23.
//

import Foundation
import RxSwift
import RxRelay
import LarkModel
import RxDataSources
import LarkContainer
import LarkBizAvatar
import CalendarFoundation
import UniverseDesignIcon

class CalendarEditViewModel: UserResolverWrapper {
    let rxAbleToSave = BehaviorRelay<Bool>(value: true)
    let rxAvatarViewData = BehaviorRelay<CalendarCellDataType>(value: CalendarCellData())
    let rxTitleViewData = BehaviorRelay<CalendarCellDataType>(value: CalendarCellData())
    let rxColorViewData = BehaviorRelay<CalendarCellDataType>(value: CalendarCellData())
    let rxDescriptionViewData = BehaviorRelay<CalendarCellDataType>(value: CalendarCellData())

    let rxAuthInGroupViewData = BehaviorRelay<CalendarCellDataType>(value: CalendarCellData())
    let rxAuthOutOfGroupViewData = BehaviorRelay<CalendarCellDataType>(value: CalendarCellData())

    let rxMembersSectioinData = BehaviorRelay<CalendarMemberSectionData>(value: .init())

    private(set) var permission: CalendarEditPermission
    private(set) var input: CalendarEditInput

    let userResolver: UserResolver

    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var rustAPI: CalendarRustAPI?

    let rxViewStatus = BehaviorRelay<CalendarDetailCardViewStatus>(value: .loading)
    let rxToastStatus = PublishRelay<ToastStatus>()
    let rxAlert = PublishRelay<Alert>()
    let rxDismissNoti = PublishRelay<()>()
    let rxCalendarListRefresh = PublishRelay<Void>()

    enum CellToUpdate {
        case avatar
        case title
        case color
        case description
        case authInGroup
        case authOutofGroup
        case all
        case none
    }
    private(set) var rxCalendar: BehaviorRelay<(pb: Rust.Calendar, fieldUpdated: CellToUpdate)>
    private(set) var rxCalendarMembers: BehaviorRelay<[Rust.CalendarMember]> = .init(value: [])
    private(set) var rxMessageToLeave: BehaviorRelay<String?> = .init(value: nil)

    private(set) var defaultAuthSettingVM: DefaultAuthSettingViewModel?
    private(set) var modelTupleBeforeEditing: (calendar: Rust.Calendar, members: [Rust.CalendarMember])
    private(set) var isSaving = false

    typealias MemberTuple = (id: String, isGroup: Bool)
    /// 预选项，二次进入 picker 可反选
    var preSelectedMembers: [MemberTuple] = []
    /// 强制勾选项，日历原有成员，不可反选（新增不变，删除跟随）
    var forcedSelectMemebers: [MemberTuple] = []
    /// filtered users in group 需要保存/分享时传给 server
    var rejectedUserIDs: [String] = []

    private var avatarImage: UIImage?
    private var avatarImageKey: String?

    private let bag = DisposeBag()

    init(from: CalendarEditInput, userResolver: UserResolver) {
        input = from
        self.userResolver = userResolver
        permission = .init(calendarfrom: from)

        switch input {
        case .fromCreate:
            let skinType = SettingService.shared().getSetting().skinTypeIos
            var calendar = CalendarModelFromPb.defaultCalendar(skinType: skinType).getCalendarPB()

            if let accessConfig = SettingService.shared().tenantSetting?.calendarAdminAccessConfig.permSettings.first,
               accessConfig.calendarType == .other {
                calendar.shareOptions = accessConfig.shareOptions
            }

            rxCalendar = .init(value: (calendar, .all))
            defaultAuthSettingVM = .init(authSettings: calendar.shareOptions)
            modelTupleBeforeEditing = (calendar, [])

            appendSelfAsMember()
            rxViewStatus.accept(.dataLoaded)
        case .fromEdit(let calendar):
            rxCalendar = .init(value: (calendar, .all))
            defaultAuthSettingVM = .init(authSettings: calendar.shareOptions)
            modelTupleBeforeEditing = (calendar, [])

            fetchCalendar(with: calendar.serverID)
        }

        bindNaviStatus()

        bindBasicInfoData()
        bindAuthInfoData()

        bindMembersData()
    }
}

// MARK: - data binding
extension CalendarEditViewModel {

    private func bindNaviStatus() {
        rxCalendar
            .compactMap { calendar, fieldUpdated -> Bool? in
                guard fieldUpdated == .all || fieldUpdated == .title else { return nil }
                return !calendar.summary.isEmpty
            }
            .bind(to: rxAbleToSave)
            .disposed(by: bag)

    }

    // MARK: - CalendarCell

    struct CalendarCellData: CalendarCellDataType {
        var title: String = ""
        var content: CalendarCellContent = .subTitle(text: "")
        var clickNeedBlock: Bool = true
    }

    private func bindBasicInfoData() {
        Observable.combineLatest(rxCalendar, rxCalendarMembers)
            .compactMap { [weak self] calendarInfo, members -> CalendarCellData? in
                let calendar = calendarInfo.pb
                let fieldUpdated = calendarInfo.fieldUpdated
                guard let self = self, fieldUpdated == .all || fieldUpdated == .avatar else { return nil }
                let avatar = BizAvatar()
                var avatarSeed: AvatarSeed?
                if !calendar.avatarKey.isEmpty {
                    // 有 key 就有 image
                    if self.avatarImage == nil || self.avatarImageKey != calendar.avatarKey {
                        self.downLoadAvatar(with: calendar.avatarKey)
                    }
                } else {
                    if calendar.type == .primary {
                        if let currentUser = (members.first { $0.userID == calendar.userID }) {
                            if !currentUser.avatarKey.isEmpty {
                                avatarSeed = AvatarSeed.lark(identifier: currentUser.memberID, avatarKey: currentUser.avatarKey)
                            } else {
                                avatarSeed = AvatarSeed.local(title: currentUser.name)
                            }
                        } else {
                            assertionFailure("main calendar members doesn't contain it's owner")
                        }
                    } else if calendar.type == .resources {
                        self.avatarImage = UIImage.cd.image(named: "resource_calendar_avatar")
                    }
                }

                if let image = self.avatarImage {
                    avatar.image = image
                } else if let seed = avatarSeed, case let .lark(identifier, avatarKey) = seed {
                    avatar.setAvatarByIdentifier(identifier, avatarKey: avatarKey)
                } else if let seed = avatarSeed, case let .local(title) = seed {
                    avatar.image = AvatarView.generateAvatarImage(withNameString: title, round: true)
                } else {
                    avatar.image = CalendarDetailCardViewModel.defaultAvatar.avatar
                }

                return .init(
                    title: I18n.Calendar_Setting_CalendarPhoto,
                    content: .sampleView(view: avatar, size: CGSize(width: 40, height: 40)),
                    clickNeedBlock: !self.permission.isCoverImageEditable
                )
            }
            .bind(to: rxAvatarViewData)
            .disposed(by: bag)

        rxCalendar
            .compactMap { calendar, fieldUpdated -> CalendarCellData? in
                guard fieldUpdated == .all || fieldUpdated == .title else { return nil }
                let titleStr = calendar.summary.isEmpty ? I18n.Calendar_Setting_EnterCalendarName : calendar.summary
                return .init(
                    title: I18n.Calendar_Setting_CalendarTitle,
                    content: .subTitle(text: titleStr),
                    clickNeedBlock: false // 一级页面一律可点击，二级页面受编辑权限控制
                )
            }
            .bind(to: rxTitleViewData)
            .disposed(by: bag)

        rxCalendar
            .compactMap { [weak self] calendar, fieldUpdated -> CalendarCellData? in
                guard let self = self, fieldUpdated == .all || fieldUpdated == .color else { return nil }
                let colorSample = UIView()
                let colorSelected = SkinColorHelper.pickerColor(of: calendar.personalizationSettings.colorIndex.rawValue)
                colorSample.backgroundColor = colorSelected
                colorSample.layer.cornerRadius = 6
                return .init(
                    title: I18n.Calendar_Setting_CalendarColor,
                    content: .sampleView(view: colorSample, size: CGSize(width: 24, height: 24)),
                    clickNeedBlock: !self.permission.isColorEditable
                )
            }
            .bind(to: rxColorViewData)
            .disposed(by: bag)

        rxCalendar
            .compactMap { [weak self] calendar, fieldUpdated -> CalendarCellData? in
                guard let self = self, fieldUpdated == .all || fieldUpdated == .description else { return nil }

                var descriptionStr: String
                if !calendar.description_p.isEmpty {
                    descriptionStr = calendar.description_p
                } else {
                    let canEdit = self.permission.isDescEditable
                    descriptionStr = canEdit ? I18n.Calendar_Setting_EnterDescription : I18n.Calendar_Detail_NoDescription
                }
                return .init(
                    title: I18n.Calendar_Setting_CalendarDescription,
                    content: .subTitle(text: descriptionStr),
                    clickNeedBlock: false // 一级页面一律可点击，二级页面受编辑权限控制
                )
            }
            .bind(to: rxDescriptionViewData)
            .disposed(by: bag)
    }

    private func bindAuthInfoData() {
        guard permission.isPermissionEditable else { return }
        rxCalendar
            .compactMap { [weak self] calendar, fieldUpdated -> CalendarCellData? in
                guard let self = self, fieldUpdated == .all || fieldUpdated == .authInGroup else { return nil }
                let roleStr = calendar.shareOptions.innerDefault.cd.shareOptionInfo
                return .init(
                    title: I18n.Calendar_Share_InternalPermissionTitle,
                    content: .subTitle(text: roleStr),
                    clickNeedBlock: self.permission.isAllStaff
                )
            }
            .bind(to: rxAuthInGroupViewData)
            .disposed(by: bag)

        rxCalendar
            .compactMap { [weak self] calendar, fieldUpdated -> CalendarCellData? in
                guard let self = self, fieldUpdated == .all || fieldUpdated == .authOutofGroup else { return nil }

                let roleStr = calendar.shareOptions.externalDefault.cd.shareOptionInfo
                return .init(
                    title: I18n.Calendar_Share_ExternalPermissionTitle,
                    content: .subTitle(text: roleStr),
                    clickNeedBlock: self.permission.isAllStaff
                )
            }
            .bind(to: rxAuthOutOfGroupViewData)
            .disposed(by: bag)
    }

    // MARK: - CalendarMemberCell

    struct CalendarMemberSectionData {
        var isCalMemberEditable: Bool = false
        var members: [CalendarMemberCellDataType] = []
        var footerStr: String?
    }

    struct CalendarMemberCellData: CalendarMemberCellDataType {
        var avatar: AvatarImpl = .init(avatarKey: "", userName: "", identifier: "")
        var title: String = ""
        var isGroup: Bool = false
        var ownerTagStr: String?
        var relationTagStr: String?
        var role: Rust.CalendarAccessRole = .freeBusyReader
        var highestRole: Rust.CalendarAccessRole?
        var canJumpProfile: Bool = true
        var isEditable: Bool = false
    }

    private func bindMembersData() {
        rxCalendarMembers
            .map { [weak self] members in
                guard let self = self else { return .init() }
                let canAdd = self.permission.isCalMemberEditable
                let calendar = self.modelTupleBeforeEditing.calendar
                let membersData = members.compactMap { member -> CalendarMemberCellDataType? in
                    guard member.status != .removed else { return nil }
                    let avatar = AvatarImpl(avatarKey: member.avatarKey, userName: member.name, identifier: member.memberID)
                    // 所有者（包含继承者）
                    let calendarOwnerID = self.input.isFromCreate ? self.currentUserID : calendar.calendarOwnerID
                    let banned = [calendarOwnerID, self.currentUserID]
                    let haveOwnerAccess = calendar.selfAccessRole == .owner
                    let highestRole = calendar.shareOptions.topOption(
                        of: member.memberType,
                        isExternal: member.relationType == .external
                    ).cd.mappedAccessRole

                    let data = CalendarMemberCellData(
                        avatar: avatar,
                        title: member.displayName,
                        isGroup: member.memberType == .group,
                        ownerTagStr: calendarOwnerID == member.memberID ? I18n.Calendar_Share_Owner : nil,
                        relationTagStr: member.relationTagStr,
                        role: member.accessRole,
                        highestRole: highestRole,
                        canJumpProfile: member.name != I18n.Calendar_Common_Feifei && member.memberType != .group,
                        isEditable: !banned.contains(where: { $0 == member.memberID }) && haveOwnerAccess
                    )
                    return data
                }
                let subscriberNum = calendar.shareInfo.subscriberNum
                // 对齐日历列表判断逻辑
                let isMyCalendar = calendar.selfAccessRole == .owner && calendar.type != .exchange && calendar.type != .google
                var footer: String?
                if !self.input.isFromCreate, isMyCalendar || FG.showSubscribers, subscriberNum >= 0 {
                    footer = I18n.Calendar_Share_MobileWhatCountAsNumber(num: subscriberNum)
                }
                return .init(isCalMemberEditable: canAdd, members: membersData, footerStr: footer)
            }.bind(to: rxMembersSectioinData)
            .disposed(by: bag)
    }

    // MARK: - Utils

    func predicateMemberShareable(member: PickerItem) -> Bool {
        var memberType: Rust.CalendarMember.CalendarMemberType = .individual
        var isExternal = false
        let calendarTenantID = input.isFromCreate ? currentTenantID : rxCalendar.value.pb.calendarTenantID
        switch member.meta {
        case .chat(let chatInfo):
            if let isOuter = chatInfo.isOuter {
                isExternal = isOuter || currentTenantID != calendarTenantID
            }
            memberType = .group
        case .chatter(let chatterInfo):
            if let tenantId = chatterInfo.tenantId {
                isExternal = tenantId != calendarTenantID
            }
        default: break
        }

        return rxCalendar.value.pb.shareOptions.topOption(
            of: memberType,
            isExternal: isExternal
        ) > .shareOptPrivate
    }

    // diff model
    private func makeCommitInfo() -> Rust.CalendarSaveInfo? {
        let isCreate = input.isFromCreate
        let from = modelTupleBeforeEditing
        let to: (calendar: Rust.Calendar, members: [Rust.CalendarMember]) = (rxCalendar.value.pb, rxCalendarMembers.value)
        var calenadrChanges = 0

        var saveInfo = Rust.CalendarSaveInfo()
        if !isCreate { saveInfo.id = to.calendar.serverID }
        if isCreate || from.calendar.avatarKey != to.calendar.avatarKey {
            saveInfo.coverImageKey = to.calendar.avatarKey
            calenadrChanges += 1
        }
        if isCreate || from.calendar.summary != to.calendar.summary {
            saveInfo.summary = to.calendar.summary
            calenadrChanges += 1
        }
        if isCreate || from.calendar.personalizationSettings.colorIndex != to.calendar.personalizationSettings.colorIndex {
            saveInfo.individualCalendarInfo.colorIndex = to.calendar.personalizationSettings.colorIndex
            calenadrChanges += 1
        }
        if isCreate || from.calendar.description_p != to.calendar.description_p {
            saveInfo.description_p = to.calendar.description_p
            calenadrChanges += 1
        }
        if isCreate || from.calendar.shareOptions != to.calendar.shareOptions {
            saveInfo.shareOptions = to.calendar.shareOptions
            calenadrChanges += 1
        }

        let memberIDsFrom = Set(from.members.map(\.memberID))
        let memberIDsTo = Set(to.members.map(\.memberID))
        var memberCommits = Rust.CalendarMemberCommits()

        // 根据 Venn 图理解

        var memberChanges = 0
        // Add
        let memberIDsToAdd = input.isFromCreate ? memberIDsTo : memberIDsTo.subtracting(memberIDsFrom)
        memberCommits.addMembers = memberIDsToAdd
            .compactMap { memberID -> Rust.CalendarMemberCommit? in
                guard let memberToAdd = to.members.first(where: { $0.memberID == memberID }) else { return nil }
                var commit = Rust.CalendarMemberCommit()
                commit.accessRole = memberToAdd.accessRole
                switch memberToAdd.memberType {
                case .group:
                    commit.memberType = .group
                    commit.group.groupID = memberToAdd.chatID
                case .individual:
                    commit.memberType = .individual
                    commit.user.userID = memberToAdd.userID
                @unknown default: break
                }
                memberChanges += 1
                return commit
            }

        // Remove
        let membersToRemove = memberIDsFrom.subtracting(memberIDsTo)
            .compactMap { memberID -> Rust.CalendarMember? in
                guard let memberToRemove = from.members.first(where: { $0.memberID == memberID }) else { return nil }
                memberChanges += 1
                return memberToRemove
            }
        memberCommits.removeUserIds = membersToRemove
            .filter { $0.memberType == .individual }
            .map(\.userID)
        memberCommits.removeGroupIds = membersToRemove
            .filter { $0.memberType == .group }
            .map(\.chatID)

        // Update
        memberCommits.updateMembers = memberIDsTo.intersection(memberIDsFrom)
            .compactMap { memberID -> Rust.CalendarMemberCommit? in
                guard let originMember = from.members.first(where: { $0.memberID == memberID }),
                      let updateMember = to.members.first(where: { $0.memberID == memberID }),
                      originMember.accessRole != updateMember.accessRole else { return nil }
                var commit = Rust.CalendarMemberCommit()
                commit.accessRole = updateMember.accessRole
                if updateMember.memberType == .group {
                    commit.memberType = .group
                    commit.group.groupID = updateMember.chatID
                } else {
                    commit.memberType = .individual
                    commit.user.userID = updateMember.userID
                }
                memberChanges += 1
                return commit
            }
        memberCommits.userCollaborationForbiddenList = rejectedUserIDs

        if let message = rxMessageToLeave.value {
            memberCommits.comment = message
            memberChanges += 1
        }

        if memberChanges > 0 { saveInfo.memberCommits = memberCommits }

        guard calenadrChanges + memberChanges > 0 else { return nil }

        return saveInfo
    }
}

// MARK: - Computing Value
extension CalendarEditViewModel {
    var currentUserID: String {
        return self.userResolver.userID
    }

    var currentTenantID: String {
        return self.calendarDependency?.currentUser.tenantId ?? ""
    }
}

// MARK: - Api
extension CalendarEditViewModel {

    func fetchCalendar(with calendarID: String) {
        rxViewStatus.accept(.loading)
        rustAPI?.fetchCalendar(calendarID: calendarID)
            .subscribeForUI(onNext: { [weak self] (calendarWithMember) in
                guard let self = self, let calendarWithMember = calendarWithMember else { return }
                self.permission = .init(calendarfrom: .fromEdit(calendar: calendarWithMember.calendar))
                let model = CalendarModelFromPb(pb: calendarWithMember.calendar).getCalendarPB()
                let members = calendarWithMember.members
                self.modelTupleBeforeEditing = (model, members)
                self.forcedSelectMemebers = members.map { ($0.memberID, $0.memberType == .group) }
                self.defaultAuthSettingVM = .init(authSettings: model.shareOptions)
                self.rxCalendar.accept((model, .all))
                self.rxCalendarMembers.accept(members)
                self.rxViewStatus.accept(.dataLoaded)
            }, onError: { error in
                if error.errorType() == .calendarTypeNotSupportErr {
                    self.rxViewStatus.accept(.error(.apiError(.init(definedType: .noSchedule, tip: I18n.Calendar_Onboarding_TypeCalendarDetailsNotSupported))))
                } else if error.errorType() == .calendarIsPrivateErr {
                    self.rxViewStatus.accept(.error(.apiError(.init(definedType: .noPreview, tip: I18n.Calendar_SubscribeCalendar_PrivateCalendarCannotBeSubscribed))))
                } else if error.errorType() == .calendarIsDeletedErr {
                    self.rxViewStatus.accept(.error(.apiError(.init(definedType: .noSchedule, tip: I18n.Calendar_Common_CalendarDeleted))))
                } else {
                    self.rxViewStatus.accept(.error(.fetchError))
                }
                CalendarBiz.editLogger.error(error.localizedDescription)
            }).disposed(by: bag)
    }

    func unsubscribe() {
        let calendar = rxCalendar.value.pb
        let calendarID = calendar.serverID
        let successorChatterID = calendar.successorChatterID

        guard let rustAPI = self.rustAPI else {
            EventEdit.logger.info("unsubscribeCalendar failed, can not get rustapi from larkcontainer")
            return
        }

        let unSubscribeCallBack = {
            self.rxToastStatus.accept(.loading(info: I18n.Calendar_Detail_UnsubscribeProcess, disableUserInteraction: true, fromWindow: true))
            rustAPI.unsubscribeCalendar(with: calendarID)
                .map { response in
                    EventEdit.logger.info("unsubscribeCalendar response \(response)")
                    guard response.code == 0 else {
                        throw CalendarError.alertNoti(title: response.alertTitle, content: response.alertContent)
                    }
                    return
                }.subscribe { [weak self] _ in
                    self?.rxToastStatus.accept(.remove)
                    self?.rxToastStatus.accept(.success(I18n.Calendar_Detail_Unsubscribed, fromWindow: true))
                    self?.rxDismissNoti.accept(())
                } onError: { [weak self] error in
                    if case let .alertNoti(title, content) = error as? CalendarError {
                        self?.rxToastStatus.accept(.remove)
                        self?.rxAlert.accept(.comfirmAlert(title: title, content: content))
                        return
                    }
                    self?.rxToastStatus.accept(.failure(error.getTitle() ?? I18n.Calendar_Toast_FailedToRemoveCalendar))
                }.disposed(by: self.bag)
        }

        if calendar.selfAccessRole == .owner {
            let isResigned = !(successorChatterID.isEmpty || successorChatterID == "0") && calendar.type == .other
            if calendar.type != .primary && isResigned {
                self.rxAlert.accept(.successorUnsubscribe(
                    doUnsubscribe: unSubscribeCallBack,
                    delete: { [weak self] in self?.delete() }
                ))
            } else {
                self.rxAlert.accept(.ownedCalUnsubAlert(doUnsubscribe: unSubscribeCallBack))
            }
        } else {
            unSubscribeCallBack()
        }
    }

    func delete() {
        let doDelete = {
            guard let rustAPI = self.rustAPI else {
                EventEdit.logger.info("delete Calendar failed, can not get rustapi from larkcontainer")
                return
            }

            let calendarID = self.rxCalendar.value.pb.serverID
            self.rxToastStatus.accept(.loading(info: I18n.Calendar_Toast_Deleting, disableUserInteraction: true))
            rustAPI.deleteCalendar(with: calendarID)
                .flatMap { _ -> Single<Void> in
                    // Server有Bug，不能立即返回正确的状态，端上加一层兜底，手动执行取消订阅
                    return rustAPI.unsubscribeCalendar(with: calendarID).map({ _ in () }).catchErrorJustReturn(()).asSingle()
                }
                .subscribe { [weak self] _ in
                    self?.rxToastStatus.accept(.remove)
                    self?.rxToastStatus.accept(.success(I18n.Calendar_Toast_Deleted, fromWindow: true))
                    self?.rxDismissNoti.accept(())
                } onError: { [weak self] error in
                    self?.rxToastStatus.accept(.failure(error.getTitle() ?? BundleI18n.Calendar.Calendar_Common_FailToDelete))
                }.disposed(by: self.bag)

            CalendarTracerV2.CalendarDeleteConfirm.traceClick {
                $0.click("confirm")
                $0.calendar_id = self.modelTupleBeforeEditing.calendar.serverID
            }
        }
        self.rxAlert.accept(.deleteConfirm(doDelete: doDelete))
    }

    func save() {
        guard rxAbleToSave.value else {
            rxToastStatus.accept(.tips(I18n.Calendar_Setting_AddNameThenSave))
            return
        }

        guard let commitInfo = makeCommitInfo() else {
            rxDismissNoti.accept(())
            return
        }

        guard let rustAPI = self.rustAPI else {
            EventEdit.logger.info("save Calendar failed, can not get rustapi from larkcontainer")
            return
        }

        self.rxToastStatus.accept(.loading(info: I18n.Calendar_Toast_Saving, disableUserInteraction: true))
        isSaving = true
        rustAPI.saveCalendar(with: commitInfo, isCreating: input.isFromCreate)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.rxToastStatus.accept(.remove)
                self?.rxToastStatus.accept(.success(I18n.Calendar_Toast_Saved, fromWindow: true))
                self?.isSaving = false
                self?.rxDismissNoti.accept(())
            }, onError: { [weak self] (error) in
                var errorStr: String
                if error.errorType() == .calendarWriterReachLimitErr {
                    errorStr = error.getServerDisplayMessage() ?? I18n.Calendar_Toast_FailedToSave
                } else {
                    errorStr = error.getTitle() ?? I18n.Calendar_Toast_FailedToSave
                }
                self?.isSaving = false
                self?.rxToastStatus.accept(.failure(errorStr))
            })
            .disposed(by: bag)
    }

    func showSelfOnly() {
        guard let rustAPI = self.rustAPI else {
            EventEdit.logger.info("showSelfOnly failed, can not get rustapi from larkcontainer")
            return
        }
        Observable.zip(
            rustAPI.specifyVisibleOnlyCalendars(ids: [rxCalendar.value.pb.serverID]),
            LocalCalendarManager.hideAllIfVisible()
        )
        .map { _ in () }
        .bind(to: rxCalendarListRefresh)
        .disposed(by: bag)
    }

    /// 编辑日历场景，快捷操作（不会进入到编辑页面）
    func directlyChangeColor(with newColorIndex: Int) {
        guard let colorIndex = ColorIndex(rawValue: newColorIndex) else {
            CalendarBiz.editLogger.error("index \(newColorIndex) out of colors panel set")
            return
        }
        var saveInfo = Rust.CalendarSaveInfo()
        saveInfo.id = rxCalendar.value.pb.serverID
        saveInfo.individualCalendarInfo.colorIndex = colorIndex
        self.rxToastStatus.accept(.loading(info: I18n.Calendar_Share_Modifying, disableUserInteraction: false, fromWindow: true))
        self.rustAPI?.saveCalendar(with: saveInfo, isCreating: input.isFromCreate)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.rxToastStatus.accept(.remove)
                self?.rxToastStatus.accept(.success(I18n.Calendar_Share_Modified, fromWindow: true))
                self?.rxCalendarListRefresh.accept(())
            }, onError: { [weak self] (error) in
                self?.rxToastStatus.accept(.failure(I18n.Calendar_Bot_SomethingWrongToast, fromWindow: true))
                CalendarBiz.editLogger.info(error.localizedDescription)
            })
            .disposed(by: bag)
    }

    func addMember(with memberSeeds: [CalendarMemberSeed], message: String?) {
        rxMessageToLeave.accept(message)
        let calID = modelTupleBeforeEditing.calendar.serverID
        guard let rustAPI = self.rustAPI else {
            EventEdit.logger.info("addMember failed, can not get rustapi from larkcontainer")
            return
        }
        rustAPI.getCalendarMembersWithCheck(calendarId: calID, userIds: memberSeeds.userIds, chatIds: memberSeeds.groupIds)
            .subscribeForUI { [weak self] (editedMembers, hasMemberInhibited, rejectedUsers) in
                guard let self = self else { return }
                if hasMemberInhibited {
                    self.rejectedUserIDs = rejectedUsers
                    self.rxToastStatus.accept(.tips(I18n.Calendar_Share_NoPermitShare_Toast, fromWindow: true))
                }
                // 若默认权限设置不合法（高于 admin 最新配置）- follow new setting.
                let shareOptioins = self.rxCalendar.value.pb.shareOptions
                let innerDefault = min(shareOptioins.innerDefault, shareOptioins.innerDefaultTopOption).cd.mappedAccessRole ?? .freeBusyReader
                let externalDefault = min(shareOptioins.externalDefault, shareOptioins.externalDefaultTopOption).cd.mappedAccessRole ?? .freeBusyReader

                let originalMembers = self.rxCalendarMembers.value
                let members = editedMembers.map {
                    var member = $0
                    if let originalMember = originalMembers.first(where: { $0.memberID == member.memberID }) {
                        member.accessRole = originalMember.accessRole
                    } else {
                        member.accessRole = $0.relationType == .external ? externalDefault : innerDefault
                    }
                    return member
                }
                let allMembers = self.forcedSelectMemebers.compactMap { selecedInfo -> Rust.CalendarMember? in
                    originalMembers.first(where: { $0.memberID == selecedInfo.id })
                } + members
                self.rxCalendarMembers.accept(allMembers)
                self.preSelectedMembers = members.map { ($0.memberID, $0.memberType == .group) }
            } onError: { error in
                CalendarBiz.editLogger.error(error.localizedDescription)
            }.disposed(by: bag)
    }

    private func downLoadAvatar(with key: String) {
        guard let rustAPI = self.rustAPI else {
            EventEdit.logger.info("downLoadAvatar failed, can not get rustapi from larkcontainer")
            return
        }
        rustAPI.downLoadImage(with: key)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (imagePath) in
                guard let self = self else { return }
                guard let path = imagePath?.asAbsPath(), let avatar = try? UIImage.read(from: path) else {
                    CalendarBiz.editLogger.error("Haven't found any image from the path.")
                    return
                }
                let calendar = self.rxCalendar.value.pb
                self.avatarImage = avatar
                self.avatarImageKey = key
                self.rxCalendar.accept((calendar, .avatar))
            }, onError: { error in
                CalendarBiz.editLogger.error(error.localizedDescription)
            }).disposed(by: bag)
    }

    private func appendSelfAsMember() {
        guard let rustAPI = self.rustAPI else {
            EventEdit.logger.info("appendSelfAsMember failed, can not get rustapi from larkcontainer")
            return
        }
        // Append self as a member automatically
        rustAPI.getCalendarMembers(with: "", userIds: [self.userResolver.userID], chatIds: [])
            .subscribeForUI { [weak self] members in
                guard let self = self, var selfAsMember = members[safeIndex: 0] else { return }
                selfAsMember.accessRole = .owner
                self.rxCalendarMembers.accept([selfAsMember])
                self.modelTupleBeforeEditing.members = [selfAsMember]
                self.forcedSelectMemebers = [(selfAsMember.memberID, selfAsMember.memberType == .group)]
            } onError: { error in
                CalendarBiz.editLogger.error(error.localizedDescription)
            }.disposed(by: bag)
    }
}

// MARK: - Model Update
extension CalendarEditViewModel {
    func updateAvatar(with key: String, image: UIImage) {
        var calendar = rxCalendar.value
        calendar.pb.avatarKey = key
        calendar.fieldUpdated = .avatar
        avatarImage = image
        rxCalendar.accept(calendar)
    }

    func updateSummary(with text: String) {
        var calendar = rxCalendar.value
        calendar.pb.summary = text
        calendar.fieldUpdated = .title
        rxCalendar.accept(calendar)
    }

    func updateColor(with index: Int) {
        guard let colorIndex = ColorIndex(rawValue: index) else {
            CalendarBiz.editLogger.error("index \(index) out of colors panel set")
            return
        }
        var calendar = rxCalendar.value
        calendar.pb.personalizationSettings.colorIndex = colorIndex
        calendar.fieldUpdated = .color
        rxCalendar.accept(calendar)
    }

    func updateDescription(with text: String) {
        var calendar = rxCalendar.value
        calendar.pb.description_p = text
        calendar.fieldUpdated = .description
        rxCalendar.accept(calendar)
    }

    func updateAuthSettings(with settings: DefaultAuthSetting, type: DefaultAuthFrom) {
        var calendar = rxCalendar.value
        calendar.pb.shareOptions = settings
        calendar.fieldUpdated = type == .inner ? .authInGroup : .authOutofGroup
        rxCalendar.accept(calendar)
    }

    func updateMemberAccess(with id: String, role: Rust.CalendarAccessRole) {
        var members = rxCalendarMembers.value
        guard let memberIndex = rxCalendarMembers.value.firstIndex(where: { $0.memberID == id }),
              var member = members[safeIndex: memberIndex] else { return }
        member.accessRole = role
        members[memberIndex] = member
        rxCalendarMembers.accept(members)
    }

    func deleteMember(with id: String) {
        var members = rxCalendarMembers.value
        members.removeAll { $0.memberID == id }
        forcedSelectMemebers.removeAll { $0.id == id }
        preSelectedMembers.removeAll { $0.id == id }
        rxCalendarMembers.accept(members)
    }
}
