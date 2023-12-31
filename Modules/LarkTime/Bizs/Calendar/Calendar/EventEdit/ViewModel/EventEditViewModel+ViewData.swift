//
//  EventEditViewModel+ViewData.swift
//  Calendar
//
//  Created by 张威 on 2020/3/23.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import RxSwift
import RxCocoa
import CalendarFoundation
import LarkTimeFormatUtils

/// Provide ViewData
extension EventEditViewModel {

    func bindViewData() {
        bindSummaryViewData()
        bindWebinarAttendeeViewData(type: .speaker)
        bindWebinarAttendeeViewData(type: .audience)
        bindAttendeeViewData()
        bindGuestPermissionViewData()
        bindArrangeDateViewData()
        bindPickDateViewData()
        bindTimeZoneViewData()
        bindVideoMeetingViewData()
        bindCalendarViewData()
        bindColorViewData()
        bindVisibilityViewData()
        bindFreeBusyViewData()
        bindMeetingRoomViewData()
        bindLocationViewData()
        bindCheckInViewData()
        bindReminderViewData()
        bindRruleViewData()
        bindAttachmentViewData()
        bindMeetingNotesViewData()
        bindNotesViewData()
        bindDeleteViewData()
        bindWebinarFooterLabelData()
    }

    // MARK: Summary

    struct SummaryViewData: EventEditSummaryViewDataType {
        var title: String = ""
        var isEditable: Bool = false
        var inset: UIEdgeInsets = EventEditSummaryView.edgeInset
        var canShowAIEntrance: Bool = false
        var shouldShowAIStyle: Bool = false
        var myAIName: String = ""
    }

    private func bindSummaryViewData() {
        guard legoInfo.shouldShow(.summary),
              let rxEvent = eventModel?.rxModel,
              let rxPermission = permissionModel?.rxModel else { return }
        let transform = { (eventModel: EventEditModel, permissions: EventEditPermissions) -> SummaryViewData in
            var inset = EventEditSummaryView.edgeInset
            if self.input.isWebinarScene {
                inset.top += 14
            }
            
            /// 是否有编辑权限
            let isEditable: Bool = permissions.summary.isEditable
            /// 是否在fg内
            let isInLineAIEnable: Bool = FeatureGating.canCreateEventInline(userID: self.userResolver.userID)
            /// 是否邮件日程
            let isEmailEvent: Bool = rxEvent.value.source == .email
            /// 是否三方日程
            let isThirdPartyEvent: Bool = rxEvent.value.source == .google || rxEvent.value.source == .exchange
            
            let myAIName: String = self.calendarMyAIService?.myAIInfo().name ?? ""
            
            let canShowAIEntrance = isInLineAIEnable && isEditable && !isEmailEvent && !isThirdPartyEvent && !self.input.isWebinarScene
            
            return SummaryViewData(
                title: eventModel.summary ?? "",
                isEditable: isEditable,
                inset: inset,
                canShowAIEntrance: canShowAIEntrance,
                shouldShowAIStyle: eventModel.aiStyleInfo.summary,
                myAIName: myAIName
            )
        }
        Observable.combineLatest(rxEvent, rxPermission)
            .map { transform($0.0, $0.1) }
            .bindRxViewData(to: rxSummaryViewData)
            .disposed(by: disposeBag)
    }

    // MARK: WebinarAttendee - Speaker & Audience
    struct WebinarAttendeeViewData: EventEditWebinarAttendeeViewDataType {
        var avatars: [Avatar] = []
        var countStr: String = ""
        var isVisible: Bool = false
        var enableAdd: Bool = false
        var isLoading: Bool = false
        var attendeeType: WebinarAttendeeType
    }

    private func bindWebinarAttendeeViewData(type: WebinarAttendeeType) {
        guard legoInfo.shouldShow(.webinarAttendee) else { return }
        var rxWebinarAttendeeViewData: BehaviorRelay<EventEditWebinarAttendeeViewDataType>?
        switch type {
        case .speaker:
            rxWebinarAttendeeViewData = rxSpeakerViewData
        case .audience:
            rxWebinarAttendeeViewData = rxAudienceViewData
        @unknown default:
            break
        }
        typealias RelatedTuple = (
            attendeeData: AttendeeData,
            permissions: EventEditPermissions,
            isLoading: Bool
        )
        let transform = { (tuple: RelatedTuple) -> WebinarAttendeeViewData in
            let (attendeeData, permissions, isLoading) = tuple
            let avatars = attendeeData.visibleAttendees.map { $0.avatar }
            let count = attendeeData.breakUpAttendeeCount
            let countStr = "\(count)"
            return WebinarAttendeeViewData(
                avatars: avatars,
                countStr: countStr,
                isVisible: permissions.attendees.isVisible,
                enableAdd: permissions.attendees.isEditable,
                isLoading: isLoading,
                attendeeType: type
            )
        }
        guard let attendeeContext = webinarAttendeeModel?.getAttendeeContext(with: type),
              let rxPermissions = permissionModel?.rxPermissions,
              let rxWebinarAttendeeViewData = rxWebinarAttendeeViewData else { return }
        Observable.combineLatest(
            attendeeContext.rxAttendeeData,
            rxPermissions,
            attendeeContext.rxLoading
        )
        .map { transform($0) }
        .bindRxViewData(to: rxWebinarAttendeeViewData)
        .disposed(by: disposeBag)
    }

    // MARK: Attendee

    struct AttendeeViewData: EventEditAttendeeViewDataType {
        var avatars: [Avatar] = []
        var countStr: String = ""
        var isVisible: Bool = false
        var enableAdd: Bool = false
        var isLoading: Bool = false
        var shouldShowAIStyle: Bool = false
    }

    private func bindAttendeeViewData() {
        guard legoInfo.shouldShow(.attendee) else { return }
        typealias RelatedTuple = (
            attendeeData: AttendeeData,
            permissions: EventEditPermissions,
            isLoading: Bool
        )
        let transform = { (tuple: RelatedTuple) -> AttendeeViewData in
            let (attendeeData, permissions, isLoading) = tuple
            let avatars = attendeeData.visibleAttendees.map { $0.avatar }
            let count = attendeeData.breakUpAttendeeCount
            let countStr = BundleI18n.Calendar.Calendar_Plural_ShortDetailStringOfGuests(number: count)
            let isVisible = permissions.attendees.isEditable
                            || (permissions.attendees.isVisible && !avatars.isEmpty)
            let noNeedShowAIStyle: Bool = self.eventModel?.rxModel?.value.aiStyleInfo.attendee.isEmpty ?? true
            return AttendeeViewData(
                avatars: avatars,
                countStr: countStr,
                isVisible: isVisible,
                enableAdd: permissions.attendees.isEditable,
                isLoading: isLoading,
                shouldShowAIStyle: !noNeedShowAIStyle
            )
        }

        guard let rxAttendeeData = attendeeModel?.rxAttendeeData,
              let rxPermissions = permissionModel?.rxPermissions,
              let rxLoading = attendeeModel?.rxLoading else { return }
        Observable.combineLatest(
                rxAttendeeData,
                rxPermissions,
                rxLoading
            )
            .map { transform($0) }
            .bindRxViewData(to: rxAttendeeViewData)
            .disposed(by: disposeBag)
    }

    struct GuestPermissionViewData: EventEditGuestPermissionViewDataType {
        var isVisible: Bool = false
        var title: String = ""
        var subtitle: String = ""
    }

    private func bindGuestPermissionViewData() {
        guard legoInfo.shouldShow(.guestPermission),
              let rxEvent = eventModel?.rxModel,
              let rxPermissions = permissionModel?.rxModel else { return }

        let transform = { (eventModel: EventEditModel, permissions: EventEditPermissions, inMeetingNotesFG: Bool) -> GuestPermissionViewData in
            let subtitle: String
            let canCreateNotes = eventModel.meetingNotesConfig.createNotesPermissionRealValue() == .all && inMeetingNotesFG
            if eventModel.guestCanModify {
                subtitle = canCreateNotes ? I18n.Calendar_G_EditEventCreateNotes_Options : I18n.Calendar_Detail_ModifyEvent
            } else if eventModel.guestCanInvite {
                subtitle = canCreateNotes ? I18n.Calendar_G_InvitePplCreateNotes_Options : I18n.Calendar_Detail_InviteOthers
            } else if eventModel.guestCanSeeOtherGuests {
                subtitle = canCreateNotes ? I18n.Calendar_G_ViewPplCreateNotes_Options : I18n.Calendar_Detail_CheckGuestList
            } else if canCreateNotes {
                subtitle = I18n.Calendar_G_CreateNotes_Options
            } else {
                subtitle = I18n.Calendar_G_BlockedActionDialogTitle
            }

            return GuestPermissionViewData(isVisible: permissions.guestPermission.isVisible,
                                           title: I18n.Calendar_G_GuestPermission_Title,
                                           subtitle: subtitle)
        }

        let rxInMeetingNotesFG = meetingNotesModel?.rxModel?.map({ [weak meetingNotesModel] (_) -> Bool in
            return meetingNotesModel?.inMeetingNotesFG ?? false
        }).distinctUntilChanged() ?? .just(false)

        Observable
            .combineLatest(rxEvent, rxPermissions, rxInMeetingNotesFG)
            .map(transform)
            .bindRxViewData(to: rxGuestPermissionViewData)
            .disposed(by: disposeBag)
    }

