//
//  EventDetailTableVideoMeetingViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/3/27.
//

import Foundation
import RxSwift
import RxRelay
import LarkFoundation
import LarkTimeFormatUtils
import LKCommonsLogging
import CalendarFoundation
import AppReciableSDK
import UIKit
import LarkUIKit
import Reachability
import ServerPB
import RustPB
import ByteViewNetwork
import LarkEMM
import LarkSensitivityControl
import LarkContainer
import LarkAccountInterface
import EENavigator

// TODO: 需要移除ByteViewNetwork的依赖
final class EventDetailTableVideoMeetingViewModel {

    private let logger = Logger.log(EventDetailTableVideoMeetingViewModel.self, category: "calendar.vc.EventDetailTableVideoMeetingViewModel")
    private static let copyMeetingInfoToken = "LARK-PSDA-calendar_copy_meeting_info"
    private static let copyPhoneNumberToken = "LARK-PSDA-calendar_copy_phone_number"

    typealias VideoChatStatus = Server.CalendarVideoChatStatus
    typealias PSTNInfo = PSTNInfoResponse
    typealias PSTNNumInfo = PSTNNumResponse

    var hasTracedShow = false

    let rxViewData = BehaviorRelay<DetailVideoMeetingCellContent?>(value: nil)
    let rxPstnNumViewData = BehaviorRelay<DetailVideoMeetingCellPstnNumContent?>(value: nil)

    let rxRoute = PublishRelay<Route>()
    let rxToast = PublishRelay<ToastStatus>()

    var isVideoMeetingLiving = false

    let userResolver: UserResolver

    private(set) lazy var passportService: PassportService? = {
        try? userResolver.resolve(assert: PassportService.self)
    }()

    private(set) lazy var api: CalendarByteViewApi? = {
        try? userResolver.resolve(assert: CalendarByteViewApi.self)
    }()
    var trace: CalendarTraceDep? { api?.trace }

    private let rxEventData: BehaviorRelay<CalendarEventData>
    private let rxVideoMeeting: BehaviorRelay<VideoMeeting>
    private let rxVChatStatus = BehaviorRelay<VideoChatStatus?>(value: nil)
    private let rxPSTNInfo = BehaviorRelay<PSTNInfo?>(value: nil)
    private let rxPSTNNum = BehaviorRelay<PSTNNumInfo?>(value: nil)
    private let rxJoinedDevices = BehaviorRelay<[Rust.JoinedDevice]>(value: [])
    private let rxTenantID: BehaviorRelay<String>
    private let rxCanRenew = BehaviorRelay<Bool>(value: false)
    private let reachability = Reachability()
    private let bag = DisposeBag()
    private var account: AccountInfo? { try? userResolver.resolve(assert: AccountInfo.self) }

    init(userResolver: UserResolver, rxEventData: BehaviorRelay<CalendarEventData>) {
        self.userResolver = userResolver
        self.rxEventData = rxEventData
        self.rxVideoMeeting = BehaviorRelay(value: VideoMeeting(pb: rxEventData.value.event.videoMeeting))

        let event = self.rxEventData.value.event
        let tenantID = event.organizer.tenantID.isEmpty ? event.creator.tenantID : event.organizer.tenantID
        self.rxTenantID = BehaviorRelay(value: tenantID)

        self.updateVideoMeeting(with: rxVideoMeeting.value)

        bindRx()

        if videoMeeting.type == .vchat {
            observeVideoMeetingPush()
            observeVideoMeetingStatusPush()
            updateVideoMeetingStatus()

            updatePSTNInfoIfNeeded()
            updateVideoMeetingEnable()
        }

        // 特化逻辑，重复性日程生成例外之后，会议链接会非常长时间后端才返回，为了避免用户体验太差，手动调用一次。三端一致的逻辑(iOS延后3秒）
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            if self.videoMeeting.uniqueId.isEmpty && self.videoMeeting.type == .vchat {
                self.loadVideoMeeting()
            }
        }

