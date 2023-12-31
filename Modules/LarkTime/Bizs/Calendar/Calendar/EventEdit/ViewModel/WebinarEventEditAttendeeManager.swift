//
//  WebinarEventEditAttendeeManager.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/16.
//

import Foundation
import RxCocoa
import RxSwift
import RustPB
import LarkContainer

typealias WebinarAttendee = (speaker: [EventEditAttendee], audience: [EventEditAttendee], changeType: WebinarEventEditAttendeeManager.WebinarAttendeeChangeType)

// WebinarAttendee - 嘉宾、观众上下文环境
class WebinarAttendeeContext {
    var type: WebinarAttendeeType
    // 日程完整参与人，包括 status == removed 的参与人
    var rxAttendees = BehaviorRelay(value: [EventEditAttendee]())
    // 日程新添加的精简参与人，出现在大群打散的时候
    var rxNewSimpleAttendees = BehaviorRelay(value: [Rust.IndividualSimpleAttendee]())
    let rxAttendeeData = BehaviorRelay(value: AttendeeData([], 0))
    let rxLoading = BehaviorRelay(value: false)
    var rustAllAttendeeCount: Int?
    var haveAllIndividualAttendee = false
    var haveAllGroupMember = false
    var rxOriginalIndividualimpleAttendees = BehaviorRelay(value: [Rust.IndividualSimpleAttendee]())
    // 大量参与人日程下 非全量参与人逻辑
    let rxPullAllAttendeeStatus = BehaviorRelay<PullAllAttendeeStatus>(value: .initialize)

    var haveAllAttendee: Bool {
        haveAllIndividualAttendee && haveAllGroupMember
    }
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

    let addAttendees = (queue: DispatchQueue(label: "lark.calendar.event_edit.add_attendee"),
                        lock: DispatchSemaphore(value: 1))

    init(type: WebinarAttendeeType) {
        self.type = type
    }

    // 重置参与人
    func resetAttedees(attendees: [EventEditAttendee],
                       simpleAttendees: [Rust.IndividualSimpleAttendee]) {
        if self.rxLoading.value {
            self.rxLoading.accept(false)
        }
        self.rxAttendees.accept(attendees)
        self.rxNewSimpleAttendees.accept(simpleAttendees)
    }