    // MARK: ArrangeDate

    struct ArrangeDateViewData: EventEditArrangeDateViewDataType {
        var isVisible: Bool = false
    }

    private static func isInSameDay(from date1: Date, to date2: Date, in timeZone: TimeZone) -> Bool {
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = timeZone

        // 如果 date2 是 0 时刻（譬如 x 年 x 月 x 日的 00:00:00），且 date1 落后 date2 不超过一天，则不认为跨天
        // eg: date1: 2021-01-01 13:00:00
        //     date2: 2021-01-02 00:00:00
        if Int64(date2.dayStart(calendar: calendar).timeIntervalSince1970) == Int64(date2.timeIntervalSince1970),
           Int64(date2.timeIntervalSince1970 - date1.timeIntervalSince1970) < 86_400 {
            return true
        }
        return calendar.isDate(date1, inSameDayAs: date2)
    }

    private func bindArrangeDateViewData() {
        guard legoInfo.shouldShow(.arrangeDate),
              let rxEvent = eventModel?.rxModel,
              let rxPermissions = permissionModel?.rxModel else { return }
        let map = { [weak self] (eventModel: EventEditModel, permissions: EventEditPermissions) -> ArrangeDateViewData in
            guard let self = self,
                  permissions.attendees.isVisible && permissions.date.isEditable else {
                return .init(isVisible: false)
            }
            // 非 lark 日程不展示
            guard let calendar = eventModel.calendar, calendar.source == .lark else {
                return .init(isVisible: false)
            }
            // 全天日程不展示
            guard !eventModel.isAllDay else {
                return .init(isVisible: false)
            }
            // 跨天日程不展示
            guard Self.isInSameDay(from: eventModel.startDate, to: eventModel.endDate, in: eventModel.timeZone) else {
                return .init(isVisible: false)
            }

            // webinar 日程不展示
            if self.input.isWebinarScene {
                return .init(isVisible: false)
            }

            let separatedAttendeeCount: Int

            if self.hasAllAttendee {
                separatedAttendeeCount = EventEditAttendee.allBreakedUpAttendeeCount(of: eventModel.attendees, individualSimpleAttendees: self.individualSimpleAttendees)
            } else {
                separatedAttendeeCount = Int(eventModel.eventAttendeeStatistics?.totalNo ?? 0)
            }

            guard separatedAttendeeCount > 1 && separatedAttendeeCount <= 30 else {
                return .init(isVisible: false)
            }
            return .init(isVisible: true)
        }

        Observable.combineLatest(rxEvent, rxPermissions)
            .map(map)
            .bindRxViewData(to: rxArrangeDateViewData)
            .disposed(by: disposeBag)
    }

    // MARK: PickDate

    struct PickDateViewData: EventEditPickDateViewData {
        var startDate: Date = Date()
        var endDate: Date = Date()
        var isAllDay: Bool = false
        var is12HourStyle: Bool = false
        var timeZone: TimeZone = .current
        // 编辑页是否展示时区信息
        var isShowTimezone = false
        var isClickable: Bool = false
        // 是否展示AIStyle
        var startDateShowAIStyle: Bool = false
        var endDateShowAIStyle: Bool = false
    }

    // 全天日程的 endDate，如果是 2020.05.21 00:00:00，则调整为前一天的最后一秒
    //   譬如：2020.05.21 00:00:00
    //   调为：2020.05.20 23:59:59
    private static func displayEndDateForAllDay(
        orignalEndDate: Date,
        timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = timeZone
        let startOfDay = calendar.startOfDay(for: orignalEndDate)
        if Int64(startOfDay.timeIntervalSince1970) == Int64(orignalEndDate.timeIntervalSince1970) {
            return orignalEndDate.addingTimeInterval(-1)
        } else {
            return orignalEndDate
        }
    }

    private func bindPickDateViewData() {
        typealias RelatedTuple = (
            eventModel: EventEditModel,
            permissions: EventEditPermissions,
            is12HourStyle: Bool,
            timezoneDisplayType: TimezoneDisplayType,
            timeZoneViewData: EventEditTimeZoneViewData
        )
        let transform = { (tuple: RelatedTuple) -> PickDateViewData in
            let (eventModel, permissions, is12HourStyle, timezoneDisplayType, timezoneData) = tuple
            var fixedEndDate = eventModel.endDate
            if eventModel.isAllDay {
                fixedEndDate = Self.displayEndDateForAllDay(
                    orignalEndDate: fixedEndDate,
                    timeZone: eventModel.timeZone
                )
            }
            
            return PickDateViewData(
                startDate: eventModel.startDate,
                endDate: fixedEndDate,
                isAllDay: eventModel.isAllDay,
                is12HourStyle: is12HourStyle,
                timeZone: timezoneDisplayType == .eventTimezone ? eventModel.timeZone : TimeZone.current,
                isShowTimezone: timezoneData.isVisible && !timezoneData.timeZoneName.isEmpty,
                isClickable: permissions.date.isEditable,
                startDateShowAIStyle: eventModel.aiStyleInfo.time.startTime,
                endDateShowAIStyle: eventModel.aiStyleInfo.time.endTime
            )
        }

        guard let rxEvent = eventModel?.rxModel,
              let rxPermissions = permissionModel?.rxPermissions else { return }
        Observable.combineLatest(rxEvent, rxPermissions, rxIs12HourStyle, rxTimezoneDisplayType, rxTimeZoneViewData)
            .map { transform($0) }
            .bindRxViewData(to: rxPickDateViewData)
            .disposed(by: disposeBag)
    }

    // MARK: TimeZone Tip

    var rxAttendeeViewDataWithTimeZone: BehaviorRelay<AttendeeData>? {
        if input.isWebinarScene {
           return webinarAttendeeModel?.rxAllAttendeeData
        } else {
            return attendeeModel?.rxAttendeeData
        }
    }

    struct TimeZoneViewData: EventEditTimeZoneViewData {
        var timeZoneName: String = ""
        var timeZoneTip: String?
        var isClickable: Bool = false
        var isVisible: Bool = false
        var timezoneDiffTip: String?
    }

