//
//  EventDetailTableOtherMeetingViewModel.swift
//  Calendar
//
//  Created by tuwenbo on 2022/11/21.
//

import Foundation
import RxSwift
import RxRelay
import LarkContainer
import LarkFoundation
import LarkTimeFormatUtils
import CalendarFoundation
import AppReciableSDK
import UIKit
import LarkUIKit
import Reachability
import LarkEMM

final class EventDetailTableOtherMeetingViewModel: EventDetailComponentViewModel {

    var hasTracedShow = false
    let rxViewData = BehaviorRelay<DetailOtherMeetingCellContent?>(value: nil)
    let rxRoute = PublishRelay<Route>()
    let rxToast = PublishRelay<ToastStatus>()

    let rxParsedMeetingLinks = BehaviorRelay<[ParsedEventMeetingLink]>(value: [])

    @ScopedInjectedLazy
    private var calendarDependency: CalendarDependency?

    @ScopedInjectedLazy
    private var calendarApi: CalendarRustAPI?

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
    private let rxVideoMeeting: BehaviorRelay<VideoMeeting>
    private let rxTenantID: BehaviorRelay<String>
    private let reachability = Reachability()
    private let bag = DisposeBag()

    override init(context: EventDetailContext, userResolver: UserResolver) {
        var initEvent = EventDetail.Event()
        if let event = context.rxModel.value.event {
            initEvent = event
        }

        self.rxVideoMeeting = BehaviorRelay(value: VideoMeeting(pb: initEvent.videoMeeting))

        let tenantID = !initEvent.organizer.dt.tenantId.isEmpty ? initEvent.organizer.dt.tenantId : initEvent.creator.dt.tenantId
        self.rxTenantID = BehaviorRelay(value: tenantID)

        super.init(context: context, userResolver: userResolver)

        bindRx()

        if videoMeeting.type == .other {
           traceVideoMeetingShowIfNeeded()
        }
    }

    private func bindRx() {
        rxModel.compactMap { model -> VideoMeeting? in
            if let videoMeeting = model.event?.videoMeeting {
                return VideoMeeting(pb: videoMeeting)
            }
            return nil
        }.bind { [weak self] meeting in
            guard let self = self else { return }
            self.updateVideoMeeting(with: meeting)
            self.parseEventMeetingLinks()
        }.disposed(by: bag)

        Observable.combineLatest(rxVideoMeeting.distinctUntilChanged(),
                                 rxParsedMeetingLinks)
        .compactMap { [weak self] videoMeeting, _ in
            guard let self = self else { return nil }
            EventDetail.logInfo("update other meeting view data")
            return self.buildViewData(with: videoMeeting)
        }
       .bind(to: rxViewData)
       .disposed(by: bag)
    }

