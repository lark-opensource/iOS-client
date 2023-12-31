//
//  EventEditAttendeeManager.swift
//  Calendar
//
//  Created by 张威 on 2020/3/20.
//

import RxCocoa
import RxSwift
import RoundedHUD
import EENavigator
import LarkContainer

typealias AttendeeData = (
    // 日程可见参与人（剔除 status == removed 的参与人以及 empty 的 group 参与人）
    visibleAttendees: [EventEditAttendee],
    // 日程可见参与人数量（群成员被打散纳入统计）
    breakUpAttendeeCount: Int
)

enum PullAllAttendeeStatus {
    case initialize // 未拉取
    case loading    // 拉取中
    case success    // 拉取成功，已经是全量参与人
    case failed     // 拉取失败
}

/// 日程编辑 - 参与人管理
final class EventEditAttendeeManager: EventEditModelManager<[EventEditAttendee]> {

    @ScopedInjectedLazy var api: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var mailContactService: MailContactService?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    // 日程完整参与人，包括 status == removed 的参与人
    var rxAttendees = BehaviorRelay(value: [EventEditAttendee]())
    // 日程新添加的精简参与人，出现在大群打散的时候
    var rxNewSimpleAttendees = BehaviorRelay(value: [Rust.IndividualSimpleAttendee]())
    // 原日程的 user 参与人，大量参与人日程有可能经过二次加载填充
    private(set) var rxOriginalIndividualimpleAttendees = BehaviorRelay(value: [Rust.IndividualSimpleAttendee]())

    let rxAttendeeData = BehaviorRelay(value: AttendeeData([], 0))
    let rxLoading = BehaviorRelay(value: false)
    /// 正常是通过计算获取当前参与人人数，某些情况使用 rust 数量，默认值为 false
    private var useRustAttendeeCount: Bool = false
    private var rustAllAttendeeCount: Int?

    // 原日程 ± 修改的attendee
    var individualSimpleAttendees: [Rust.IndividualSimpleAttendee] {
        let userAttendee = self.rxAttendees.value.filter { attendee in
            switch attendee {
            case .user:
                return true
            case .email:
                return true
            default:
                return false
            }
        }.compactMap { $0.getPBModel()?.toIndividualSimpleAttendee() }

        var fullAttendees = userAttendee
        let fullAttendeesKeys = Set(fullAttendees.map { $0.deduplicatedKey })

        let simpleAttendees = Rust.IndividualSimpleAttendee
            .deduplicated(of: rxOriginalIndividualimpleAttendees.value + rxNewSimpleAttendees.value)
            .filter { !fullAttendeesKeys.contains($0.deduplicatedKey) }
        return userAttendee + simpleAttendees
    }

    // 原日程 ± 修改的attendee
    var groupSimpleAttendees: [Rust.GroupSimpleAttendee] {
        return self.rxAttendees.value.filter { attendee in
            if case .group = attendee {
                return true
            }
            return false
        }.compactMap { $0.getPBModel()?.toGroupSimpleAttendee() }
    }

    private var disposeBag = DisposeBag()
    private var lastLoadDisposable: Disposable?
    private(set) var groupSimpleMembers: [String: [Rust.IndividualSimpleAttendee]] = [:]
    private(set) var groupEncryptedMembers: [String: [Rust.EncryptedSimpleAttendee]] = [:]
    private(set) var extraGroupMember: [Rust.IndividualSimpleAttendee] = []

    let input: EventEditInput

    // 参与人的管理，与 calendar、meetingRooms 有耦合逻辑
    private(set) var calendar: EventEditCalendar?
    // 最大参与人限制数量
    private let attendeeTotalLimit: Int = SettingService.shared().finalEventAttendeeLimit
    // 是否被大人数日程管控，默认true，管控状态
    var attendeeMaxCountControlled: Bool = true
    // 群参与人过滤掉的群成员（高管）
    private(set) var rejectedGroupUserMap: [String: [Int64]] = [:]
    // 部门作为参与人的成员数量限制
    let departmentMemberUpperLimit: Int = SettingService.shared().settingExtension.departmentMemberUpperLimit

    // 日程相关信息获取 delegate
    weak var eventDelegate: EventEditModelGetterProtocol?