        if videoMeeting.type == .other {
            traceVideoMeetingShowIfNeeded(calendarEvent: calendarEvent, with: false)
        }
    }

    private func bindRx() {

        _ = rxEventData
            .debounce(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
            .subscribe { [weak self] (eventData: CalendarEventData) in
                guard let `self` = self else { return }
                let meeting = VideoMeeting(pb: eventData.event.videoMeeting)
                self.logger.info("update video meeting: \(meeting)")
                self.updateVideoMeeting(with: meeting)
            }
            .disposed(by: bag)

        Observable.combineLatest(rxVideoMeeting.distinctUntilChanged(),
                                 rxVChatStatus.distinctUntilChanged(),
                                 rxJoinedDevices.distinctUntilChanged(),
                                 rxPSTNInfo,
                                 rxCanRenew.distinctUntilChanged())
            .compactMap { [weak self] videoMeeting, status, joinedDevices, pstnInfo, canRenew in
                guard let self = self else { return nil }
                self.logger.info("update video meeting view data")
                return self.buildViewData(with: videoMeeting,
                                          vChatStatus: status,
                                          joinedDevices: joinedDevices,
                                          pstnInfo: pstnInfo,
                                          disableVideoMeeting: self.disableVideoMeeting(canRenew: canRenew))
            }
            .bind(to: rxViewData)
            .disposed(by: bag)

        Observable.combineLatest(rxVideoMeeting.distinctUntilChanged(), rxPSTNNum)
            .compactMap { [weak self] videoMeeting, pstnNum in
                guard let self = self else { return nil }
                self.logger.info("update video meeting pstnNum data")
                var isMoreNumAvailable = false
                var phoneNumber = ""
                if videoMeeting.type == .googleVideoConference {
                    let googleConfig = videoMeeting.pb.googleConfigs
                    isMoreNumAvailable = Utils.isValidUrl(googleConfig.morePhoneNumberURL)
                    phoneNumber = googleConfig.phoneNumber
                } else {
                    let isPstnEnabled = pstnNum?.isPstnEnabled ?? false
                    isMoreNumAvailable = isPstnEnabled && videoMeeting.type == .vchat
                    phoneNumber = isPstnEnabled ? pstnNum?.defaultPhoneNumber ?? "" : ""
                }
                return DetailVCPstnNumCellModel(isMoreNumberAvailable: isMoreNumAvailable, phoneNumber: phoneNumber)
            }
            .bind(to: rxPstnNumViewData)
            .disposed(by: bag)

        rxViewData.compactMap { $0 }
        .observeOn(MainScheduler.instance)
        .scan("") { [weak self] link, content in
            guard let self = self else { return "" }
            let validLink = content.isLinkAvailable && !content.linkDesc.isEmpty && self.videoMeeting.type == .vchat
            if validLink {
                if !link.isEmpty && link != content.linkDesc {
                    // 提示会议链接有变动
                    self.rxToast.accept(.tips(I18n.Calendar_VideoMeeting_ChangeVCLink))
                }
                return content.linkDesc
            } else {
                return link
            }
        }.subscribe()
            .disposed(by: bag)

        rxVChatStatus
            .compactMap { $0 }
            .bind { [weak self] vcStatus in
                guard let self = self else { return }
                self.isVideoMeetingLiving = vcStatus.status == .live
                if self.eventTenantId.isEmpty {
                    self.rxTenantID.accept(String(vcStatus.tenantID))
                }
            }
            .disposed(by: bag)
    }

    private func loadVideoMeeting() {
        api?.getVideoChatByEvent(
            calendarID: calendarEvent.calendarID,
            key: calendarEvent.key,
            originalTime: Int(calendarEvent.originalTime),
            forceRenew: false)
            .subscribe(onNext: { [weak self] videoMeeting in
                guard let self = self else { return }
                self.updateVideoMeeting(with: videoMeeting)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.info("getVideoChatByEvent error: \(error)")
            }).disposed(by: bag)
    }

    private func observeVideoMeetingPush() {
        // 不用手动移除，内部有防重复逻辑
        Push.calendarEventVideoMeetingChange.inUser(userResolver.userID).addObserver(self) { [weak self] in
            self?.didGetCalendarEventVideoMeetingChange($0)
        }

        Push.vcJoinedDevicesInfo.inUser(userResolver.userID).addObserver(self) { [weak self] in
            self?.didGetVCJoinedDeviceInfoChange($0)
        }
    }

    private func observeVideoMeetingStatusPush() {
        // 不用手动移除，内部有防重复逻辑
        Push.associatedVideoChatStatus.inUser(userResolver.userID).addObserver(self) { [weak self] in
            self?.didGetAssociatedVideoChatStatus($0)
        }
    }

    // 刷新视频按钮living态
    private func updateVideoMeetingStatus() {
        guard videoMeeting.type == .vchat else {
            return
        }

        _ = videoMeeting.uniqueId
        var source: VideoMeetingEventType = .normal
        if calendarEvent.source == .people {
            source = .interview
        }
        api?.getVideoMeetingStatusRequest(instanceDetails: self.instanceDetails, source: source)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                guard let self = self else { return }

                self.updatePSTNInfoIfNeeded()
                self.rxVChatStatus.accept(status)

                if status.status != .unknown {
                    self.traceVideoMeetingShowIfNeeded(calendarEvent: self.calendarEvent, with: status.status == .live)
                }
            })
            .disposed(by: bag)
    }

    private func loadJoinedDeviceInfos() {
        api?.getJoinedDeviceInfos()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] devices in
                guard let self = self else { return }
                self.logger.info("get \(devices.count) joined devices")
                self.updateJoinedDeviceInfos(from: devices)
            })
            .disposed(by: bag)
    }

    private func updateJoinedDeviceInfos(from devices: [Rust.JoinedDevice]) {
        let joinedDevices = devices.sorted(by: { $0.joinTime < $1.joinTime })
        self.rxJoinedDevices.accept(joinedDevices)
    }

    private func updatePSTNInfoIfNeeded() {
        guard !eventTenantId.isEmpty else { return }
        var calendarType: VideoMeetingEventType = .normal
        if calendarEvent.source == .people {
            calendarType = .interview
        }

        let startTime = getDateFromInt64(calendarInstance.startTime)
        let endTime = getDateFromInt64(calendarInstance.endTime)
        let isAllDay = calendarEvent.isAllDay

        // 使用设备时区
        let customOptions = Options(
            timeZone: TimeZone.current,
            is12HourStyle: !Date.lf.is24HourTime,
            timePrecisionType: .minute,
            datePrecisionType: .day,
            dateStatusType: .absolute,
            shouldRemoveTrailingZeros: false
        )

        let meetingTimeDesc = CalendarTimeFormatter.formatFullDateTimeRange(
            startFrom: startTime,
            endAt: endTime,
            isAllDayEvent: isAllDay,
            with: customOptions
        )

        api?.fetchPSTNInfo(instanceDetails: self.instanceDetails,
                                         videoMeetingTitle: calendarEvent.displayTitle,
                                         videoMeetingURL: videoMeeting.url,
                                         isWebinar: self.isWebinar,
                                         tenantID: eventTenantId,
                                         calendarType: calendarType,
                                         meetingTimeDesc: meetingTimeDesc) { [weak self] (pstnInfoResponse, error) in
            guard let self = self else { return }
            if error == nil {
                self.rxPSTNInfo.accept(pstnInfoResponse)
            }
        }

        api?.fetchPSTNNum(instanceDetails: self.instanceDetails, tenantID: eventTenantId, calendarType: calendarType) { [weak self] (res, error) in
            guard let self = self else { return }
            if error == nil {
                self.rxPSTNNum.accept(res)
            }
        }
    }

    // 刷新视频按钮点击态
    private func updateVideoMeetingEnable() {

        //过期了看能不能续期
        api?.getCanRenewExpiredVideoChat(
            calendarId: calendarEvent.calendarID,
            key: calendarEvent.key,
            originalTime: calendarEvent.originalTime
        )
            .subscribe(onNext: { [weak self] (canRenew) in
                guard let self = self else { return }
                self.rxCanRenew.accept(canRenew)
            })
            .disposed(by: bag)
    }

    private func updateVideoMeeting(with videoMeeting: VideoMeeting) {
        //guard videoMeeting != self.rxVideoMeeting.value else { return }
        // 更新VideoMeeting
        if videoMeeting.type == .vchat
            && self.rxVideoMeeting.value.type == .vchat
            && !self.rxVideoMeeting.value.uniqueId.isEmpty
            && videoMeeting.uniqueId.isEmpty {
            // 特化逻辑，同是VC视频会议，id从有到无不刷新。防止例外产生的时候uniqueID变没了导致各种bad case
            return
        }
        self.rxVideoMeeting.accept(videoMeeting)

        if videoMeeting.type == .vchat {
            observeVideoMeetingPush()
            if !self.rxVideoMeeting.value.uniqueId.isEmpty {
                observeVideoMeetingStatusPush()
                updateVideoMeetingStatus()
                loadJoinedDeviceInfos()
                updatePSTNInfoIfNeeded()
            }
        }
    }

    private func updateVChatVideoMeeting(with videoMeeting: VideoMeeting) {
        // 当前event的type是vchat的时候允许覆盖。
        // 避免 badcase：如果先设置了vchat保存，又设置成了其他的，服务端还是可能会把push发过来
        guard !videoMeeting.uniqueId.isEmpty,
              videoMeeting != self.rxVideoMeeting.value,
              self.calendarEvent.videoMeeting.videoMeetingType == .vchat else { return }
        // 更新VideoMeeting
        self.rxVideoMeeting.accept(videoMeeting)
        self.logger.info("video meeting updateVChatVideoMeeting")

        updatePSTNInfoIfNeeded()
        observeVideoMeetingStatusPush()
        updateVideoMeetingStatus()
        updateVideoMeetingEnable()
    }
}