    private func buildViewData(with videoMeeting: VideoMeeting) -> DetailOtherMeetingCellModel {
        if videoMeeting.type == .googleVideoConference {
            // 谷歌视频会议
            // google 日程 VC 链接设计文档: https://bytedance.feishu.cn/docs/doccnIQ6szozi9MxnVBIAEiZDhC#
            let phoneNumber: String

            let googleConfig = videoMeeting.pb.googleConfigs
            EventDetail.logInfo("googleConfig.phoneNumber \(googleConfig.phoneNumber)")
            EventDetail.logInfo("googleConfig.morePhoneNumberURL \(googleConfig.morePhoneNumberURL)")

            let summary = BundleI18n.Calendar.Calendar_VideoMeeting_JoinVideoMeeting
            phoneNumber = googleConfig.phoneNumber

            let meetingURL = videoMeeting.url
            var linkStr = meetingURL
            // UI 展示中，不包含 `https://`、`http://` 等 schema 前缀
            if let upperBound = linkStr.range(of: "://")?.upperBound {
                linkStr = String(linkStr.suffix(from: upperBound))
            }

            return DetailOtherMeetingCellModel(
                summary: summary,
                linkDesc: linkStr,
                linkAvailableChecker: { [weak self] in
                    guard let self = self else { return (false, false) }
                    return (self.isValidUrl(meetingURL), self.isValidUrl(googleConfig.morePhoneNumberURL))
                },
                isCopyAvailable: true,
                iconType: .videoMeeting,
                phoneNumber: phoneNumber)
        } else {
            // 会议链接优化
            if model.isMeetingLinkParsable {
                if isMeetingLinkParsed {
                    // 如果解析到只一个会议链接，则展示之
                    if let parsedLink = getParsedLinkIfOnlyOne() {
                        EventDetail.logInfo("meeting link parsable, get only one link")
                        return DetailOtherMeetingCellModel(
                            summary: getMeetingButtonText(by: parsedLink.vcType),
                            linkDesc: parsedLink.vcLink,
                            linkAvailableChecker: { [weak self] in
                                guard let self = self else { return (false, false) }
                                return (self.isValidUrl(parsedLink.vcLink), false)
                            },
                            isCopyAvailable: true,
                            iconType: videoMeeting.pb.videoMeetingIconType)
                    } else {
                        EventDetail.logInfo("meeting link parsable, get more than one link")
                        return DetailOtherMeetingCellModel(
                            summary: BundleI18n.Calendar.Calendar_Detail_JoinVC,
                            linkAvailableChecker: { [weak self] in
                                return (true, false)
                            },
                            iconType: videoMeeting.pb.videoMeetingIconType)
                    }
                } else {
                    // 被骗了，没解析到会议链接
                    EventDetail.logInfo("meeting link parsable, but get zero link, hide view")
                    return DetailOtherMeetingCellModel(
                        summary: BundleI18n.Calendar.Calendar_Detail_JoinVC,
                        linkDesc: BundleI18n.Calendar.Calendar_Edit_NoVCLink,
                        iconType: videoMeeting.pb.videoMeetingIconType,
                        isMeetingInvalid: true)
                }
            }

            var summary = BundleI18n.Calendar.Calendar_VideoMeeting_OpenVideoMeeting

            if videoMeeting.type == .other,
               case .otherConfigs(let configs) = videoMeeting.pb.customizedConfigs {
                if !configs.customizedDescription.isEmpty {
                    summary = configs.customizedDescription
                } else {
                    switch configs.icon {
                    case .live:
                        summary = BundleI18n.Calendar.Calendar_Edit_EnterLivestream
                    @unknown default:
                        summary = BundleI18n.Calendar.Calendar_Edit_JoinVC
                    }
                }
            }

            if videoMeeting.type == .unknownVideoMeetingType {
                summary = BundleI18n.Calendar.Calendar_Edit_JoinVC
            }

            // 没有会议链接的 OtherMeeting 一律不再展示会议按钮等信息
            if videoMeeting.url.isEmpty {
                if videoMeeting.type == .other || videoMeeting.type == .unknownVideoMeetingType {
                    return DetailOtherMeetingCellModel(
                        summary: summary,
                        linkDesc: BundleI18n.Calendar.Calendar_Edit_NoVCLink,
                        iconType: videoMeeting.pb.videoMeetingIconType,
                        isMeetingInvalid: true)
                }

                return DetailOtherMeetingCellModel(
                    summary: summary,
                    linkDesc: BundleI18n.Calendar.Calendar_VideoMeeting_VCLinkOutofDate,
                    iconType: videoMeeting.pb.videoMeetingIconType,
                    isMeetingInvalid: true)
            }

            // 旧版本会存储所有类型链接，4.0后仅会存储VCHAT、LARK_LIVE_HOST等从VC获取的链接
            var linkStr = videoMeeting.url
            // UI 展示中，不包含 `https://`、`http://` 等 schema 前缀
            if let upperBound = linkStr.range(of: "://")?.upperBound {
                linkStr = String(linkStr.suffix(from: upperBound))
            }

            return DetailOtherMeetingCellModel(
                summary: summary,
                linkDesc: linkStr,
                linkAvailableChecker: { [weak self] in
                    guard let self = self else { return (false, false) }
                    let isValidUrl = self.isValidUrl(videoMeeting.url)
                    let otherType = videoMeeting.type == .other
                    let isMeetingLinkAvailable = (!self.disableVideoMeeting || otherType) && isValidUrl
                    let isMoreNumAvailable = false
                    return (isMeetingLinkAvailable, isMoreNumAvailable)
                },
                isCopyAvailable: true,
                iconType: videoMeeting.pb.videoMeetingIconType)
        }
    }

    private func updateVideoMeeting(with videoMeeting: VideoMeeting) {
        guard videoMeeting != self.rxVideoMeeting.value else { return }
        EventDetail.logInfo("update other video meeting")
        // 更新VideoMeeting
        self.rxVideoMeeting.accept(videoMeeting)
    }
}