    // 大量参与人日程下 非全量参与人逻辑
    let rxPullAllAttendeeStatus = BehaviorRelay<PullAllAttendeeStatus>(value: .initialize)
    var haveAllAttendee: Bool {
        haveAllIndivudualAttendee && haveAllGroupMember
    }
    private var haveAllIndivudualAttendee: Bool = false
    private var haveAllGroupMember: Bool = false

    let rxAnyFilteredAttendee = BehaviorRelay<Bool>(value: false)

    let rxAddAttendeeMessage: BehaviorRelay<AddAttendeeViewMessage?> = .init(value: nil)

    let rxAlertMessage: BehaviorRelay<(title: String, message: String)?> = .init(value: nil)

    private let addAttendees = (queue: DispatchQueue(label: "lark.calendar.event_edit.add_attendee"),
                                lock: DispatchSemaphore(value: 1))

    init(identifier: String, input: EventEditInput, userResolver: UserResolver) {
        self.input = input
        super.init(userResolver: userResolver, identifier: identifier, rxModel: rxAttendees)
    }

    func initMethod(with calendar: EventEditCalendar?) {
        var seeds = [EventAttendeeSeed]()
        self.calendar = calendar
        if let calendar = calendar {
            self.updateAttendeeIfNeeded(forCalendarChanged: calendar)
        }

        switch input {
        case .createWithContext(let createContext):
            seeds = EventAttendeeSeed.deduplicated(of: createContext.attendeeSeeds)
            self.haveAllIndivudualAttendee = true
            self.haveAllGroupMember = true
        case .editFrom(let pbEvent, _):
            var attendees = EventEditAttendee.makeAttendees(from: pbEvent.attendees)
            let simpleAttendees = pbEvent.attendees
                .filter { $0.category == .user || $0.category == .thirdPartyUser }
                .map { $0.toIndividualSimpleAttendee() }
            self.rxOriginalIndividualimpleAttendees.accept(simpleAttendees)
            self.rxAttendees.accept(EventEditAttendee.deduplicated(of: attendees))
            self.rustAllAttendeeCount = Int(pbEvent.attendeeInfo.totalNo)
            self.haveAllIndivudualAttendee = pbEvent.attendeeInfo.allIndividualAttendee
            self.useRustAttendeeCount = !(pbEvent.isEditable || pbEvent.guestCanInvite)
            if pbEvent.guestCanInvite && pbEvent.attendees.contains(where: { $0.category == .group }) {
                self.haveAllGroupMember = false
                self.pullGroupsSimpleMembers(with: pbEvent)
            } else {
                self.haveAllGroupMember = true
            }
        case .editFromLocal(let ekEvent):
            let attendees: [EventEditAttendee] = (ekEvent.attendees ?? [])
                .filter { $0.participantType != .resource && $0.participantType != .room }
                .map { .local(EventEditLocalAttendee(ekModel: $0)) }
            self.rxAttendees.accept(EventEditAttendee.deduplicated(of: attendees))
            self.haveAllIndivudualAttendee = true
            self.haveAllGroupMember = true
        case .copyWithEvent(let event, _):
            let attendees = EventEditAttendee.makeAttendees(from: event.attendees)

            self.rxAttendees.accept(EventAttendee.deduplicated(of: attendees))
            self.haveAllIndivudualAttendee = false
            self.haveAllGroupMember = false

            let attendeesCount = Int(event.attendeeInfo.totalNo)
            if let limitReason = attendeesUpperLimitReason(with: attendeesCount) {
                self.haveAllIndivudualAttendee = true
                self.haveAllGroupMember = true
                self.rxAttendees.accept([])
                self.rxAlertMessage.accept((I18n.Calendar_G_FailCopyGuests_Pop, I18n.Calendar_G_FailCopyGuests_Explain(number: limitReason.limit)))
            }
        case .createWebinar, .editWebinar:
//            assertionFailure("webinar should not init attendee model!")
            break
        }

        self.bindRxAttendeeData()
        self.bindRxMailParsedPush()
        self.addAttendees(withSeeds: seeds, isFromInit: true) { [weak self] message in
            self?.rxAddAttendeeMessage.accept(message)
        }
        self.loadAllAttendeeIfNeeded()
    }

