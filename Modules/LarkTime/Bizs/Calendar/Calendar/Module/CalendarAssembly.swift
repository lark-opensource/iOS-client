//
//  CalendarAssembly.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/25.
//

import UIKit
import Swinject
import LarkContainer
import AnimatedTabBar
import EENavigator
import LarkTab
import LarkRustClient
import RxSwift
import RxCocoa
import LarkGuide
import LarkMessageBase
import LarkModel
import CalendarRichTextEditor
import LarkAppConfig
import RustPB
import LarkAccountInterface
import AppContainer
import BootManager
import LarkOpenChat
import LarkAssembler
import LKCommonsTracker
import LarkNavigation
import LarkUIKit
import LarkAlertController
import UniverseDesignToast
import UniverseDesignIcon
import LarkDebugExtensionPoint
import LarkOpenSetting
import LarkReleaseConfig
import LarkSetting
import LKCommonsLogging
import LarkAIInfra
import LarkEnv

typealias DomainSettings = InitSettingKey
typealias Assemble = (Container) -> Void
typealias I18n = BundleI18n.Calendar

public final class CalendarAssembly: LarkAssemblyInterface {
    let disposeBag = DisposeBag()
    let logger = Logger.log(CalendarAssembly.self, category: "calendar.CalendarAssembly")

    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)

        user.register(CalendarManager.self) { userResolver -> CalendarManager in
            try CalendarManager(userResolver: userResolver)
        }

        user.register(TimeZoneService.self) { userResolver -> TimeZoneServiceImpl in
            try TimeZoneServiceImpl(userResolver: userResolver)
        }

        user.register(TimeZoneSelectService.self) { userResolver -> TimeZoneService in
            try userResolver.resolve(assert: TimeZoneService.self)
        }

        user.register(LocalRefreshService.self) { _ in
            return LocalRefreshService()
        }

        user.register(DocsDispatherSerivce.self) { userResolver in
            try DocsDispatherSerivceImpl(userResolver: userResolver)
        }

        user.register(CalendarInterface.self) { userResolver -> CalendarInterfaceImpl in
            let dependency = try userResolver.resolve(assert: CalendarDependency.self)
            return try CalendarInterfaceImpl(with: dependency, userResolver: userResolver)
        }

        user.register(CalendarRustAPI.self) { userResolver -> CalendarRustAPI in
            let rustService = try userResolver.resolve(assert: RustService.self)
            return try CalendarRustAPI(rustClient: rustService, userResolver: userResolver)
        }
        
        user.register(TimeBlockAPI.self) { userResolver -> TimeBlockAPI in
            let rustService = try userResolver.resolve(assert: RustService.self)
            return try CalendarRustAPI(rustClient: rustService, userResolver: userResolver)
        }

        user.register(TimeContainerAPI.self) { userResolver -> TimeContainerAPI in
            let rustService = try userResolver.resolve(assert: RustService.self)
            return try CalendarRustAPI(rustClient: rustService, userResolver: userResolver)
        }

        user.register(RustPushService.self) { _ -> RustPushService in
            return RustPushService()
        }

        user.register(ServerPushService.self) { _ -> ServerPushService in
            return ServerPushService()
        }

        user.register(ReminderService.self) { userResolver -> ReminderService in
            try ReminderServiceImpl(userResolver: userResolver)
        }
        
        user.register(CalendarMyAIService.self) { userResolver -> CalendarMyAIService in
            let myAIExtensionService = try userResolver.resolve(assert: MyAIExtensionService.self)
            let myAIInfoService = try userResolver.resolve(assert: MyAIInfoService.self)
            return CalendarMyAIServiceImpl(userResolver: userResolver, myAIExtensionService: myAIExtensionService, myAIInfoService: myAIInfoService)
        }

        user.register(CalendarHome.self) { userResolver -> CalendarHome in
            let calendarInterface = try userResolver.resolve(assert: CalendarInterface.self)
            return calendarInterface.calendarHome()
        }

        user.register(TabBarView.self) { _ -> TabBarView in
            return TabBarViewImpl()
        }

        user.register(InterviewChatService.self) { userResolver -> InterviewChatService in
            try InterviewChatServiceImpl(userResolver: userResolver)
        }

        user.register(CalendarSelectTracer.self) { userResolver -> CalendarSelectTracer in
            try CalendarSelectTracer(userResolver: userResolver)
        }

        user.register(CalendarSubscribeTracer.self) { _ -> CalendarSubscribeTracer in
            return CalendarSubscribeTracer()
        }

        user.register(MeetingRoomHomeTracer.self) { _ -> MeetingRoomHomeTracer in
            return MeetingRoomHomeTracer()
        }

        user.register(MailContactService.self) { userResolver -> MailContactService in
            return MailContactService(userResolver: userResolver)
        }

        user.register(TodayEventService.self) { userResolver -> TodayEventService in
            try TodayEventServiceImpl(userResolver: userResolver)
        }
        
        user.register(TimeDataService.self) { userResolver -> TimeDataService in
            TimeDataServiceImpl(userResolver: userResolver)
        }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(CalendarSetupTask.self)
        NewBootManager.register(CalendarPreloadTask.self)
        NewBootManager.register(CalendarLoadTask.self)
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory { CalendarLauncherDelegate() }, PassportDelegatePriority.high)
    }

    public func registTabRegistry(container: Container) {
        (Tab.calendar, { (_: [URLQueryItem]?) -> TabRepresentable in
            CalendarTab(userResolver: container.getCurrentUserResolver())
        })
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.plain(Tab.calendar.urlString)
            .priority(.high)
            .factory(CalendarRouterHandler.init(resolver:))

        Navigator.shared.registerMiddleware
            .factory(CalendarMiddlewareHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarSettingBody.self)
            .factory(CalendarSettingRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarEventDetailBody.self)
            .factory(CalendarEventDetailRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarEventDetailWithTimeBody.self)
            .factory(CalendarEventDetailWithTimeRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarEventDetailFromMail.self)
            .factory(CalendarEventDetailFromMailRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarEeventDetailFromMeeting.self)
            .factory(CalendarEventDetailFromMeetingRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarEventDetailWithUniqueIdBody.self)
            .factory(CalendarEventDetailWithUniqueIdBodyRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarDocsFromMeeting.self)
            .factory(CalendarDocsFromMeetingRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarFreeBusyBody.self)
            .factory(CalendarFreeBusyBodyRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarEventSubSearch.self)
            .factory(CalendarEventSubSearchRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(FreeBusyInGroupBody.self)
            .factory(FreeBusyInGroupBodyRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarCreateEventBody.self)
            .factory(CalendarCreateEventBodyRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.regex("/recruitment/chat")
            .factory { resolver in
                InterviewChatRouterHandler.init(resolver: resolver, useV1: true)
            }

        Navigator.shared.registerRoute.regex("need_lark_interception_jump_to_chat")
            .factory { resolver in
                InterviewChatRouterHandler.init(resolver: resolver, useV1: false)
            }

        Navigator.shared.registerRoute.type(CalendarTodayEventBody.self)
            .factory(CalendarTodayEventHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarAdditionalTimeZoneBody.self)
            .factory(CalendarAdditionalTimeZoneHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(CalendarAdditionalTimeZoneManagerBody.self)
            .factory(CalendarAdditionalTimeZoneManagerHandler.init(resolver: ))

        Navigator.shared.registerRoute.match( { url -> Bool in
            var config = RouterMatchConfig()
            config.schema = "https"
            if EnvManager.env.type == .staging {
                // 因历史原因 boe 与 online path 不一样，后端说不好改。在客户端兼容一下
                config.path = "/calendar/meetingroom"
            } else {
                config.path = "/calendarpro/meetingroom"
            }
            config.queryItems = ["resource_token"]
            let routerMatch = RouterMatch(config: config)
            return routerMatch.match(url: url)
        }).factory(SeizeMeetingroomRouterHandler.init(resolver:))

        // 二维码签到
        // e.g. https://www.feishu.cn/calendar/pages/resource_qrcode?code=0&resource_token=2b5ee703-d174-418d-a496-7c49eb9a0285
        Navigator.shared.registerRoute.match( { url -> Bool in
            let requiredPath = "calendar/pages/resource_qrcode"
            let exceptionKey = "first_active"
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return false
            }

            // 包含特殊key不走端上逻辑
            if components.queryItems?.contains(where: { $0.name == exceptionKey }) ?? false {
                return false
            }

            return (components.scheme?.hasPrefix("http") ?? false)
                && components.path.contains(requiredPath)
        }).factory(CalendarCheckInRouterHandler.init(resolver: ))

        Navigator.shared.registerRoute.match( { url -> Bool in
            var config = RouterMatchConfig()
            config.schema = "https"
            config.path = "/calendar/share"
            config.queryItems = ["token"]
            let routerMatch = RouterMatch(config: config)
            return routerMatch.match(url: url)
        }).factory(EventShareRouterHandler.init(resolver:))

        Navigator.shared.registerRoute.match( { url -> Bool in
            var config = RouterMatchConfig()
            config.schema = "https"
            config.path = "/calendar/share/calendar"
            config.queryItems = ["token"]
            let routerMatch = RouterMatch(config: config)
            return routerMatch.match(url: url)
        }).factory(CalendarShareRouterHandler.init(resolver:))
    }

    public func registBootLoader(container: Container) {
        (CalendarApplicationDelegate.self, DelegateLevel.default)
    }

    @_silgen_name("Lark.OpenChat.Messenger.CalendarBanner")
    public static func registBanner() {
        ChatBannerModule.register(MeetingGroupBannerModule.self)
    }

    @_silgen_name("Lark.OpenChat.Messenger.CalendarCard")
    public static func messageCardRegister() {
        MessageEngineSubFactoryRegistery.register(EventRSVPComponentFactory.self)
        MessageEngineSubFactoryRegistery.register(MessageLinkEventCardComponentFactory.self)
        MessageEngineSubFactoryRegistery.register(EventShareComponentFactory.self)
        MessageEngineSubFactoryRegistery.register(RoundRobinCardComponentFactory.self)
        MessageEngineSubFactoryRegistery.register(SchedulerAppointmentComponentFactory.self)

        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinEventRSVPComponentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinEventCardComponentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinEventShareComponentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(RoundRobinCardComponentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(SchedulerAppointmentComponentFactory.self)

        ChatMessageSubFactoryRegistery.register(EventCardComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(EventShareComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(EventRSVPComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(RoundRobinCardComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(SchedulerAppointmentComponentFactory.self)

        MergeForwardMessageSubFactoryRegistery.register(RoundRobinCardComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(SchedulerAppointmentComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MergeForwardEventCardComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MergeForwardEventShareComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MergeForwardEventRSVPComponentFactory.self)

        ThreadChatSubFactoryRegistery.register(ThreadEventCardComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadEventShareComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadEventRSVPComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadRoundRobinCardComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadSchedulerAppointmentComponentFactory.self)

        ThreadDetailSubFactoryRegistery.register(ThreadEventCardComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadEventShareComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadEventRSVPComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadRoundRobinCardComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadSchedulerAppointmentComponentFactory.self)

        ReplyInThreadSubFactoryRegistery.register(DetailEventCardComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(DetailEventShareComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(DetailEventRSVPComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(DetailRoundRobinCardComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(DetailSchedulerAppointmentComponentFactory.self)

        ReplyInThreadForwardDetailSubFactoryRegistery.register(DetailEventCardComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(DetailEventShareComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(DetailEventRSVPComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(DetailRoundRobinCardComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(DetailSchedulerAppointmentComponentFactory.self)

        MessageDetailMessageSubFactoryRegistery.register(DetailEventCardComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(DetailEventShareComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(DetailEventRSVPComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(DetailRoundRobinCardComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(DetailSchedulerAppointmentComponentFactory.self)
    }

    @_silgen_name("Lark.OpenSetting.CalendarMineSetting")
    public static func registerMineSetting() {
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.calendarEntry.moduleKey, provider: { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.Calendar.Calendar_NewSettings_Calendar,
                onClickBlock: { (userResolver, vc) in
                    userResolver.navigator.push(body: CalendarSettingBody(), from: vc)
            })
        })
    }

#if !LARK_NO_DEBUG
    public func registDebugItem(container: Container) {
        ({ CalendarDebugItem() }, SectionType.debugTool)
    }
#endif

    public func registURLInterceptor(container: Container) {
        (CalendarEventDetailBody.pattern, { (url: URL, from: NavigatorFrom) in
            if Display.pad {
                Navigator.shared.switchTab(Tab.calendar.url, from: from, animated: false) {
                    Navigator.shared.present(url, from: from, prepare: { $0.modalPresentationStyle = .formSheet })
                }
            } else {
                var params = NaviParams()
                params.switchTab = Tab.calendar.url
                params.forcePush = true
                let context = [String: Any](naviParams: params)
                Navigator.shared.push(url, context: context, from: from)
            }
        })
    }

    /// 注册serverPush
    public func registServerPushHandlerInUserSpace(container: Container) {
        (ServerCommand.pushBindExchangeSuccessNotification, BindExchangeSuccessNotificationPushHandler.init(resolver:))
        (ServerCommand.pushBindZoomSuccessNotification, BindZoomSuccessNotificationPushHandler.init(resolver:))
        (ServerCommand.pushMeetingNotesUpdateNotification, MeetingNotesUpdateNotificationPushHandler.init(resolver:))
        (ServerCommand.pushCalendarMyAiInlineStage , MyAiInlineStageNotificationPushHandler.init(resolver:))
    }

    /// 注册pushHandler
    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushScrollClosedNotification, MeetingBannerClosedPushHandler.init(resolver:))
        (Command.pushCalendarEventReminder, CalendarEventReminderPushHandler.init(resolver:))
        (Command.pushReminderClosedNotification, ReminderClosedPushHandler.init(resolver:))
        (Command.pushCalendarEventVideoMeetingChange, EventVideoMeetingChangedPushHandler.init(resolver:))
        (Command.pushAssociatedLiveStatus, AssociatedLiveStatusPushHandler.init(resolver:))
        (Command.pushCalendarEventChangedNotification, CalendarEventChangedPushHandler.init(resolver:))
        (Command.pushAssociatedVcStatus, VideoChatStatusPushHandler.init(resolver:))
        (Command.pushEventShareToChatNotification, EventShareToChatPushHandler.init(resolver:))
        (Command.pushCalendarEventRefreshNotification, CalendarEventRefreshPushHandler.init(resolver:))
        (Command.pushCalendarBindGoogleNotification, CalendarBindGooglePushHandler.init(resolver:))
        (Command.pushGoogleBindSettingNotification, GoogleBindSettingPushHandler.init(resolver:))
        (Command.pushExternalCalendarChangeNotification, ExternalCalendarChangedPushHandler.init(resolver:))
        (Command.pushCalendarSettingsChangeNotification, CalendarSettingChangedPushHandler.init(resolver:))
        (Command.pushMeetingNotification, MeetingNotificationPushHandler.init(resolver:))
        (Command.pushMeetingMinuteEditors, MeetingMinuteEditorsPushHandler.init(resolver:))
        (Command.pushCalendarSyncNotification, CalendarSyncPushHandler.init(resolver:))
        (Command.pushActiveEventChangedNotification, ActiveEventChangedPushHandler.init(resolver:))
        (Command.pushRoomViewInstanceChangeNotification, RoomViewInstanceChangedPushHandler.init(resolver:))
        (Command.pushCalendarTenantSettingsChangeNotification, CalendarTenantSettingsChangedPushHandler.init(resolver:))
        (Command.pushMeetingChatBannerChangedNotification, MeetingChatBannerChangedPushHandler.init(resolver:))
        (Command.pushCalendarTodayInstanceChangedNotification, CalendarTodayInstanceChangedPushHandler.init(resolver:))
        (Command.pushEventSetting, EventInFeedSettingPushHandler.init(resolver:))
        (Command.inlineAiTaskStatusPush, InlineAITaskStatusPushHandler.init(resolver:))
        (Command.pushTimeContainerChangedNotification, TimeContainerChangedPushHandler.init(resolver:))
        (Command.pushTimeBlocksChangedOnContainerNotification, PushTimeBlocksChangeHandler.init(resolver:))
    }

}
