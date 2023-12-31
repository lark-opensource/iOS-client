//
//  EventAttendeeListViewModel.swift
//  Calendar
//
//  Created by 张威 on 2020/4/6.
//

import RxSwift
import RxCocoa
import LKCommonsLogging
import CalendarFoundation
import UniverseDesignToast
import LarkContainer
import UIKit

/// 日程参与人列表
/// 支持展示 user、group、email 类型参与人

final class EventAttendeeListViewModel: UserResolverWrapper {

    let userResolver: UserResolver

    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var api: CalendarRustAPI?
    @ScopedInjectedLazy var mailContactService: MailContactService?

    typealias EventTuple = (calendarId: String, key: String, originalTime: Int64)

    static let EventGroupAttendeeMembersPageCount: Int32 = 100

    // 所有 cell 数据被更新的回调
    var onAllCellDataUpdate: (() -> Void)?
    // 某个 section 被更新的回调
    var onSectionDataUpdate: ((_ section: Int) -> Void)?

    // attendees 描述当前操作的参与人，可能由 EventAttendee、SimpleAttendee + DisplayInfo 构造。
    // 分页加载时拉 DisplayInfo 构造 EventEditAttendee，未加载的参与人不能编辑，不存入 attendees。
    internal private(set) var attendees = [EventEditAttendee]()
    // 描述编辑前的原日程参与人，删除参与人时，用于判断设置 removed 还是删除
    private let originalIndividualAttendees: [Rust.IndividualSimpleAttendee]
    // 描述编辑页添加的精简参与人
    private(set) var newSimpleAttendees: [Rust.IndividualSimpleAttendee]

    // 描述未显示的精简参与人，由 newSimpleAttendees + originalIndividualAttendees 去重得来
    private var hiddenSimpleAttendees: [Rust.IndividualSimpleAttendee] {
        let attendeeDeduplicatedKeys = Set(attendees.map { $0.deduplicatedKey })

        return Rust.IndividualSimpleAttendee.deduplicated(of: newSimpleAttendees + originalIndividualAttendees).filter({ simpleAttendee in
            // 与 event.attendee merge 去重
            !attendeeDeduplicatedKeys.contains(simpleAttendee.deduplicatedKey)
        })
    }
    // 描述参与人是否编辑了（删除、打散）
    internal private(set) var changed = false

    private let disposeBag = DisposeBag()
    // 整个参与人模块权限
    private let attendeesPermission: PermissionOption
    // 是否是 lark 日程
    let isLarkEvent: Bool
    // 当前用户的 tenantId
    private let currentTenantId: String
    // 当前用户的 calendarId
    let currentUserCalendarId: String
    // 组织者的 calendarId
    let organizerCalendarId: String
    // 创建者的 calendarId
    let creatorCalendarId: String
    private var sectionDataList = [SectionData]()
    private let isExternalUtil: (_ tenantId: String) -> Bool
    private var eventTuple: EventTuple?

    @ScopedInjectedLazy var pushService: RustPushService?

    // 仅编辑页使用，群打散时置灰「完成」button
    var rxEnableDoneBtn = BehaviorRelay(value: true)
    // 用于同时打散多个群的场景
    private var disableDoneBtnCount = 0

    private let rustAllAttendeeCount: Int

    // 仅详情页使用
    private(set) var isFromDetail = false
    var eventTitle: String?
    private(set) var isDirtyFromDetail = false
    private(set) var attendeeType: AttendeeType = .normal  // 区分普通参与人和 webinar 参与人
    private var groupSimpleMemberMap: [String: [Rust.IndividualSimpleAttendee]]?
    private var groupEncryptedMemberMap: [String: [Rust.EncryptedSimpleAttendee]]

    // 用于hud展示
    weak var viewController: UIViewController?

    // 分页拉取数据管理
    private var paginator: AttendeePaginatorImpl?
    let rxLoadingState = BehaviorRelay<LoadMoreState>(value: .initial)

    let rxToast = BehaviorRelay<String>(value: "")

    let originalGroupAttendee: [EventEditAttendee]
    var originalKeys: [String]
    let eventID: String
    let startTime: Int64
    let rrule: String
    var eventVersion: String?
    var aiGenerateAttendeeList: [String] = []
    // 参与人排序上下文
    private lazy var sortContext: AttendeeSortContext = {
        AttendeeSortContext(organizerCalendarId: organizerCalendarId,
                            creatorCalendarId: creatorCalendarId,
                            addedAtTail: !isFromDetail,
                            originalKeys: originalKeys)
    }()