extension EventDetailTableOtherMeetingViewModel {
    enum Route {
        case url(url: URL)
        case applink(url: URL, vcType: Rust.ParsedMeetingLinkVCType)
        case selector(parsedMeetingLinks: [ParsedEventMeetingLink])
    }

    enum Action {
        case dail
        case videoMeeting
        case linkCopy
        case morePhoneNumber
    }

    func action(_ action: Action) {
        switch action {
        case .dail: tapDail()
        case .videoMeeting: tapVideoMeeting()
        case .linkCopy: tapLinkCopy()
        case .morePhoneNumber: tapMorePhoneNumber()
        }
    }

    private func tapDail() {
        EventDetail.logInfo("tap dail action")

        CalendarTracerV2.EventDetail.traceClick {
            $0.click(CalendarTracer.EventClickType.joinPhone.value).target(CalendarTracer.EventClickType.joinPhone.target)
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.rxModel.value.instance, event: self.event))
        }

        var phoneNumWithID = getPhoneNumberWithID()
        if Display.pad {
            SCPasteboard.generalPasteboard(shouldImmunity: true).string = phoneNumWithID
            self.rxToast.accept(.success(BundleI18n.Calendar.View_M_PhoneNumberAndMeetingIdCopied))
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
        var phoneNumber: String = ""

        if videoMeeting.type == .googleVideoConference {
            var number = videoMeeting.pb.googleConfigs.phoneNumber
            number = number.replacingOccurrences(of: "[a-zA-Z()]", with: "", options: .regularExpression)
            number = number.replacingOccurrences(of: ":", with: ",,", options: .regularExpression)
            phoneNumber = number
        }

        return phoneNumber
    }

    private func tapVideoMeeting() {
        EventDetail.logInfo("tap videomeeting action")

        ReciableTracer.shared.recStartJumpVideo()
        if videoMeeting.type == .googleVideoConference {
            let urlString = videoMeeting.url

            guard let url = URL(string: urlString) else {
                EventDetail.logInfo("cannot jump url, url is invalid")
                return
            }
            if urlString.contains("meet.google.com") {
                // 跳转 google app
                self.rxRoute.accept(.applink(url: url, vcType: .google))
                CalendarTracerV2.EventDetail.traceClick(commonParam: CommonParamData(instance: self.rxModel.value.instance, event: self.event)) {
                    $0.click("enter_vc")
                    $0.vchat_type = String(describing: "google")
                    $0.link_type = "original"
                }
            } else {
                // 路由兜底
                self.rxRoute.accept(.url(url: url))
            }
        } else {
            // 会议链接优化，如果解析到只一个会议链接，则展示之
            if isMeetingLinkParsed {
                let parsedLinks = rxParsedMeetingLinks.value
                if parsedLinks.count > 1 {
                    self.rxRoute.accept(.selector(parsedMeetingLinks: parsedLinks))
                } else {
                    if let parsedLink = parsedLinks.first, let url = URL(string: parsedLink.vcLink) {
                        self.rxRoute.accept(.applink(url: url, vcType: parsedLink.vcType))
                        CalendarTracerV2.EventDetail.traceClick(commonParam: CommonParamData(instance: self.rxModel.value.instance, event: self.event)) {
                            $0.click("enter_vc")
                            $0.vchat_type = String(describing: parsedLink.vcType)
                            $0.link_type = "parse"
                        }
                    }
                }
                return
            }

            CalendarTracerV2.EventDetail.traceClick {
                $0.click("enter_vc").target("vc_meeting_pre_view")
                $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.rxModel.value.instance, event: self.event))
            }

            guard let url = URL(string: videoMeeting.url) else {
                self.rxToast.accept(.failure(BundleI18n.Calendar.Calendar_Common_FailedToLoad))
                return
            }
            self.rxRoute.accept(.url(url: url))
        }
        ReciableTracer.shared.recEndJumpVideo()
    }

    private func tapLinkCopy() {

        EventDetail.logInfo("tap link copy action")

        CalendarTracerV2.EventDetail.traceClick {
            $0.click("copy_vc_link").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.rxModel.value.instance, event: self.event))
        }

        if videoMeeting.type == .googleVideoConference {
            print("googleConfig \(event.key)")
            let googleConfig = videoMeeting.pb.googleConfigs

            /*
             {User}邀请你加入视频会议
             会议主题：{subject}
             会议链接：{Url}
             手机拨号一键入会:  {phone_no}
             更多电话号码：{more_phone_number_link}
             */

            var copyMessage = ""
            let userName = calendarDependency?.currentUser.displayName ?? ""
            copyMessage.append(BundleI18n.Calendar.Calendar_Google_UserInvitesYouJoinMeeting(User: userName))
            copyMessage.append("\n")
            copyMessage.append(BundleI18n.Calendar.Calendar_Google_MeetingTopic(subject: event.dt.displayTitle))
            copyMessage.append("\n")

            let url = videoMeeting.url
            if !url.isEmpty {
                copyMessage.append(BundleI18n.Calendar.Calendar_Google_MeetingURL(Url: url))
                copyMessage.append("\n")
            }

            if !googleConfig.phoneNumber.isEmpty {
                copyMessage.append(BundleI18n.Calendar.Calendar_Google_DialViaPhone(phone_no: googleConfig.phoneNumber))
                copyMessage.append("\n")
            }

            if !googleConfig.morePhoneNumberURL.isEmpty {
                copyMessage.append(BundleI18n.Calendar.Calendar_Google_MorePhoneNumbers(more_phone_number_link: googleConfig.morePhoneNumberURL))
            }

            SCPasteboard.generalPasteboard(shouldImmunity: true).string = copyMessage
            self.rxToast.accept(.success(BundleI18n.Calendar.Calendar_Edit_JoinInfoCopied))

        } else {
            var copyMessage = videoMeeting.url
            if let parsedLink = getParsedLinkIfOnlyOne() {
                copyMessage = parsedLink.vcLink
            }
            SCPasteboard.generalPasteboard(shouldImmunity: true).string = copyMessage
            self.rxToast.accept(.success(BundleI18n.Calendar.Calendar_VideoMeeting_VCLinkSuccess))
        }

        let eventType: CalendarTracer.EventType = event.type == .meeting ? .meeting : .event
        CalendarTracer.shareInstance.calCopyVideoMeeting(eventType: eventType)
    }

    private func tapMorePhoneNumber() {
        EventDetail.logInfo("tap phone number action")
        guard let reachability = self.reachability, reachability.isReachable else {
            rxToast.accept(.failure(BundleI18n.Calendar.View_VM_UnstableConnectionTryAgain))
            return
        }
        if videoMeeting.type == .googleVideoConference {
            let url = videoMeeting.pb.googleConfigs.morePhoneNumberURL
            if let url = URL(string: url) {
                self.rxRoute.accept(.url(url: url))
            }
            CalendarTracerV2.EventDetail.traceClick {
                $0.click(CalendarTracer.EventClickType.joinPhone.value).target(CalendarTracer.EventClickType.joinPhone.target)
                $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.rxModel.value.instance, event: self.event))
            }
        }
    }
}

