//
//  ByteViewCalendarAssembly.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/21.
//

import Foundation
import Swinject
import LarkAssembler
import EENavigator
import LarkAppLinkSDK
import CalendarFoundation
import ByteViewInterface

public final class ByteViewCalendarAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)
        user.register(CalendarByteViewApi.self) {
            CalendarByteViewApi(userResolver: $0)
        }

        user.register(CalendarSettingService.self) {
            CalendarSettingServiceImpl(userResolver: $0)
        }

        user.register(CalendarEventCardButtonService.self) {
            CalendarEventCardButtonServiceImpl(userResolver: $0)
        }
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(OpenCalendarLiveByLinkBody.self).factory(OpenCalendarLiveByLinkHandler.init(resolver:))
    }

    public func registLarkAppLink(container: Container) {
        // 注册日历直播 AppLink 协议
        LarkAppLinkSDK.registerHandler(path: OpenCalendarLiveByLinkBody.path, handler: { (appLink: AppLink) in
            OpenCalendarLiveLinkHandler().handle(appLink: appLink)
        })
    }

    @_silgen_name("Lark.CalendarEventDetail_AttachableComponent_regist.ByteViewMod")
    public static func calendarComponentRegister() {
        CalendarAttachableComponentRegistery.register(identifier: .larkMeeting, type: EventDetailTableVideoMeetingComponent.self)
    }

    @_silgen_name("Lark.TodayEvent.ByteView.EventCard")
    public static func eventCardRegister() {
         EventFeedCardModule.register(type: CalendarEventFeedCardSubModule.self)
    }
}