    private func bindTimeZoneViewData() {
        guard legoInfo.shouldShow(.timeZone) else { return }
        typealias RelatedTuple = (
            eventModel: EventEditModel,
            attendeeViewData: AttendeeData,
            permissions: EventEditPermissions,
            timezoneDisplayType: TimezoneDisplayType,
            is12HourStyle: Bool
        )

        let transform = { [weak self] (tuple: RelatedTuple) -> TimeZoneViewData in
            let (eventModel, attendeeViewData, permissions, timezoneDisplayType, is12HourStyle) = tuple
            guard !eventModel.isAllDay, let self = self else {
                return .init(
                    timeZoneName: "",
                    timeZoneTip: nil,
                    isClickable: false,
                    isVisible: false
                )
            }
            var tip: String?
            if CalConfig.isMultiTimeZone &&
                permissions.date.isEditable &&
                attendeeViewData.breakUpAttendeeCount < self.attendeeTimeZoneEnableLimit {
                let currentUserId = self.userResolver.userID
                // 过滤当前用户：上层拿到的timezone是对外展示时区，不适用于本业务场景
                func getAttendeesFilterCurrentUser(_ data: AttendeeData) -> [EventEditAttendee] {
                    data.visibleAttendees.filter { attendee in
                        if case .user(let userAttendee) = attendee, userAttendee.chatterId == currentUserId {
                            return false
                        }
                        return true
                    }
                }
                var timeZones = EventEditAttendee.allUserAttendees(of: getAttendeesFilterCurrentUser(attendeeViewData))
                    .map { $0.timeZone }
                // 上面结果里过滤了当前用户，这里额外添加上用户的设备时区
                timeZones.append(TimeZone.current)
                let groupedSet = TimeZoneUtil.groupedGmtOffset(for: timeZones).filter { $0 != TimeZoneUtil.HiddenOffsetFlag }
                if groupedSet.count > 1 {
                    tip = BundleI18n.Calendar.Calendar_Timezone_Alert
                }
            }
            let opt = Options(timeZone: timezoneDisplayType == .deviceTimezone ? eventModel.timeZone : .current,
                              is12HourStyle: is12HourStyle,
                              shouldShowGMT: true,
                              timePrecisionType: .minute,
                              datePrecisionType: .day)
            let timedate = CalendarTimeFormatter.formatTimeOrDateTimeRange(startFrom: eventModel.startDate,
                                                                           endAt: eventModel.endDate,
                                                                           mirrorTimezone: (timezoneDisplayType == .deviceTimezone) ? TimeZone.current : eventModel.timeZone,
                                                                           with: opt)
            let displayedTimezone: TimeZone = timezoneDisplayType == .deviceTimezone ? .current : eventModel.timeZone
            let timezoneDiffTip = timezoneDisplayType == .deviceTimezone ? BundleI18n.Calendar.Calendar_G_InEventTimeZone : BundleI18n.Calendar.Calendar_G_InDeviceTimeZone
            return .init(
                timeZoneName: displayedTimezone.standardName(for: eventModel.startDate),
                timeZoneTip: tip,
                isClickable: permissions.date.isEditable,
                isVisible: true,
                timezoneDiffTip: self.areTimezonesDifferent ? "\(timezoneDiffTip) \(timedate)" : nil  // + formatted time
            )
        }

        guard let rxEventModel = eventModel?.rxModel,
              let rxAttendeeData = rxAttendeeViewDataWithTimeZone,
              let rxPermissions = permissionModel?.rxPermissions else { return }
        Observable.combineLatest(rxEventModel, rxAttendeeData, rxPermissions, rxTimezoneDisplayType, rxIs12HourStyle)
            .map { transform($0) }
            .bindRxViewData(to: rxTimeZoneViewData)
            .disposed(by: disposeBag)
    }

    // MARK: - VideoMeeting
    struct VideoMeetingData: EventEditVideoMeetingViewDataType {
        var title: String = ""
        var isOpen: Bool = false
        var editable: Bool = false
        var isVisible: Bool = false
        var isShowSetting: Bool = false
        var videoIcon: UIImage = UDIcon.getIconByKeyNoLimitSize(.livestreamOutlined).renderColor(with: .n3)
        var zoomConfig: Rust.ZoomVideoMeetingConfigs?
        var videoType: VideoItemType = .unknown
    }

    private func bindVideoMeetingViewData() {
        guard legoInfo.shouldShow(.videoMeeting) else { return }
        let shouldShowSetting = self.legoInfo.shouldShow(.larkVideoMeetingSetting)
        let transform = { (editModel: EventEditModel, permissions: EventEditPermissions) -> VideoMeetingData in
            let videoMeeting = editModel.videoMeeting

            let isOpen = videoMeeting.videoMeetingType != .noVideoMeeting
            let title: String

            if videoMeeting.videoMeetingType == .noVideoMeeting {
                title = I18n.Calendar_Edit_AddVC
            } else if videoMeeting.videoMeetingType == .vchat {
                title = I18n.Calendar_Edit_FeishuVC()
            } else if videoMeeting.videoMeetingType == .zoomVideoMeeting {
                title = I18n.Calendar_Settings_ZoomMeet
            } else {
                title = I18n.Calendar_Edit_OtherVC
            }

            var videoType: VideoItemType = .unknown
            switch videoMeeting.videoMeetingType {
            case .zoomVideoMeeting:
                videoType = .zoom
            case .vchat:
                videoType = .feishu
            @unknown default:
                videoType = .custom
                break
            }

            let isShowSetting = shouldShowSetting && (videoMeeting.videoMeetingType == .vchat || videoMeeting.videoMeetingType == .zoomVideoMeeting)
            let originIcon = videoMeeting.videoMeetingIconType.iconGary
            let videoIcon = permissions.videoMeeting.isEditable ? originIcon : originIcon.renderColor(with: .n4)
            let data = VideoMeetingData(title: title,
                                        isOpen: isOpen,
                                        editable: permissions.videoMeeting.isEditable,
                                        isVisible: permissions.videoMeeting.isVisible,
                                        isShowSetting: isShowSetting,
                                        videoIcon: videoIcon,
                                        zoomConfig: videoMeeting.zoomConfigs,
                                        videoType: videoType)
            return data
        }

        guard let rxEventModel = eventModel?.rxModel,
              let rxPermissions = permissionModel?.rxPermissions else { return }
        Observable.combineLatest(rxEventModel, rxPermissions)
            .map { transform($0.0, $0.1) }
            .bindRxViewData(to: rxVideoMeetingViewData)
            .disposed(by: disposeBag)
    }

    // MARK: - Calendar
    struct CalendarViewData: EventEditCalendarViewDataType {
        var title: String = ""
        var subtitle: String?
        var flag: [EventEditCalendarFlagType]?
        var color: UIColor = .white
        var isVisible: Bool = false
        var isEditable: Bool = false
    }
    private func bindCalendarViewData() {
        guard legoInfo.shouldShow(.calendar) else { return }
        let transform = { [weak self] (eventModel: EventEditModel, permissions: EventEditPermissions) -> CalendarViewData in
            guard let self = self,
                  let calendar = eventModel.calendar,
                  let userTenantId = self.calendarDependency?.currentUser.tenantId else {
                return CalendarViewData(
                    title: "",
                    subtitle: nil,
                    flag: nil,
                    color: .clear,
                    isVisible: false,
                    isEditable: false
                )
            }
            var flag: [EventEditCalendarFlagType] = []

            var subtitle: String?
            if case .exchange = calendar.source {
                subtitle = calendar.emailAddress
            }

            let successorChatterID = calendar.getPBModel().successorChatterID
            let isResigned = !(successorChatterID.isEmpty || successorChatterID == "0") && calendar.getPBModel().type == .other
            let isExternal = calendar.getPBModel().cd.isExternalCalendar(userTenantId: userTenantId)

            // 几种 flag 不可能同时出现
            if case .google = calendar.source {
                flag.append(.threeParty(UDIcon.getIconByKeyNoLimitSize(.googleColorful)))
            } else if case .exchange = calendar.source {
                flag.append(.threeParty(UDIcon.getIconByKeyNoLimitSize(.exchangeColorful)))
            } else {
                if isResigned { flag.append(.resigned) }
                if isExternal { flag.append(.external) }
            }

            return CalendarViewData(
                title: calendar.name,
                subtitle: subtitle,
                flag: flag,
                color: SkinColorHelper.pickerColor(of: calendar.color.rawValue),
                isVisible: permissions.calendar.isVisible,
                // 有一个奇怪的交互逻辑：即便 calendar 不可编辑，但是仍然可以点击进入二级页面
                isEditable: permissions.calendar.isEditable
            )
        }

        guard let rxEventModel = eventModel?.rxModel,
              let rxPermissions = permissionModel?.rxPermissions else { return }
        Observable.combineLatest(rxEventModel, rxPermissions)
            .map { transform($0.0, $0.1) }
            .bindRxViewData(to: rxCalendarViewData)
            .disposed(by: disposeBag)
    }

    struct ColorViewData: EventEditColorViewDataType {
        var color: UIColor = .white
        var isVisible: Bool = false
        var isEditable: Bool = false
    }

    private func bindColorViewData() {
        guard legoInfo.shouldShow(.color) else { return }
        let transform = { (eventModel: EventEditModel, permissions: EventEditPermissions) -> ColorViewData in
            guard let colorIndex = eventModel.color?.rawValue else {
                return ColorViewData(
                    color: .clear,
                    isVisible: permissions.color.isVisible,
                    isEditable: permissions.color.isEditable
                )
            }
            return ColorViewData(
                color: SkinColorHelper.pickerColor(of: colorIndex),
                isVisible: permissions.color.isVisible,
                isEditable: permissions.color.isEditable
            )
        }

        guard let rxEventModel = eventModel?.rxModel,
              let rxPermissions = permissionModel?.rxPermissions else { return }
        Observable.combineLatest(rxEventModel, rxPermissions)
            .map { transform($0.0, $0.1) }
            .bindRxViewData(to: rxColorViewData)
            .disposed(by: disposeBag)
    }

    // MARK: Visibility

    struct VisibilityViewData: EventEditVisibilityViewDataType {
        var title: String = ""
        var isVisible: Bool = false
        var isEditable: Bool = false
    }

