//
//  EventDetailViewModel+BuildComponent.swift
//  Calendar
//
//  Created by Rico on 2021/3/18.
//

import Foundation
import EventKit
import CalendarFoundation
import LKLoadable
import RxSwift
import RxRelay

extension EventDetailViewModel: EventDetailComponentProvider {

    func shouldLoadComponent(for componentType: EventDetailComponent) -> Bool {
        switch componentType {
        case .navigation, .header: return true
        case .calendar: return showCalendarInfo
        case .videoMeeting: return showVideoMeeting
        case .zoomMeeting: return showZoomMeeting
        case .organizer: return showOrganizer
        case .attendee: return showAttendee
        case .webinarSpeaker: return showWebinarSpeaker
        case .webinarAudience: return showWebinarAudience
        case .location: return showLocation
        case .attachment: return showAttachment
        case .description: return showDescription
        case .checkIn: return showCheckIn
        case .remind: return showRemind
        case .visibility: return showVisibility
        case .freebusy: return showFreeBusy
        case .meetingRoom: return showMeetingRoomInfo
        case .creator: return showCreator
        case .videoLive: return showVideoLive
        case .bottomAction: return showBottomAction
        case .undecryptableDetail: return showUndecryptable
        case .meetingNotes: return showMeetingNotes
        case .conflict: return showConflict
        }
    }

    func buildComponent(for componentType: EventDetailComponent) -> ComponentType? {

        switch componentType {
        case .navigation:
            let viewModel = EventDetailNavigationBarViewModel(context: context, userResolver: self.userResolver)
            return EventDetailNavigationBarComponent(viewModel: viewModel, userResolver: self.userResolver)
        case .header:
            let viewModel = EventDetailHeaderViewModel(context: context, userResolver: self.userResolver)
            return EventDetailHeaderComponent(viewModel: viewModel, userResolver: self.userResolver)
        case .calendar: return buildCalendarComponent()
        case .videoMeeting: return buildVideoMeetingComponent()
        case .zoomMeeting: return buildZoomMeetingComponent()
        case .organizer: return buildOrganizerComponent()
        case .attendee: return buildAttendeeComponent()
        case .webinarSpeaker: return buildWebinarSpeakerComponent()
        case .webinarAudience: return buildWebinarAudienceComponent()
        case .location: return buildLocationComponent()
        case .attachment: return buildAttachmentComponent()
        case .description: return buildDesciptionComponent()
        case .checkIn: return buildCheckInComponent()
        case .remind: return buildRemindComponent()
        case .visibility: return buildVisibilityComponent()
        case .freebusy: return buildFreeBusyComponent()
        case .meetingRoom: return buildMeetingRoomComponent()
        case .creator: return buildCreatorComponent()
        case .videoLive: return buildVideoLiveComopnent()
        case .bottomAction: return buildBottomActionComponent()
        case .undecryptableDetail: return buildUndecryptableDetailComponent()
        case .meetingNotes: return buildMeetingNotesComponent()
        case .conflict: return buildConflictViewComponent()
        }
    }
}

// MARK: - 组织者控制
extension EventDetailViewModel {

    private func buildOrganizerComponent() -> EventDetailTableOrganizerComponent? {
        guard showOrganizer else { return nil }
        let viewModel = EventDetailTableOrganizerViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableOrganizerComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showOrganizer: Bool {

        func _showOrganizerWithPB(event: EventDetail.Event) -> Bool {
            guard event.category != .resourceStrategy && event.category != .resourceRequisition else {
                return false
            }

            if let schema = event.dt.isSchemaDisplay(key: .organizerOrCreater), !schema {
                return false
            }

            /// 会议室日程
            if let calendar = model.getCalendar(calendarManager: self.calendarManager),
               calendar.type == .resources || calendar.type == .googleResource {
                return true
            }

            /// 非会议室日程 且 没有查看详情权限的日程
            guard event.displayType == .full else {
                return false
            }

            if !event.calendarEventDisplayInfo.isEventOrganizerShow {
                return false
            }

            let hasDetailContactAttendee = event.hasSuccessor || event.hasCreator || event.hasOrganizer

            return hasDetailContactAttendee
        }

        switch model {
        case .local: return false /*本地不显示组织者*/
        case .meetingRoomLimit: return true
        case let .pb(event, _): return _showOrganizerWithPB(event: event)
        }

    }
}

// MARK: - 参与者控制
extension EventDetailViewModel {