    private func bindRxAttendeeData() {
        let map = { [weak self] (attendees: [EventEditAttendee],
                                 newSimpleAttendees: [Rust.IndividualSimpleAttendee],
                                 originalIndividualSimpleAttendees: [Rust.IndividualSimpleAttendee]) -> AttendeeData in
            guard let self = self else { return AttendeeData([], 0) }
            var attendees = attendees.map { att in
                switch att {
                case .email(var mail):
                    mail.mailContactService = self.mailContactService
                    return EventEditAttendee.email(mail)
                default: return att
                }
            }
            var breakUpAttendeeCount: Int
            let simpleAttendee = Rust.IndividualSimpleAttendee.deduplicated(of: newSimpleAttendees + originalIndividualSimpleAttendees)

            if !self.useRustAttendeeCount {
                breakUpAttendeeCount = EventEditAttendee
                    .allBreakedUpAttendeeCount(of: attendees,
                                               individualSimpleAttendees: simpleAttendee)
            } else {
                breakUpAttendeeCount = self.rustAllAttendeeCount ?? 0
            }

            attendees.forEach { att in
                if case .group(let groupAttendee) = att, !groupAttendee.memberSeeds.isEmpty {
                    self.groupSimpleMembers[groupAttendee.chatId] = groupAttendee.memberSeeds
                }
            }

            let originalKeys = originalIndividualSimpleAttendees.map { $0.deduplicatedKey }
            // 参与者显示排序
            let sortContext = AttendeeSortContext(
                organizerCalendarId: self.organizerCalendarId,
                creatorCalendarId: self.creatorCalendarId,
                addedAtTail: true,
                originalKeys: originalKeys)
            attendees = attendees.sortedWith(context: sortContext)

            return AttendeeData(
                EventAttendee.visibleAttendees(of: attendees),
                breakUpAttendeeCount
            )
        }

        Observable.combineLatest(
            rxAttendees,
            rxNewSimpleAttendees,
            rxOriginalIndividualimpleAttendees
        )
        .observeOn(MainScheduler.instance)
        .map(map)
        .bind(to: rxAttendeeData)
        .disposed(by: disposeBag)
    }

