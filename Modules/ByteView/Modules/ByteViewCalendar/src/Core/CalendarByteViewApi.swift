//
//  CalendarByteViewApi.swift
//  ByteViewMod
//
//  Created by tuwenbo on 2022/9/15.
//

import Foundation
import ByteViewInterface
import EENavigator
import LarkUIKit
import LarkRustClient
import RustPB
import ServerPB
import RxSwift
import AppContainer
import LarkContainer
import ByteViewCommon

typealias I18n = BundleI18n.ByteViewCalendar

extension Logger {
    static let calendar = Logger.getLogger("Calendar")
}

final class CalendarByteViewApi {

    private let logger = Logger.calendar

    var rustService: RustService? { try? userResolver.resolve(assert: RustService.self) }
    lazy var pstnService: PSTNService? = { try? PSTNService(userResolver: userResolver) }()
    var navigator: Navigatable { userResolver.navigator }
    lazy var trace = CalendarTraceDep(userResolver: userResolver)

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func joinVideoMeeting(instanceDetails: CalendarInstanceDetails, title: String, isJoinMeeting: Bool, isWebinar: Bool) {
        logger.info("joinVideoMeeting, uniqueID: \(instanceDetails.uniqueID)")
        let fromVC = navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        let body = JoinMeetingByCalendarBody(uniqueId: instanceDetails.uniqueID, uid: instanceDetails.key,
                                             originalTime: instanceDetails.originalTime,
                                             instanceStartTime: instanceDetails.instanceStartTime,
                                             instanceEndTime: instanceDetails.instanceEndTime,
                                             title: title,
                                             entrySource: .calendarDetails,
                                             linkScene: false, isStartMeeting: !isJoinMeeting,
                                             isWebinar: isWebinar)
        navigator.push(body: body, from: fromVC)
    }

    func joinInterviewVideoMeeting(uniqueID: String) {
        logger.info("joinInterviewVideoMeeting, uniqueID: \(uniqueID)")
        let body = JoinMeetingBody(id: uniqueID, idType: .interview, entrySource: .calendarDetails)
        let fromVC = navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        navigator.push(body: body, from: fromVC)
    }

    func jumpToJoinVideoMeeting() {
        logger.info("jumpToJoinVideoMeeting")
        // entrySource 确认过无意义，已废弃的埋点
        let body = JoinMeetingBody(id: "", idType: .number, entrySource: .calendarDetails)
        let fromVC = navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        navigator.push(body: body, from: fromVC)
    }

    func showVideoMeetingSetting(instanceDetails: CalendarInstanceDetails, from: UIViewController) {
        logger.info("showVideoMeetingSetting, uniqueID: \(instanceDetails.uniqueID)")
        let body = VCCalendarSettingsBody(uniqueID: instanceDetails.uniqueID,
                                          uid: instanceDetails.key,
                                          originalTime: instanceDetails.originalTime,
                                          instanceStartTime: instanceDetails.instanceStartTime,
                                          instanceEndTime: instanceDetails.instanceEndTime)
        navigator.present(body: body, wrap: LkNavigationController.self, from: from,
                           prepare: { $0.modalPresentationStyle = .formSheet })
    }

    func showPSTNDetail(meetingUrl: String, tenantID: String, calendarType: VideoMeetingEventType,
                        instanceDetails: CalendarInstanceDetails,
                        from: UIViewController) {
        logger.info("showPSTNDetail, tenantID:\(tenantID), calendarType:\(calendarType)")
        pstnService?.showPstnDetail(meetingUrl: meetingUrl, tenantID: tenantID, calendarType: calendarType, instance: instanceDetails, from: from)
    }

    func fetchPSTNInfo(instanceDetails: CalendarInstanceDetails,
                       videoMeetingTitle: String,
                       videoMeetingURL: String,
                       isWebinar: Bool,
                       tenantID: String,
                       calendarType: VideoMeetingEventType,
                       meetingTimeDesc: String?,
                       callback: @escaping (PSTNInfoResponse?, Error?) -> Void) {
        logger.info("fetchPSTNInfo, uniqueID:\(instanceDetails.uniqueID), tenantID:\(tenantID), calendarType:\(calendarType)")
        pstnService?.fetchPstnInfo(instance: instanceDetails,
                                  videoMeetingTitle: videoMeetingTitle,
                                  videoMeetingURL: videoMeetingURL,
                                  isWebinar: isWebinar,
                                  tenantID: tenantID,
                                  calendarType: calendarType,
                                  meetingTimeDesc: meetingTimeDesc) { [weak self] result in
            switch result {
            case .success(let info):
                let psthInfoResponse = PSTNInfoResponseImpl(pstnCopyMessage: info.copyContent, adminSettings: "fake")
                callback(psthInfoResponse, nil)
            case .failure(let error):
                self?.logger.warn("fetchPstnInfo error: \(String(describing: error))")
                callback(nil, error)
            }
        }
    }