extension EventDetailTableVideoMeetingViewModel {
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
        logger.info("tap dail action")

        self.trace?.traceEventDetailVideoMeetingClick(event: calendarEvent, click: "join_phone")

        var phoneNumWithID = getPhoneNumberWithID()
        if Display.pad {
            do {
                let config = PasteboardConfig(token: Token(Self.copyPhoneNumberToken), shouldImmunity: true)
                try SCPasteboard.generalUnsafe(config).string = phoneNumWithID
                self.rxToast.accept(.success(I18n.View_M_PhoneNumberAndMeetingIdCopied))
            } catch {}
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

        if videoMeeting.type == .googleVideoConference {
            var number = videoMeeting.pb.googleConfigs.phoneNumber
            number = number.replacingOccurrences(of: "[a-zA-Z()]", with: "", options: .regularExpression)
            number = number.replacingOccurrences(of: ":", with: ",,", options: .regularExpression)
            phoneNumber = number
            return phoneNumber
        } else {
            guard var number = rxPSTNNum.value?.defaultPhoneNumber else {
                return ""
            }
            number = number.replacingOccurrences(of: "[^+0-9]", with: "", options: .regularExpression)
            phoneNumber = number
            let meetingNumber = videoMeeting.pb.meetingNumber
            return phoneNumber + ",," + meetingNumber + "#"
        }

    }