    private func bindRxMailParsedPush() {
        mailContactService?.rxDataChanged
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.rxAttendees.accept(self.rxAttendees.value)
            })
            .disposed(by: disposeBag)
    }

    private func pullGroupsSimpleMembers(with event: Rust.Event) {
        api?.pullEventGroupsSimpleAttendeeList(
            calendarID: event.calendarID,
            key: event.key,
            originalTime: event.originalTime
        ).observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (response) in
            guard let `self` = self else { return }
            self.groupSimpleMembers = response.groupMembers.mapValues { $0.attendees }
            self.groupEncryptedMembers = response.encryptedGroupMembers.mapValues { $0.encryptedAttendees }
            self.appendGroupsSimpleMembers(groupsSimpleMembers: self.groupSimpleMembers,
                                           encrpytedSimpleMembers: self.groupEncryptedMembers)
            var groupLimitInfo: [String: Int] = [:]
            event.attendees.filter { $0.category == .group }.forEach { attendee in
                if attendee.group.openSecurity {
                    groupLimitInfo[attendee.group.groupID] = Int(attendee.group.showMemberLimit)
                }
            }

            self.pullUserAttendeeDisplayInfo(groupsSimpleMembers: response.groupMembers.mapValues { $0.attendees },
                                             groupLimitInfo: groupLimitInfo)
            self.haveAllGroupMember = true
            self.rxPullAllAttendeeStatus.accept(self.haveAllAttendee ? .success : .loading)
        }).disposed(by: self.disposeBag)
    }

    private func appendGroupsSimpleMembers(groupsSimpleMembers: [String: [Rust.IndividualSimpleAttendee]],
                                           encrpytedSimpleMembers: [String: [Rust.EncryptedSimpleAttendee]]) {
        let attendees = self.rxAttendees.value.map { (attendee) -> EventEditAttendee in
            // 仅在groupMember是normal类型，并且为空时会填充simple类型
            if case .group(var groupAttendee) = attendee {
                groupAttendee.memberSeeds = groupsSimpleMembers[groupAttendee.chatId] ?? []
                groupAttendee.encryptedSeeds = encrpytedSimpleMembers[groupAttendee.chatId] ?? []
                return .group(groupAttendee)
            }
            return attendee
        }
        self.rxAttendees.accept(attendees)
    }

    // 避免安全隐患，预加载群成员 displayInfo 以 showMemberLimit 为上限
    private func pullUserAttendeeDisplayInfo(groupsSimpleMembers: [String: [Rust.IndividualSimpleAttendee]],
                                             groupLimitInfo: [String: Int]) {
        var pullChatterTotalCnt = 0
        let totalLimit = SettingService.shared().settingExtension.attendeeTimeZoneEnableLimit
        let oneceLimit = EventAttendeeListViewModel.EventGroupAttendeeMembersPageCount
        groupsSimpleMembers.forEach { (chatID, simpleAttendees) in
            var pullCount = min(totalLimit - pullChatterTotalCnt, Int(oneceLimit))
            if let showMemberLimit = groupLimitInfo[chatID] {
                pullCount = min(showMemberLimit, pullCount)
            }

            let pullAttendees = simpleAttendees.prefix(pullCount)
            pullChatterTotalCnt += pullAttendees.count
            api?.pullEventEditUserAttendee(with: pullAttendees)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (attendees) in
                    guard let `self` = self else { return }

                    let attendees = self.rxAttendees.value.map { (attendee) -> EventEditAttendee in
                        if case .group(var groupAttendee) = attendee, groupAttendee.chatId == chatID {
                            groupAttendee.members = attendees
                            groupAttendee.hasMoreMembers = simpleAttendees.count > groupAttendee.members.count

                            return .group(groupAttendee)
                        }
                        return attendee
                    }
                    self.rxAttendees.accept(attendees)
                }).disposed(by: self.disposeBag)
        }
    }

    // 重置参与人
    func resetAttedees(attendees: [EventEditAttendee],
                       simpleAttendees: [Rust.IndividualSimpleAttendee]) {
        self.lastLoadDisposable?.dispose()
        if self.rxLoading.value {
            self.rxLoading.accept(false)
        }
        self.rxAttendees.accept(attendees)
        self.rxNewSimpleAttendees.accept(simpleAttendees)
    }

    // 清除参与人
    func clearAttendees() {
        resetAttedees(attendees: [], simpleAttendees: [])
    }

    // 添加参与人
    func addAttendees(
        withSeeds seeds: [EventAttendeeSeed],
        departments: [(id: String, name: String)] = .init(),
        isFromInit: Bool = false,
        messageReceiver: ((AddAttendeeViewMessage) -> Void)? = nil,
        onCompleted: (() -> Void)? = nil
    ) {
        guard !seeds.isEmpty || !departments.isEmpty else { return }

        addAttendees.queue.async {
            self.addAttendees.lock.wait()
            self.doAddAttendees(
                withSeeds: seeds,
                departments: departments,
                isFromInit: isFromInit,
                messageReceiver: messageReceiver,
                onCompleted: {
                    self.addAttendees.lock.signal()
                    onCompleted?()
                },
                onTerminated: { self.addAttendees.lock.signal() }
            )
        }
    }

    func autoInsertAttendeeForCopyEvent() {
        guard case .copyWithEvent = input else { return }
        let userAttendees = self.rxAttendees.value
        if userAttendees.isEmpty { return }
        if let calendar = calendar,
           let autoInsertChatterId = autoInsertAttendeeChatterId(forLarkCalendar: calendar) {

            if !userAttendees.containsUser(with: autoInsertChatterId) {
                addAttendees(withSeeds: [.user(chatterId: autoInsertChatterId)])
            }
        }
    }

    func changeEmailUserEditableForCopyEvent() {
        guard case .copyWithEvent = input,
              let calendar = calendar,
              calendar.source == .google || calendar.source == .exchange,
              !calendar.emailAddress.isEmpty else { return }
        autoInsertAttendee(forExternalCalendar: calendar)
    }

    func autoInsertEmailAttendee() -> EventEditEmailAttendee? {
        guard let calendar = calendar,
            calendar.source == .google,
            calendar.isPrimary,
            !calendar.emailAddress.isEmpty else {
            return nil
        }

        return EventEditEmailAttendee(
            address: calendar.emailAddress,
            calendarId: calendar.id,
            status: .accept,
            permission: .writable
        )
    }

    private func autoInsertAttendeeChatterId(forLarkCalendar calendar: EventEditCalendar) -> String? {
        guard calendar.source == .lark else {
            return nil
        }
        let chatterId: String
        if calendar.isPrimary {
            // 添加参与人时，如果当前是 lark 主日历，则根据需要将日历对应的 chatter 给带进去
            guard !calendar.userChatterId.isEmpty else {
                assertionFailure()
                return nil
            }
            chatterId = calendar.userChatterId
        } else {
            // 添加参与人时，如果当前是 lark 普通日历，则根据需要将日程对应的组织者（当前用户）给带进去
            chatterId = userResolver.userID
        }
        let attendees = EventAttendee.visibleAttendees(of: rxAttendees.value)
        guard attendees.isEmpty || input.isCopy,
              !rxOriginalIndividualimpleAttendees.value.map(\.user.chatterID).contains(chatterId) else { return nil }
        return chatterId
    }

    private func resetAttendee(forOldCalendar calendar: EventEditCalendar) {
        guard input.isFromCreating else { return }
        switch calendar.source {
        case .exchange, .google:
            guard !calendar.emailAddress.isEmpty else { return }
            let attendees = rxAttendees.value.map { attendee -> EventEditAttendee in
                guard case .email(let e) = attendee,
                      e.address == calendar.emailAddress,
                      e.status == .accept else {
                          return attendee
                      }
                var me = e
                me.status = .needsAction
                me.permission = .writable
                return .email(me)
            }
            rxAttendees.accept(attendees)
        case .lark:
            let attendees = rxAttendees.value.map { attendee -> EventEditAttendee in
                guard case .user(let u) = attendee,
                      u.chatterId != self.userResolver.userID,
                      u.chatterId == calendar.userChatterId else {
                          return attendee
                      }
                // 原日历的owner（不包含当前用户）状态置为 needsAction
                var user = u
                user.status = .needsAction
                return .user(user)
            }
            rxAttendees.accept(attendees)
        default:
            return
        }
    }

    private func resetAttendee(forNewCalendar calendar: EventEditCalendar) {
        guard input.isFromCreating else { return }
        switch calendar.source {
        case .exchange:
            // 如果切换到 三方 日历，则自动将组织者添加为参与人
            autoInsertAttendee(forExternalCalendar: calendar)
        case .lark:
            // 如果切换到 Lark主日历，则自动将参与人中对应的owner状态设置为accept
            guard calendar.isPrimary else { return }
            let attendees = rxAttendees.value.map { attendee -> EventEditAttendee in
                guard case .user(let u) = attendee,
                      u.chatterId == calendar.userChatterId else {
                          return attendee
                      }
                // 新目标日历的owner状态置为 accept
                var user = u
                user.status = .accept
                return .user(user)
            }
            rxAttendees.accept(attendees)
        default:
            return
        }
    }

    private func autoInsertAttendee(forExternalCalendar calendar: EventEditCalendar) {
        guard input.isFromCreating,
              calendar.source == .exchange || calendar.source == .google,
              !calendar.emailAddress.isEmpty else {
            return
        }

        let calendarId: String?
        if calendar.isPrimary {
            calendarId = calendar.id
        } else {
            calendarId = calendar.parentId
        }
        let permission: PermissionOption = calendar.source == .google ? .writable : .readable
        let needInsert = EventEditEmailAttendee(
            address: calendar.emailAddress,
            calendarId: calendarId ?? "",
            status: .accept,
            permission: permission
        )
        var attendees = rxAttendees.value.filter {
            if case .email(let attendee) = $0 {
                return attendee.address != needInsert.address
            }
            return true
        }
        attendees.append(.email(needInsert))
        rxAttendees.accept(attendees)
    }

    func updateAttendeeIfNeeded(forCalendarChanged newCalendar: EventEditCalendar) {
        if let oldCalendar = calendar {
            // 如果之前是 exchange 日历，则将对应 attendee 的状态置为 writable，
            // status 设置为 needAction
            resetAttendee(forOldCalendar: oldCalendar)
        }

        calendar = newCalendar

        resetAttendee(forNewCalendar: newCalendar)
    }

    func updateAttendeeIfNeeded(forMeetingRoomsAdded newMeetingRooms: [CalendarMeetingRoom]) {
        guard let calendar = calendar else {
            return
        }
        guard let chatterId = autoInsertAttendeeChatterId(forLarkCalendar: calendar) else { return
        }

        self.addAttendees(withSeeds: [.user(chatterId: chatterId)])
    }
}

