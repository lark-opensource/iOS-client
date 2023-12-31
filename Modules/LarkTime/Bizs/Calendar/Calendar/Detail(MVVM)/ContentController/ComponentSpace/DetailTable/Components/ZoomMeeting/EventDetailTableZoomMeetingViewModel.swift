//
//  EventDetailTableZoomMeetingViewModel.swift
//  Calendar
//
//  Created by pluto on 2022-10-20.
//

import Foundation
import RxSwift
import RxRelay
import LarkContainer
import LarkFoundation
import LarkTimeFormatUtils
import LarkAccountInterface
import CalendarFoundation
import LKCommonsLogging
import UIKit
import LarkUIKit
import LarkEMM

final class EventDetailTableZoomMeetingViewModel: EventDetailComponentViewModel {

    private let logger = Logger.log(EventDetailTableZoomMeetingViewModel.self, category: "calendar.EventDetailTableZoomMeetingViewModel")
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy var calendarAPI: CalendarRustAPI?
    @ScopedProvider private var userService: PassportUserService?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    private let rxVideoMeeting: BehaviorRelay<VideoMeeting>
    let rxViewData = BehaviorRelay<DetailZoomMeetingCellContent?>(value: nil)
    let rxDefaultNumber = BehaviorRelay<String?>(value: nil)
    let rxRoute = PublishRelay<Route>()
    let rxToast = PublishRelay<ToastStatus>()

    @ContextObject(\.rxModel) var rxModel
    @ContextObject(\.monitor) var monitor

    private var model: EventDetailModel { rxModel.value }
    var event: EventDetail.Event {
        guard let event = rxModel.value.event else {
            EventDetail.logUnreachableLogic()
            return EventDetail.Event()
        }
        return event
    }

    override init(context: EventDetailContext, userResolver: UserResolver) {
        var videoMeeting = Rust.VideoMeeting()
        if let videoMeetingModel = context.rxModel.value.event?.videoMeeting {
            videoMeeting = videoMeetingModel
        }

        self.rxVideoMeeting = BehaviorRelay(value: VideoMeeting(pb: videoMeeting))
        super.init(context: context, userResolver: userResolver)
        bindRx()
        loadDefaultPhoneNumber()
    }

    private func bindRx() {
        Observable.combineLatest(rxVideoMeeting.distinctUntilChanged(),
                                 rxDefaultNumber)
            .compactMap { [weak self] videoMeeting, number in
                guard let self = self else { return nil }
                return self.buildViewData(with: videoMeeting, phoneNumber: number)
            }
            .bind(to: rxViewData)
            .disposed(by: disposeBag)
    }

    private func loadDefaultPhoneNumber() {
        let zoomConfig = rxVideoMeeting.value.pb.zoomConfigs
        calendarAPI?.getZoomMeetingPhoneNumsRequest(meetingID: zoomConfig.meetingID, creatorAccount: zoomConfig.creatorAccount, isDefault: true, creatorUserID: zoomConfig.creatorUserID)
            .map {  (response) -> String in
                if let zoomPhone = response.phoneNums[safeIndex: 0], !zoomPhone.dialInNumbers.isEmpty {
                    return zoomPhone.dialInNumbers.first ?? ""
                }
                return ""
            }
            .bind(to: rxDefaultNumber)
            .disposed(by: disposeBag)
    }

    // 用于详情页修改设置保存更新
    func updateVideoMeeting(meetingNo: Int64, password: String, meetingUrl: String) {
        var videoMeeting = event.videoMeeting
        videoMeeting.zoomConfigs.meetingNo = meetingNo
        videoMeeting.zoomConfigs.password = password
        videoMeeting.zoomConfigs.meetingURL = meetingUrl
        videoMeeting.meetingURL = meetingUrl
        rxVideoMeeting.accept(VideoMeeting(pb: videoMeeting))
        loadDefaultPhoneNumber()
    }
}

extension EventDetailTableZoomMeetingViewModel {
    enum Action {
        case dail
        case videoMeeting
        case linkCopy
        case morePhoneNumber
        case setting
    }

    func action(_ action: Action) {
        switch action {
        case .dail: tapDail()
        case .videoMeeting: tapVideoMeeting()
        case .linkCopy: tapLinkCopy()
        case .morePhoneNumber: tapMorePhoneNumber()
        case .setting: tapSetting()
        }
    }