    private func bindVisibilityViewData() {
        guard legoInfo.shouldShow(.visibility) else { return }
        let transform = { (eventModel: EventEditModel, permissions: EventEditPermissions) -> VisibilityViewData in
            let visibilityStr: String
            switch eventModel.visibility {
            case .default: visibilityStr = BundleI18n.Calendar.Calendar_Edit_DefalutVisibility
            case .public: visibilityStr = BundleI18n.Calendar.Calendar_Edit_Public
            case .private: visibilityStr = BundleI18n.Calendar.Calendar_Edit_Private
            }
            return VisibilityViewData(
                title: visibilityStr,
                isVisible: permissions.visibility.isVisible,
                isEditable: permissions.visibility.isEditable
            )
        }

        guard let rxEventModel = eventModel?.rxModel,
              let rxPermissions = permissionModel?.rxPermissions else { return }
        Observable.combineLatest(rxEventModel, rxPermissions)
            .map { transform($0.0, $0.1) }
            .bindRxViewData(to: rxVisibilityViewData)
            .disposed(by: disposeBag)
    }

    // MARK: FreeBusy

    struct FreeBusyViewData: EventEditFreeBusyViewDataType {
        var title: String = ""
        var isVisible: Bool = false
        var isEditable: Bool = false
    }

    private func bindFreeBusyViewData() {
        guard legoInfo.shouldShow(.freebusy) else { return }
        let transform = { (eventModel: EventEditModel, permissions: EventEditPermissions) -> FreeBusyViewData in
            let freeBusyStr: String
            switch eventModel.freeBusy {
            case .busy: freeBusyStr = BundleI18n.Calendar.Calendar_Detail_Busy
            case .free: freeBusyStr = BundleI18n.Calendar.Calendar_Detail_Free
            }
            return FreeBusyViewData(
                title: freeBusyStr,
                isVisible: permissions.freeBusy.isVisible,
                isEditable: permissions.freeBusy.isEditable
            )
        }

        guard let rxEventModel = eventModel?.rxModel,
              let rxPermissions = permissionModel?.rxPermissions else { return }
        Observable.combineLatest(rxEventModel, rxPermissions)
            .map { transform($0.0, $0.1) }
            .bindRxViewData(to: rxFreeBusyViewData)
            .disposed(by: disposeBag)
    }

    // MARK: MeetingRoom
    struct MeetingRoomItemViewData: EventEditMeetingRoomItemDataType {
        var name: String
        var canDelete: Bool
        var isDisabled: Bool = false
        var needsApproval: Bool = false
        var conditionalApproval: Bool
        var isValid: Bool = true
        var resourceCustomization: Rust.ResourceCustomization?
        var hasForm: Bool { resourceCustomization != nil }
        var formIsEmpty: Bool {
            if let form = resourceCustomization?.customizationData {
                var formIsEmpty = true
                form.forEach { question in
                    switch question.customizationType {
                    case .singleSelect, .multipleSelect:
                        if question.options.contains(where: { $0.isSelected }) {
                            formIsEmpty = false
                            return
                        }
                    case .input:
                        if !question.inputContent.isEmpty {
                            formIsEmpty = false
                        }
                    @unknown default:
                        break
                    }
                }
                return formIsEmpty
            } else {
                return true
            }
        }
        var nameNotGray: Bool = true
        var formCompleted: Bool = true
        var invalidReasons: [String] = []
        var shouldShowAIStyle: Bool = false
        var shouldShowBluetooth: Bool = false
    }

    struct MeetingRoomViewData: EventEditMeetingRoomViewDataType {
        var items: [EventEditMeetingRoomItemDataType] = []
        var isVisible: Bool = false
        var isEditable: Bool = false
        // 添加会议室标题的颜色
        var addRoomTitleColor: UIColor = UDColor.textPlaceholder
    }

    private func unusableReasonMap(
        meetingRooms: [CalendarMeetingRoom],
        eventInfo: (startTime: Date, endTime: Date, rrule: EventRecurrenceRule?),
        eventOriginalTime: Int64,
        eventStartTimezone: String,
        eventUniqueFields: Server.CalendarEventUniqueField?
    ) -> Observable<Server.UnusableReasonMap> {

        guard !meetingRooms.isEmpty else { return .just([:]) }
        let rRuleStr = eventInfo.rrule?.iCalendarString() ?? ""

        guard let api = calendarApi else { return .empty() }

        let serverResponse = api.getMeetingRoomReserveStatusFromServer(
            startTime: eventInfo.startTime, endTime: eventInfo.endTime,
            eventRrule: rRuleStr, startTimezone: eventStartTimezone,
            roomCalendarIDs: meetingRooms.map(\.uniqueId),
            eventUniqueFields: eventUniqueFields
        ).map { $0.mapValues(\.unusableReasons.unusableReasons) }

        let resourceStatusInfoArray = meetingRooms.map { (resource) -> Rust.ResourceStatusInfo in
            var info = Rust.ResourceStatusInfo()
            info.calendarID = resource.uniqueId
            if let resourceStrategy = resource.resourceStrategy {
                info.resourceStrategy = resourceStrategy
            }
            if let resourceRequisition = resource.resourceRequisition {
                info.resourceRequisition = resourceRequisition
            }
            if let resourceApprovalInfo = resource.getPBModel().schemaExtraData.cd.resourceApprovalInfo {
                info.resourceApproval = resourceApprovalInfo
            }
            return info
        }

        let sdkResponse = api.getUnusableMeetingRooms(
            startDate: eventInfo.startTime,
            endDate: eventInfo.endTime,
            eventRRule: rRuleStr,
            eventOriginTime: eventOriginalTime,
            resourceStatusInfoArray: resourceStatusInfoArray
        ).map { sdkReasonsDic in
            sdkReasonsDic.mapValues { reasons in
                reasons.unusableReasons.map { reason -> Server.MeetingRoomUnusableReasonType in
                    switch reason {
                    case .beforeEarliestBookTime: return .beforeEarliestBookTime
                    case .duringRequisition: return .duringRequisition
                    case .notInUsableTime: return .notInUsableTime
                    case .overMaxDuration: return .overMaxDuration
                    case .pastTime: return .pastTime
                    case .recurrentEventDurationTriggersApproval: return .cantReserveOverTime
                    case .overMaxUntilTime: return .overMaxUntilTime
                    @unknown default: return .unknownUnusableReason
                    }
                }
            }
        }

        return Observable.merge(sdkResponse, serverResponse).catchError { error in
            print(error)
            return .empty()
        }.observeOn(MainScheduler.instance)
    }