    init(
        userResolver: UserResolver,
        attendees: [EventEditAttendee],
        originalGroupAttendee: [EventEditAttendee],
        originalIndividualAttendees: [Rust.IndividualSimpleAttendee],
        newSimpleAttendees: [Rust.IndividualSimpleAttendee],
        groupSimpleMemberMap: [String: [Rust.IndividualSimpleAttendee]],
        groupEncryptedMemberMap: [String: [Rust.EncryptedSimpleAttendee]],
        attendeesPermission: PermissionOption = .writable,
        isLarkEvent: Bool,
        currentTenantId: String,
        currentUserCalendarId: String,
        organizerCalendarId: String,
        creatorCalendarId: String,
        rustAllAttendeeCount: Int,
        eventTuple: EventTuple?,
        eventID: String,
        startTime: Int64,
        isFromDetail: Bool = false,
        rrule: String?,
        pageContext: PaginationContext,
        attendeeType: AttendeeType = .normal,
        aiGenerateAttendeeList: [String] = []
    ) {
        assert(attendeesPermission.isReadable)
        self.userResolver = userResolver
        self.attendeesPermission = attendeesPermission
        self.isLarkEvent = isLarkEvent
        self.newSimpleAttendees = newSimpleAttendees
        self.currentTenantId = currentTenantId
        let tenant = Tenant(currentTenantId: currentTenantId)
        self.isExternalUtil = {
            return tenant.isExternalTenant(tenantId: $0, isCrossTenant: false)
        }
        self.originalGroupAttendee = originalGroupAttendee
        self.groupSimpleMemberMap = groupSimpleMemberMap
        self.groupEncryptedMemberMap = groupEncryptedMemberMap
        self.currentUserCalendarId = currentUserCalendarId
        self.organizerCalendarId = organizerCalendarId
        self.creatorCalendarId = creatorCalendarId
        self.attendees = EventEditAttendee.deduplicated(of: attendees)
        self.rustAllAttendeeCount = rustAllAttendeeCount
        self.isFromDetail = isFromDetail
        self.attendeeType = attendeeType
        let groupMemberKeys: [String] = groupSimpleMemberMap.values.flatMap { attendees in
            attendees.map { $0.deduplicatedKey }
        }
        let individualAttendeeKeys = originalIndividualAttendees.map { $0.deduplicatedKey }
        let groupAttendeeKeys = originalGroupAttendee.map { $0.deduplicatedKey }

        originalKeys = individualAttendeeKeys + groupMemberKeys + groupAttendeeKeys
        self.eventID = eventID
        self.startTime = startTime
        self.eventTuple = eventTuple
        self.rrule = rrule ?? ""
        self.originalIndividualAttendees = originalIndividualAttendees
        self.aiGenerateAttendeeList = aiGenerateAttendeeList
        self.sectionDataList = produceSectionData(with: self.attendees)
        assert(attendees.count == self.attendees.count)

        switch pageContext {
        case .needPaginationWithPageOffset:
            // 精简参与人分页模式
            self.paginator = AttendeePaginatorImpl(
                userResolver: self.userResolver,
                initialPageIdentifier: .index,
                simpleAttendeeList: self.hiddenSimpleAttendees)
        case .needPagination(let token, let version):
            self.eventVersion = version
            if let eventTuple = eventTuple {
                self.paginator = AttendeePaginatorImpl(
                    userResolver: self.userResolver,
                    initialPageIdentifier: .token(token, eventTuple, version),
                    originalAttendeeList: attendees)
            }
        case .needWaitEventUpdate:
            self.paginator = AttendeePaginatorImpl(userResolver: self.userResolver, initialPageIdentifier: .waiting)
        case .noMore:
            break
        }

        if let (calendarId, key, originalTime) = eventTuple {
            registerActiceEventPush(calendarId: calendarId, key: key, originalTime: originalTime)
        }
        rxLoadingState.bind { [weak self] _ in
            guard let self = self else { return }
            self.onSectionDataUpdate?(self.sectionDataList.count - 1)
        }.disposed(by: self.disposeBag)
        bindRxMailContactPush()

        rxToast.subscribeForUI { [weak self] msg in
            guard !msg.isEmpty,
                  let self = self,
                  let controller = self.viewController  else { return }
            UDToast.showTips(with: msg, on: controller.view)
        }.disposed(by: disposeBag)

        checkAiGenerateStatus()
    }

    private func checkAiGenerateStatus() {
        if !aiGenerateAttendeeList.isEmpty {
            disableDoneBtn()
        }
    }

    private func registerActiceEventPush(calendarId: String, key: String, originalTime: Int64) {
        guard let pushService = self.pushService, let rustApi = self.api else { return }
        pushService.rxActiveEventChanged.filter { [weak self] events -> Bool in
            guard let self = self else { return false }
            if case let .waiting = self.paginator?.pageIdentifier {
                var event = Rust.ChangedActiveEvent()
                event.calendarID = calendarId
                event.key = key
                return events.contains(event)
            }
            return false
        }.map { _ in () }
        .subscribe(onNext: { [weak self] in
            guard let self = self else { return }

            rustApi.getEventPB(calendarId: calendarId,
                                key: key,
                                originalTime: originalTime)
            .flatMap({ event -> Observable<(CalendarEvent, [Rust.IndividualSimpleAttendee]?)> in
                let hasTotalAttendee = event.attendeeInfo.allIndividualAttendee
                if hasTotalAttendee {
                    return .just((event, nil))
                } else {
                    return rustApi.pullEventIndividualSimpleAttendeeList(calendarID: calendarId,
                                                                          key: key,
                                                                          originalTime: originalTime)
                    .map { response in
                        (event, response.attendees)
                    }
                }
            })
            .subscribe(onNext: { [weak self] (event, simpleAttendees) in
                guard let self = self,
                    !event.calendarEventDisplayInfo.isIndividualAttendeeSyncing else { return }
                // 进入分页模式
                self.attendees = EventEditAttendee.makeAttendees(from: event.attendees)
                let hasTotalAttendee = event.attendeeInfo.allIndividualAttendee
                if let simpleAttendees = simpleAttendees {
                    self.newSimpleAttendees = simpleAttendees
                    self.paginator = AttendeePaginatorImpl(
                        userResolver: self.userResolver,
                        initialPageIdentifier: .index,
                        simpleAttendeeList: self.hiddenSimpleAttendees)
                } else if !hasTotalAttendee {
                    let tuple = (calendarId: calendarId, key: key, originalTime: originalTime)
                    self.paginator = AttendeePaginatorImpl(
                        userResolver: self.userResolver,
                        initialPageIdentifier: .token(event.attendeeInfo.snapshotPageToken, tuple, self.eventVersion ?? ""),
                        originalAttendeeList: self.attendees)
                }

                self.onAllCellDataUpdate?()
            }).disposed(by: self.disposeBag)

        }).disposed(by: disposeBag)
    }

    // for event detail
    convenience init(
        userResolver: UserResolver,
        attendees: [EventEditAttendee],
        isLarkEvent: Bool,
        currentTenantId: String,
        currentUserCalendarId: String,
        organizerCalendarId: String,
        creatorCalendarId: String,
        eventTitle: String,
        rustAllAttendeeCount: Int,
        eventTuple: EventTuple?,
        eventID: String,
        startTime: Int64,
        rrule: String?,
        pageContext: PaginationContext,
        isDirtyFromDetail: Bool = false,
        attendeeType: AttendeeType = .normal
    ) {
        // originalIndividualAttendees 仅用于群打散和删除参与人，而详情页的权限为readable，不会涉及这些逻辑，设置为空即可
        // newSimpleAttendees 用户编辑页新增精简参与人，详情页不涉及
        // groupSimpleMemberMap 用户打散、展开群。详情页未提前加载可不传，内部会加载
        // groupEncryptedMemberMap 不具有参看权限的群成员，仅用来编辑页计算人数，详情页不涉及
        self.init(
            userResolver: userResolver,
            attendees: attendees,
            originalGroupAttendee: [],
            originalIndividualAttendees: [],
            newSimpleAttendees: [],
            groupSimpleMemberMap: [:],
            groupEncryptedMemberMap: [:],
            attendeesPermission: .readable,
            isLarkEvent: isLarkEvent,
            currentTenantId: currentTenantId,
            currentUserCalendarId: currentUserCalendarId,
            organizerCalendarId: organizerCalendarId,
            creatorCalendarId: creatorCalendarId,
            rustAllAttendeeCount: rustAllAttendeeCount,
            eventTuple: eventTuple,
            eventID: eventID,
            startTime: startTime,
            isFromDetail: true,
            rrule: rrule,
            pageContext: pageContext,
            attendeeType: attendeeType)
        self.eventTitle = eventTitle
        self.isDirtyFromDetail = isDirtyFromDetail
    }