    private func tapVideoMeeting() {

        logger.info("tap videomeeting action")
        self.trace?.reciableTraceEventDetailStartEnterMeeting()
        self.trace?.traceEventDetailVideoMeetingClick(event: calendarEvent, click: "enter_vc", target: "vc_meeting_pre_view")

        if videoMeeting.type == .googleVideoConference {
            let urlString = videoMeeting.url

            guard let url = URL(string: urlString) else {
                logger.info("cannot jump url: \(urlString)")
                return
            }
            if urlString.contains("meet.google.com") {
                // 跳转 google app
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // 路由兜底
                self.rxRoute.accept(.url(url: url))
            }
        } else if videoMeeting.type == .vchat {
            rxToast.accept(.loading(info: I18n.Calendar_Common_LoadingCommon, disableUserInteraction: false))

            api?.getVideoChatByEvent(
                calendarID: calendarEvent.calendarID,
                key: calendarEvent.key,
                originalTime: Int(calendarEvent.originalTime),
                forceRenew: false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] videoMeeting in
                    guard let self = self else { return }
                    self.rxToast.accept(.remove)
                    self.jumpVideo(videoMeeting)
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    self.rxToast.accept(.failure(error.getTitle() ?? I18n.Calendar_Common_FailedToLoad))
                    self.trace?.reciableTraceEventDetailEnterMeetingFailed(
                        errorCode: Int(error.errorCode() ?? 0),
                        errorMessage: error.getMessage() ?? "" )
                }).disposed(by: bag)
        } else {
            guard let url = URL(string: videoMeeting.url) else {
                self.rxToast.accept(.failure(I18n.Calendar_Common_FailedToLoad))
                return
            }
            self.rxRoute.accept(.url(url: url))
        }
        self.trace?.reciableTraceEventDetailEndEnterMeeting()
    }

    private func jumpVideo(_ videoMeeting: VideoMeeting) {
        self.logger.info("jump video")

        if videoMeeting.isExpired {
            self.logger.info("jump video expired")
            rxToast.accept(.tips(I18n.Calendar_Detail_VCExpired))
            return
        }
        if calendarEvent.source == .people {
            api?.joinInterviewVideoMeeting(uniqueID: videoMeeting.uniqueId)
        } else {
            let instanceDetails = CalendarInstanceDetails(uniqueID: videoMeeting.uniqueId, key: calendarEvent.key, originalTime: calendarEvent.originalTime, instanceStartTime: calendarInstance.startTime, instanceEndTime: calendarInstance.endTime, isAudience: isWebinarAudience)
            if rxVChatStatus.value?.status == .live {
                api?.joinVideoMeeting(instanceDetails: instanceDetails, title: calendarEvent.displayTitle, isJoinMeeting: true, isWebinar: self.isWebinar)
                self.trace?.traceEventDetailJoinVideoMeeting(event: calendarEvent)
            } else {
                api?.joinVideoMeeting(instanceDetails: instanceDetails, title: calendarEvent.displayTitle, isJoinMeeting: false, isWebinar: self.isWebinar)
                self.trace?.traceEventDetailOpenVideoMeeting(event: calendarEvent)
            }
        }
    }

    private func tapLinkCopy() {

        logger.info("tap link copy action")

        self.trace?.traceEventDetailVideoMeetingClick(event: calendarEvent, click: "copy_vc_link")

        var copyMessage = ""

        if videoMeeting.type == .googleVideoConference {

            print("googleConfig \(calendarEvent.key)")

            let googleConfig = videoMeeting.pb.googleConfigs

            /*
             {User}邀请你加入视频会议
             会议主题：{subject}
             会议链接：{Url}
             手机拨号一键入会:  {phone_no}
             更多电话号码：{more_phone_number_link}
             */

            let userName = self.account?.userName ?? ""
            copyMessage.append(I18n.Calendar_Google_UserInvitesYouJoinMeeting(userName))
            copyMessage.append("\n")
            copyMessage.append(I18n.Calendar_Google_MeetingTopic(calendarEvent.displayTitle))
            copyMessage.append("\n")

            let url = videoMeeting.url
            if !url.isEmpty {
                copyMessage.append(I18n.Calendar_Google_MeetingURL(url))
                copyMessage.append("\n")
            }

            if !googleConfig.phoneNumber.isEmpty {
                copyMessage.append(I18n.Calendar_Google_DialViaPhone(googleConfig.phoneNumber))
                copyMessage.append("\n")
            }

            if !googleConfig.morePhoneNumberURL.isEmpty {
                copyMessage.append(I18n.Calendar_Google_MorePhoneNumbers(googleConfig.morePhoneNumberURL))
            }
        } else {
            copyMessage = rxPSTNInfo.value?.pstnCopyMessage ?? videoMeeting.url
        }

        do {
            let config = PasteboardConfig(token: Token(Self.copyMeetingInfoToken), shouldImmunity: true)
            try SCPasteboard.generalUnsafe(config).string = copyMessage
            self.rxToast.accept(.success(I18n.Calendar_Edit_JoinInfoCopied))
            self.trace?.traceEventDetailCopyVideoMeeting(event: calendarEvent)
        } catch {}
    }

    private func tapMorePhoneNumber() {
        logger.info("tap phone number action")
        if videoMeeting.type == .googleVideoConference {
            tapMorePhoneNumberForGoogle()
        } else {
            tapMorePhoneNumberForOther()
        }
    }

    private func tapMorePhoneNumberForGoogle() {
        guard let reachability = self.reachability, reachability.isReachable else {
            rxToast.accept(.failure(I18n.View_VM_UnstableConnectionTryAgain))
            return
        }
        let url = videoMeeting.pb.googleConfigs.morePhoneNumberURL
        if let url = URL(string: url) {
            self.rxRoute.accept(.url(url: url))
        }
        self.trace?.traceEventDetailVideoMeetingClick(event: calendarEvent, click: "join_phone_more")
    }

    private func tapMorePhoneNumberForOther() {
        self.rxRoute.accept(.pstnDetail(instanceDetails: self.instanceDetails,
                                        meetingUrl: videoMeeting.url,
                                        tenantID: eventTenantId))

        self.trace?.traceEventDetailVideoMeetingClick(event: calendarEvent, click: "join_phone_more")
    }

    private func tapSetting() {

        logger.info("tap setting action")

        guard !rxVideoMeeting.value.uniqueId.isEmpty else {
            self.rxToast.accept(.tips(I18n.Calendar_Common_FailedToLoad))
            return
        }

        if let status = rxVChatStatus.value?.status, status == .live {
            self.rxToast.accept(.tips(I18n.Calendar_Edit_MeetingCantChange))
            return
        }

        self.rxRoute.accept(.meetingSetting(instanceDetails: self.instanceDetails))
        self.trace?.traceEventDetailVideoMeetingClick(event: calendarEvent, click: "edit_vc_setting", target: "vc_meeting_pre_setting_view")
        self.trace?.traceEventDetailVCSetting()
    }
}