typealias CopyAttendees = (attendees: [EventEditAttendee],
                           groupAttendees: [EventEditAttendee],
                           simpleAttendees: [Rust.IndividualSimpleAttendee])

extension EventEditAttendeeManager {
    private func loadAllAttendeeIfNeeded() {

        if haveAllAttendee {
            // 已经包含全量独立参与人了
            rxPullAllAttendeeStatus.accept(.success)
            return
        }

        if case let .editFrom(pbEvent, _) = input,
           pbEvent.displayType == .full && (pbEvent.calendarID == pbEvent.organizerCalendarID || pbEvent.guestCanSeeOtherGuests) {
            rxPullAllAttendeeStatus.accept(.loading)
            api?.pullEventIndividualSimpleAttendeeList(calendarID: pbEvent.calendarID, key: pbEvent.key, originalTime: pbEvent.originalTime)
                .asSingle()
                .subscribe { [weak self] (response) in
                    guard let self = self else { return }
                    EventEdit.logger.info("pull all individual attendees success")
                    // 拉到全量独立参与人之后，直接覆盖
                    self.rxOriginalIndividualimpleAttendees.accept(response.attendees)
                    self.haveAllIndivudualAttendee = true
                    self.rxPullAllAttendeeStatus.accept(self.haveAllAttendee ? .success : .loading)
                } onError: { [weak self] (error) in
                    guard let self = self else { return }
                    EventEdit.logger.error("pull all individual attendees error: \(error)")
                    self.rxPullAllAttendeeStatus.accept(.failed)
                }.disposed(by: disposeBag)
        } else if case .copyWithEvent(let originalEvent, let instance) = input {
            rxPullAllAttendeeStatus.accept(.loading)
            var originalEmailAttendee: [String: Rust.Attendee] = [:]
            originalEvent.attendees.forEach { attendee in
                if attendee.category == .thirdPartyUser {
                    originalEmailAttendee[attendee.thirdPartyUser.email] = attendee
                }
            }

            var anyFilteredAttendee: Bool = false
            var simpleAttendees: [Rust.IndividualSimpleAttendee] = []
            api?.getEventAttendeesForCopyV2(calendarID: instance.calendarID,
                                           key: instance.key,
                                           originalTime: instance.originalTime)
            .flatMap { [weak self] copyResponse -> Observable<([PBAttendee], [EventEditUserAttendee])> in
                guard let self = self,
                      let rustAPi = self.api,
                      let primaryCalendarID = self.calendarManager?.primaryCalendarID else { return .empty() }

                anyFilteredAttendee = copyResponse.anyFilteredAttendee

                let groupIDs = copyResponse.groupAttendees.map { $0.group.groupID }
                let rxGetGroupAttendees = rustAPi.getGroupFakeAttendees(groupIds: groupIDs,
                                                                        primaryCalendarID: primaryCalendarID)

                simpleAttendees = copyResponse.individualAttendees
                let userOptional = [String: Bool].init(
                    uniqueKeysWithValues: simpleAttendees.compactMap({ attendee in
                        switch attendee.attendeeUserInfo {
                        case .user:
                            return (attendee.deduplicatedKey, attendee.isOptional)
                        @unknown default:
                            return nil
                        }
                    }))

                let pullAttendee = simpleAttendees.prefix(AttendeePaginatorImpl.pageSize)
                let rxPullIndividualAttendee = rustAPi.pullEventEditUserAttendee(with: pullAttendee)

                return Observable.zip(rxGetGroupAttendees, rxPullIndividualAttendee)
            }
            .subscribe(onNext: { [weak self] (groupAttendees, userAttendees) in
                guard let self = self else { return }
                var userAttendees = userAttendees.map { EventEditAttendee.user($0) }
                let emailAttendees = simpleAttendees
                    .filter { $0.category == .thirdPartyUser }
                    .map { attendee -> EventEditAttendee in
                        // 修复邮件参与人标签
                        let type = originalEmailAttendee[attendee.thirdPartyUser.email]?.thirdPartyUser.mailContactType
                        return EventEditAttendee.email(EventEditEmailAttendee(simpleAttendee: attendee, type: type ?? .unknown))
                    }

                userAttendees.append(contentsOf: emailAttendees)
                if !anyFilteredAttendee {
                    anyFilteredAttendee = !groupAttendees.flatMap(\.forbidenChatterIDs).isEmpty
                }
                var groupAttendees = EventEditAttendee.makeAttendees(from: groupAttendees)
                var simpleAttendees = simpleAttendees
                let attendeesCount = EventEditAttendee.allBreakedUpAttendeeCount(of: groupAttendees + userAttendees, individualSimpleAttendees: simpleAttendees)
                if let limitReason = self.attendeesUpperLimitReason(with: attendeesCount) {
                    // 大人数日程管控后置判断，优先展示大人数日程弹窗
                    anyFilteredAttendee = false
                    userAttendees = []
                    groupAttendees = []
                    simpleAttendees = []
                    self.rxAlertMessage.accept((I18n.Calendar_G_FailCopyGuests_Pop, I18n.Calendar_G_FailCopyGuests_Explain(number: limitReason.limit)))
                }
                self.haveAllIndivudualAttendee = true // 和参与者cell toast相关
                self.haveAllGroupMember = true
                self.rxOriginalIndividualimpleAttendees.accept(simpleAttendees)
                self.rxAttendees.accept(userAttendees + groupAttendees)
                self.rxNewSimpleAttendees.accept([])
                self.rxPullAllAttendeeStatus.accept(.success) // 和保存置灰相关
                self.rxAnyFilteredAttendee.accept(anyFilteredAttendee)
                if anyFilteredAttendee {
                    CalendarTracerV2.EventCopyFilteredMembers.traceView {
                        $0.action_source = "full_create_view"
                        $0.mergeEventCommonParams(commonParam: CommonParamData())
                    }
                    self.rxAlertMessage.accept((I18n.Calendar_Copy_UnableToCopyAllGuests_PopupTitle, I18n.Calendar_G_CreateEvent_AddUser_CantInvite_Hover))
                }
                // 复制场景自动添加原日程参与者中不存在的目标日历owner或者当前用户
                self.autoInsertAttendeeForCopyEvent()
                // 复制场景自动添加原日程参与者中不存在的的目标三方日历owner并改变其状态(is_editable)为可读
                self.changeEmailUserEditableForCopyEvent()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                EventEdit.logger.error("pull all authorized attendees error: \(error)")
                self.rxOriginalIndividualimpleAttendees.accept([])
                self.rxAttendees.accept([])
                self.haveAllIndivudualAttendee = true
                self.haveAllGroupMember = true
                self.rxPullAllAttendeeStatus.accept(.failed)
                self.autoInsertAttendeeForCopyEvent()
                self.changeEmailUserEditableForCopyEvent()
            }).disposed(by: disposeBag)
        } else {
            /// SDK 隐藏参与人的日程，在保存后回到详情页，触发的GetEvent返回的attendeeInfo存在问题（haveAllIndividualAttendee会为false)，端上进行兜底处理
            self.rxPullAllAttendeeStatus.accept(.failed)
        }
    }