    enum PaginationContext {
        case noMore
        case needWaitEventUpdate // SDK 脏 attendee 未同步完成，显示loading等待push刷新
        case needPagination(token: String, version: String)
        case needPaginationWithPageOffset
    }

    var inPaginationMode: Bool {
        return paginator != nil
    }
}

extension EventAttendeeListViewModel {

    private func attendeeMappedIndex(in section: Int) -> Int? {
        guard section >= 0 && section < sectionDataList.count else {
            return nil
        }
        let targetKey = sectionDataList[section].deduplicatedKey
        guard let mappedIndex = attendees.firstIndex(where: { $0.deduplicatedKey == targetKey }) else {
            return nil
        }
        return mappedIndex
    }

    private func removeItem(from attendees: inout [EventEditAttendee], at index: Int) {
        let item = attendees[index]
        let contains = originalIndividualAttendees.contains { attendee -> Bool in
            attendee.deduplicatedKey == item.deduplicatedKey
        } || originalGroupAttendee.contains { attendee -> Bool in
            attendee.deduplicatedKey == item.deduplicatedKey
        }

        if contains {
            switch item {
            case .user(var userAttendee):
                userAttendee.status = .removed
                attendees[index] = .user(userAttendee)
            case .group(var groupAttendee):
                groupAttendee.status = .removed
                attendees[index] = .group(groupAttendee)
            case .email(var emailAttendee):
                emailAttendee.status = .removed
                attendees[index] = .email(emailAttendee)
            case .local:
                assertionFailure()
                attendees.remove(at: index)
            }
        } else {
            attendees.remove(at: index)
        }
    }

    private func appendUserAttendees(_ items: [EventEditUserAttendee], to attendees: inout [EventEditAttendee]) {
        let items = items.filter { $0.status != .removed }
        guard !items.isEmpty else { return }
        let calendarIds = items.map { $0.calendarId }
        // 用于记录已经存在于 attendees 的 calendarIds
        var existsCalendarIds = Set<String>()
        // 用于标记已经存在但是被 removed 的 attendee
        var existsButRemoved: [Int] = []
        for i in 0 ..< attendees.count {
            guard case .user(let u) = attendees[i] else { continue }
            if calendarIds.contains(u.calendarId) {
                if u.status == .removed {
                    existsButRemoved.append(i)
                }
                existsCalendarIds.insert(u.calendarId)
            }
        }
        for i in existsButRemoved {
            guard case .user(var u) = attendees[i] else { continue }
            u.status = u.calendarId == currentUserCalendarId ? .accept : .needsAction
            u.permission = .writable
            attendees[i] = .user(u)
        }
        attendees.append(
            contentsOf: items
                .filter { !existsCalendarIds.contains($0.calendarId) }
                .map { user in
                    var user = user
                    user.permission = .writable
                    return .user(user)
                }
        )
    }