    private func bindMeetingRoomViewData() {
        guard legoInfo.shouldShow(.meetingRoom) else { return }
        typealias RelatedTriple = (
            eventModel: EventEditModel,
            meetingRooms: [CalendarMeetingRoom],
            permissions: EventEditPermissions
        )
        let transform = { (triple: RelatedTriple, is12HourStyle: Bool, unusableReasonMap: Server.UnusableReasonMap, trigerReserve: Bool) -> MeetingRoomViewData in

            let permissions = triple.permissions
            let meetingRooms = triple.meetingRooms.filter { $0.status != .removed }
            let items: [MeetingRoomItemViewData] = meetingRooms.map {
                // 如果既有重复性又触发了条件审批 会议室不可用
                let duration = Int64(triple.eventModel.endDate.timeIntervalSince(triple.eventModel.startDate))
                let conditionalApproval = $0.shouldTriggerApproval(duration: duration)

                let reasons = unusableReasonMap[$0.uniqueId] ?? []
                let isValid = ($0.status == .accept && !trigerReserve) ? true : (reasons.isEmpty && !$0.conflictWithRrule(rrule: triple.0.rrule)) // 未修改状态下的已预订成功会议室始终认为有效

                var reasonsStr = [String]()
                if !isValid {
                    reasonsStr = ScrollableAlertMessage.contents(
                        from: reasons, by: $0,
                        startDate: triple.eventModel.startDate, endDate: triple.eventModel.endDate,
                        is12HourStyle: is12HourStyle, timeZone: triple.eventModel.timeZone
                    )
                }

                var canDelete: Bool = min($0.permission, permissions.meetingRooms).isEditable
                if $0.resourceCustomization != nil,
                   permissions.meetingRoomsForm.isReadOnly {
                    canDelete = false
                }
                let nameNotGray: Bool = triple.eventModel.isEditable

                let attendeeCalendarID = $0.getPBModel().attendeeCalendarID
                let roomInfo = self.eventModel?.rxModel?.value.aiStyleInfo.meetingRoom.filter {
                    $0.resourceID == attendeeCalendarID
                }

                return MeetingRoomItemViewData(
                    name: $0.fullName,
                    canDelete: canDelete,
                    isDisabled: $0.isDisabled,
                    needsApproval: $0.needsApproval,
                    conditionalApproval: conditionalApproval,
                    isValid: isValid,
                    resourceCustomization: $0.resourceCustomization,
                    nameNotGray: nameNotGray,
                    formCompleted: ($0.resourceCustomization == nil) || $0.formCompleted,
                    invalidReasons: reasonsStr,
                    shouldShowAIStyle: roomInfo?.isEmpty == false,
                    shouldShowBluetooth: roomInfo?.first?.resourceType == .bleResource
                )
            }
            let addRoomTitleColor: UIColor
            // 有权限并且无会议室的时候为蓝色
            if permissions.meetingRooms.isEditable && items.isEmpty && triple.eventModel.isEditable == true {
                addRoomTitleColor = EventEditUIStyle.Color.blueText
            } else {
                addRoomTitleColor = UDColor.functionInfoContentDefault
            }

            return MeetingRoomViewData(
                items: items,
                isVisible: items.isEmpty ? permissions.meetingRooms.isEditable : permissions.meetingRooms.isVisible,
                isEditable: permissions.meetingRooms.isEditable,
                addRoomTitleColor: addRoomTitleColor
            )
        }

        guard let rxEventModel = eventModel?.rxModel,
              let rxMeetingRooms = meetingRoomModel?.rxMeetingRooms,
              let rxPermissions = permissionModel?.rxPermissions else { return }

        let rxRelatedChanged = rxEventModel.distinctUntilChanged { (e1, e2) in
            let e1 = e1.getPBModel()
            let e2 = e2.getPBModel()
            let rruleChanged = self.checkChangedForRrule(with: e1, and: e2)
            let dateChanged = self.checkChangedForDate(with: e1, and: e2)
            return !(rruleChanged || dateChanged)
        }

        Observable.combineLatest(
            rxRelatedChanged, rxMeetingRooms,
            rxPermissions, rxIs12HourStyle, rxEventDateOrRruleChanged
        ).flatMapLatest { [weak self] (eventModel, meetingRooms, permission, is12HourStyle, hasChanged) -> Observable<EventEditMeetingRoomViewDataType> in
            guard let self = self else { return .empty() }
            let tripleSource = (eventModel, meetingRooms, permission)

            var uniqueFields: Server.CalendarEventUniqueField?
            let eventPB = eventModel.getPBModel()
            if !self.input.isFromCreating {
                var fields = Server.CalendarEventUniqueField()
                fields.calendarID = eventPB.calendarID
                fields.originalTime = String(eventPB.originalTime)
                fields.key = eventPB.key
                uniqueFields = fields
            }

            return self.unusableReasonMap(
                meetingRooms: meetingRooms,
                eventInfo: (eventModel.startDate, eventModel.endDate, eventModel.rrule),
                eventOriginalTime: eventPB.originalTime,
                eventStartTimezone: eventPB.startTimezone,
                eventUniqueFields: uniqueFields
            ).map { transform(tripleSource, is12HourStyle, $0, hasChanged) }
        }
        .bindRxViewData(to: rxMeetingRoomViewData)
        .disposed(by: disposeBag)
    }

    // MARK: Location

    struct LocationViewData: EventEditLocationViewDataType {
        var title: String = ""
        var isVisible: Bool = false
        var isEditable: Bool = false
    }

    private func bindLocationViewData() {
        guard legoInfo.shouldShow(.location) else { return }
        let transform = { (eventModel: EventEditModel, permissions: EventEditPermissions) -> LocationViewData in
            guard let locationName = eventModel.location?.name, !locationName.isEmpty else {
                return LocationViewData(
                    title: "",
                    isVisible: permissions.location.isEditable,
                    isEditable: permissions.location.isEditable
                )
            }
            return LocationViewData(
                title: locationName,
                isVisible: permissions.location.isVisible,
                isEditable: permissions.location.isEditable
            )
        }

        guard let rxEventModel = eventModel?.rxModel,
              let rxPermissions = permissionModel?.rxPermissions else { return }
        Observable.combineLatest(rxEventModel, rxPermissions)
            .map { transform($0.0, $0.1) }
            .bindRxViewData(to: rxLocationViewData)
            .disposed(by: disposeBag)
    }

    // MARK: CheckIn

    struct CheckInViewData: EventEditCheckInViewDataType {
        var title: String = ""
        var isVisible: Bool = false
        var isEditable: Bool = false
        var isValid: Bool = false
        var errorText: String = ""
    }

    private func bindCheckInViewData() {
        guard let rxEventModel = eventModel?.rxModel,
              let rxPermission = permissionModel?.rxPermissions,
              legoInfo.shouldShow(.checkIn) else { return }

        let transform = { [weak self] (event: EventEditModel, permission: EventEditPermissions) -> CheckInViewData in
            guard let self = self,
                  event.checkInConfig.checkInEnable else {
                return CheckInViewData(
                    title: I18n.Calendar_Event_NoCheckInRequire,
                    isVisible: permission.checkIn.isEditable,
                    isEditable: permission.checkIn.isEditable,
                    isValid: true)
            }
            let checkInConfig = event.checkInConfig
            let checkInDates = checkInConfig.getCheckInDate(startDate: event.startDate, endDate: event.endDate)
            let isValid = checkInConfig.startAndEndTimeIsValid(startDate: event.startDate, endDate: event.endDate)
            let errorText = isValid ? "" : I18n.Calendar_Event_CheckInTimeError

            let options = Options(timeZone: TimeZone.current,
                                  is12HourStyle: self.rxIs12HourStyle.value,
                                  shouldShowGMT: true,
                                  timeFormatType: .long,
                                  timePrecisionType: .minute,
                                  datePrecisionType: .day,
                                  dateStatusType: .absolute,
                                  shouldRemoveTrailingZeros: false)
            let title = CalendarTimeFormatter.formatFullDateTimeRange(startFrom: checkInDates.startDate, endAt: checkInDates.endDate, isAllDayEvent: event.isAllDay, shouldTextInOneLine: true, shouldShowTailingGMT: false, with: options)
            return CheckInViewData(title: I18n.Calendar_Event_DateTimeCanCheckIn(time: title),
                                   isVisible: permission.checkIn.isVisible,
                                   isEditable: permission.checkIn.isEditable,
                                   isValid: isValid,
                                   errorText: errorText)

        }
        Observable.combineLatest(rxEventModel, rxPermission)
            .map { transform($0.0, $0.1) }
            .bindRxViewData(to: rxCheckInViewData)
            .disposed(by: disposeBag)
    }

    // MARK: Reminder

    struct ReminderViewData: EventEditReminderViewDataType {
        var title: String = ""
        var isVisible: Bool = false
        var isEditable: Bool = false
        var outOfRangeText: String = ""
    }

    private func bindReminderViewData() {
        guard legoInfo.shouldShow(.reminder) else { return }
        typealias RelatedTuple = (
            eventModel: EventEditModel,
            permissions: EventEditPermissions,
            is12HourStyle: Bool
        )
        let transform = { (tuple: RelatedTuple) -> ReminderViewData in
            let (eventModel, permissions, is12HourStyle) = tuple
            let divideSymbol = I18n.Calendar_Common_DivideSymbol
            var title = eventModel.reminders
                .map {
                    $0.toReminderString(
                        isAllDay: eventModel.isAllDay,
                        is12HourStyle: is12HourStyle
                    )
                }
                .joined(separator: divideSymbol)
            title = title.isEmpty ? I18n.Calendar_Common_NoAlerts : title + "\(divideSymbol)\(I18n.Calendar_Detail_RemindMeLengthMobile)"
            let outOfRangeText = "...\(divideSymbol)\(I18n.Calendar_Detail_RemindMeLengthMobile)"
            return ReminderViewData(
                title: title,
                isVisible: eventModel.reminders.isEmpty ? permissions.reminders.isEditable : permissions.reminders.isVisible,
                isEditable: permissions.reminders.isEditable,
                outOfRangeText: outOfRangeText
            )
        }

        guard let rxEventModel = eventModel?.rxModel,
              let rxPermissions = permissionModel?.rxPermissions else { return }
        Observable.combineLatest(rxEventModel, rxPermissions, rxIs12HourStyle)
            .map { transform($0) }
            .bindRxViewData(to: rxReminderViewData)
            .disposed(by: disposeBag)
    }

    // MARK: Rrule
    struct RruleViewData: EventEditRruleViewDataType {
        var isVisible: Bool = false
        var ruleStr: String = ""
        var isRuleEditable: Bool = false
        var isShowArrow: Bool = true
        var endDateIsVisible: Bool = true
        var endDateStr: String = ""
        var isEndDateValid: Bool = false
        var isEndDateEditable: Bool = false
        var shouldShowTip: Bool = false
        var tipStr: String = ""
        var isTipClickable: Bool = false
        var notEditReason: NotEditReason = .none
        var rruleShowAIStyle: Bool = false
        var endDateShowAIStyle: Bool = false
    }
    