extension EventDetailTableVideoMeetingViewModel {
    enum Route {
        case meetingSetting(instanceDetails: CalendarInstanceDetails)
        case url(url: URL)
        case pstnDetail(instanceDetails: CalendarInstanceDetails,
                        meetingUrl: String,
                        tenantID: String)
    }
}

extension EventDetailTableVideoMeetingViewModel {
//    func isValidUrl(_ urlString: String) -> Bool {
//        if let url = NSURL(string: urlString) {
//            return UIApplication.shared.canOpenURL(url as URL)
//        }
//        return false
//    }

    func disableVideoMeeting(canRenew: Bool) -> Bool {
        let isExpired = rxVideoMeeting.value.isExpired
        let hasMeetingId = !rxVideoMeeting.value.uniqueId.isEmpty
        //不可刷新 且 (没有meetingID 或者 有meetingID但失效了)
        return !canRenew && ((isExpired && hasMeetingId) || !hasMeetingId)
    }

    var calendarEvent: Rust.CalendarEvent {
        rxEventData.value.event
    }

    var calendarInstance: Rust.CalendarInstance {
        rxEventData.value.instance
    }

    var videoMeeting: VideoMeeting {
        rxVideoMeeting.value
    }

    var eventTenantId: String {
        rxTenantID.value
    }

