//
//  DailyDetailViewModel.swift
//  Pods
//
//  Created by LUNNER on 2019/5/23.
//

import Foundation
import Action
import RxSwift
import RxCocoa
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting

struct DailyDetailInfo: Equatable {
    let topic: String
    let time: String
    let room: String
    let location: String
    let desc: String
    let enterGroupText: String
    static var `default`: DailyDetailInfo { DailyDetailInfo(topic: I18n.View_G_ServerNoTitle,
                                                            time: "", room: "", location: "",
                                                            desc: "", enterGroupText: "") }
}

enum DailyDetailContentType {
    case meetingNum
    case organizer
    case meetingLink
    case dialIn
    case benefit(BenefitInfo)
    case e2EeMeeting
    // 面试速记提醒
    case peopleMinutes
    // 以下四个是calendarMeeting才有的
    case date
    case roomInfo
    case location
    case description
}

class DailyDetailViewModel: InMeetMeetingProvider {
    private let disposeBag = DisposeBag()

    let meeting: InMeetMeeting
    let context: InMeetViewContext
    weak var hostViewController: UIViewController?

    private var meetingId: String {
        meeting.meetingId
    }

    var isMeetingShareViewVisible: Bool {
        isCopyMeetingLinkEnabled || isShareCardEnabled
    }

    var isEnterGroupButtonVisible: Bool = false

    var isCopyMeetingLinkEnabled: Bool {
        meeting.setting.isCopyLinkEnabled
    }

    var isShareCardEnabled: Bool {
        meeting.setting.isShareCardEnabled
    }

    var isDialInViewVisible: Bool {
        !dialInRelay.value.isEmpty && meeting.setting.isPstnIncomingEnabled
    }

    let benefitViewModel: InMeetBenefitViewModel
    var meetingOwner: ByteviewUser? {
        benefitViewModel.meetingOwner
    }

    var hasMoreDialInPhones: Bool = false

    let isCalendarMeeting: Bool
    let isInterviewMeeting: Bool
    let meetingNumber: String
    var currentDetailInfo: DailyDetailInfo { detailInfoRelay.value }
    var dailyDetailContent: [DailyDetailContentType] = []

    private let meetingLinkRelay = BehaviorRelay(value: "")
    private(set) lazy var meetingLinkObservable = meetingLinkRelay.asObservable()

    private let dialInRelay = BehaviorRelay<String>(value: "")
    private(set) lazy var dialIn: Observable<String> = dialInRelay.asObservable()

    private let detailInfoRelay = BehaviorRelay<DailyDetailInfo>(value: .default)
    private(set) lazy var detailInfoObservable: Observable<DailyDetailInfo> = detailInfoRelay.asObservable()

    private func getTopic(_ info: CalendarInfo) -> String {
        if info.topic.isEmpty {
            if let topic = self.meeting.data.inMeetingInfo?.meetingSettings.topic, !topic.isEmpty {
                return self.meeting.data.roleStrategy.displayTopic(topic: topic)
            }
            return I18n.View_G_ServerNoTitle
        }
        return info.topic
    }

    private func getTopic(_ info: VideoChatInMeetingInfo) -> String {
        if !info.meetingSettings.topic.isEmpty {
            return meeting.data.roleStrategy.displayTopic(topic: info.meetingSettings.topic)
        }
        return I18n.View_G_ServerNoTitle
    }

    private func getTime(_ info: CalendarInfo) -> String {
        guard info.theEventStartTime > 0 && info.theEventEndTime > 0 else {
            return ""
        }
        let startTime = TimeInterval(info.theEventStartTime / 1000)
        let endTime = TimeInterval(info.theEventEndTime / 1000)
        return service.calendar.formatDateTimeRange(startTime: startTime, endTime: endTime, isAllDay: info.isAllDay)
    }

    private func getRoom(_ info: CalendarInfo) -> String {
        var roomStrs: [String] = []
        let rooms = info.rooms.merging(info.viewRooms, uniquingKeysWith: { return $1 })
        for (key, room) in rooms {
            guard info.roomStatus[key] == .accept else { continue }
            roomStrs.append(room.fullNameSite)
        }
        return roomStrs.joined(separator: "\n")
    }

    private func getLocation(_ info: CalendarInfo) -> String {
        guard let location = info.calendarLocations.first else { return "" }
        var locationStr = location.name
        if location.name.isEmpty {
            locationStr = location.address
        } else if !location.address.isEmpty {
            locationStr += ", " + location.address
        }
        return locationStr
    }

    // 按规定顺序添加，存在实时刷新逻辑的内容需要先预置进去
    private func getDailyDetailContent(meeting: InMeetMeeting) -> [DailyDetailContentType] {
        var content: [DailyDetailContentType] = [.meetingNum]
        // 1v1，Rooms 发起的即时会议，通过 Open API 机器人发起的会议不显示组织者，面试会议也不显示组织者
        if meeting.type != .call, let owner = benefitViewModel.meetingOwner, owner.type == .larkUser, !meeting.isInterviewMeeting {
            content.append(.organizer)
        }
        content.append(.meetingLink)
        content.append(.dialIn)
        if benefitViewModel.shouldShowBenefitInfo, let benefitInfo = benefitViewModel.benefit {
            content.append(.benefit(benefitInfo))
        }
        if meeting.isE2EeMeeing {
            content.append(.e2EeMeeting)
        }
        if meeting.data.isPeopleMinutesOpened {
            content.append(.peopleMinutes)
        }
        if meeting.isCalendarMeeting {
            content.append(contentsOf: [.date, .roomInfo, .location, .description])
        }
        return content
    }