    func enterToChat(in section: Int, from: UIViewController) {
        if isFromDetail {
            CalendarTracerV2.EventDetail.traceClick {
                $0.click(CalendarTracer.EventClickType.enterGroupChat.value).target(CalendarTracer.EventClickType.enterGroupChat.target)
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.eventID, eventStartTime: self.startTime.description, isOrganizer: self.currentUserCalendarId == self.organizerCalendarId, isRecurrence: !self.rrule.isEmpty, originalTime: self.eventTuple?.originalTime.description, uid: eventTuple?.key))
            }
        } else {
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click(CalendarTracer.EventClickType.enterGroupChat.value).target(CalendarTracer.EventClickType.enterGroupChat.target)
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.eventID, eventStartTime: self.startTime.description, isOrganizer: self.currentUserCalendarId == self.organizerCalendarId, isRecurrence: !self.rrule.isEmpty, originalTime: self.eventTuple?.originalTime.description, uid: eventTuple?.key))
            }
        }

        guard let mappedIndex = attendeeMappedIndex(in: section) else {
            assertionFailure()
            return
        }

        if case .group(var group) = attendees[mappedIndex] {
            let chatId = group.chatId
            let isFromDetail = isFromDetail

            let onError = {
                UDToast().showFailure(with: BundleI18n.Calendar.Lark_Legacy_RecallMessage, on: from.view)
            }

            let onLeaveMeeting = {
                if isFromDetail {
                    from.navigationController?.popToRootViewController(animated: true)
                } else {
                    from.presentedViewController?.dismiss(animated: true)
                }
            }
            if isFromDetail {
                calendarDependency?.jumpToChatController(from: from,
                                                        chatID: chatId,
                                                        onError: onError,
                                                        onLeaveMeeting: onLeaveMeeting)
            } else {
                calendarDependency?.presentToChatController(from: from,
                                                           chatID: chatId,
                                                           style: .fullScreen,
                                                           onError: onError,
                                                           onLeaveMeeting: onLeaveMeeting)
            }
        }

    }

    // 群打散、群展开复用
    func getGroupSimpleAttendees(group: EventEditGroupAttendee) -> Observable<[Rust.IndividualSimpleAttendee]> {
        if !group.memberSeeds.isEmpty {
            // 先去群本身找，新增群、复制日程群走这个case
            return .just(group.memberSeeds)
        } else if let attendees = groupSimpleMemberMap?[group.chatId] {
            // 再去传入的 map 找，编辑页走这个 case
            return .just(attendees)
        } else {
            // 再直接拉取全部 group member id，详情页走这个 case
            guard let (calendarID, key, origianlTime) = eventTuple else {
                return .just([])
            }

            guard let rustApi = self.api else {
                EventEdit.logger.info("getGroupSimpleAttendees failed, can not get rust api from lark container")
                return .just([])
            }

            return rustApi.pullEventGroupsSimpleAttendeeList(calendarID: calendarID, key: key, originalTime: origianlTime)
                .do(onNext: { [weak self] response in
                    self?.groupSimpleMemberMap = response.groupMembers.mapValues { $0.attendees }
                }).map { response in
                    let map = response.groupMembers.mapValues { $0.attendees }
                    return map[group.chatId] ?? []
                }
        }
    }

    // 打散群成员
    func breakUpGroup(in section: Int) {
        CalendarTracerV2.EventAttendeeList.traceClick {
            $0.click("expand").target("none")
                .mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.eventID, eventStartTime: self.startTime.description, isOrganizer: self.currentUserCalendarId == self.organizerCalendarId, isRecurrence: !self.rrule.isEmpty, originalTime: self.eventTuple?.originalTime.description, uid: eventTuple?.key))
        }

        guard let mappedIndex = attendeeMappedIndex(in: section) else {
            assertionFailure()
            return
        }
        guard case .group(var group) = attendees[mappedIndex],
            enableBreakUpGroup(group) else {
            assertionFailure()
            return
        }

        guard let rustApi = self.api else {
            EventEdit.logger.info("break up group failed, can not get rust api from lark container")
            return
        }

        if !group.members.isEmpty,
           group.validMemberCount == group.members.count {
            // 确保具备所有完整群成员，才直接使用，否则走精简信息获取路径
            changed = true
            removeItem(from: &attendees, at: mappedIndex)

            let uids = group.memberSeeds.map { $0.user.chatterID }
            rustApi.checkCollaborationPermissionIgnoreError(uids: uids)
                .subscribe(onNext: { [weak self] blockedIDs in
                    guard let self = self else { return }

                    var hasBlocked = false
                    // 过滤 memberSeeds 中屏蔽自己的参与人，不删除，只改变状态
                    for (i, attendee) in group.memberSeeds.enumerated() {
                        if blockedIDs.contains(attendee.user.chatterID) {
                            var userAttendee = attendee
                            userAttendee.status = .removed
                            group.memberSeeds[i] = userAttendee
                            hasBlocked = true
                        }
                    }
                    // 过滤 members 中屏蔽自己的参与人，不删除，只改变状态
                    for (i, attendee) in group.members.enumerated() {
                        if blockedIDs.contains(attendee.chatterId) {
                            var userAttendee = attendee
                            userAttendee.status = .removed
                            group.members[i] = userAttendee
                            hasBlocked = true
                        }
                    }

                    EventEdit.logger.info("breakup group, blocked list count: \(blockedIDs.count), attends hasBlocked: \(hasBlocked)")
                    if hasBlocked {
                        self.rxToast.accept(I18n.Calendar_G_CreateEvent_AddUser_CantInvite_Hover)
                        CalendarTracerV2.ToastStatus.trace(commonParam: self.traceCommonParam) {
                            $0.toast_name = "unable_to_add_someone_to_event"
                        }
                    }

                    self.removeNewAttendee(with: group.visibleMembers().map { $0.deduplicatedKey })
                    self.appendUserAttendees(group.visibleMembers(), to: &self.attendees)
                    self.sectionDataList = self.produceSectionData(with: self.attendees, preLoadContactData: false)
                    self.onAllCellDataUpdate?()
                }).disposed(by: disposeBag)
            return
        }

        if case .group(let cellData, _) = sectionDataList[section], cellData.isLoading {
            return
        }

        // 开始loading
        sectionDataList[section] = convertToSectionData(fromGroup: group, withStatus: .collapsed, isLoading: true)
        disableDoneBtn()
        onSectionDataUpdate?(section)

        // 有入口就证明可以打散
        getGroupSimpleAttendees(group: group)
            .flatMap { seeds -> Observable<[Rust.IndividualSimpleAttendee]> in
                let uids = seeds.map { $0.user.chatterID }
                return rustApi.checkCollaborationPermissionIgnoreError(uids: uids)
                    .flatMap { [weak self] blockedIDs -> Observable<[Rust.IndividualSimpleAttendee]> in
                        guard let self = self else { return .just(seeds) }
                        // 过滤即将被打散的群中屏蔽自己的人
                        let newSeeds = blockedIDs.reduce(seeds) { (summary, newValue) in
                            summary.filter { $0.user.chatterID != newValue }
                        }
                        EventEdit.logger.info("breakup group, seed origin count: \(seeds.count), after filter blocked: \(newSeeds.count)")
                        if seeds.count > newSeeds.count {
                            self.rxToast.accept(I18n.Calendar_G_CreateEvent_AddUser_CantInvite_Hover)
                            CalendarTracerV2.ToastStatus.trace(commonParam: self.traceCommonParam) {
                                $0.toast_name = "unable_to_add_someone_to_event"
                            }
                        }
                        return Observable.just(newSeeds)
                    }
            }
            .flatMap { [weak self] seeds -> Observable<(attendees: [EventEditUserAttendee], seeds: [Rust.IndividualSimpleAttendee])> in
                guard let self = self else { return .empty() }

                // 为防止多个群打散顺序不一致，打散后按需拉数据。最少拉1个，填坑打散的群
                var needPullCount = AttendeePaginatorImpl.pageSize - self.attendees.count
                needPullCount = max(1, needPullCount)
                needPullCount = min(needPullCount, AttendeePaginatorImpl.pageSize)

                let requestAttendees = seeds.prefix(needPullCount)
                return rustApi.pullEventEditUserAttendee(with: requestAttendees).map {
                    let seeds = seeds.filter { !requestAttendees.contains($0) }
                    return ($0, seeds)
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (attendees, seeds) in
                guard let `self` = self else { return }
                if aiGenerateAttendeeList.isEmpty {
                    self.enableDoneBtn()
                }
                self.changed = true

                self.removeNewAttendee(with: attendees.map { $0.deduplicatedKey })
                self.removeItem(from: &self.attendees, at: mappedIndex)
                self.appendUserAttendees(attendees, to: &self.attendees)
                // 成功打散，loading的行会被直接删除
                self.sectionDataList = self.produceSectionData(with: self.attendees)
                self.newSimpleAttendees.append(contentsOf: seeds.filter { !self.newSimpleAttendees.contains($0) })
                if !seeds.isEmpty {
                   let paginator = self.paginator ?? AttendeePaginatorImpl(userResolver: self.userResolver, initialPageIdentifier: .index)
                    paginator.append(simpleAttendee: seeds)
                    paginator.loadNextPage()
                    self.paginator = paginator
                }

                self.onAllCellDataUpdate?()
            }, onError: { [weak self] (_) in
                guard let `self` = self else { return }
                if let controller = self.viewController {
                    UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Edit_FindTimeFailed, on: controller.view)
                }
                // 失败，不展开并结束loading
                self.sectionDataList[section] = self.convertToSectionData(fromGroup: group, withStatus: .collapsed, isLoading: false)
                self.onSectionDataUpdate?(section)
                if aiGenerateAttendeeList.isEmpty {
                    self.enableDoneBtn()
                }
            }).disposed(by: self.disposeBag)

        EventEdit.logger.info("break up group: \(group.chatId)")
    }

    // 新增参与人转为全量后需要移除，避免转为全量后删除状态不同步
    private func removeNewAttendee(with attendeeIds: [String]) {
        newSimpleAttendees = newSimpleAttendees.filter {
            !attendeeIds.contains($0.deduplicatedKey)
        }
    }

    private func enableDoneBtn() {
        disableDoneBtnCount -= 1
        if disableDoneBtnCount <= 0 {
            rxEnableDoneBtn.accept(true)
        }
    }

    private func disableDoneBtn() {
        rxEnableDoneBtn.accept(false)
        disableDoneBtnCount += 1
    }

    // 查看 invisible 群
    func seeInvisible(in section: Int) {
        guard let mappedIndex = attendeeMappedIndex(in: section) else {
            assertionFailure()
            return
        }
        guard case .group(let group) = attendees[mappedIndex],
            shouldHideMembers(ofGroup: group) else {
            assertionFailure()
            return
        }

        EventEdit.logger.info("see invisble group: \(group.chatId)")
    }

    // 删除参与人
    func deleteAttendee(in section: Int) {
        guard let mappedIndex = attendeeMappedIndex(in: section) else {
            assertionFailure()
            return
        }

        let attendee = attendees[mappedIndex]
        guard min(attendeesPermission, attendee.permission).isEditable else {
            assertionFailure()
            return
        }

        changed = true

        removeItem(from: &attendees, at: mappedIndex)
        sectionDataList = produceSectionData(with: attendees, preLoadContactData: false)
        onAllCellDataUpdate?()

        EventEdit.logger.info("delete attendee: \(attendee.uniqueId)")
   }

    // 展开群成员
    func expandGroup(in section: Int) {
        if isFromDetail {
            CalendarTracerV2.EventDetail.traceClick {
                $0.click(CalendarTracer.EventClickType.showGroupAttendeeList.value).target(CalendarTracer.EventClickType.showGroupAttendeeList.target)
                $0.status = CalendarTracer.EventDetailClickStatus.on.rawValue
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.eventID, eventStartTime: self.startTime.description, isOrganizer: self.currentUserCalendarId == self.organizerCalendarId, isRecurrence: !self.rrule.isEmpty, originalTime: self.eventTuple?.originalTime.description, uid: eventTuple?.key))
            }
        } else {
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click(CalendarTracer.EventClickType.showGroupAttendeeList.value).target(CalendarTracer.EventClickType.showGroupAttendeeList.target)
                $0.status = CalendarTracer.EventDetailClickStatus.on.rawValue
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.eventID, eventStartTime: self.startTime.description, isOrganizer: self.currentUserCalendarId == self.organizerCalendarId, isRecurrence: !self.rrule.isEmpty, originalTime: self.eventTuple?.originalTime.description, uid: eventTuple?.key))
            }
        }

        guard let mappedIndex = attendeeMappedIndex(in: section) else {
            assertionFailure()
            return
        }

        let attendee = attendees[mappedIndex]
        guard case .group(var group) = attendee else {
            assertionFailure()
            return
        }

        if !group.members.isEmpty {
            sectionDataList[section] = convertToSectionData(fromGroup: group, withStatus: .expanded)
            onSectionDataUpdate?(section)
            return
        }

        if case .group(let cellData, _) = sectionDataList[section], cellData.isLoading {
            return
        }

        // 开始loading
        sectionDataList[section] = convertToSectionData(fromGroup: group, withStatus: .collapsed, isLoading: true)
        onSectionDataUpdate?(section)

        guard let rustApi = self.api else {
            EventEdit.logger.info("expand group failed, can not get rust api from lark container")
            return
        }

        getGroupSimpleAttendees(group: group)
            .flatMap { [weak self] (seeds) -> Observable<(attendees: [EventEditUserAttendee], seeds: [Rust.IndividualSimpleAttendee])> in
                guard let `self` = self else { return .empty() }
                let pullCount = min(EventAttendeeListViewModel.EventGroupAttendeeMembersPageCount, group.memberShownLimit)
                let requestAttendees = seeds.prefix(Int(pullCount))
                return rustApi.pullEventEditUserAttendee(with: requestAttendees).map {
                    return ($0, seeds)
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (attendees, seeds) in
                guard let `self` = self else { return }
                guard section < self.sectionDataList.count else { return }
                group.memberSeeds = seeds // 展开后保留所有 seeds，参与人三级页去重
                group.members = attendees
                group.hasMoreMembers = seeds.count > attendees.count
                self.attendees[mappedIndex] = .group(group)

                // 展开并结束loading
                self.sectionDataList[section] = self.convertToSectionData(fromGroup: group,
                                                                          withStatus: .expanded,
                                                                          isLoading: false)
                self.onSectionDataUpdate?(section)
            }, onError: { [weak self] (_) in
                guard let `self` = self else { return }
                guard section < self.sectionDataList.count else { return }
                if let controller = self.viewController {
                    UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Edit_FindTimeFailed, on: controller.view)
                }
                // 失败，不展开并结束loading
                self.sectionDataList[section] = self.convertToSectionData(fromGroup: group, withStatus: .collapsed, isLoading: false)
                self.onSectionDataUpdate?(section)
            }).disposed(by: self.disposeBag)

        EventEdit.logger.info("expand group: \(attendee.uniqueId)")
    }

    // 收拢群成员
    func collapseGroup(in section: Int) {
        if isFromDetail {
            CalendarTracerV2.EventDetail.traceClick {
                $0.click(CalendarTracer.EventClickType.showGroupAttendeeList.value).target(CalendarTracer.EventClickType.showGroupAttendeeList.target)
                $0.status = CalendarTracer.EventDetailClickStatus.off.rawValue
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.eventID, eventStartTime: self.startTime.description, isOrganizer: self.currentUserCalendarId == self.organizerCalendarId, isRecurrence: !self.rrule.isEmpty, originalTime: self.eventTuple?.originalTime.description, uid: eventTuple?.key))
            }
        } else {
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click(CalendarTracer.EventClickType.showGroupAttendeeList.value).target(CalendarTracer.EventClickType.showGroupAttendeeList.target)
                $0.status = CalendarTracer.EventDetailClickStatus.off.rawValue
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.eventID, eventStartTime: self.startTime.description, isOrganizer: self.currentUserCalendarId == self.organizerCalendarId, isRecurrence: !self.rrule.isEmpty, originalTime: self.eventTuple?.originalTime.description, uid: eventTuple?.key))
            }
        }

        guard let mappedIndex = attendeeMappedIndex(in: section) else {
            assertionFailure()
            return
        }

        let attendee = attendees[mappedIndex]
        guard case .group(let group) = attendee else {
            assertionFailure()
            return
        }
        sectionDataList[section] = convertToSectionData(fromGroup: group, withStatus: .collapsed)
        onSectionDataUpdate?(section)

        EventEdit.logger.info("collapse group: \(attendee.uniqueId)")
    }

    func numberOfSections() -> Int {
        return sectionDataList.count + (inPaginationMode ? 1 : 0)
    }

    func groupAttendee(at section: Int) -> EventEditGroupAttendee? {
        guard let mappedIndex = attendeeMappedIndex(in: section),
              case .group(let group) = attendees[mappedIndex] else {
            assertionFailure()
            return nil
        }
        return group
    }

    func groupCellHeaderTitle(at section: Int) -> String? {
        guard section >= 0 && section < sectionDataList.count else {
            assertionFailure()
            return nil
        }

        guard case .group(let header, _) = sectionDataList[section] else {
            return nil
        }

        return header.title
    }

    func numberOfRows(inSection section: Int) -> Int {

        if inPaginationMode && section == sectionDataList.count {
            // loading section
            return 1
        }

        guard section >= 0 && section < sectionDataList.count else {
            return 0
        }

        switch sectionDataList[section] {
        case .nonGroup: return 1
        case .group(_, let members): return 1 + members.count
        }
    }

    func cellData(at indexPath: IndexPath) -> CellData? {

        if inPaginationMode && sectionDataList.count == indexPath.section {
            // loading section
            return .loadMore(LoadMoreCellData(state: rxLoadingState.value))
        }

        let (section, index) = (indexPath.section, indexPath.row)
        guard section >= 0 && section < sectionDataList.count else {
            assertionFailure()
            return nil
        }
        let sectionData = sectionDataList[section]
        if index == 0 {
            switch sectionData {
            case .nonGroup(let justOne): return .nonGroup(justOne)
            case .group(let header, _): return .groupHeader(header)
            }
        }
        guard index > 0, case .group(_, let members) = sectionData else {
            assertionFailure()
            return nil
        }
        return .groupMember(members[index - 1])
    }

    func calendarId(at indexPath: IndexPath) -> String? {
        let (section, index) = (indexPath.section, indexPath.row)
        guard section >= 0 && section < sectionDataList.count else {
            assertionFailure()
            return nil
        }
        let sectionData = sectionDataList[section]
        if index == 0 {
            switch sectionData {
            case .nonGroup(let justOne): return justOne.calendarId
            case .group: return nil
            }
        }
        guard index > 0, case .group(_, let members) = sectionData else {
            assertionFailure()
            return nil
        }
        return members[index - 1].calendarId
    }

    func footerTypeForSection(_ section: Int) -> GroupAttendeeCellFooterType? {

        if inPaginationMode && section == sectionDataList.count {
            return nil
        }

        guard let mappedIndex = attendeeMappedIndex(in: section) else {
            assertionFailure()
            return nil
        }

        guard case .group(let groupAttendee) = attendees[mappedIndex],
              case .group(let groupHeader, _) = sectionDataList[section],
              groupHeader.status == .expanded,
              let hasMoreMembers = groupHeader.hasMoreMembers else {
            return nil
        }

        if groupAttendee.openSecurity {
            return .security
        }

        if hasMoreMembers {
            return .more
        }

        return nil
    }
}

