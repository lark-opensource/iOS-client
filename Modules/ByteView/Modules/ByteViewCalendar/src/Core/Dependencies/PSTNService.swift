//
//  PSTNService.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/21.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting
import LarkContainer

final class PSTNService {
    private let logger = Logger.getLogger("PSTNService")
    let setting: UserSettingManager
    let userResolver: UserResolver
    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.setting = try userResolver.resolve(assert: UserSettingManager.self)
    }

    func fetchPstnInfo(instance: CalendarInstanceDetails,
                       videoMeetingTitle: String,
                       videoMeetingURL: String,
                       isWebinar: Bool,
                       tenantID: String,
                       calendarType: VideoMeetingEventType,
                       meetingTimeDesc: String?,
                       completion: @escaping (Result<MeetingCopyInfoResponse, Error>) -> Void) {
        logger.info("fetchPstnInfo(instance: \(instance), meetingUrl: \(videoMeetingURL.hashValue), tenantID: \(tenantID), calendarType: \(calendarType))")
        let info = MeetingCopyInfoRequest.CalendarInfo(tenantId: tenantID, uniqueId: instance.uniqueID, instance: instance.toIdentifier())
        let request = MeetingCopyInfoRequest(type: .calendar(info), topic: videoMeetingTitle, meetingURL: videoMeetingURL, isWebinar: isWebinar, isInterview: calendarType == .interview, meetingTime: meetingTimeDesc, meetingNumber: nil, isE2EeMeeting: false)
        setting.fetchCopyInfo(request) { [weak self] result in
            switch result {
            case .success:
                self?.logger.info("fetch pstn info success")
            case .failure(let error):
                self?.logger.error("fetch pstn info failure, error: \(error)")
            }
            completion(result)
        }
    }

    func fetchPstnNum(instance: CalendarInstanceDetails, tenantID: String, calendarType: VideoMeetingEventType,
                      completion: @escaping (Result<PstnIncomingCallInfo, Error>) -> Void) {
        setting.fetchPstnIncomingCallInfo(tenantId: tenantID, uniqueId: instance.uniqueID, isInterview: calendarType == .interview, calendarIdentifier: instance.toIdentifier()) { [weak self] result in
            switch result {
            case .success(let info):
                self?.logger.info("PstnInComingCallInfoRequest \(info.isPstnEnabled) \(info.phoneList.count), uniqueID: \(instance.uniqueID)")
            case .failure(let error):
                self?.logger.error("PstnInComingCallInfoRequest \(error)")
            }
            completion(result)
        }
    }

    func showPstnDetail(meetingUrl: String, tenantID: String, calendarType: VideoMeetingEventType, instance: CalendarInstanceDetails, from: UIViewController) {
        logger.info("showPstnDetail(meetingUrl: \(meetingUrl.hashValue), tenantID: \(tenantID)), uniqueID: \(instance.uniqueID), calendarType: \(calendarType)")
        setting.fetchPstnIncomingCallInfo(tenantId: tenantID, uniqueId: instance.uniqueID, isInterview: calendarType == .interview, calendarIdentifier: instance.toIdentifier()) { [weak self, weak from] result in
            switch result {
            case .success(let info):
                Util.runInMainThread {
                    if let from = from, let dependency = try? self?.userResolver.resolve(assert: ByteViewCalendarDependency.self) {
                        let meetingNumber = String(meetingUrl.split(separator: "/").last ?? "")
                        dependency.showPstnPhones(meetingNumber: meetingNumber, phones: info.phoneList, from: from)
                    }
                }
                self?.logger.info("show pstn detail VC success through PstnInComingCallInfoRequest \(info.isPstnEnabled), listcount: \(info.phoneList.count)")
            case .failure:
                self?.logger.error("show pstn detail VC failure because fetth PstnInComingCallInfoRequest failure")
            }
        }
    }
}

private extension CalendarInstanceDetails {
    func toIdentifier() -> CalendarInstanceIdentifier {
        CalendarInstanceIdentifier(uid: self.key, originalTime: self.originalTime, instanceStartTime: self.instanceStartTime, instanceEndTime: self.instanceEndTime)
    }
}
