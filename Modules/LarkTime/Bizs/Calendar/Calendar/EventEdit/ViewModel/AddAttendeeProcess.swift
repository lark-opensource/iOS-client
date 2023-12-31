//
//  AddAttendeeProcess.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/17.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LarkExtensions

// 添加执行人的 ViewMessage
enum AddAttendeeViewMessage {
    /// 展示 alert
    case showAlert(EventEdit.Alert)
    /// 日程人数上限原因，弹窗位置比较特殊，在picker页面上，闭包参数表示继续添加参与人流程
    case attendeeCountLimit(AttendeesLimitReason?, () -> Void)
    /// 展示联系人申请
    case applyContactAlert
    /// 错误提示
    case errorToast(msg: String)
    /// 警告提示
    case warningToast(msg: String)
    /// 不带 icon 的 toast
    case tipsToast(msg: String)
}

class AddAttendeeContext: UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver

    /// 依赖
    @ScopedInjectedLazy var api: CalendarRustAPI?
    @ScopedInjectedLazy var mailContactService: MailContactService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    var primaryCalendarID: String {
        return calendarManager?.primaryCalendarID ?? ""
    }

    /// 添加参与人流程 Result，由外部传入，也存储添加参与人的最终结果，暴露给外部获取
    /// 当前环境包含的所有参与人
    var currentAttendees: [EventEditAttendee]
    /// 当前环境包含的所有精简参与人
    var currentSimpleAttendees: [Rust.IndividualSimpleAttendee]
    /// 群参与人的成员中拒绝的 user
    var rejectedGroupUserMap: [String: [Int64]] = [:]
    /// 日程参与人的数据监听
    var rxAttendees: BehaviorRelay<[EventEditAttendee]>
    /// 当前用户是否是日程创建者
    var isEventCreator: Bool = true
    /// 要添加的参与人
    var seeds: [EventAttendeeSeed]
    /// 要添加的部门
    var departments: [(id: String, name: String)]
    /// 自动添加的参与人 userid
    var autoInsertAttendeeChatterId: String?
    /// 添加的部门成员上限
    var departmentMemberUpperLimit = SettingService.shared().settingExtension.departmentMemberUpperLimit
    /// 日程当前所在日历
    var calendar: EventEditCalendar?
    /// 大人数日程管控判断闭包
    var attendeesUpperLimitReasonGetter: (() -> AttendeesLimitReason?)?
    /// 垃圾袋
    var disposeBag: DisposeBag

    var eventCommonParam: CommonParamData

    /// 流程内部使用字段
    fileprivate var existNoAuthAttendeeFiltered: Bool = false
    fileprivate var unableAddGroups: (groupNames: [String], ids: [String], limit: Int32) = ([], [], 0)
    fileprivate var addingAttendees = (
        /// 添加的独立参与人 + 普通群
        noneMeetingGroupAttendees: [EventEditAttendee](),
        /// 会议群打散得来
        groupMembers: [Rust.IndividualSimpleAttendee](),
        /// 部门打散得来
        departmentMembers: [Rust.IndividualSimpleAttendee]()
    )
    /// 描述触发了部门上限的名字
    fileprivate var departmentLimitExceededIds = [String]()

    /// 保存流程是否被中断
    var isTransactionEnded: Bool = false

    init(
        userResolver: UserResolver,
        currentAttendees: [EventEditAttendee],
        currentSimpleAttendees: [Rust.IndividualSimpleAttendee],
        calendar: EventEditCalendar? = nil,
        rejectedGroupUserMap: [String: [Int64]] = [:],
        seeds: [EventAttendeeSeed],
        departments: [(id: String, name: String)],
        rxAttendees: BehaviorRelay<[EventEditAttendee]>,
        autoInsertAttendeeChatterId: String? = nil,
        disposeBag: DisposeBag = DisposeBag(),
        departmentMemberUpperLimit: Int = SettingService.shared().settingExtension.departmentMemberUpperLimit,
        isEventCreator: Bool = true,
        eventCommonParam: CommonParamData
    ) {
        self.userResolver = userResolver
        self.currentAttendees = currentAttendees
        self.currentSimpleAttendees = currentSimpleAttendees
        self.rejectedGroupUserMap = rejectedGroupUserMap
        self.seeds = seeds
        self.departments = departments
        self.rxAttendees = rxAttendees
        self.autoInsertAttendeeChatterId = autoInsertAttendeeChatterId
        self.disposeBag = disposeBag
        self.departmentMemberUpperLimit = departmentMemberUpperLimit
        self.isEventCreator = isEventCreator
        self.calendar = calendar
        self.eventCommonParam = eventCommonParam
    }
}