    func appendGroupsSimpleMembers(groupsSimpleMembers: [String: [Rust.IndividualSimpleAttendee]],
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


class WebinarEventEditAttendeeManager: EventEditModelManager<WebinarAttendee> {

    @ScopedInjectedLazy var api: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    enum WebinarAttendeeChangeType {
        case all
        case speaker
        case audience
    }

    var rxAttendee: BehaviorRelay<WebinarAttendee> = .init(value: ([], [], .all))

    // 嘉宾
    private(set) var speakerContext = WebinarAttendeeContext(type: .speaker)

    // 观众
    private(set) var audienceContext = WebinarAttendeeContext(type: .audience)

    // All attendee view data (嘉宾 + 观众)
    let rxAllAttendeeData = BehaviorRelay(value: AttendeeData([], 0))

    private let input: EventEditInput
    private let disposeBag = DisposeBag()

    var calendar: EventEditCalendar?
    // 是否被大人数日程管控，默认true，管控状态
    var attendeeMaxCountControlled: Bool = true
    // 群参与人过滤掉的群成员（高管）
    private(set) var rejectedGroupUserMap: [String: [Int64]] = [:]
    private(set) var groupSimpleMembers: [String: [Rust.IndividualSimpleAttendee]] = [:]
    private(set) var groupEncryptedMembers: [String: [Rust.EncryptedSimpleAttendee]] = [:]
    private(set) var extraGroupMember: [Rust.IndividualSimpleAttendee] = []

    weak var eventDelegate: EventEditModelGetterProtocol?

    init(identifier: String, input: EventEditInput, userResolver: UserResolver) {
        self.input = input
        super.init(userResolver: userResolver, identifier: identifier, rxModel: rxAttendee)
    }

    func startInit(with calendar: EventEditCalendar?) {
        self.calendar = calendar
        bindRxAttendee()
        bindRxAttendeeData()

        switch input {
        case .createWebinar:
            // 嘉宾
            self.speakerContext.haveAllIndividualAttendee = true
            self.speakerContext.haveAllGroupMember = true
            self.speakerContext.rxPullAllAttendeeStatus.accept(.success)
            // 观众
            self.audienceContext.haveAllIndividualAttendee = true
            self.audienceContext.haveAllGroupMember = true
            self.audienceContext.rxPullAllAttendeeStatus.accept(.success)
        case .editWebinar(let pbEvent, let pbInstance):
            // 嘉宾
            let speakerWebinarInfo = pbEvent.webinarInfo.speakers
            setupAttendeeContext(webinarInfo: speakerWebinarInfo, attendeeContext: speakerContext, pbEvent: pbEvent)
            loadAllAttendeeIfNeeded(with: speakerContext)
            // 观众
            let audienceWebinarInfo = pbEvent.webinarInfo.audiences
            setupAttendeeContext(webinarInfo: audienceWebinarInfo, attendeeContext: audienceContext, pbEvent: pbEvent)
            loadAllAttendeeIfNeeded(with: audienceContext)
            self.pullGroupsSimpleMembers(with: pbEvent)
        default:
            assertionFailure("cannot run here")
        }
    }

    private func bindRxAttendeeData() {
        bindRxAttendeeData(context: speakerContext)
        bindRxAttendeeData(context: audienceContext)

        Observable.combineLatest(speakerContext.rxAttendeeData, audienceContext.rxAttendeeData)
            .map { (speaker, audience) -> AttendeeData in
                return (speaker.visibleAttendees + audience.visibleAttendees, speaker.breakUpAttendeeCount + audience.breakUpAttendeeCount)
            }
            .bind(to: rxAllAttendeeData)
            .disposed(by: disposeBag)
    }

    private func bindRxAttendee() {
        let rxSpeaker = speakerContext.rxAttendees
        let rxAudience = audienceContext.rxAttendees
        Observable.combineLatest(rxSpeaker, rxAudience)
            .subscribe(onNext: { [weak self] (speaker, audience) in
                guard let self = self else { return }
                let speakerChanged = speaker.description != self.rxAttendee.value.speaker.description
                let audienceChanged = audience.description != self.rxAttendee.value.audience.description
                let changeType: WebinarAttendeeChangeType
                if speakerChanged && audienceChanged {
                    changeType = .all
                } else {
                    changeType = speakerChanged ? .speaker : .audience
                }
                self.rxAttendee.accept((speaker, audience, changeType))
            }).disposed(by: disposeBag)
    }

    private func bindRxAttendeeData(context: WebinarAttendeeContext) {
        let map = { [weak self] (attendees: [EventEditAttendee],
                                 newSimpleAttendees: [Rust.IndividualSimpleAttendee],
                                 originalIndividualSimpleAttendees: [Rust.IndividualSimpleAttendee]) -> AttendeeData in
            guard let self = self else { return AttendeeData([], 0) }
            var attendees = attendees
            var breakUpAttendeeCount: Int
            let simpleAttendee = Rust.IndividualSimpleAttendee.deduplicated(of: newSimpleAttendees + originalIndividualSimpleAttendees)

            if context.haveAllAttendee {
                breakUpAttendeeCount = EventEditAttendee
                    .allBreakedUpAttendeeCount(of: attendees,
                                               individualSimpleAttendees: simpleAttendee)
            } else {
                breakUpAttendeeCount = context.rustAllAttendeeCount ?? 0
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
            context.rxAttendees,
            context.rxNewSimpleAttendees,
            context.rxOriginalIndividualimpleAttendees
        )
        .observeOn(MainScheduler.instance)
        .map(map)
        .bind(to: context.rxAttendeeData)
        .disposed(by: disposeBag)
    }

    private func setupAttendeeContext(webinarInfo: Calendar_V1_CalendarEventWebinarAttendeeInfo, attendeeContext: WebinarAttendeeContext, pbEvent: Rust.Event) {
        var attendees = EventEditAttendee.makeAttendees(from: webinarInfo.attendees)
        attendeeContext.rxAttendees.accept(EventEditAttendee.deduplicated(of: attendees))
        attendeeContext.rustAllAttendeeCount = Int(webinarInfo.eventAttendeeInfo.totalNo)
        attendeeContext.haveAllIndividualAttendee = webinarInfo.eventAttendeeInfo.allIndividualAttendee
        if pbEvent.guestCanInvite && webinarInfo.attendees.contains(where: { $0.category == .group }) {
            attendeeContext.haveAllGroupMember = false
        } else {
            attendeeContext.haveAllGroupMember = true
        }

        let simpleAttendees = webinarInfo.attendees
            .filter { $0.category == .user || $0.category == .thirdPartyUser }
            .map { $0.toIndividualSimpleAttendee() }
        attendeeContext.rxOriginalIndividualimpleAttendees.accept(simpleAttendees)
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
            self.speakerContext.haveAllGroupMember = true
            self.audienceContext.haveAllGroupMember = true
            self.speakerContext.appendGroupsSimpleMembers(groupsSimpleMembers: self.groupSimpleMembers,
                                           encrpytedSimpleMembers: self.groupEncryptedMembers)
            self.audienceContext.appendGroupsSimpleMembers(groupsSimpleMembers: self.groupSimpleMembers,
                                                      encrpytedSimpleMembers: self.groupEncryptedMembers)
            var groupLimitInfo: [String: Int] = [:]
            (event.webinarInfo.speakers.attendees + event.webinarInfo.audiences.attendees).filter { $0.category == .group }.forEach { attendee in
                if attendee.group.openSecurity {
                    groupLimitInfo[attendee.group.groupID] = Int(attendee.group.showMemberLimit)
                }
            }

            self.pullUserAttendeeDisplayInfo(groupsSimpleMembers: response.groupMembers.mapValues { $0.attendees },
                                             groupLimitInfo: groupLimitInfo)

        }).disposed(by: self.disposeBag)
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
                    let transform = { (attendee: EventEditAttendee) -> EventEditAttendee in
                        if case .group(var groupAttendee) = attendee, groupAttendee.chatId == chatID {
                            groupAttendee.members = attendees
                            groupAttendee.hasMoreMembers = simpleAttendees.count > groupAttendee.members.count

                            return .group(groupAttendee)
                        }
                        return attendee
                    }

                    let speakers = self.speakerContext.rxAttendees.value.map(transform)
                    self.speakerContext.rxAttendees.accept(speakers)
                    let audiences = self.audienceContext.rxAttendees.value.map(transform)
                    self.audienceContext.rxAttendees.accept(audiences)
                }).disposed(by: self.disposeBag)
        }
    }
}