    // 不可编辑的原因
    enum NotEditReason {
        case none
        // 会议室审批
        case meetingRoomApproval
        // 日程参与者超过x人不支持转为重复性日程
        case fullEventNoConvertRecur(_ count: Int)
        
        var isValidReason: Bool {
            if case .none = self {
                return false
            }
            return true
        }
    }

    private func endDateDesc(ofRrule rrule: EventRecurrenceRule, timezone: String) -> String {
        guard rrule.recurrenceEnd != nil else {
            return BundleI18n.Calendar.Calendar_RRule_NeverEnds
        }
        return rrule.getReadableRecurrenceEndString(timezone: timezone)
    }

    func isRruleEndDateValid(
        of rrule: EventRecurrenceRule,
        by startDate: Date,
        model: EventEditModel?
    ) -> Bool {
        if let (_, maxEndDate) = meetingRoomMaxEndDateInfoWithModel(model) {
            // 有会议室的情况
            // 优先判断会议室可预定最远范围是否早于日程开始时间
            if maxEndDate < startDate {
                return false
            } else if let endDate = rrule.recurrenceEnd?.endDate {
                // 有截止日期的情况
                let dayEnd = endDate.dayEnd()
                if dayEnd < startDate {
                    return false
                } else {
                    // 会议室最长可预定的日期与重复性规则截止日期是否冲突
                    return dayEnd <= maxEndDate.dayEnd()
                }
            } else {
                // 无截止日期的情况
                return false
            }
        } else {
            // 无会议室的情况
            if let endDate = rrule.recurrenceEnd?.endDate {
                // 有截止日期的情况
                return startDate < endDate.dayEnd()
            } else {
                // 无截止日期的情况
                return true
            }
        }
    }

    func getDateInvalidWarningDescription(by startDate: Date, model: EventEditModel) -> String {
        guard let (name, maxEndDate) = meetingRoomMaxEndDateInfoWithModel(model) else { return "" }
        let timezone: TimeZone
        if FG.calendarRoomsReservationTime {
            timezone = TimeZone(identifier: self.rxPickDateViewData.value.timeZone.identifier) ?? .current
        } else {
            timezone = .current
        }
        let customOptions = Options(
            timeZone: timezone,
            timeFormatType: .long,
            datePrecisionType: .day
        )
        let amount = self.selectedMeetingRooms.count
        let dateStr = TimeFormatUtils.formatDate(from: maxEndDate, with: customOptions)
        return RruleInvalidWarningType.meetingRoomReservableDateEarlierThanStartDate(
            amount > 1 ? .some(name) : .one,
            dateStr
        ).readableStr
    }

    func rruleInvalidWarningType(
        of rrule: EventRecurrenceRule,
        model: EventEditModel
    ) -> RruleInvalidWarningType {
        // 涉及会议室的提示文案根据会议室个数而异
        let startDate = model.startDate
        if let (name, maxEndDate) = meetingRoomMaxEndDateInfoWithModel(model) {
            // 有会议室的情况
            // FG打开使用使用日程时区，否则系统时区
            let timezone: TimeZone
            if FG.calendarRoomsReservationTime {
                timezone = TimeZone(identifier: self.rxPickDateViewData.value.timeZone.identifier) ?? .current
            } else {
                timezone = .current
            }
            let customOptions = Options(
                timeZone: timezone,
                timeFormatType: .long,
                datePrecisionType: .day
            )
            let dateStr = TimeFormatUtils.formatDate(from: maxEndDate, with: customOptions)
            let amount = self.selectedMeetingRooms.count
            if maxEndDate < startDate {
                return .meetingRoomReservableDateEarlierThanStartDate(
                    amount > 1 ? .some(name) : .one,
                    dateStr
                )
            } else if let endDate = rrule.recurrenceEnd?.endDate {
                // 有截止日期的情况
                if endDate.dayEnd() < startDate {
                    return .startDateLaterThanDueDate
                } else {
                    return .meetingRoomReservableDateEarlierThanDueDate(
                        amount > 1 ? .some(name) : .one,
                        dateStr
                    )
                }
            } else {
                // 无截止日期的情况
                return .meetingRoomReservableDateEarlierThanDueDate(
                    amount > 1 ? .some(name) : .one,
                    dateStr
                )
            }
        } else {
            // 无会议室的情况
            return .startDateLaterThanDueDate
        }
    }

    private func isEndDateCompatible(ofRrule rrule: EventRecurrenceRule) -> Bool {
        if let recurrenceEnd = rrule.recurrenceEnd, recurrenceEnd.occurrenceCount != 0 {
            return false
        }
        return true
    }

    private func bindRruleViewData() {
        guard legoInfo.shouldShow(.rrule) else { return }
        let transform = { [weak self] (eventModel: EventEditModel,
                                       permissions: EventEditPermissions,
                                       totalAttendeeNum: Int,
                                       calendar: EventEditCalendar?,
                                       hasChanged: Bool,
                                       meetingRoomViewData: EventEditMeetingRoomViewDataType) -> RruleViewData in
            guard let self = self else {
                return RruleViewData(
                    isVisible: false,
                    ruleStr: I18n.Calendar_Detail_NoRepeat,
                    isRuleEditable: false,
                    isShowArrow: false,
                    endDateIsVisible: false,
                    endDateStr: "",
                    isEndDateValid: false,
                    isEndDateEditable: false,
                    shouldShowTip: false,
                    tipStr: "",
                    isTipClickable: false,
                    notEditReason: .none
                )
            }
            guard let rrule = eventModel.rrule else {
                var warningString: String = ""
                var isEndDateValid = true
                if let (_, maxEndDate) = self.meetingRoomMaxEndDateInfoWithModel(eventModel) {
                    if maxEndDate < eventModel.startDate {
                        isEndDateValid = false
                        warningString = self.getDateInvalidWarningDescription(by: eventModel.startDate, model: eventModel)
                    }
                }
                let meetingRoomIsApproval = meetingRoomViewData.items.contains(where: { $0.needsApproval || $0.conditionalApproval })
                // 未设置rrule场景
                if eventModel.span == .noneSpan {
                    var notEditReason: NotEditReason = .none
                    if meetingRoomIsApproval  {
                        notEditReason = .meetingRoomApproval
                    } else if case .reachRecurEventLimit(let limit) = EventEditAttendeeManager.attendeesUpperLimitReason(
                                        count: totalAttendeeNum,
                                        calendar: calendar,
                                        attendeeMaxCountControlled: false, isEventCreator: false,
                                        isRecurEvent: true) {
                        notEditReason = .fullEventNoConvertRecur(limit)
                    }
                    return RruleViewData(
                        isVisible: permissions.rrule.isEditable,
                        ruleStr: I18n.Calendar_Detail_NoRepeat,
                        isRuleEditable: notEditReason.isValidReason == false,
                        isShowArrow: true,
                        endDateIsVisible: false,
                        endDateStr: "",
                        isEndDateValid: false,
                        isEndDateEditable: false,
                        shouldShowTip: !isEndDateValid,
                        tipStr: warningString,
                        isTipClickable: false,
                        notEditReason: notEditReason
                    )
                }
                let isThisSpan = eventModel.span == .thisEvent
                return RruleViewData(
                    isVisible: permissions.rrule.isVisible,
                    ruleStr: I18n.Calendar_Detail_NoRepeat,
                    isRuleEditable: false,
                    isShowArrow: !isThisSpan,
                    endDateIsVisible: false,
                    endDateStr: "",
                    isEndDateValid: false,
                    isEndDateEditable: false,
                    shouldShowTip: !isEndDateValid,
                    tipStr: warningString,
                    isTipClickable: false,
                    notEditReason: .none
                )
            }
            // 编辑前置下重复性日程不再可以删除 rrule
            let isShowArrow = ![.futureEvents, .allEvents].contains(eventModel.span)
            // 在会议室可预定时长改变后，针对存量的已经预定成功的日程，若其日程时间、rrule、meetingRoom未发生变化
            // 则不会显示rrule warning
            if self.input.isFromCreating && self.input.isFromAI {}
            else {
                guard hasChanged else {
                    return RruleViewData(
                        isVisible: permissions.rrule.isVisible,
                        ruleStr: rrule.getReadableRecurrenceRepeatString(timezone: eventModel.timeZone.identifier),
                        isRuleEditable: permissions.rrule.isEditable,
                        isShowArrow: isShowArrow,
                        endDateStr: self.endDateDesc(ofRrule: rrule, timezone: eventModel.timeZone.identifier),
                        isEndDateValid: true,
                        isEndDateEditable: self.isEndDateCompatible(ofRrule: rrule) && permissions.rrule.isEditable,
                        shouldShowTip: false,
                        tipStr: "",
                        isTipClickable: false
                    )
                }
            }
            var warningType: RruleInvalidWarningType?

            // Feature: 没有编辑权限的日程也支持保存会议室，即使截止日期与重复性规则冲突也不变色
            guard permissions.rrule.isEditable else {
                return RruleViewData(
                    isVisible: permissions.rrule.isVisible,
                    ruleStr: rrule.getReadableRecurrenceRepeatString(timezone: eventModel.timeZone.identifier),
                    isRuleEditable: permissions.rrule.isEditable,
                    isShowArrow: isShowArrow,
                    endDateStr: self.endDateDesc(ofRrule: rrule, timezone: eventModel.timeZone.identifier),
                    isEndDateValid: true,
                    isEndDateEditable: false,
                    shouldShowTip: false,
                    tipStr: "",
                    isTipClickable: false
                )
            }
            let isEndDateValid = self.isRruleEndDateValid(
                of: rrule,
                by: eventModel.startDate,
                model: eventModel
            )

            if !isEndDateValid {
                warningType = self.rruleInvalidWarningType(
                    of: rrule,
                    model: eventModel
                )
            }

            let isClickable: Bool
            if let type = warningType {
                switch type {
                case .meetingRoomReservableDateEarlierThanDueDate: isClickable = true
                default: isClickable = false
                }
            } else {
                isClickable = false
            }

            return RruleViewData(
                isVisible: permissions.rrule.isVisible,
                ruleStr: rrule.getReadableRecurrenceRepeatString(timezone: eventModel.timeZone.identifier),
                isRuleEditable: permissions.rrule.isEditable,
                isShowArrow: isShowArrow,
                endDateStr: self.endDateDesc(ofRrule: rrule, timezone: eventModel.timeZone.identifier),
                isEndDateValid: isEndDateValid,
                isEndDateEditable: self.isEndDateCompatible(ofRrule: rrule) && permissions.rrule.isEditable,
                shouldShowTip: !isEndDateValid,
                tipStr: warningType?.readableStr ?? "",
                isTipClickable: isClickable,
                rruleShowAIStyle: eventModel.aiStyleInfo.rrule.rrule,
                endDateShowAIStyle: eventModel.aiStyleInfo.rrule.endTime
            )
        }

        guard let rxEventModel = eventModel?.rxModel,
              let rxCalendarModel = calendarModel?.rxModel,
              let rxAttendeeData = attendeeModel?.rxAttendeeData,
              let rxPermissions = permissionModel?.rxPermissions else { return }
        Observable.combineLatest(rxEventModel,
                                 rxPermissions,
                                 rxAttendeeData.map(\.breakUpAttendeeCount),
                                 rxCalendarModel.map(\.current),
                                 rxEventDateOrRruleChanged,
                                 rxMeetingRoomViewData)
            .map(transform)
            .bindRxViewData(to: rxRruleViewData)
            .disposed(by: disposeBag)
    }