typealias AddAttendeeStage<Stage> = RxStage<Stage, AddAttendeeViewMessage>
typealias AddAttendeeForwarder<State> = StageForwarder<State, AddAttendeeViewMessage>

protocol AddAttendeeProcess {
    // 添加参与人流程
    func doAddAttendees(context: AddAttendeeContext) -> AddAttendeeStage<Void>
}

extension AddAttendeeProcess {

    func doAddAttendees(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        return
            // start
            AddAttendeeStage<Void>.complete()
            .joinStage { _ -> AddAttendeeStage<Void> in
                autoFixSeedsStage(context: context)
            }
            .joinStage { _ -> AddAttendeeStage<Void> in
                checkCollaborationPermissionStage(context: context)
            }
            // get addingAttendees by seeds
            .joinStage { _ -> AddAttendeeStage<Void> in
                getAttendeesStage(context: context)
            }
            .joinStage { _ -> AddAttendeeStage<Void> in
                filterBlockedAttendeesStaged(context: context)
            }
            // get addingAttendees by departments
            .joinStage { _ -> AddAttendeeStage<Void> in
                getDepartmentAttendeeStage(context: context)
            }
            // append addingAttendees
            .joinStage { _ -> AddAttendeeStage<Void> in
                appendAddingAttendeesStage(context: context)
            }
            // check max attendees limit
            .joinStage { _ -> AddAttendeeStage<Void> in
                checkMaxAttendeeLimitStage(context: context)
            }
            // check toast for filtered users
            .joinStage { _ -> AddAttendeeStage <Void> in
                checkToastForFilteredUsers(context: context)
            }
            // check meetingGroup limit
            .joinStage { _ -> AddAttendeeStage <Void> in
                checkMeetingGroupLimit(context: context)
            }
            // check department limit
            .joinStage { _ -> AddAttendeeStage <Void> in
                checkDepartmentLimit(context: context)
            }
            // 补充参与人信息
            .joinStage { _ -> AddAttendeeStage <Void> in
                supplyAttendeeDisplayInfo(context: context)
            }
            .joinStage { _ -> AddAttendeeStage <Void> in
                applyContactAlert(context: context)
            }
            // catch error
            .catchError { (_, forwader: AddAttendeeForwarder<Void>) in
                context.isTransactionEnded = true // 捕获错误，结束事务
                forwader.deliver(.errorToast(msg: BundleI18n.Calendar.Calendar_Toast_GuestError))
                forwader.complete()
                return Disposables.create()
            }
    }

    // MARK: check individual users
    func checkCollaborationPermissionStage(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        guard let api = context.api else { return .complete() }
        let uids = context.seeds.compactMap { seed -> String? in
            if case .user(let uid) = seed {
                return uid
            } else { return nil }
        }

        return api.checkCollaborationPermissionIgnoreError(uids: uids)
            .asStage { .state($0) }
            .joinStage { restrictedIDs -> AddAttendeeStage<Void> in
                context.existNoAuthAttendeeFiltered = !restrictedIDs.isEmpty
                context.seeds = context.seeds.filter { seed -> Bool in
                    if case .user(let uid) = seed, restrictedIDs.contains(uid) {
                        return false
                    } else {
                        return true
                    }
                }
                return .complete()
            }
    }

    // MARK: 自动添加参与人
    func autoFixSeedsStage(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        guard !context.seeds.isEmpty || !context.departments.isEmpty else {
            return .complete()
        }

        if let autoInsertChatterId = context.autoInsertAttendeeChatterId {
            let whereExpr = { (seed: EventAttendeeSeed) -> Bool in
                if case .user(let chatterId) = seed, chatterId == autoInsertChatterId {
                    return true
                } else {
                    return false
                }
            }
            if !context.seeds.contains(where: whereExpr) {
                context.seeds.insert(.user(chatterId: autoInsertChatterId), at: 0)
            }

        }
        return .complete()
    }