    init(meeting: InMeetMeeting, context: InMeetViewContext, benefit: InMeetBenefitViewModel) {
        self.meeting = meeting
        self.context = context
        self.isCalendarMeeting = meeting.isCalendarMeeting
        self.isInterviewMeeting = meeting.isInterviewMeeting
        self.meetingNumber = meeting.info.formattedMeetingNumber
        self.benefitViewModel = benefit
        self.dailyDetailContent = self.getDailyDetailContent(meeting: meeting)
        meeting.data.addListener(self)
        meeting.data.fetchCalendarInfoIfNeeded()
        self.updatePstnIncomingCallInfo()
    }

    func enterGroup(from vc: UIViewController) {
        let request = GetCalendarGroupRequest(meetingID: meetingId, autoCreate: true)
        meeting.httpClient.getResponse(request) { [weak self] (result) in
            guard let resp = result.value else { return }
            Util.runInMainThread {
                switch resp.getCalGroupStatus {
                case .getGroupSuccess:
                    self?.meeting.router.setWindowFloating(true)
                    self?.larkRouter.gotoChat(body: ChatBody(chatId: resp.groupID, isGroup: true, switchFeedTab: Display.pad))
                    MeetingTracks.trackEnterGroup()
                default:
                    Toast.show(I18n.View_M_FailedToJoinMeetingGroup)
                }
            }
        }
    }

    func shareViaCall(from vc: UIViewController) {
        MeetingTracks.trackShareMeetingLink()
        MeetingTracksV2.trackShareMeeting()
        guard !meeting.setting.isMeetingLocked else {
            Toast.show(I18n.View_MV_MeetingLocked_Toast)
            return
        }
        vc.presentingViewController?.dismiss(animated: true) { [weak self] in
            if let self = self, let vc = self.meeting.router.topMost {
                // pageSheet弹出的视图系统方向主要取决于底部VC ，所以理论样式一定要支持所有方向，iOS 15及以下暂时强制转成竖屏
                if #unavailable(iOS 16.0) {
                    UIDevice.updateDeviceOrientationForViewScene(nil, to: .portrait, animated: true)
                }
                self.service.messenger.shareMeetingCard(meetingId: self.meetingId, from: vc, source: .meetingDetail) { [weak self] in
                    return self?.meeting.setting.isMeetingLocked != true
                }
            }
        }
    }
}

extension DailyDetailViewModel: InMeetDataListener {
    func didChangeCalenderInfo(_ calendarInfo: CalendarInfo?, oldValue: CalendarInfo?) {
        if isCalendarMeeting {
            let detailInfo = detailInfoByCalendarInfo(calendarInfo)
            if detailInfo != self.detailInfoRelay.value {
                self.detailInfoRelay.accept(detailInfo)
            }
        }
    }

    func didChangeInMeetingInfo(_ info: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if !isCalendarMeeting {
            let detailInfo = DailyDetailInfo(topic: getTopic(info), time: "", room: "", location: "", desc: "",
                                             enterGroupText: "")
            if detailInfo != self.detailInfoRelay.value {
                self.detailInfoRelay.accept(detailInfo)
            }
        }
        let url = info.meetingURL
        if url != meetingLinkRelay.value {
            meetingLinkRelay.accept(url)
        }
    }

    private func detailInfoByCalendarInfo(_ info: CalendarInfo?) -> DailyDetailInfo {
        guard let info = info else { return .default }
        let desc = info.desc
        let enterGroupText: String
        if !info.canEnterOrCreateGroup || !meeting.setting.isEnterGroupEnabled {
            enterGroupText = ""
        } else if info.groupID == 0 {
            enterGroupText = I18n.View_M_CreateMeetingGroup
        } else {
            enterGroupText = I18n.View_M_EnterMeetingGroup
        }
        self.isEnterGroupButtonVisible = !enterGroupText.isEmpty
        return DailyDetailInfo(topic: self.getTopic(info), time: self.getTime(info),
                               room: self.getRoom(info), location: self.getLocation(info),
                               desc: desc, enterGroupText: enterGroupText)
    }

    func updatePstnIncomingCallInfo() {
        let phones = meeting.setting.pstnIncomingCallPhoneList.filter { !$0.country.isEmpty && !$0.numberDisplay.isEmpty }
        let pstnIncomingCallCountryDefault = phones.filter { $0.mobileCode.isDefault }

        var dialInText = ""
        self.hasMoreDialInPhones = phones.count > 1
        if let pstnPhone = pstnIncomingCallCountryDefault.first ?? meeting.setting.pstnIncomingCallPhoneList.first {
            dialInText = "\(pstnPhone.numberDisplay) (\(pstnPhone.countryName))"
        }
        if dialInText != dialInRelay.value {
            dialInRelay.accept(dialInText)
        }
    }
}