// MARK: 参与人数据操作
extension WebinarEventEditAttendeeManager {
    // 重置参与人
    func resetAttedees(attendees: [EventEditAttendee],
                       simpleAttendees: [Rust.IndividualSimpleAttendee],
                       type: WebinarAttendeeType) {
        guard let attendeeContext = getAttendeeContext(with: type) else { return }
        attendeeContext.resetAttedees(attendees: attendees, simpleAttendees: simpleAttendees)
    }

    func updateAttendeeIfNeeded(forMeetingRoomsAdded newMeetingRooms: [CalendarMeetingRoom], type: WebinarAttendeeType) {
        guard let calendar = calendar,
              let chatterId = autoInsertAttendeeChatterId(forLarkCalendar: calendar, with: .speaker) else {
            return
        }
        self.addAttendees(type: .speaker, seeds: [.user(chatterId: chatterId)])
    }
}

extension WebinarEventEditAttendeeManager {

    func getAttendeeContext(with type: WebinarAttendeeType) -> WebinarAttendeeContext? {
        switch type {
        case .speaker:
            return speakerContext
        case .audience:
            return audienceContext
        @unknown default:
            return nil
        }
    }

    private func loadAllAttendeeIfNeeded(with attendeeContext: WebinarAttendeeContext) {
        if attendeeContext.haveAllAttendee {
            // 已经包含全量独立参与人了
            attendeeContext.rxPullAllAttendeeStatus.accept(.success)
            return
        }

        if case let .editWebinar(pbEvent, _) = input,
           pbEvent.displayType == .full && (pbEvent.calendarID == pbEvent.organizerCalendarID || pbEvent.guestCanSeeOtherGuests) {
            guard let rustApi = api else { return }
            attendeeContext.rxPullAllAttendeeStatus.accept(.loading)
            rustApi.pullWebinarEventIndividualSimpleAttendees(
                calendarID: pbEvent.calendarID,
                key: pbEvent.key,
                originalTime: pbEvent.originalTime,
                webinarType: attendeeContext.type
            )
            .asSingle()
            .subscribe { [weak self] (response) in
                guard let self = self else { return }
                EventEdit.logger.info("webinar event pull all individual attendees success")
                // 拉到全量独立参与人之后，直接覆盖
                attendeeContext.rxOriginalIndividualimpleAttendees.accept(response.attendees)
                attendeeContext.haveAllIndividualAttendee = true
                attendeeContext.rxPullAllAttendeeStatus.accept(.success)
            } onError: { [weak self] (error) in
                guard let self = self else { return }
                EventEdit.logger.error("webinar event pull all individual attendees \(attendeeContext.type.rawValue) error: \(error)")
                attendeeContext.rxPullAllAttendeeStatus.accept(.failed)
            }
            .disposed(by: disposeBag)
        }
    }

    private func autoInsertAttendeeChatterId(forLarkCalendar calendar: EventEditCalendar, with type: WebinarAttendeeType) -> String? {
        guard calendar.source == .lark, type == .speaker else {
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
            chatterId = self.userResolver.userID
        }
        let attendees = EventAttendee.visibleAttendees(of: speakerContext.rxAttendees.value)
        guard attendees.isEmpty || input.isCopy,
              !speakerContext.rxOriginalIndividualimpleAttendees.value.map(\.user.chatterID).contains(chatterId)else { return nil }
        return chatterId
    }
}

extension WebinarEventEditAttendeeManager: AddAttendeeProcess {