    // MARK: Attachment

    struct AttachmentItemViewData: EventEditAttachmentItemViewDataType {
        var icon: UIImage
        var name: String
        var type: CalendarEventAttachment.TypeEnum
        var sizeString: String
        var token: String
        var isLargeAttachments: Bool
        var tipInfo: (String?, UIColor)
        var status: UploadStatus
        var hasBeenDeleted: Bool = false
        var isFileRisk: Bool = false
        var canDelete: Bool = false
        var needReUpload: Bool = false
        var googleDriveLink: String
        var urlLink: String
    }

    struct AttachmentViewData: EventEditAttachmentViewDataType {
        var title: String = ""
        var items: [EventEditAttachmentItemViewDataType] = []
        var isVisible: Bool = false
        var isEditable: Bool = false
        var needResetAllItems: Bool = true
        var source: Rust.CalendarEventSource = .unknownSource
    }

    private func bindAttachmentViewData() {
        let transform = { [weak self] (displayingInfo: (attachments: [CalendarEventAttachmentEntity], needResetAll: Bool),
                           permissions: EventEditPermissions, fileRiskTag: [Server.FileRiskTag]) -> AttachmentViewData in
            guard let self = self else {
                return AttachmentViewData()
            }
            var items = [AttachmentItemViewData]()
            var (size, count): (UInt64, Int) = (0, 0)
            let isEditable = permissions.attachments.isEditable
            for attachment in displayingInfo.attachments {
                let fileExtension = (attachment.name as NSString).pathExtension.lowercased()
                let fileType = CommonFileType(fileExtension: fileExtension)

                items.append(
                    AttachmentItemViewData(
                        icon: fileType.iconImage ?? UIImage(),
                        name: attachment.name,
                        type: attachment.type,
                        sizeString: attachment.sizeString(),
                        token: attachment.token,
                        isLargeAttachments: attachment.isLargeAttachments,
                        tipInfo: attachment.expireTip,
                        status: attachment.status,
                        hasBeenDeleted: attachment.isDeleted,
                        isFileRisk: fileRiskTag.filter { $0.fileToken == attachment.token }.first?.isRiskFile ?? false,
                        canDelete: isEditable,
                        googleDriveLink: attachment.googleDriveLink,
                        urlLink: attachment.urlLink
                    )
                )
                if (!attachment.token.isEmpty && !attachment.isDeleted) || self.judgeIsGoogleEventAttachment(attachment) {
                    size += attachment.size
                    count += 1
                }
            }
            let titleStr: String
            if items.isEmpty {
                titleStr = ""
            } else {
                let countStr = BundleI18n.Calendar.Calendar_Plural_Attachment(number: count)
                let sizeStr = "(\(EventEditAttachment.sizeString(for: size)))"
                if self.eventModel?.rxModel?.value.getPBModel().source == .google {
                    titleStr = countStr
                } else {
                    titleStr = countStr + sizeStr
                }
            }
            return AttachmentViewData(
                title: titleStr,
                items: items,
                isVisible: permissions.attachments.isVisible,
                isEditable: isEditable,
                needResetAllItems: displayingInfo.needResetAll,
                source: self.eventModel?.rxModel?.value.getPBModel().source ?? .unknownSource
            )
        }

        guard let rxAttachments = attachmentModel?.rxDisplayingAttachmentsInfo,
              let rxRiskTags = attachmentModel?.rxRiskTags.distinctUntilChanged(),
              let rxPermissions = permissionModel?.rxPermissions else { return }

        Observable.combineLatest(rxAttachments, rxPermissions, rxRiskTags)
            .map(transform)
            .observeOn(MainScheduler.instance)
            .bindRxViewData(to: rxAttachmentViewData)
            .disposed(by: disposeBag)
    }

    private func judgeIsGoogleEventAttachment(_ attachment: CalendarEventAttachmentEntity)-> Bool {
        let isTokenEmpty: Bool = attachment.token.isEmpty
        let isGoogleDriveLinkEmpty: Bool = attachment.googleDriveLink.isEmpty
        let isSourceGoogle: Bool = self.eventModel?.rxModel?.value.getPBModel().source == .google

        return isTokenEmpty && !isGoogleDriveLinkEmpty && isSourceGoogle
    }

    // MARK: MeetingNotes

    struct MeetingNotesViewData: EventEditMeetingNotesViewDataType {
        var viewStatus: MeetingNotesViewStatus = .loading
        var showDeleteIcon: Bool = false
        var shouldShowAIStyle: Bool = false
    }