enum GroupAttendeeCellFooterType {
    case security
    case more
}

// MARK: Util

extension EventAttendeeListViewModel {

    private func shouldHideMembers(ofGroup group: EventEditGroupAttendee) -> Bool {
        return !group.isSelfInGroup
    }

    private func enableBreakUpGroup(_ group: EventEditGroupAttendee) -> Bool {
        return !group.isCrossTenant
            && !shouldHideMembers(ofGroup: group)
            && min(group.permission, attendeesPermission).isEditable
            && !(group.openSecurity && group.validMemberCount > group.memberShownLimit)
    }

}

// MARK: Header Title

extension EventAttendeeListViewModel {

    func headerTitle() -> String {
        // 本地日程不参与以下逻辑，优先级最高
        if hasLocalAttendee() {
            let count = EventEditAttendee.allBreakedUpAttendeeCount(of: attendees)
            return BundleI18n.Calendar.Calendar_Plural_AttendeeNumAfter(number: count)
        }
        // 详情页，如果是dirty的日程，不显示人数
        if isDirtyFromDetail {
            return BundleI18n.Calendar.Calendar_Common_Guests
        }

        func titleWithCount(_ count: Int) -> String {
            switch attendeeType {
            case .normal:
                return BundleI18n.Calendar.Calendar_Plural_AttendeeNumAfter(number: count)
            case .webinar(let webinarAttendeeType):
                if case .speaker = webinarAttendeeType {
                    return BundleI18n.Calendar.Calendar_G_PanelistNum(number: count)
                } else {
                    return BundleI18n.Calendar.Calendar_G_AttendeeNum(number: count)
                }
            }
        }
        // 详情页无法删除成员，所以人数不需要更新，一直用传进来的值就可以
        if isFromDetail || attendeesPermission == .readable {
            return titleWithCount(self.rustAllAttendeeCount)
        }

        let simpeAttendees = Rust.IndividualSimpleAttendee.deduplicated(of: newSimpleAttendees + originalIndividualAttendees)
        let count = EventEditAttendee.allBreakedUpAttendeeCount(of: attendees, individualSimpleAttendees: simpeAttendees)
        return titleWithCount(count)
    }