    // MARK: get addingAttendees by seeds
    func getAttendeesStage(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        guard let api = context.api else { return .complete() }
        // 预解析邮箱参与人
        context.mailContactService?.loadMailContact(mails: context.seeds.compactMap(\.mail))
        return api.loadAttendees(by: context.seeds, primaryCalendarID: context.primaryCalendarID)
            .asStage { .state($0) }
            .joinStage { attendees -> AddAttendeeStage<Void> in
                var meetingGroupAttendees = attendees.filter { $0.isMeetingGroup }
                var noneMeetingGroupAttendees = attendees.filter { !$0.isMeetingGroup }

                let meetingGroupIds: [String] = context.seeds.compactMap { seed in
                    switch seed {
                    case .meetingGroup(let chatId): return chatId
                    default:
                        return nil
                    }
                }

                context.unableAddGroups = EventEditAttendee
                    .groupSecurityLimit(of: EventEditAttendee.makeAttendees(from: meetingGroupAttendees),
                                        meetingGroupIds: meetingGroupIds)
                meetingGroupAttendees = meetingGroupAttendees.filter({ attendee in
                    return !context.unableAddGroups.ids.contains(attendee.chatId ?? "")
                })

                // 打散会议群
                let simpleMembers = meetingGroupAttendees.flatMap { $0.groupMemberSeeds }
                let editAttendees = EventEditAttendee.makeAttendees(from: noneMeetingGroupAttendees)

                // check is there any group or meetingGroup has filtered people
                attendees.forEach {
                    if !$0.forbidenChatterIDs.isEmpty {
                        context.existNoAuthAttendeeFiltered = true
                        context.rejectedGroupUserMap[$0.identifier] = $0.forbidenChatterIDs
                    }
                }
                context.addingAttendees.noneMeetingGroupAttendees = editAttendees.map({
                    fixedNewAttendee(from: $0, calendar: context.calendar, userID: context.userResolver.userID)
                })
                context.addingAttendees.groupMembers = Rust.IndividualSimpleAttendee.deduplicated(of: simpleMembers)
                return .complete()
            }
    }

    func filterBlockedAttendeesStaged(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        guard let api = context.api else { return .complete() }
        let simpleMembers = context.addingAttendees.groupMembers
        let uids = simpleMembers.map { $0.user.chatterID }
        EventEdit.logger.info("filter uids count: \(uids.count)")
        return api.checkCollaborationPermissionIgnoreError(uids: uids)
            .asStage { .state($0) }
            .joinStage { (blockedUserIDs, forwarder: AddAttendeeForwarder<Void>) in
                EventEdit.logger.info("blockedUserIDs: \(blockedUserIDs.count)")
                let newMembers = blockedUserIDs.reduce(simpleMembers) { (summary, newValue) in
                    summary.filter { $0.user.chatterID != newValue }
                }
                if simpleMembers.count > newMembers.count {
                    forwarder.deliver(.tipsToast(msg: I18n.Calendar_G_CreateEvent_AddUser_CantInvite_Hover))
                    CalendarTracerV2.ToastStatus.trace(commonParam: context.eventCommonParam) {
                        $0.toast_name = "unable_to_add_someone_to_event"
                    }
                }
                context.addingAttendees.groupMembers = newMembers
                forwarder.complete()
            }
    }

    // MARK: get addingAttendees by departments
    func getDepartmentAttendeeStage(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        guard !context.departments.isEmpty,
              let api = context.api else { return .complete() }
        return api.pullDepartmentChatterIDs(context.departments.map(\.id))
            .do(onError: { err in
                EventEdit.logger.error("pullDepartmentChatterIDs failed. err: \(err)")
            })
            .asStage { .state($0) }
            .joinStage { (result, forwarder: AddAttendeeForwarder<Void>) in
                context.addingAttendees.departmentMembers = result.chatChatterIds.values.flatMap { idsPack in
                    idsPack.chatterIds.compactMap { chatterId in
                        guard !result.rejectedUserList.contains(chatterId) else {
                            context.existNoAuthAttendeeFiltered = true
                            return nil
                        }
                        let chatterID = "\(chatterId)"
                        guard let calendarID = result.chatterCalendarIDMap[chatterID] else { return nil }
                        var simpleAttendee = Rust.IndividualSimpleAttendee()
                        simpleAttendee.category = .user
                        simpleAttendee.user.chatterID = chatterID
                        simpleAttendee.isEditable = true
                        simpleAttendee.status = .needsAction
                        simpleAttendee.calendarID = calendarID
                        return simpleAttendee
                    }
                }
                context.departmentLimitExceededIds = result.limitExceededDepartmentIds
                forwarder.complete()
            }
    }