    private func buildAttendeeComponent() -> EventDetailTableAttendeeComponent? {
        guard showAttendee else { return nil }
        let viewModel = EventDetailTableAttendeeViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableAttendeeComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showAttendee: Bool {

        if model.isWebinar {
            return false
        }

        if let event = model.event {
            // 会议室创建的日程不显示参与人一栏
            guard event.category != .resourceStrategy && event.category != .resourceRequisition else {
                return false
            }

            if let schema = event.dt.isSchemaDisplay(key: .attendee), !schema {
                return false
            }

            if let calendar = calendar,
               calendar.type == .resources || calendar.type == .googleResource {
                return false
            }

            if isForReview { return false }
        }

        if model.shouldHideAttendees(for: calendar) { return true }

        return model.hasVisibleAttendees
    }
}

// MARK: - webinar 控制
extension EventDetailViewModel {

    private func buildWebinarSpeakerComponent() -> EventDetailTableWebinarSpeakerComponent? {
        guard showWebinarSpeaker else { return nil }
        let viewModel = EventDetailTableWebinarSpeakerViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableWebinarSpeakerComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showWebinarSpeaker: Bool {
        guard model.isWebinar else { return false }

        if let event = model.event {
            if let calendar = calendar,
               calendar.type == .resources || calendar.type == .googleResource {
                EventDetail.logInfo("not showWebinarSpeaker cause calendar type is wrong")
                return false
            }

            if isForReview {
                EventDetail.logInfo("not showWebinarSpeaker cause it is for review")
                return false
            }
        }

        if let webinar = webinarContext {
            // 这里是判断是不是要显示一个无权限查看的view
            if webinar.shouldHideWebinarSpeaker(detailModel: model, for: calendar) { return true }
            return webinar.webinarSpeakerTotalCount > 0
        }

        return false
    }

    private func buildWebinarAudienceComponent() -> EventDetailTableWebinarAudienceComponent? {
        guard showWebinarAudience else { return nil }
        let viewModel = EventDetailTableWebinarAudienceViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableWebinarAudienceComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showWebinarAudience: Bool {
        guard model.isWebinar else { return false }

        if let event = model.event {
            if let calendar = calendar,
               calendar.type == .resources || calendar.type == .googleResource {
                return false
            }

            if isForReview { return false }
        }

        if let webinar = webinarContext {
            // 这里是判断是不是要显示一个无权限查看的view
            if webinar.shouldHideWebinarAudience(detailModel: model, for: calendar) { return true }
            return webinar.webinarAudienceTotalCount > 0
        }

        return false
    }
}

// MARK: - 地点控制
extension EventDetailViewModel {

    private func buildLocationComponent() -> EventDetailTableLocationComponent? {
        guard showLocation else { return nil }
        let viewModel = EventDetailTableLocationViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableLocationComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showLocation: Bool {

        if model.isRoomLimit { return false }
        let hasLocation = !model.location.location.isEmpty
        let fullDisplayType = model.displayType == .full

        if isForReview { return hasLocation }

        return fullDisplayType && hasLocation

    }
}

// MARK: - 描述控制
extension EventDetailViewModel {

    private func buildDesciptionComponent() -> EventDetailTableDescComponent? {
        guard showDescription else { return nil }
        let viewModel = EventDetailTableDescViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableDescComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showDescription: Bool {

        if AppConfig.eventDesc == false {
            return false
        }

        if model.isRoomLimit {
            return false
        }

        let hasDesc = !model.eventDescription.isEmpty || !model.docsDescription.isEmpty
        let fullDisplayType = model.displayType == .full

        if isForReview { return hasDesc }

        return fullDisplayType && hasDesc

    }
}

// MARK: - 签到控制
extension EventDetailViewModel {

    private func buildCheckInComponent() -> EventDetailCheckInComponent? {
        guard showCheckIn else { return nil }
        let viewModel = EventDetailCheckInViewModel(context: context, userResolver: self.userResolver)
        return EventDetailCheckInComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showCheckIn: Bool {
        guard FG.eventCheckIn, let event = model.event else { return false }
        return event.displayType == .full && event.checkInConfig.checkInEnable
    }
}

// MARK: - 提醒控制
extension EventDetailViewModel {

    private func buildRemindComponent() -> EventDetailTableRemindComponent? {
        guard showRemind else { return nil }
        let viewModel = EventDetailTableRemindViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableRemindComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showRemind: Bool {

        if model.isRoomLimit {
            return false
        }

        if isForReview {
            return false
        }

        if let schema = model.event?.dt.isSchemaDisplay(key: .reminder), !schema {
            return false
        }

        return model.reminderCount > 0
    }
}

// MARK: - 日程可见性控制
extension EventDetailViewModel {

    private func buildVisibilityComponent() -> EventDetailTableVisibilityComponent? {
        guard showVisibility,
              let event = model.event else { return nil }
        let viewModel = EventDetailTableVisibilityViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableVisibilityComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showVisibility: Bool {

        if isForReview {
            return false
        }

        if model.isRoomLimit {
            return false
        }

        if model.isLocal {
            // iOS不显示公开范围
            return false
        }

        if let schema = model.event?.dt.isSchemaDisplay(key: .visibility), !schema {
            return false
        }

        if model.displayType != .full {
            return false
        }

        return model.visibility != .default
    }
}

// MARK: - 忙闲
extension EventDetailViewModel {
    private func buildFreeBusyComponent() -> EventDetailTableFreeBusyComponent? {
        guard showFreeBusy else { return nil }
        let viewModel = EventDetailTableFreeBusyViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableFreeBusyComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showFreeBusy: Bool {
        if isForReview { return false }
        if model.isRoomLimit { return false }

        if let schema = model.event?.dt.isSchemaDisplay(key: .freeBusy), !schema {
            return false
        }

        return model.isFree
    }
}

// MARK: - 会议室信息控制
extension EventDetailViewModel {

    private func buildMeetingRoomComponent() -> EventDetailTableMeetingRoomComponent? {
        guard showMeetingRoomInfo else { return nil }
        let viewModel = EventDetailTableMeetingRoomViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableMeetingRoomComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showMeetingRoomInfo: Bool {

        let hasMeetingRoom: Bool
        switch model {
        case let .local(event):
            let visibleRooms: [EKParticipant] = event.attendees?
                .filter { $0.participantType == .resource || $0.participantType == .room }
                .filter { $0.participantStatus.toCalendarEvnetAttendeeStatus() != .removed } ?? []
            hasMeetingRoom = !visibleRooms.isEmpty
        case let .pb(event, _):
            hasMeetingRoom = event.attendees.contains { $0.category == .resource && $0.status != .removed }
        case .meetingRoomLimit:
            hasMeetingRoom = true
        }

        // 谷歌日程，不展示会议室
        if let event = model.event, event.source == .google {
            return false
        }

        let fullDisplayType = model.displayType == .full

        if isForReview { return hasMeetingRoom }

        return fullDisplayType && hasMeetingRoom
    }
}

// MARK: - 视频会议控制
extension EventDetailViewModel {

    private func buildVideoMeetingComponent() -> Component? {
        if showLarkMeeting {
            EventDetail.logInfo("buildVideoMeetingComponent, showLarkMeeting")
            return buildLarkMeetingComponent()
        } else if showOtherMeeting {
            EventDetail.logInfo("buildVideoMeetingComponent, showOtherMeeting")
            return buildOtherMeetingComponent()
        }
        EventDetail.logInfo("buildVideoMeetingComponent, no video meeting")
        return nil
    }

    private func buildLarkMeetingComponent() -> Component? {
        guard showLarkMeeting,
              let event = model.event,
              let instance = model.instance else { return nil }
        SwiftLoadable.startOnlyOnce(key: "CalendarEventDetail_AttachableComponent_regist")
        let rxEventData = BehaviorRelay<CalendarEventData>(value: CalendarEventData(event: event, instance: instance))
        let component = CalendarAttachableComponentRegistery.buildComponent(for: .larkMeeting, with: rxEventData, userResolver: userResolver)
        bindRxModel(rxEventData: rxEventData)
        EventDetail.logInfo("buildLarkMeetingComponent successful?: \(component != nil)")
        return component
    }

    private func buildOtherMeetingComponent() -> EventDetailTableOtherMeetingComponent? {
        guard showOtherMeeting else { return nil }
        let viewModel = EventDetailTableOtherMeetingViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableOtherMeetingComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private func bindRxModel(rxEventData: BehaviorRelay<CalendarEventData>) {
        context.rxModel.compactMap { model -> CalendarEventData? in
            if let event = model.event, let instance = model.instance {
                return CalendarEventData(event: event, instance: instance)
            } else {
                return nil
            }
        }.bind { eventData in
            rxEventData.accept(eventData)
        }.disposed(by: disposeBag)
    }

    private var isVideoMeetingEnable: Bool {

        func showVideo(with event: EventDetail.Event) -> Bool {
            if !AppConfig.detailVideo {
                return false
            }
            if !FS.suiteVc(userID: self.userResolver.userID) {
                return false
            }

            if !(event.dt.isSchemaDisplay(key: .meetingVideo) ?? true) {
                return false
            }

            let sdkResult = event.calendarEventDisplayInfo.isVideoMeetingBtnShow
            return sdkResult
        }

        if model.isLocal { return false }
        if model.isRoomLimit { return false }

        guard let event = model.event else { return false }

        let displayFull = model.displayType == .full
        let sdkResult = showVideo(with: event)
        if isForReview { return sdkResult }

        return displayFull && sdkResult
    }

    private var showVideoMeeting: Bool {
        return showLarkMeeting || showOtherMeeting
    }

    // 是否展示飞书原生视频会议
    var showLarkMeeting: Bool {
        if let event = model.event, isVideoMeetingEnable {
            // 有的同步过来的日程，videoMeetingType 是 vchat 的，所以这里打个补丁
            let inVchatExceptSource = ![.email, .exchange].contains(event.source)
            return event.videoMeeting.videoMeetingType == .vchat && inVchatExceptSource
        }
        return false
    }

    // 是否展示飞书原生以外未插件化的视频会议
    var showOtherMeeting: Bool {
        if let event = model.event, isVideoMeetingEnable {
            // 可解析 meeting link 的要显示
            if model.isMeetingLinkParsable {
                return true
            } else { // 未插件化的谷歌会议和其他会议根据 meetingURL 判断
                let meetingType = event.videoMeeting.videoMeetingType
                if meetingType == .googleVideoConference || meetingType == .other {
                    return !event.videoMeeting.meetingURL.isEmpty
                }
                return false
            }
        }
        return false
    }
}

// MARK: - ZOOM会议显示控制
extension EventDetailViewModel {

    private func buildZoomMeetingComponent() -> Component? {
        guard showZoomMeeting, let event = model.event, let instance = model.instance else { return nil }
        let viewModel = EventDetailTableZoomMeetingViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableZoomMeetingComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showZoomMeeting: Bool {
        func showVideo(with event: EventDetail.Event) -> Bool {
            if !(event.dt.isSchemaDisplay(key: .meetingVideo) ?? true) {
                return false
            }

            let sdkResult = event.calendarEventDisplayInfo.isVideoMeetingBtnShow
            return sdkResult
        }

        if model.isLocal { return false }
        if model.isRoomLimit { return false }

        guard let event = model.event else { return false }

        let isForReview = isForReview
        let displayFull = model.displayType == .full

        let type = event.videoMeeting.videoMeetingType
        let hasVideoMeeting = (type == .zoomVideoMeeting)
        let sdkResult = showVideo(with: event)

        if isForReview { return hasVideoMeeting && sdkResult }
        return displayFull && hasVideoMeeting && sdkResult
    }
}

// MARK: - 日历显示控制
extension EventDetailViewModel {

    private func buildCalendarComponent() -> EventDetailTableCalendarComponent? {
        guard showCalendarInfo else { return nil }

        guard let calendar = calendar else { return nil }

        let viewModel = EventDetailTableCalendarViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableCalendarComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showCalendarInfo: Bool {

        guard calendar != nil, !isForReview else {
            return false
        }

        switch model {
        case .local: return true
        case let .pb(event, _):
            if let isSchemaDisplay = event.dt.isSchemaDisplay(key: .calendar), !isSchemaDisplay {
                return false
            }
            return true
        case .meetingRoomLimit: return false
        }
    }
}

// MARK: - 附件显示控制
extension EventDetailViewModel {

    private func buildAttachmentComponent() -> EventDetailTableAttachmentComponent? {
        guard showAttachment,
              let event = model.event else { return nil }
        let viewModel = EventDetailTableAttachmentViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableAttachmentComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showAttachment: Bool {

        if model.isLocal { return false }
        if model.isRoomLimit { return false }

        if AppConfig.eventAttachment == false {
            return false
        }

        if case let .pb(event, _) = model {
            if event.displayType == .limited { return false }
            return !event.attachments.allSatisfy { $0.isDeleted }
        }

        return false
    }
}

// MARK: - 创建者显示控制
extension EventDetailViewModel {

    private func buildCreatorComponent() -> EventDetailTableCreatorComponent? {
        guard showCreator,
              let event = model.event else { return nil }
        let viewModel = EventDetailTableCreatorViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableCreatorComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showCreator: Bool {
        if model.isLocal {
            return false
        }

        if model.isRoomLimit {
            return false
        }

        if let event = model.event {
            return event.calendarEventDisplayInfo.isEventCreatorShow
        }

        return false
    }
}

// MARK: - 视频直播显示控制
extension EventDetailViewModel {

    private func buildVideoLiveComopnent() -> EventDetailTableVideoLiveComponent? {
        guard showVideoLive,
              let event = model.event else { return nil }
        let viewModel = EventDetailTableVideoLiveViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableVideoLiveComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showVideoLive: Bool {

        if model.isLocal { return false }
        if model.isThirdParty { return false }

        guard let event = model.event else {
            return false
        }

        let isFullType = event.displayType == .full
        let hasVideoMeeting = (event.videoMeeting.videoMeetingType == .larkLiveHost)

        return hasVideoMeeting && (isForReview || isFullType)
    }
}

// MARK: - 底部交互区(加入日程按钮/RSVP）
extension EventDetailViewModel {
    private func buildBottomActionComponent() -> EventDetailBottomActionComponent? {
        guard showBottomAction else { return nil }
        let viewModel = EventDetailBottomActionViewModel(context: context, userResolver: self.userResolver)
        return EventDetailBottomActionComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showBottomAction: Bool {

        func shouldShowRSVPBar() -> Bool {
            guard let event = model.event else { return false }
            guard let calendar = calendar else { return false }
            // 如果我没有编辑权限，那不显示RSVPbar
            if isForReview || !calendar.isOwnerOrWriter() { return false }
            // exchange 日程，组织者的status为accepted，且不可取消，不显示 rsvp bar
            if event.source == .exchange && event.calendarID == event.organizerCalendarID {
                return false
            }
            // 如果这个日程所属日历不是这个日程的组织者, 那么一定显示RSVP
            if event.calendarID != event.organizerCalendarID { return true }
            // 如果这个日程所属日历是这个日程的组织者
            if !event.attendees.isEmpty, // 这个日程有attendee且
                event.willOrganizerAttend {// 我是一个有效的attendee（不管在群里还是在attendee里）
                return true // 那么显示RSVP
            }
            // webinar 日程，且我是一个有效的attendee（不管在群里还是在attendee里）
            if model.isWebinar && event.willOrganizerAttend {
                return true
            }
            // 否则不显示RSVP
            return false
        }

        func shouldShowJionButton() -> Bool {
            return isForReview && !options.contains(.isFromVideoMeeting)
        }

        // 整个rsvp底部栏都会被控制
        if let isSchemaDisplay = model.event?.dt.isSchemaDisplay(key: .rsvp), !isSchemaDisplay {
            return false
        }

        if model.displayType == .undecryptable { return false }
        if model.isRoomLimit { return false }
        if model.isLocal { return model.shouldShowLocalActionBar }

        if options.contains(.isFromRSVP) && payload.rsvpString?.isEmpty ?? true {
            return false
        }

        if shouldShowRSVPBar() || shouldShowJionButton() || options.contains(.isFromRSVP) {
            return true
        }

        return false
    }
}

// MARK: - 内容区(显示秘钥不可用)
extension EventDetailViewModel {
    private func buildUndecryptableDetailComponent() -> EventDetailTableUndecryptableComponent? {
        guard showUndecryptable else { return nil }
        return EventDetailTableUndecryptableComponent()
    }

    private var showUndecryptable: Bool {
        guard let event = model.event else { return false }
        return event.displayType == .undecryptable
    }
}

// MARK: - 有效会议
extension EventDetailViewModel {

    private func buildMeetingNotesComponent() -> EventDetailTableMeetingNotesComponent? {
        guard showMeetingNotes else { return nil }
        let viewModel = EventDetailTableMeetingNotesViewModel(context: context, userResolver: self.userResolver)
        return EventDetailTableMeetingNotesComponent(viewModel: viewModel, userResolver: self.userResolver)
    }

    private var showMeetingNotes: Bool {
        guard let event = model.event else { return false }
        if let schema = model.event?.dt.isSchemaDisplay(key: .meetingMinutes), !schema {
            return false
        }
        return event.displayType == .full && event.calendarEventDisplayInfo.isEventNoteShow
    }
}

// MARK: - 冲突视图
extension EventDetailViewModel {

    private func buildConflictViewComponent() -> EventDetailTableConflictViewComponent? {
        guard showConflict else { return nil }
        return conflictViewComponent
    }
    
    private var showConflict: Bool {
        /// 在非日历场景进入会显示冲突视图
        switch scene {
        case .calendarView: 
            return false
        case .chat:
            return true
        case .vc:
            return true
        case .search:
            return false
        case .inviteCard:
            return true
        case .shareCard:
            return true
        case .transferCard:
            return true
        case .rsvpCard:
            return true
        case .calendarFeedCard:
            return true
        case .url:
            return true
        case .reminder:
            return false
        case .offlineNotification:
            return false
        }
    }
}