    private func bindMeetingNotesViewData() {
        guard legoInfo.shouldShow(.meetingNotes) else { return }

        let getFutureOrAllSpanViewData = { [weak self] (docTitle: String?) -> MeetingNotesViewData? in
            guard let self = self else { return nil }
            var reason: String = ""
            switch self.span {
            case .futureEvents:
                reason = I18n.Calendar_Notes_EditRestrict_Tooltip
            case .allEvents:
                reason = I18n.Calendar_Notes_EditRestrictAll_Tooltip
            case .thisEvent, .noneSpan: return nil
            @unknown default: return nil
            }
            let newViewStatus: MeetingNotesViewStatus = .disabled(title: docTitle ?? reason, iconShow: docTitle != nil, reason: docTitle == nil ? nil : reason)
            return MeetingNotesViewData(viewStatus: newViewStatus, showDeleteIcon: false)
        }

        let transform = { [weak self] (viewStatus: MeetingNotesViewStatus, permission: EventEditPermissions, isExternal: Bool) -> MeetingNotesViewData in
            guard let self = self, permission.meetingNotes.isVisible else { return MeetingNotesViewData(viewStatus: .hidden) }
            let isFutureOrAllSpan = self.span == .allEvents || self.span == .futureEvents
            switch viewStatus {
            case .loading, .failed, .hidden:
                /// 中间状态场景，透传 viewStatus
                return MeetingNotesViewData(viewStatus: viewStatus, showDeleteIcon: false)
            case .templateList, .createMeetingNotes:
                /// 编辑后续/所有特化逻辑
                if let viewData = getFutureOrAllSpanViewData(nil) {
                    return viewData
                }
                /// AI 场景埋点
                if case .createMeetingNotes = viewStatus, FG.myAI, self.rxMeetingNotesViewData.value.viewStatus != .createMeetingNotes {
                    CalendarTracerV2.CreateAIMeetingNotes.traceView(commonParam: .init(event: self.eventModel?.rxModel?.value.getPBModel()))
                }
                return MeetingNotesViewData(viewStatus: viewStatus, showDeleteIcon: false)
            case .viewData(var viewData):
                /// 有MeetingNotes场景，编辑后续/所有特化逻辑
                if let viewData = getFutureOrAllSpanViewData(nil) {
                    return viewData
                }
                /// 底部权限 Tip 展示 重新校验
                viewData.showPermissionTip = viewData.showPermissionTip && isExternal
                if viewData.showPermissionTip && !viewData.permissionSettingStr.isEmpty {
                    let event = self.eventModel?.rxModel?.value.getPBModel()
                    CalendarTracerV2.EventFullCreateNotesPermission.traceView(commonParam: .init(event: event))
                }
                /// 日程协作人文档权限的编辑权限校验
                if !permission.notesEventPermission.isWritable {
                    viewData.eventPermission = nil
                }
                return MeetingNotesViewData(viewStatus: .viewData(viewData),
                                            showDeleteIcon: viewData.isDocDeletable,
                                            shouldShowAIStyle: self.eventModel?.rxModel?.value.aiStyleInfo.meetingNotes ?? false)
            case .createEmpty:
                /// 没有 MeetingNotes 场景，同时 templateList 拉取失败
                if isFutureOrAllSpan {
                    return MeetingNotesViewData(viewStatus: viewStatus, showDeleteIcon: false)
                }
                return MeetingNotesViewData(viewStatus: viewStatus, showDeleteIcon: false)
            case .disabled:
                return MeetingNotesViewData(viewStatus: viewStatus, showDeleteIcon: false)
            }
        }

        guard let rxMeetingNotesStatus = meetingNotesModel?.rxViewStatus,
              let rxPermission = permissionModel?.rxModel,
              let rxAttendees = attendeeModel?.rxModel,
              let tenantId = calendarDependency?.currentUser.tenantId,
              let event = eventModel?.rxModel?.value else { return }
        let eventIsExternal = event.getPBModel().isCrossTenant
        let rxIsExternal = rxAttendees.map { attendees -> Bool in
            return eventIsExternal || attendees.hasExternalAttendee(tenantId: tenantId)
        }
        Observable.combineLatest(rxMeetingNotesStatus, rxPermission, rxIsExternal)
            .map(transform)
            .bindRxViewData(to: rxMeetingNotesViewData)
            .disposed(by: disposeBag)
    }


    // MARK: Notes

    struct EventNotesViewData: EventEditNotesViewDataType {
        var notes: EventNotes = .html(text: "")
        var isVisible: Bool = false
        var isEditable: Bool = false
        var isDeletable: Bool = true
    }

    private func bindNotesViewData() {
        guard legoInfo.shouldShow(.description) else { return }
        let transform = { [weak self] (eventModel: EventEditModel, permissions: EventEditPermissions)
                            -> EventNotesViewData in
            let notes = eventModel.notes ?? self?.makeEmptyNotes() ?? EventNotes.html(text: "")
            return EventNotesViewData(
                notes: notes,
                isVisible: notes.isEmpty ? permissions.notes.isEditable : permissions.notes.isVisible,
                isEditable: permissions.notes.isEditable,
                isDeletable: !(self?.input.isWebinarScene ?? false)
            )
        }

        guard let rxEventModel = eventModel?.rxModel,
              let rxPermissions = permissionModel?.rxPermissions else { return }
        Observable.combineLatest(rxEventModel, rxPermissions)
            .map { transform($0.0, $0.1) }
            .bindRxViewData(to: rxNotesViewData)
            .disposed(by: disposeBag)
    }
    
    // MARK: Delete
    struct EventEditDeleteViewData: EventEditDeleteViewDataType {
        var isVisible: Bool = false
        var title: String = I18n.Calendar_Event_Remove
    }
    
    private func bindDeleteViewData() {
        guard legoInfo.shouldShow(.delete) else { return }
        typealias RelatedTuple = (
            permissions: EventEditPermissions,
            legoInfo: EventEditLegoInfo
        )
        let transform = { [weak self] (tuple: RelatedTuple) -> EventEditDeleteViewData in
            if tuple.permissions.deletion.isEditable && tuple.legoInfo.shouldShow(.delete),
               let deleteModel = self?.getModelForDeleting() {
                let title = deleteModel.canDeleteAll ? I18n.Calendar_DetailsPage_DeleteEvent_Button : I18n.Calendar_Event_Remove
                return EventEditDeleteViewData(isVisible: true, title: title)
            }
            return EventEditDeleteViewData(isVisible: false)
        }

        guard let rxPermissions = permissionModel?.rxPermissions else { return }
        let tuple = RelatedTuple(
            permissions: rxPermissions.value,
            legoInfo: self.legoInfo
        )
        rxDeleteViewData = BehaviorRelay(value: transform(tuple))

        Observable.combineLatest(rxPermissions,
                                 Observable.just(self.legoInfo))
            .map { transform($0) }
            .bindRxViewData(to: rxDeleteViewData)
            .disposed(by: disposeBag)
    }

    private func bindWebinarFooterLabelData() {
        guard input.isWebinarScene,
              let rxCalendarModel = calendarModel?.rxModel else {
            return
        }

        let paramsGetter = { [weak self] (calendar: EventEditCalendar) -> (origanizerTenantId: Int64, organizerUserId: Int64) in
            guard let self = self, let event: Rust.Event = self.eventModel?.rxModel?.value.getPBModel() else { return (0, 0) }
            if self.input.isFromCreating {
                if calendar.isShared {
                    let currentUser = self.calendarDependency?.currentUser
                    let uid = Int64(currentUser?.id ?? "") ?? 0
                    let tenantId = Int64(currentUser?.tenantId ?? "") ?? 0
                    return (tenantId, uid)
                } else {
                    return (Int64(calendar.getPBModel().calendarTenantID) ?? 0,
                            Int64(calendar.getPBModel().userID) ?? 0)
                }
            } else {
                let organizer: Rust.Attendee? = {
                    if event.hasSuccessor {
                        return event.successor
                    } else if event.hasOrganizer {
                        return event.organizer
                    } else if event.hasCreator {
                        return event.creator
                    } else {
                        return nil
                    }
                }()
                let uid = Int64(organizer?.user.userID ?? "") ?? 0
                let tenantId = Int64(organizer?.user.tenantID ?? "") ?? 0
                return (tenantId, uid)
            }
        }

        rxCalendarModel
            .map(\.current)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self, weak rxCalendarModel] calendar in
                guard let calendar = calendar else {
                    self?.rxWebinarFooterLabelData.accept(nil)
                    return
                }
                let params = paramsGetter(calendar)
                self?.calendarDependency?.pullWebinarMaxParticipantsCount(
                    organizerTenantId: params.origanizerTenantId,
                    organizerUserId: params.organizerUserId
                ) { [weak self, weak rxCalendarModel] result in
                    if let currentCalendar = rxCalendarModel?.value.current,
                       calendar != currentCalendar {
                        EventEdit.logger.warn("current calendar != calendar")
                        return
                    }
                    switch result {
                    case .success(let count):
                        self?.rxWebinarFooterLabelData.accept(BundleI18n.Calendar.Calendar_Settings_MaxNumColon + String(count))
                    case .failure(let err):
                        EventEdit.logger.log(level: .error, "pullWebinarMaxParticipantsCount error: \(err)")
                        self?.rxWebinarFooterLabelData.accept(nil)
                    }
                }

            }).disposed(by: disposeBag)
    }

}

fileprivate extension ObservableType {
    func bindRxViewData(to relays: RxRelay.BehaviorRelay<Self.Element>) -> RxSwift.Disposable {
        return self
            .observeOn(SerialDispatchQueueScheduler(qos: .userInteractive))
            .bind(to: relays)
    }
}