    // MARK: appendAddingAttendeeStage
    func appendAddingAttendeesStage(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        let addingFullAttendees = context.addingAttendees.noneMeetingGroupAttendees
        let addingAttendeeSeeds = context.addingAttendees.departmentMembers + context.addingAttendees.groupMembers

        context.currentAttendees = context.currentAttendees
        .filter { attendee in
            return !addingFullAttendees.contains {
                // 新增加的参与人，之前被 removed 掉了，将之前 removed 的 attendee 给剔除掉
                $0.deduplicatedKey == attendee.deduplicatedKey && attendee.status == .removed
            }
        }
        .filter { attendee in
            return !addingAttendeeSeeds.contains {
                // 新增加的参与人，之前被 removed 掉了，将之前 removed 的 attendee 给剔除掉
                $0.deduplicatedKey == attendee.deduplicatedKey && attendee.status == .removed
            }
        }

        context.currentAttendees = EventEditAttendee.deduplicated(of: context.currentAttendees + addingFullAttendees)
        context.currentSimpleAttendees = Rust.IndividualSimpleAttendee.deduplicated(of: context.currentSimpleAttendees + addingAttendeeSeeds)
        return .complete()
    }

    // MARK: check max attendees limit
    func checkMaxAttendeeLimitStage(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        guard let getReason = context.attendeesUpperLimitReasonGetter else { return .complete() }

        return .create { forwarder in
            let limitReason = getReason()
            let continueAction = { forwarder.complete() }
            context.isTransactionEnded = limitReason != nil
            forwarder.deliver(.attendeeCountLimit(limitReason, continueAction))
            forwarder.complete()
            return Disposables.create()
        }
    }

    static func attendeesUpperLimitReason(
        count: Int,
        calendar: EventEditCalendar?,
        attendeeMaxCountControlled: Bool,
        isEventCreator: Bool,
        isRecurEvent: Bool,
        isForAI: Bool = false) -> AttendeesLimitReason? {
        guard let calendar = calendar,
              ![.exchange, .google].contains(calendar.source) else {
            // 三方日历不走大人数日程管控逻辑
            return nil
        }
        guard let setting = SettingService.shared().tenantSetting,
              setting.hasAttendeeNumberControlConfig else {
            /// 租户配置数据缺失，走 settingExtension 的技术上限兜底
            let eventAttendeeLimit = SettingService.shared().settingExtension.eventAttendeeLimit
            AttendeeLimitApprove.logInfo("attendeesUpperLimitReason: tenantSetting miss")
            return count > eventAttendeeLimit ? .reachFinalLimit(eventAttendeeLimit) : nil
        }

        let config = setting.attendeeNumberControlConfig
        AttendeeLimitApprove.logInfo("attendee number control config: \(config.debugDescription), count: \(count)")
        ///  管控人数上限
        let controlLimit = Int(config.controlAttendeeMaxCount)
        ///  技术人数上限
        let finalLimit = Int(config.attendeeMaxCount)
        ///  重复性日程人数上限
        let reCurLimit = Int(config.recurEventControlMaxCount)

        if isForAI {
            if !config.isTenantCertificated {
                /// 未认证企业
                return count > finalLimit ? .notTenantCertificated(finalLimit) : nil
            }

            if config.isControlFeatureOn && count > controlLimit && attendeeMaxCountControlled {
                /// 被管控状态下，超出管控上限，白名单用户通过（是白名单用户 && 是原始日程的创建者）
                return config.isUserInAccessList && isEventCreator ? nil : .reachControlLimit(controlLimit)
            }

            if config.isRecurEventControlFeatureOn && isRecurEvent && count > reCurLimit {
                /// 优先判断重复性日程人数上限
                return .reachRecurEventLimit(reCurLimit)
            }

            if count > finalLimit {
                /// 超出技术上限
                return .reachFinalLimit(finalLimit)
            }
        } else {
            if !config.isTenantCertificated {
                /// 未认证企业
                return count > finalLimit ? .notTenantCertificated(finalLimit) : nil
            }

            if count > finalLimit {
                /// 超出技术上限
                return .reachFinalLimit(finalLimit)
            }

            if config.isRecurEventControlFeatureOn && isRecurEvent && count > reCurLimit {
                /// 优先判断重复性日程人数上限
                return .reachRecurEventLimit(reCurLimit)
            }

            if config.isControlFeatureOn && count > controlLimit && attendeeMaxCountControlled {
                /// 被管控状态下，超出管控上限，白名单用户通过（是白名单用户 && 是原始日程的创建者）
                return config.isUserInAccessList && isEventCreator ? nil : .reachControlLimit(controlLimit)
            }
        }

        return nil
    }

