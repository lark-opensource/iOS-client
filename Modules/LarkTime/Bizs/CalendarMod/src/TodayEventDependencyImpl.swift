//
//  TodayEventDependencyImpl.swift
//  CalendarMod
//
//  Created by chaishenghua on 2023/8/11.
//

import Calendar
import LarkContainer
#if ByteViewMod
import ByteViewInterface
#endif

class TodayEventDependencyImpl: TodayEventDependency, UserResolverWrapper {
    #if ByteViewMod
    private let buttonService: CalendarEventCardButtonService
    #endif
    var userResolver: LarkContainer.UserResolver

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        #if ByteViewMod
        self.buttonService = try userResolver.resolve(assert: CalendarEventCardButtonService.self)
        #endif
    }

    func createEventCardVCButton(_ info: ScheduleCardButtonModel) -> UIButton {
        #if ByteViewMod
        return buttonService.createEventCardButton(modelTransForm(info))
        #endif
        return UIButton()
    }

    func removeVCBtn(uniqueId: String) {
        #if ByteViewMod
        buttonService.remove(uniqueId: uniqueId)
        #endif
    }

    func updateButtonStatus(_ info: ScheduleCardButtonModel) {
        #if ByteViewMod
        buttonService.updateStatus(modelTransForm(info))
        #endif
    }

    func removeAllVCBtn() {
        #if ByteViewMod
        buttonService.removeAll()
        #endif
    }

    #if ByteViewMod
    private func modelTransForm(_ info: ScheduleCardButtonModel) -> EventCardButtonInfo {
        let videoMeetingType: EventCardButtonInfo.VideoMeetingType
        switch info.videoMeetingType {
        case .googleVideoConference:
            videoMeetingType = .googleVideoConference
        case .unknownVideoMeetingType:
            videoMeetingType = .unknownVideoMeetingType
        case .vchat:
            videoMeetingType = .vchat
        case .other:
            videoMeetingType = .other
        case .larkLiveHost:
            videoMeetingType = .larkLiveHost
        case .noVideoMeeting:
            videoMeetingType = .noVideoMeeting
        case .zoomVideoMeeting:
            videoMeetingType = .zoomVideoMeeting
        @unknown default:
            videoMeetingType = .unknownVideoMeetingType
            assertionFailure("Need to expand the type of VCBtn")
        }
        return EventCardButtonInfo(uniqueId: info.uniqueId,
                                   key: info.key,
                                   originalTime: info.originalTime,
                                   startTime: info.startTime,
                                   endTime: info.endTime,
                                   displayTitle: info.displayTitle,
                                   isFromPeople: info.isFromPeople,
                                   isWebinar: info.isWebinar,
                                   isWebinarOrganizer: info.isWebinarOrganizer,
                                   isWebinarSpeaker: info.isWebinarSpeaker,
                                   isWebinarAudience: info.isWebinarAudience,
                                   videoMeetingType: videoMeetingType,
                                   url: info.url,
                                   isExpired: info.isExpired,
                                   isTop: info.isTop,
                                   feedTab: info.feedTab)
    }
    #endif
}