extension EventDetailTableOtherMeetingViewModel {
    func isValidUrl(_ urlString: String) -> Bool {
        if let url = NSURL(string: urlString) {
            return UIApplication.shared.canOpenURL(url as URL)
        }
        return false
    }

    func getDateFromInt64(_ int: Int64) -> Date {
        let doubleTSP = Double(int)
        let date = Date(timeIntervalSince1970: doubleTSP)
        return date
    }

    var disableVideoMeeting: Bool {
        return rxVideoMeeting.value.uniqueId.isEmpty
    }

    var videoMeeting: VideoMeeting {
        rxVideoMeeting.value
    }

    var eventTenantId: String {
        rxTenantID.value
    }

    var instanceDetails: CalendarInstanceDetails {
        CalendarInstanceDetails(uniqueID: videoMeeting.uniqueId,
                                key: event.key,
                                originalTime: event.originalTime,
                                instanceStartTime: model.startTime,
                                instanceEndTime: model.endTime)
    }
}

struct DetailOtherMeetingCellModel: DetailOtherMeetingCellContent {
    var summary: String
    var linkDesc: String = ""
    var linkAvailableChecker: (() -> (meetingURL: Bool, moreNum: Bool))?
    var isLinkAvailable: Bool {
        linkAvailableChecker?().meetingURL ?? false
    }
    var isMoreNumberAvailable: Bool {
        linkAvailableChecker?().moreNum ?? false
    }
    var isCopyAvailable: Bool = false
    var iconType: Rust.VideoMeetingIconType
    var phoneNumber: String = ""
    var isMeetingInvalid: Bool = false
}