    private func hasLocalAttendee() -> Bool {
        return attendees.contains(where: { (item) -> Bool in
            if case .local = item { return true }
            return false
        })
    }

}

// MARK: Cell Data

extension EventAttendeeListViewModel {

    enum CellData {
        case nonGroup(EventNonGroupEditCellDataType)
        case groupHeader(EventGroupEditCellDataType)
        case groupMember(EventNonGroupEditCellDataType)
        case loadMore(EventAttendeeListLoadMoreCellDataType)
    }

    private enum SectionData {
        case group(header: GroupCellData, members: [NonGroupCellData])
        case nonGroup(justOne: NonGroupCellData)

        var deduplicatedKey: String {
            switch self {
            case .group(let header, _): return header.key
            case .nonGroup(let justOne): return justOne.key
            }
        }
    }

    struct NonGroupCellData: EventNonGroupEditCellDataType, Avatar {
        var key: String = ""
        var status: AttendeeStatus = .needsAction
        var name: String = ""
        var subTitle: String?
        var underGroup: Bool = false
        var externalTag: String?
        var isOptional: Bool = false
        var canDelete: Bool = false
        var avatarKey: String = ""
        var identifier: String
        var userName: String { name }
        var avatar: Avatar { self }
        var calendarId: String?
        var shouldShowAIStyle: Bool = false
    }

    private struct GroupCellData: EventGroupEditCellDataType, Avatar {
        var key: String = ""
        var title: String = ""
        var subtitle: String?
        var status: EventGroupEditViewStatus
        var relationTagStr: String?
        var canBreakUp: Bool = false
        var canDelete: Bool = false
        var avatarKey: String = ""
        var identifier: String
        var userName: String = ""
        var avatar: Avatar { self }
        var isLoading: Bool = false
        var hasMoreMembers: Bool?
        var shouldShowAIStyle: Bool = false
    }