    // 判断 count 后是否达到人数管控上限
    func attendeesUpperLimitReason(with count: Int) -> AttendeesLimitReason? {
        guard let serverID = calendarManager?.primaryCalendar.serverId else { return nil }
        return Self.attendeesUpperLimitReason(
            count: count,
            calendar: calendar,
            attendeeMaxCountControlled: attendeeMaxCountControlled,
            isEventCreator: originEventCreator == serverID,
            isRecurEvent: false
        )
    }

    // 添加参与人
    func addAttendees(
        type: WebinarAttendeeType,
        seeds: [EventAttendeeSeed],
        departments: [(id: String, name: String)] = .init(),
        messageReceiver: ((AddAttendeeViewMessage) -> Void)? = nil
    ) {
        guard !seeds.isEmpty || !departments.isEmpty else { return }

        self.doAddAttendees(type: type, withSeeds: seeds, departments: departments, messageReceiver: messageReceiver)
    }

    private var originEventCreator: String {
        switch self.input {
        case .editWebinar(let event, _):
            return event.creatorCalendarID
        case .createWebinar:
            return self.creatorCalendarId.isEmpty ? calendarManager?.primaryCalendarID ?? "": self.creatorCalendarId
        default:
            return ""
        }
    }

    var isEventCreator: Bool {
        originEventCreator == calendarManager?.primaryCalendar.serverId
    }

    func getAutoInsertAttendeeChatterId(type: WebinarAttendeeType) -> String? {
        guard let calendar = calendar else { return nil }
        return autoInsertAttendeeChatterId(forLarkCalendar: calendar, with: type)
    }

    private func doAddAttendees(
        type: WebinarAttendeeType,
        withSeeds seeds: [EventAttendeeSeed],
        departments: [(id: String, name: String)] = .init(),
        messageReceiver: ((AddAttendeeViewMessage) -> Void)? = nil
    ) {
        guard let attendeeContext = getAttendeeContext(with: type) else { return }

        attendeeContext.addAttendees.queue.async {
            let lock = attendeeContext.addAttendees.lock
            lock.wait()
            var calendarEvent: CalendarEvent?
            if case .editWebinar(let event, _) = self.input {
                calendarEvent = event
            }
            let processContext = AddAttendeeContext(
                userResolver: self.userResolver,
                currentAttendees: attendeeContext.rxAttendees.value,
                currentSimpleAttendees: attendeeContext.rxNewSimpleAttendees.value,
                calendar: self.calendar,
                rejectedGroupUserMap: self.rejectedGroupUserMap,
                seeds: seeds,
                departments: departments,
                rxAttendees: attendeeContext.rxAttendees,
                autoInsertAttendeeChatterId: self.getAutoInsertAttendeeChatterId(type: type),
                disposeBag: self.disposeBag,
                isEventCreator: self.isEventCreator,
                eventCommonParam: CommonParamData(event: calendarEvent))
            processContext.attendeesUpperLimitReasonGetter = { [weak processContext, weak self] () -> AttendeesLimitReason? in
                guard let processContext = processContext, let self = self else {
                    return nil
                }
                let allBreakedUpCount = EventEditAttendee.allBreakedUpAttendeeCount(
                    of: processContext.currentAttendees + self.speakerContext.rxAttendees.value + self.audienceContext.rxAttendees.value,
                    individualSimpleAttendees: processContext.currentSimpleAttendees + self.speakerContext.rxNewSimpleAttendees.value + self.audienceContext.rxNewSimpleAttendees.value
                )
                return self.attendeesUpperLimitReason(with: allBreakedUpCount)
            }

            self.doAddAttendees(context: processContext)
                .subscribe(
                    onState: { [weak self] in
                        attendeeContext.rxLoading.accept(false)
                        if !processContext.isTransactionEnded {
                            attendeeContext.rxAttendees.accept(processContext.currentAttendees)
                            attendeeContext.rxNewSimpleAttendees.accept(processContext.currentSimpleAttendees)
                            self?.rejectedGroupUserMap = processContext.rejectedGroupUserMap

                            processContext.isTransactionEnded = true
                        }
                    },
                    onMessage: { message in
                        messageReceiver?(message)
                    },
                    onCompleted: {
                        lock.signal()
                    },
                    onTerminate: { err in
                        EventEdit.logger.error("err: \(err)")
                        attendeeContext.rxLoading.accept(false)
                        lock.signal()
                    },
                    scheduler: MainScheduler.instance
                )
        }
    }
}

extension WebinarEventEditAttendeeManager {
    private var event: EventEditModel? {
        eventDelegate?.getEventEditModel()
    }

    var organizerCalendarId: String {
        event?.organizerCalendarId ?? ""
    }

    var creatorCalendarId: String {
        event?.creatorCalendarId ?? ""
    }
}