extension EventDetailTableOtherMeetingViewModel {
    func traceVideoMeetingShowIfNeeded() {
        guard hasTracedShow == false else {
            return
        }
        hasTracedShow = true
        CalendarTracerV2.EventDetailVideoMeeting.traceView {
            $0.is_in_meeting = "false"
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.rxModel.value.instance, event: self.event))
        }
    }
}

// MARK: 会议链接优化
extension EventDetailTableOtherMeetingViewModel {

    var isMeetingLinkParsed: Bool {
        let parsed = model.isMeetingLinkParsable && !rxParsedMeetingLinks.value.isEmpty
        EventDetail.logInfo("isMeetingLinkParsed: \(parsed)")
        return parsed
    }

    // 只有当 parsedMeetingLinks 有且只有一个元素时，返回之
    private func getParsedLinkIfOnlyOne() -> ParsedEventMeetingLink? {
        guard isMeetingLinkParsed else { return nil }
        if rxParsedMeetingLinks.value.count > 1 {
            return nil
        }
        return rxParsedMeetingLinks.value.first
    }

    private func parseEventMeetingLinks() {
        guard model.isMeetingLinkParsable else { return }
        if event.location.location.isEmpty && event.description_p.isEmpty { return }
        calendarApi?.parseEventMeetingLinks(eventLocation: event.location.location,
                                           eventDescription: event.description_p,
                                           eventSource: event.source,
                                           resourceName: [])
        .subscribe(onNext: {[weak self] resp in
            guard let self = self else { return }
            let locationVC = resp.locationItem.filter { $0.linkType == .vcLink && $0.vcType != .unknown }.map {
                ParsedEventMeetingLink(vcType: $0.vcType, vcLink: $0.locationURL.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            let descriptionVC = resp.descriptionLink.filter { $0.vcType != .unknown }.map { ParsedEventMeetingLink(vcType: $0.vcType, vcLink: $0.descriptionURL) }
            let links = self.duplicateLinksInOrder(locationVC + descriptionVC)
            if !links.isEmpty {
                EventDetail.logInfo("get \(links.count) links from parseEventMeetingLinks")
                self.rxParsedMeetingLinks.accept(links)
            }
            self.traceParsedLink()
        }, onError: { error in
            EventDetail.logError("parseEventMeetingLinks failed: \(error)")
        }).disposed(by: bag)
    }

    private func duplicateLinksInOrder(_ links: [ParsedEventMeetingLink]) -> [ParsedEventMeetingLink] {
        var newLinks: [ParsedEventMeetingLink] = []
        for item in links {
            if !newLinks.contains(item) {
                newLinks.append(item)
            }
        }
        return newLinks
    }

    private func getMeetingButtonText(by vcType: Rust.ParsedMeetingLinkVCType) -> String {
        switch vcType {
        case .google:
            return BundleI18n.Calendar.Calendar_Join_GoogleMeet
        case .zoom:
            return BundleI18n.Calendar.Calendar_Zoom_JoinMeetButton
        case .teams:
            return BundleI18n.Calendar.Calendar_Join_Teams
        case .webex:
            return BundleI18n.Calendar.Calendar_Join_Webex
        case .bluejeans:
            return BundleI18n.Calendar.Calendar_Join_BlueJeans
        case .tencent:
            return BundleI18n.Calendar.Calendar_Join_VooVMeeting
        case .lark:
            return BundleI18n.Calendar.Calendar_Join_BrandMeeting()
        @unknown default:
            return BundleI18n.Calendar.Calendar_Detail_JoinVC
        }
    }

    private func traceParsedLink() {
        if isMeetingLinkParsed {
            var parsedDict: [String: Int] = [:]
            for item in rxParsedMeetingLinks.value {
                parsedDict[String(describing: item.vcType), default: 0] += 1
            }
            CalendarTracerV2.EventDetailParseVC.traceView {
                $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.rxModel.value.instance, event: self.event))
                $0.parse_vc_link_num = parsedDict.description
            }
        }
    }
}

struct ParsedEventMeetingLink: Hashable {
    var vcType: Rust.ParsedMeetingLinkVCType
    var vcLink: String
}