    func fetchPSTNNum(instanceDetails: CalendarInstanceDetails, tenantID: String, calendarType: VideoMeetingEventType, callback: @escaping (PSTNNumResponse?, Error?) -> Void) {
        logger.info("fetchPSTNNum, uniqueID:\(instanceDetails.uniqueID), tenantID:\(tenantID)")
        pstnService?.fetchPstnNum(instance: instanceDetails, tenantID: tenantID, calendarType: calendarType) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let res):
                let pstnNumResponse = PSTNNumResponseImpl(isPstnEnabled: res.isPstnEnabled, defaultPhoneNumber: res.defaultPhoneNumber)
                self.logger.info("fetchPSTNNum  success")
                callback(pstnNumResponse, nil)
            case .failure(let error):
                self.logger.warn("fetchPSTNNum error: \(String(describing: error))")
                callback(nil, error)
            }
        }
    }

    func getVideoChatByEvent(calendarID: String,
                             key: String,
                             originalTime: Int,
                             forceRenew: Bool) -> Observable<VideoMeeting> {
        var request = Rust.GetVideoMeetingByEventRequest()
        request.calendarID = calendarID
        request.key = key
        request.originalTime = Int64(originalTime)
        request.forceRenew = forceRenew
        logger.info("getVideoChatByEvent, calendarID: \(calendarID)")
        guard let rustService = rustService else { return .empty() }
        return rustService.sendAsyncRequest(request).map({ (response: Rust.GetVideoMeetingByEventResponse) -> VideoMeeting in
            return VideoMeeting(pb: response.videoMeeting)
        })
    }

    func getVideoMeetingStatusRequest(instanceDetails: CalendarInstanceDetails, source: VideoMeetingEventType) -> Observable<Server.CalendarVideoChatStatus> {
        var request = Server.GetCalendarVchatStatusRequest()
        request.uniqueID = Int64(instanceDetails.uniqueID) ?? 0
        request.calendarInstanceIdentifier.uid = instanceDetails.key
        request.calendarInstanceIdentifier.originalTime = instanceDetails.originalTime
        request.calendarInstanceIdentifier.instanceStartTime = instanceDetails.instanceStartTime
        request.calendarInstanceIdentifier.instanceEndTime = instanceDetails.instanceEndTime
        request.isAudience = instanceDetails.isAudience
        let reqStart = DispatchTime.now()
        var command: ServerCommand = .getCalendarVchatStatus

        if case .interview = source {
            command = .getInterviewVchatStatus
        }
        logger.info("getVideoMeetingStatusRequest, uniqueID: \(instanceDetails.uniqueID)")
        guard let rustService = rustService else { return .empty() }
        return rustService.sendPassThroughAsyncRequest(request, serCommand: command)
            .map { (response: Server.GetCalendarVchatStatusResponse) -> Server.CalendarVideoChatStatus in
            let reqEnd = DispatchTime.now()
            let reqTime = Double(reqEnd.uptimeNanoseconds - reqStart.uptimeNanoseconds) / 1_000_000
            var status = response.videoChatStatus
            status.clientRequestTime = Int64(reqTime)
            return status
        }
    }

    func getCanRenewExpiredVideoChat(calendarId: String,
                                     key: String,
                                     originalTime: Int64) -> Observable<Bool> {
        var request = Rust.GetCanRenewExpiredVideoMeetingNumberRequest()
        request.calendarID = calendarId
        request.key = key
        request.originalTime = originalTime
        logger.info("getCanRenewExpiredVideoChat, calendarId: \(calendarId)")
        guard let rustService = rustService else { return .empty() }
        return rustService.sendAsyncRequest(request)
            .map { (response: Rust.GetCanRenewExpiredVideoMeetingNumberResponse) -> Bool in
                response.canRenew
            }
    }

    func getJoinedDeviceInfos() -> Observable<[Rust.JoinedDevice]> {
        guard let rustService = rustService else { return .empty() }
        let request = Rust.GetJoinedDevicesInfoRequest()

        return rustService.sendAsyncRequest(request)
            .map { (response: Rust.GetJoinedDevicesInfoResponse) -> [Rust.JoinedDevice] in
                response.devices
            }
    }
}


enum VideoMeetingEventType: Int {
  case normal = 0
  case interview = 1
}

protocol PSTNInfoResponse {
    var pstnCopyMessage: String { get }     // 复制信息
    var adminSettings: String { get }
}

protocol PSTNNumResponse {
    var isPstnEnabled: Bool { get }         // pstn 信息是否展示
    var defaultPhoneNumber: String { get }  // 电话号码
}

struct PSTNInfoResponseImpl: PSTNInfoResponse {
    let pstnCopyMessage: String     // 复制信息
    let adminSettings: String
}

struct PSTNNumResponseImpl: PSTNNumResponse {
    let isPstnEnabled: Bool         // pstn 信息是否展示
    let defaultPhoneNumber: String  // 电话号码
}

public struct CalendarInstanceDetails {
    public let uniqueID: String
    public let key: String
    public let originalTime: Int64
    public let instanceStartTime: Int64
    public let instanceEndTime: Int64
    public let isAudience: Bool

    public init(
        uniqueID: String,
        key: String,
        originalTime: Int64,
        instanceStartTime: Int64,
        instanceEndTime: Int64,
        isAudience: Bool) {
            self.uniqueID = uniqueID
            self.key = key
            self.originalTime = originalTime
            self.instanceStartTime = instanceStartTime
            self.instanceEndTime = instanceEndTime
            self.isAudience = isAudience
    }
}