    var instanceDetails: CalendarInstanceDetails {
        CalendarInstanceDetails(uniqueID: videoMeeting.uniqueId,
                                key: calendarEvent.key,
                                originalTime: calendarEvent.originalTime,
                                instanceStartTime: calendarInstance.startTime,
                                instanceEndTime: calendarInstance.endTime,
                                isAudience: isWebinarAudience)
    }

    var isWebinar: Bool {
        rxEventData.value.event.category == .webinar
    }

    var isWebinarOrganizer: Bool {
        if !isWebinar { return false }
        let event = rxEventData.value.event
        return event.organizerCalendarID == event.calendarID
    }

    var isWebinarSpeaker: Bool {
        if !isWebinar { return false }
        let event = rxEventData.value.event
        return event.webinarInfo.selfWebinarAttendeeType == .speaker
    }

    var isWebinarAudience: Bool {
        if !isWebinar { return false }
        let event = rxEventData.value.event
        return event.webinarInfo.selfWebinarAttendeeType == .audience
    }

    var myDeviceID: String? {
        passportService?.deviceID
    }
}

struct DetailVideoMeetingCellModel: DetailVideoMeetingCellContent {
    var isLiving: Bool = false
    var summary: String
    var linkDesc: String
    var linkAvailableChecker: (() -> (meetingURL: Bool, moreNum: Bool))?
    var isLinkAvailable: Bool {
        linkAvailableChecker?().meetingURL ?? false
    }
    var isCopyAvailable: Bool = false
    var settingPermission: PermissionOption = .none
    var iconType: Rust.VideoMeetingIconType
    var durationTime: Int = 0
    var isWebinar: Bool = false
    var webinarRole: DetailVideoMeetingParticipantType = .unknown
    var isWebinarRehearsal = false
    var deviceJoinedText: String?
}

struct DetailVCPstnNumCellModel: DetailVideoMeetingCellPstnNumContent {
    var isMoreNumberAvailable: Bool = false
    var phoneNumber: String
}

extension EventDetailTableVideoMeetingViewModel {