    private struct LoadMoreCellData: EventAttendeeListLoadMoreCellDataType {
        var loadMoreViewData: LoadMoreViewDataType

        init(state: LoadMoreState) {
            loadMoreViewData = LoadMoreViewData(state: state)
        }
    }

    private struct LoadMoreViewData: LoadMoreViewDataType {
        var state: LoadMoreState
    }

    private func convertToCellData(fromUser user: EventEditUserAttendee, underGroup: Bool) -> NonGroupCellData {
        var cellData = NonGroupCellData(identifier: user.avatar.identifier)
        cellData.key = EventEditAttendee.user(user).deduplicatedKey
        cellData.status = user.status
        cellData.name = user.name
        cellData.underGroup = underGroup
        cellData.externalTag = user.relationTagStr.isEmpty ? nil : user.relationTagStr
        cellData.isOptional = user.isOptional
        cellData.canDelete = !underGroup && min(user.permission, attendeesPermission).isEditable
        cellData.avatarKey = user.avatar.avatarKey
        cellData.calendarId = user.calendarId
        cellData.shouldShowAIStyle = aiGenerateAttendeeList.contains(user.chatterId)
        return cellData
    }

    private func convertToSectionData(fromUser user: EventEditUserAttendee) -> SectionData {
        return .nonGroup(justOne: convertToCellData(fromUser: user, underGroup: false))
    }

    private func convertToCellData(fromEmail email: EventEditEmailAttendee) -> NonGroupCellData {
        var email = email
        email.mailContactService = mailContactService
        var cellData = NonGroupCellData(identifier: email.avatar.identifier)
        cellData.key = EventEditAttendee.email(email).deduplicatedKey
        cellData.status = email.status
        cellData.name = !email.displayName.isEmpty ? email.displayName : email.address
        cellData.underGroup = false
        if let tag = email.type.emailTag {
            cellData.externalTag = isLarkEvent ? tag : nil
        }
        cellData.isOptional = false
        cellData.canDelete = min(email.permission, attendeesPermission).isEditable
        cellData.avatarKey = email.avatar.avatarKey

        // 从 MailContactService 获取邮箱解析数据
        if email.canParsed {
            cellData.subTitle = email.address
            cellData.calendarId = email.toProfileCalendarId
            cellData.externalTag = email.relationTagStr
        }
        return cellData
    }

    private func convertToCellData(fromLocal local: EventEditLocalAttendee) -> NonGroupCellData {
        var cellData = NonGroupCellData(identifier: "")
        cellData.key = EventEditAttendee.local(local).deduplicatedKey
        cellData.status = local.status
        cellData.name = local.name
        cellData.underGroup = false
        cellData.externalTag = nil
        cellData.isOptional = false
        cellData.canDelete = min(local.permission, attendeesPermission).isEditable
        return cellData
    }

    private func convertToSectionData(fromEmail email: EventEditEmailAttendee) -> SectionData {
        return .nonGroup(justOne: convertToCellData(fromEmail: email))
    }

    private func convertToSectionData(fromLocal local: EventEditLocalAttendee) -> SectionData {
        return .nonGroup(justOne: convertToCellData(fromLocal: local))
    }

    private func convertToSectionData(
        fromGroup group: EventEditGroupAttendee,
        withStatus status: EventGroupEditViewStatus,
        isLoading: Bool? = nil
    ) -> SectionData {
        var cellData = GroupCellData(status: status, identifier: group.avatar.identifier)
        cellData.key = EventEditAttendee.group(group).deduplicatedKey
        cellData.title = group.name
        if status != .invisible {
            if group.isUserCountVisible {
                cellData.title.append("(\(group.validMemberCount))")
            }
        }
        if group.isAnyRemoved && group.isSelfInGroup {
            cellData.subtitle = BundleI18n.Calendar.Calendar_Meeting_PartOfMemLeftTip
        } else {
            cellData.subtitle = nil
        }
        cellData.relationTagStr = group.relationTagStr.isEmpty ? nil : group.relationTagStr
        cellData.canBreakUp = enableBreakUpGroup(group)
        cellData.canDelete = min(group.permission, attendeesPermission).isEditable
        cellData.avatarKey = group.avatar.avatarKey
        cellData.userName = group.avatar.userName
        cellData.shouldShowAIStyle = !aiGenerateAttendeeList.isEmpty
        if let isLoading = isLoading {
            cellData.isLoading = isLoading
        }
        if let hasMoreMembers = group.hasMoreMembers {
            cellData.hasMoreMembers = hasMoreMembers
        }
        let members: [NonGroupCellData]

        if status == .expanded {
            var maxLength = group.memberShownLimit > 0 ? Int(group.memberShownLimit) : group.members.count
            maxLength = min(Int(EventAttendeeListViewModel.EventGroupAttendeeMembersPageCount), maxLength)
            let groupMembers = group.members.prefix(maxLength).sorted {
                EventEditAttendee.userAttendeeCompare($0, $1, context: sortContext) != .orderedDescending
            }
            members = groupMembers.map {
                convertToCellData(fromUser: $0, underGroup: true)
            }
        } else {
            members = []
        }
        return .group(header: cellData, members: members)
    }

    // 加工处理：剔除 invisible；排序
    private func produceSectionData(with attendees: [EventEditAttendee], needSort: Bool = true, preLoadContactData: Bool = true) -> [SectionData] {
        let visibleAttendees = EventEditAttendee.visibleAttendees(of: attendees)
        let rawAttendees = needSort ? visibleAttendees.sortedWith(context: sortContext) : visibleAttendees

        if preLoadContactData {
            preLoadMailContactData(rawAttendees.compactMap({ attendee in
                switch attendee {
                case .email(let mailAttendee):
                    return mailAttendee.address
                default: return nil
                }
            }))
        }

        return rawAttendees
            .map { attendee -> EventEditAttendee in
                guard
                    case .group(var groupAttendee) = attendee else {
                    return attendee
                }
                let groupMembers = groupAttendee.members.sorted {
                    EventEditAttendee.userAttendeeCompare($0, $1, context: sortContext) != .orderedDescending
                }
                groupAttendee.members = groupMembers
                return .group(groupAttendee)
            }
            .map { attendee -> SectionData in
                switch attendee {
                case .user(let user):
                    return convertToSectionData(fromUser: user)
                case .email(let email):
                    return convertToSectionData(fromEmail: email)
                case .local(let local):
                    return convertToSectionData(fromLocal: local)
                case .group(let group):
                    return convertToSectionData(
                        fromGroup: group,
                        withStatus: shouldHideMembers(ofGroup: group) ? .invisible : .collapsed
                    )
                }
            }
    }

}