    func waitAllAttendees(onSuccess: @escaping (() -> Void),
                          onFailure: @escaping (() -> Void)) {

        var onceDispose: Disposable?

        let currentState = rxPullAllAttendeeStatus.value
        switch currentState {
        case .initialize: break
        case .success: onSuccess()
        case .failed: onFailure()
        case .loading:
            onceDispose = rxPullAllAttendeeStatus.subscribeForUI(onNext: { state in
                switch state {
                case .success:
                    onSuccess()
                    onceDispose?.dispose()
                case .failed:
                    onFailure()
                    onceDispose?.dispose()
                case .initialize, .loading: break
                }
            })
        }
    }
}

fileprivate extension Array where Element == EventEditAttendee {
    func containsUser(with chatterId: String) -> Bool {
        let whereExpr = { (attendee: EventEditAttendee) -> Bool in
            if case .user(let userAttendee) = attendee, chatterId == userAttendee.chatterId {
                return true
            } else {
                return false
            }
        }
        return self.contains(where: whereExpr)
    }
}

// MARK: 大人数日程管控逻辑
extension EventEditAttendeeManager {
    // 判断 count 后是否达到人数管控上限
    func attendeesUpperLimitReason(with count: Int, isForAI: Bool = false) -> AttendeesLimitReason? {
        guard let serverID = calendarManager?.primaryCalendar.serverId else { return nil }
        return Self.attendeesUpperLimitReason(
            count: count,
            calendar: calendar,
            attendeeMaxCountControlled: attendeeMaxCountControlled,
            isEventCreator: originEventCreator == serverID,
            isRecurEvent: isRecurEvent,
            isForAI: isForAI
        )
    }