    private func buildViewData(with videoMeeting: VideoMeeting,
                               vChatStatus: VideoChatStatus?,
                               joinedDevices: [Rust.JoinedDevice],
                               pstnInfo: PSTNInfo?,
                               disableVideoMeeting: Bool) -> DetailVideoMeetingCellContent {
        if videoMeeting.type == .googleVideoConference {
            // 谷歌视频会议
            // google 日程 VC 链接设计文档: https://bytedance.feishu.cn/docs/doccnIQ6szozi9MxnVBIAEiZDhC#
            let phoneNumber: String

            let googleConfig = videoMeeting.pb.googleConfigs
            logger.info("googleConfig.phoneNumber \(googleConfig.phoneNumber)")
            logger.info("googleConfig.morePhoneNumberURL \(googleConfig.morePhoneNumberURL)")

            let summary = I18n.Calendar_VideoMeeting_JoinVideoMeeting
            phoneNumber = googleConfig.phoneNumber

            let meetingURL = videoMeeting.url
            var linkStr = meetingURL
            // UI 展示中，不包含 `https://`、`http://` 等 schema 前缀
            if let upperBound = linkStr.range(of: "://")?.upperBound {
                linkStr = String(linkStr.suffix(from: upperBound))
            }

            return DetailVideoMeetingCellModel(
                summary: summary,
                linkDesc: linkStr,
                linkAvailableChecker: { [weak self] in
                    guard let self = self else { return (false, false) }
                    return (Utils.isValidUrl(meetingURL), Utils.isValidUrl(googleConfig.morePhoneNumberURL))
                },
                isCopyAvailable: true,
                iconType: .videoMeeting)
        } else {
            var settingPermission: PermissionOption = .none
            if calendarEvent.isEditable && videoMeeting.type == .vchat {
                if vChatStatus?.status == .live || videoMeeting.uniqueId.isEmpty {
                    settingPermission = .readable
                } else {
                    settingPermission = .writable
                }
            }

            var summary = I18n.Calendar_VideoMeeting_OpenVideoMeeting

            let isRehearsal = vChatStatus?.rehearsalMode ?? false
            let isRehearsing = vChatStatus?.isRehearsal ?? false
            var webinarRole: DetailVideoMeetingParticipantType = .unknown
            if isWebinar {
                if isWebinarSpeaker {
                    webinarRole = .organizer
                } else if isWebinarSpeaker {
                    webinarRole = .participant
                } else {
                    webinarRole = .attendee
                }
                // 对于组织者/嘉宾，显示为：开始彩排
                if isWebinarOrganizer || isWebinarSpeaker {
                    summary = isRehearsal ? I18n.View_G_StartRehearsal_Button : I18n.Calendar_G_StartWebinar
                } else {
                    // 对于观众，显示为：加入研讨会；（同现状，不希望观众感知到彩排）
                    summary = I18n.Calendar_G_JoinWebinar
                }
            }

            if videoMeeting.type == .other,
               case .otherConfigs(let configs) = videoMeeting.pb.customizedConfigs {
                if !configs.customizedDescription.isEmpty {
                    summary = configs.customizedDescription
                } else {
                    switch configs.icon {
                    case .live:
                        summary = I18n.Calendar_Edit_EnterLivestream
                    @unknown default:
                        summary = I18n.Calendar_Edit_JoinVC
                    }
                }
            }

            if videoMeeting.type == .unknownVideoMeetingType {
                summary = I18n.Calendar_Edit_JoinVC
            }

            if videoMeeting.url.isEmpty {
                if videoMeeting.type == .other || videoMeeting.type == .unknownVideoMeetingType {
                    return DetailVideoMeetingCellModel(
                        summary: summary,
                        linkDesc: I18n.Calendar_Edit_NoVCLink,
                        iconType: videoMeeting.pb.videoMeetingIconType)
                }

                return DetailVideoMeetingCellModel(
                    summary: summary,
                    linkDesc: I18n.Calendar_VideoMeeting_VCLinkOutofDate,
                    settingPermission: settingPermission,
                    iconType: videoMeeting.pb.videoMeetingIconType,
                    isWebinar: isWebinar,
                    webinarRole: webinarRole,
                    isWebinarRehearsal: isRehearsing)
            }

            var linkStr = videoMeeting.url
            // UI 展示中，不包含 `https://`、`http://` 等 schema 前缀
            if let upperBound = linkStr.range(of: "://")?.upperBound {
                linkStr = String(linkStr.suffix(from: upperBound))
            }

            let isLiving = vChatStatus?.status == .live
            let durationTime = vChatStatus?.durationTime ?? 0

            var deviceJoinedText = self.getDeviceJoinedText(vChatStatus: vChatStatus, joinedDevices: joinedDevices)

            return DetailVideoMeetingCellModel(
                isLiving: isLiving,
                summary: summary,
                linkDesc: linkStr,
                linkAvailableChecker: { [weak self] in
                    guard let self = self else { return (false, false) }
                    let isValidUrl = Utils.isValidUrl(videoMeeting.url)
                    let otherType = videoMeeting.type == .other
                    let isMeetingLinkAvailable = (!disableVideoMeeting || otherType) && isValidUrl
                    return (isMeetingLinkAvailable, true)
                },
                isCopyAvailable: true,
                settingPermission: settingPermission,
                iconType: videoMeeting.pb.videoMeetingIconType,
                durationTime: durationTime,
                isWebinar: isWebinar,
                webinarRole: webinarRole,
                isWebinarRehearsal: isRehearsing,
                deviceJoinedText: deviceJoinedText)
        }
    }