    private func tapDail() {
        EventDetail.logInfo("tap dail action")

        var phoneNumWithID = getPhoneNumberWithID()
        if Display.pad {
            SCPasteboard.generalPasteboard(shouldImmunity: true).string = phoneNumWithID
            self.rxToast.accept(.success(I18n.View_M_PhoneNumberAndMeetingIdCopied))
        } else {
            // 15.4 有bug，加 # 不能拨打电话。后续观察系统修复情况
            // https://developer.apple.com/forums/thread/701865
            if #available(iOS 15.4, *) {
                phoneNumWithID = phoneNumWithID.replacingOccurrences(of: "#", with: "")
            }
            phoneNumWithID = (phoneNumWithID as NSString).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            LarkFoundation.Utils.telecall(phoneNumber: phoneNumWithID)
        }

    }

    private func getPhoneNumberWithID() -> String {
        let phoneNumber: String

        guard var number = rxDefaultNumber.value else {
            return ""
        }

        number = number.replacingOccurrences(of: "[^+0-9]", with: "", options: .regularExpression)
        phoneNumber = number
        let meetingNumber = videoMeeting.pb.meetingNumber
        return phoneNumber + "#"
    }

    private func tapVideoMeeting() {
        EventDetail.logInfo("tap videomeeting action")

        if videoMeeting.type == .zoomVideoMeeting {
            CalendarTracerV2.EventDetail.traceClick(commonParam: CommonParamData(instance: self.rxModel.value.instance, event: self.event)) {
                $0.click("enter_vc")
                $0.vchat_type = "zoom_vc"
                $0.is_create = "false"
            }
            let urlString = rxVideoMeeting.value.pb.zoomConfigs.meetingURL

            guard let url = URL(string: urlString) else {
                EventDetail.logError("cannot jump url: \(urlString)")
                return
            }

            self.rxRoute.accept(.url(url: url))
        } else {
            guard let url = URL(string: videoMeeting.url) else {
                self.rxToast.accept(.failure(I18n.Calendar_Common_FailedToLoad))
                return
            }
            self.rxRoute.accept(.url(url: url))
        }
    }

    private func tapLinkCopy() {
        if videoMeeting.type == .zoomVideoMeeting {
            let zoomConfigs = videoMeeting.pb.zoomConfigs
            let inviteMsg: String = I18n.Calendar_Zoom_PrescheduleMeet(name: userService?.user.localizedName ?? "") + "\n"
            let meetingTheme: String = I18n.Calendar_Edit_MeetingTopic + "\(event.summary)\n"
            let meetingTime: String = I18n.Calendar_Zoom_MeetTimeColon + getFormatTimeStr() + "\n"
            let meetingID: String = I18n.Calendar_Edit_MeetingID2 + "\(rxVideoMeeting.value.pb.zoomConfigs.meetingID)\n"
            let meetingLink: String = I18n.Calendar_Edit_MeetingLink + rxVideoMeeting.value.pb.zoomConfigs.meetingURL + "\n"
            var meetingPassword: String = ""
            if !rxVideoMeeting.value.pb.zoomConfigs.password.isEmpty {
                meetingPassword = I18n.Calendar_Zoom_MeetPasscode + rxVideoMeeting.value.pb.zoomConfigs.password + "\n"
            }
            var copyMessage = inviteMsg + meetingTheme + meetingTime + meetingID + meetingLink + meetingPassword
            SCPasteboard.generalPasteboard(shouldImmunity: true).string = copyMessage

        } else {
            let copyMessage = videoMeeting.url
            SCPasteboard.generalPasteboard(shouldImmunity: true).string = copyMessage
        }
        self.rxToast.accept(.success(I18n.Calendar_Edit_JoinInfoCopied))
    }

    private func getFormatTimeStr() -> String {
        let timeLabel: CATimeFormatterLabel = CATimeFormatterLabel(isOneLine: true)
        timeLabel.setTimeString(startTime: getDateFromInt64(event.startTime),
                                endTime: getDateFromInt64(event.endTime),
                                isAllday: event.isAllDay,
                                is12HourStyle: calendarDependency?.is12HourStyle.value ?? true)
        return timeLabel.attributedText?.string ?? ""
    }

    private func tapMorePhoneNumber() {
        EventDetail.logInfo("tap phone number action")
        let zoomConfig = rxVideoMeeting.value.pb.zoomConfigs
        // 更多电话号码列表
        self.rxRoute.accept(.phoneNumberList(info: zoomConfig))
    }

    private func tapSetting() {
        EventDetail.logInfo("EventDetail tap ZoomMeeting setting action")
        guard rxVideoMeeting.value.pb.zoomConfigs.isEditable else {
            rxToast.accept(.tips(I18n.Calendar_Zoom_NoEditPermit))
            return
        }
        self.rxRoute.accept(.meetingSetting(id: ""))
    }
}

extension EventDetailTableZoomMeetingViewModel {
    enum Route {
        case meetingSetting(id: String)
        case url(url: URL)
        case phoneNumberList(info: Rust.ZoomVideoMeetingConfigs)
    }
}

extension EventDetailTableZoomMeetingViewModel {
    var videoMeeting: VideoMeeting {
        rxVideoMeeting.value
    }
}

struct DetailZoomMeetingCellModel: DetailZoomMeetingCellContent {

    var summary: String
    var meetingNo: Int64
    var password: String
    var isCopyAvailable: Bool = true
    var settingPermission: PermissionOption = .none
    var iconType: Rust.VideoMeetingIconType
    var phoneNumber: String
}

extension EventDetailTableZoomMeetingViewModel {

    private func buildViewData(with videoMeeting: VideoMeeting, phoneNumber: String?) -> DetailZoomMeetingCellContent {

        var summary = I18n.Calendar_Zoom_JoinMeetButton
        var settingPermission: PermissionOption = (videoMeeting.pb.zoomConfigs.isEditable && event.isEditable) ? .writable : .none

        return DetailZoomMeetingCellModel(
            summary: summary,
            meetingNo: videoMeeting.pb.zoomConfigs.meetingNo,
            password: videoMeeting.pb.zoomConfigs.password,
            settingPermission: settingPermission,
            iconType: videoMeeting.pb.videoMeetingIconType,
            phoneNumber: phoneNumber ?? "")

    }
}