    // MARK: check toast for filtered users
    func checkToastForFilteredUsers(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        guard context.existNoAuthAttendeeFiltered else { return .complete() }
        return .create { forwarder in
            let alertText = I18n.Calendar_G_CreateEvent_AddUser_CantInvite_Hover
            CalendarTracerV2.EventNoAutoToInvite.traceView {
                $0.action_source = "full_create_view"
                $0.mergeEventCommonParams(commonParam: CommonParamData())
            }
            CalendarTracerV2.ToastStatus.trace(commonParam: context.eventCommonParam) {
                $0.toast_name = "unable_to_add_someone_to_event"
            }
            forwarder.deliver(.tipsToast(msg: alertText))
            forwarder.complete()
            return Disposables.create()
        }
    }

    // MARK: check meetingGroup limit
    func checkMeetingGroupLimit(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        return .create { forwarder in
            guard !context.isTransactionEnded, !context.unableAddGroups.groupNames.isEmpty else {
                forwarder.complete()
                return Disposables.create()
            }
            // 在编辑页进行不可添加的会议群弹窗提示
            var alert = EventEdit.Alert()
            let names = context.unableAddGroups.groupNames.joined(separator: "、")
            alert.title = BundleI18n.Calendar.Calendar_Edit_AddMeetingGroupMaxNum(number: context.unableAddGroups.limit)
            alert.titleAlignment = .left
            alert.contentAlignment = .left
            alert.content = names
            alert.actions = [
                .init(title: BundleI18n.Calendar.Calendar_Common_GotIt, titleColor: UIColor.ud.primaryContentDefault) {
                    forwarder.complete()
                }
            ]
            forwarder.deliver(.showAlert(alert))
            return Disposables.create()
        }
    }

    // MARK: check department limit
    func checkDepartmentLimit(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        return .create { forwarder in
            guard !context.isTransactionEnded, !context.departmentLimitExceededIds.isEmpty else {
                forwarder.complete()
                return Disposables.create()
            }
            var idNameMap = [String: String]()
            context.departments.forEach { (id, name) in idNameMap[id] = name }
            let limitDepartmentNames = context.departmentLimitExceededIds
                .compactMap { idNameMap[$0] }
                .joined(separator: BundleI18n.Calendar.Calendar_Common_Comma)
            var alert = EventEdit.Alert()
            alert.title = BundleI18n.Calendar.Calendar_Edit_AddOrganizationMaxNum(number: context.departmentMemberUpperLimit)
            alert.content = limitDepartmentNames
            alert.actions = [
                .init(title: BundleI18n.Calendar.Calendar_Common_GotIt, titleColor: UIColor.ud.primaryContentDefault) {
                    forwarder.complete(())
                }
            ]
            forwarder.deliver(.showAlert(alert))
            return Disposables.create()
        }
    }
//
    // MARK: 补充参与人信息
    func supplyAttendeeDisplayInfo(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        guard !context.isTransactionEnded, let api = context.api else {
            return .complete()
        }

        // 异步预加载群成员时区信息
        var groupMemberMap: [String: [Rust.IndividualSimpleAttendee]] = [:]
        var groupLimitInfo: [String: Int] = [:]
        context.addingAttendees.noneMeetingGroupAttendees.forEach { editAttendee in
            if case .group(let groupAttendee) = editAttendee {
                groupMemberMap[groupAttendee.chatId] = groupAttendee.memberSeeds
                if groupAttendee.openSecurity {
                    groupLimitInfo[groupAttendee.chatId] = Int(groupAttendee.memberShownLimit)
                }
            }
        }

        self.pullUserAttendeeDisplayInfo(
            groupsSimpleMembers: groupMemberMap,
            groupLimitInfo: groupLimitInfo,
            context: context
        )

        // 打散的参与人补齐一页数据
        let pageSize = AttendeePaginatorImpl.pageSize
        let fullAttendeeCount = context.rxAttendees.value.count
        let needPullCount = max(0, pageSize - fullAttendeeCount)

        let pullDisplayAttendees = context.currentSimpleAttendees.prefix(needPullCount)

        return api.pullEventEditUserAttendee(with: pullDisplayAttendees)
            .do(onError: { err in
                EventEdit.logger.error("loadAttendees failed. err: \(err)")
            })
            .asStage { .state($0) }
            .joinStage { attendees -> AddAttendeeStage<Void> in
                let addingFullMembers = attendees.flatMap({ EventEditAttendee.user($0) }).map({ fixedNewAttendee(from: $0, calendar: context.calendar, userID: context.userResolver.userID) })

                let fullMemberIDs = attendees.map { $0.deduplicatedKey }
                // 补完剔除添加到精简参与人，后面分页的时候再转成display attendee
                context.currentSimpleAttendees = context.currentSimpleAttendees.filter { !fullMemberIDs.contains($0.deduplicatedKey) }
                context.currentAttendees = EventEditAttendee.deduplicated(of: context.currentAttendees + addingFullMembers)
                return .complete()
            }
    }