    private func getDeviceJoinedText(vChatStatus: VideoChatStatus?, joinedDevices: [Rust.JoinedDevice]) -> String? {
        // 当前日程的会议状态必须是进行中；当前用户须有设备在会中
        guard let vcStatus = vChatStatus, vcStatus.status == .live, !joinedDevices.isEmpty else {
            return nil
        }
        // joinedDevices 本来是不区分会议的，过滤在本日程会议中的设备
        let devicesInEvent = joinedDevices.filter { $0.meetingID == String(vcStatus.meetingID) }
        logger.info("count of joined device in this event: \(devicesInEvent.count)")

        if devicesInEvent.isEmpty { return nil }

        guard let myDeviceID = self.myDeviceID else {
            logger.warn("get deviceID failed!")
            return nil
        }

        var deviceJoinedText: String?
        let myDeviceJoined = devicesInEvent.contains { $0.deviceID == myDeviceID }
        if !myDeviceJoined {
            if devicesInEvent.count > 1 {
                deviceJoinedText = I18n.View_G_JoinedonOtherDevices_Desc("\(devicesInEvent.count)")
            } else if let device = devicesInEvent.first {
                deviceJoinedText = I18n.View_G_AlreadyJoinedOnThisTypeOfDevice_Desc(device.defaultDeviceName)
            }
        }
        logger.info("Is my device in the meeting: \(myDeviceJoined)")
        return deviceJoinedText
    }
}


extension EventDetailTableVideoMeetingViewModel {
    func getDateFromInt64(_ int: Int64) -> Date {
        let doubleTSP = Double(int)
        let date = Date(timeIntervalSince1970: doubleTSP)
        return date
    }
}

extension EventDetailTableVideoMeetingViewModel {
    func didGetAssociatedVideoChatStatus(_ status: GetAssociatedVideoChatStatusResponse) {
        logger.info("onPush: VideoChatStatus")
        let uniqueID = self.rxVideoMeeting.value.uniqueId
        guard !uniqueID.isEmpty, uniqueID == status.id else {
            logger.info("video meeting status push, skip!! id not match")
            return
        }
        switch status.idType {
        case .uniqueID, .interviewUid:
            logger.info("video meeting status push")
            updateVideoMeetingStatus()
        default:
            break
        }
    }
}

extension EventDetailTableVideoMeetingViewModel {
    func didGetCalendarEventVideoMeetingChange(_ data: CalendarEventVideoMeetingChangeData) {
        logger.info("onPush: CalendarEventVideoMeetingChange")
        let event = self.calendarEvent
        if let info = data.infos.last(where: {
            $0.calendarID == event.calendarID
            && $0.originalTime == event.originalTime
            && $0.key == event.key
        }) {
            logger.info("videomeeting push changed. update VChat videoMeeting")
            self.updateVChatVideoMeeting(with: VideoMeeting(pb: info.videoMeeting))
        }
    }
}

extension EventDetailTableVideoMeetingViewModel {
    func didGetVCJoinedDeviceInfoChange(_ data: VCJoinedDeviceInfoChangeData) {
        logger.info("onPush: VCJoinedDeviceInfoChange, count: \(data.infos.count)")
        self.updateJoinedDeviceInfos(from: data.infos)
    }
}

extension EventDetailTableVideoMeetingViewModel {

    func traceVideoMeetingShowIfNeeded(calendarEvent: Rust.CalendarEvent, with isInMeeting: Bool) {
        guard hasTracedShow == false else {
            return
        }
        hasTracedShow = true
        self.trace?.traceEventDetailVideoMeetingShowIfNeed(event: calendarEvent, with: isInMeeting)
    }
}


fileprivate extension Rust.JoinedDevice {
    var defaultDeviceName: String {
        switch self.osType {
        case .mac: return "Mac"
        case .windows: return "Windows"
        case .android: return "Android"
        case .iphone: return "iPhone"
        case .ipad: return "iPad"
        case .web: return "Web"
        case .linux: return "Linux"
        case .webMobile: return "WebMobile"
        default: return ""
        }
    }
}