// MARK: - Mail Contact
extension EventAttendeeListViewModel {
    private func preLoadMailContactData(_ mails: [String]) {
        let fixMails = isLarkEvent ? mails : Array(mails.prefix(200))
        mailContactService?.loadMailContact(mails: fixMails)
    }

    private func bindRxMailContactPush() {
        mailContactService?.rxDataChanged
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.sectionDataList = self.produceSectionData(with: self.attendees, preLoadContactData: false)
                self.onAllCellDataUpdate?()
            }).disposed(by: disposeBag)
    }
}

// MARK: - Action

extension EventAttendeeListViewModel {

    func triggerLoadMoreCell() {
        switch rxLoadingState.value {
        case .initial:
            switch attendeeType {
            case .normal:
                loadNextPage()
            case .webinar(let webinarAttendeeType):
                loadWebinarNextPage(webinarAttendeeType: webinarAttendeeType)
            }
        default: break
        }
    }

    private func loadNextPage() {
        self.rxLoadingState.accept(.loading)
        self.paginator?.loadNextPage()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] result in
                guard let self = self else { return }
                self.attendees += result.attendees
                self.removeNewAttendee(with: result.attendees.map { $0.deduplicatedKey })

                // 分页加载的参与人不参与排序
                self.sectionDataList += self.produceSectionData(with: result.attendees, needSort: false)
                self.onAllCellDataUpdate?()
                self.rxLoadingState.accept(result.hasMore ? .initial : .noMore)
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            EventEdit.logger.error("load next page error: \(error)")
            self.rxLoadingState.accept(.failed(self.loadNextPage))
        }).disposed(by: disposeBag)
    }

    private func loadWebinarNextPage(webinarAttendeeType: WebinarAttendeeType) {
        self.rxLoadingState.accept(.loading)
        self.paginator?.loadWebinarAttendeeNextPage(serverID: self.eventID, webinarAttendeeType: webinarAttendeeType)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] result in
                guard let self = self else { return }
                self.attendees += result.attendees
                self.removeNewAttendee(with: result.attendees.map { $0.deduplicatedKey })

                // 分页加载的参与人不参与排序
                self.sectionDataList += self.produceSectionData(with: result.attendees, needSort: false)
                self.onAllCellDataUpdate?()
                self.rxLoadingState.accept(result.hasMore && !result.attendees.isEmpty ? .initial : .noMore)
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            EventEdit.logger.error("load next page error: \(error)")
            self.rxLoadingState.accept(.failed(self.loadNextPage))
        }).disposed(by: disposeBag)
    }

    private func deduplicatedOnCurrent(with attendees: [EventEditAttendee]) -> [EventEditAttendee] {
        let currentKeys = self.attendees.map { $0.deduplicatedKey }
        return attendees.filter { !currentKeys.contains($0.deduplicatedKey) }
    }
}

extension EmailContactType {
    var emailTag: String? {
        switch self {
        case .normalMail: return I18n.Calendar_Detail_External
        case .publicMail: return I18n.Calendar_EmailEvent_PublicMailbox
        case .mailGroup: return I18n.Calendar_EmailEvent_MailingList
        case .mailContact: return I18n.Calendar_EmailEvent_EmailContact
        case .unknown: return nil
        @unknown default: return nil
        }
    }
}

// MARK: - API
extension CalendarRustAPI {
    func pullEventEditUserAttendee(with simpleAttendees: ArraySlice<Rust.IndividualSimpleAttendee>) -> Observable<[EventEditUserAttendee]> {
        guard !simpleAttendees.isEmpty else { return .just([]) }
        let chatterIds: [String] = simpleAttendees.map { $0.user.chatterID }

        return self.pullAttendeeDisplayInfoList(chatterIds: chatterIds, chatIds: [])
            .map { attendeeDisplayInfos -> [EventEditUserAttendee] in
                let attendees: [EventEditAttendee] = simpleAttendees.compactMap { attendee in
                    switch attendee.category {
                    case .user:
                        if let displayInfo = attendeeDisplayInfos.first(where: {
                            return attendee.user.chatterID == $0.user.chatterID
                        }) {
                            return EventEditAttendee.makeAttenee(from: attendee, displayInfo: displayInfo)
                        } else {
                            return nil
                        }
                    @unknown default:
                        return nil
                    }
                }

                return attendees.compactMap { attendee in
                    if case .user(let userAttendee) = attendee {
                        return userAttendee
                    }
                    return nil
                }
            }
    }

    func pullEventEditAttendee(with simpleAttendees: ArraySlice<Rust.IndividualSimpleAttendee>) -> Observable<[EventEditAttendee]> {
        guard !simpleAttendees.isEmpty else { return .just([]) }
        let chatterIds: [String] = simpleAttendees.filter { $0.category == .user }.map { $0.user.chatterID }

        let thirdPartyAttendees = simpleAttendees.filter { $0.category == .thirdPartyUser }.compactMap { EventEditAttendee.makeAttenee(from: $0, displayInfo: nil) }

        return self.pullAttendeeDisplayInfoList(chatterIds: chatterIds, chatIds: [])
            .map { attendeeDisplayInfos -> [EventEditAttendee] in
                let attendees: [EventEditAttendee] = simpleAttendees.compactMap { attendee in
                    switch attendee.category {
                    case .user:
                        if let displayInfo = attendeeDisplayInfos.first(where: {
                            return attendee.user.chatterID == $0.user.chatterID
                        }) {
                            return EventEditAttendee.makeAttenee(from: attendee, displayInfo: displayInfo)
                        } else {
                            return nil
                        }
                    @unknown default:
                        return nil
                    }
                } + thirdPartyAttendees

                return attendees + thirdPartyAttendees
            }
    }
}

enum AttendeeType {
    case normal
    case webinar(WebinarAttendeeType)
}

extension EventAttendeeListViewModel {
    func getEventTuple() -> (originalTime: Int64?, key: String?) {
        return (eventTuple?.originalTime, eventTuple?.key)
    }
}

extension EventAttendeeListViewModel {
    var traceCommonParam: CommonParamData {
        return CommonParamData(calEventId: self.eventID,
                               eventStartTime: String(self.startTime),
                               isOrganizer: self.organizerCalendarId == self.currentUserCalendarId,
                               isRecurrence: !self.rrule.isEmpty,
                               originalTime: String(self.eventTuple?.originalTime ?? 0),
                               uid: eventTuple?.key)
    }
}