    // 避免安全隐患，预加载群成员 displayInfo 以 showMemberLimit 为上限
    private func pullUserAttendeeDisplayInfo(groupsSimpleMembers: [String: [Rust.IndividualSimpleAttendee]],
                                             groupLimitInfo: [String: Int],
                                             context: AddAttendeeContext) {
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
            context.api?.pullEventEditUserAttendee(with: pullAttendees)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak context] (attendees) in
                    guard let context = context else { return }
                    let attendees = context.rxAttendees.value.map { (attendee) -> EventEditAttendee in
                        if case .group(var groupAttendee) = attendee, groupAttendee.chatId == chatID {
                            groupAttendee.members = attendees
                            groupAttendee.hasMoreMembers = simpleAttendees.count > groupAttendee.members.count

                            return .group(groupAttendee)
                        }
                        return attendee
                    }
                    context.rxAttendees.accept(attendees)
                }).disposed(by: context.disposeBag)
        }
    }

    // 修复新增参与人的可编辑状态 & rsvp
    private func fixedNewAttendee(from attendee: EventEditAttendee, calendar: EventEditCalendar?, userID: String) -> EventEditAttendee {
        switch attendee {
        case .user(var user):
            user.permission = .writable
            if user.chatterId == userID {
                // 当前用户，默认 accept
                user.status = .accept
            } else if let calendar = calendar, calendar.isPrimary, calendar.userChatterId == user.chatterId {
                // 当前 calendar 对应用户，默认 accept，calendar须为主日历
                user.status = .accept
            } else {
                // do nothing
            }
            return .user(user)
        case .email(var email):
            email.permission = .writable
            return .email(email)
        case .group(var group):
            group.permission = .writable
            group.members = group.members.map { member in
                var member = member
                member.permission = .writable
                return member
            }
            return .group(group)
        case .local(let attendee):
            return .local(attendee)
        }
    }

    // MARK: 联系人申请
    func applyContactAlert(context: AddAttendeeContext) -> AddAttendeeStage<Void> {
        return .create { forwarder in
            guard !context.isTransactionEnded else {
                forwarder.complete()
                return Disposables.create()
            }
            forwarder.deliver(.applyContactAlert)
            forwarder.complete()
            return Disposables.create()
        }
    }
}

enum AttendeesLimitReason {
    case notTenantCertificated(Int) // 企业未认证
    case reachFinalLimit(Int) // 达到技术上限
    case reachControlLimit(Int) // 达到管控上限
    case reachRecurEventLimit(Int) // 达到重复性日程人数上限

    var limit: Int {
        switch self {
        case .notTenantCertificated(let limit),
             .reachFinalLimit(let limit),
             .reachControlLimit(let limit),
             .reachRecurEventLimit(let limit):
            return limit
        }
    }
}