    private var originEventCreator: String {
        switch self.input {
        case .editFrom(let event, _):
            return event.creatorCalendarID
        case .createWithContext, .copyWithEvent:
            return self.creatorCalendarId.isEmpty ? calendarManager?.primaryCalendarID ?? "" : self.creatorCalendarId
        default:
            return ""
        }
    }
}

extension EventEditAttendeeManager: AddAttendeeProcess {

    var isEventCreator: Bool {
        originEventCreator == calendarManager?.primaryCalendar.serverId
    }

    func autoInsertAttendeeChatterIdForAddAttendeeProcess() -> String? {
        guard let calendar = calendar else { return nil }
        return autoInsertAttendeeChatterId(forLarkCalendar: calendar)
    }

    private func doAddAttendees(
        withSeeds seeds: [EventAttendeeSeed],
        departments: [(id: String, name: String)] = .init(),
        isFromInit: Bool = false,
        messageReceiver: ((AddAttendeeViewMessage) -> Void)? = nil,
        onCompleted: (() -> Void)? = nil,
        onTerminated: (() -> Void)? = nil
    ) {
        let context = AddAttendeeContext(
            userResolver: userResolver,
            currentAttendees: rxAttendees.value,
            currentSimpleAttendees: rxNewSimpleAttendees.value,
            calendar: calendar,
            rejectedGroupUserMap: rejectedGroupUserMap,
            seeds: seeds,
            departments: departments,
            rxAttendees: rxAttendees,
            autoInsertAttendeeChatterId: (input.isFromAI && isFromInit) ? nil : autoInsertAttendeeChatterIdForAddAttendeeProcess(),
            disposeBag: disposeBag,
            isEventCreator: isEventCreator,
            eventCommonParam: CommonParamData(event: self.event?.getPBModel())
        )
        context.attendeesUpperLimitReasonGetter = (input.isFromAI && isFromInit) ? nil : { [weak context, weak self] () -> AttendeesLimitReason? in
            guard let processContext = context else {
                return nil
            }
            let allBreakedUpCount = EventEditAttendee.allBreakedUpAttendeeCount(
                of: processContext.currentAttendees,
                individualSimpleAttendees: processContext.currentSimpleAttendees
            )
            return self?.attendeesUpperLimitReason(with: allBreakedUpCount)
        }

        doAddAttendees(context: context)
            .subscribe(
                onState: { [weak self] in
                    self?.rxLoading.accept(false)
                    if !context.isTransactionEnded {
                        self?.rxAttendees.accept(context.currentAttendees)
                        self?.rxNewSimpleAttendees.accept(context.currentSimpleAttendees)
                        self?.rejectedGroupUserMap = context.rejectedGroupUserMap
                        context.isTransactionEnded = true
                    }
                },
                onMessage: { message in
                    messageReceiver?(message)
                },
                onCompleted: onCompleted,
                onTerminate: { [weak self] err in
                    EventEdit.logger.error("err: \(err)")
                    self?.rxLoading.accept(false)
                    onTerminated?()
                },
                scheduler: MainScheduler.instance
            )
    }
}

extension EventEditAttendeeManager {
    private var event: EventEditModel? {
        eventDelegate?.getEventEditModel()
    }

    var organizerCalendarId: String {
        event?.organizerCalendarId ?? ""
    }

    var creatorCalendarId: String {
        event?.creatorCalendarId ?? ""
    }

    var isRecurEvent: Bool {
        event?.isRecurEvent ?? false
    }
}
