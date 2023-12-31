//
//  CalendarInterfaceImpl.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/1.
//
import Foundation
import CalendarFoundation
import LarkRustClient
import LarkUIKit
import RxSwift
import RustPB
import EventKit
import AsyncComponent
import RxCocoa
import LarkActionSheet
import RoundedHUD
import Swinject
import LarkContainer
import EENavigator
import LarkAlertController
import UniverseDesignToast
import AppReciableSDK
import UIKit
import LarkSetting
import ThreadSafeDataStructure

// CalendarApiGetter
typealias CalendarApiGetter = () -> CalendarRustAPI?
typealias GetNormalDetailController = (
    _ scene: EventDetailScene,
    _ key: String,
    _ calendarId: String,
    _ originalTime: Int64,
    _ startTime: Int64?,
    _ endTime: Int64?,
    _ instanceScore: String,
    _ isFromChat: Bool,
    _ isFromNew: Bool,
    _ actionSource: CalendarTracer.ActionSource) -> UIViewController

typealias GetCreateEventCoordinator = (
    _ contextBuilder: (UnsafeMutablePointer<EventCreateContext>) -> Void
) -> EventEditCoordinator

typealias CreateEventSucceedHandler = (
    _ event: Rust.Event,
    _ fromVC: UIViewController
) -> Void

// CalendarInterface 先照搬原 CalendarContext 的实现。后续 service 下沉完毕，再逐渐拆出各个页面
extension CalendarInterfaceImpl: CalendarInterface {
    public func showTimeZoneSelectController(with timeZone: TimeZone?,
                                             from: UIViewController,
                                             onTimeZoneSelect: @escaping (TimeZone) -> Void) {
        timeZoneService.selectedTimeZone.accept(timeZone ?? FackTimeZone())

        let selectedTimeZone = timeZoneService.selectedTimeZone
        let popupVC = getPopupTimeZoneSelectViewController(
            with: timeZoneService,
            selectedTimeZone: selectedTimeZone,
            onTimeZoneSelect: { timeZone in
                onTimeZoneSelect(TimeZone(identifier: timeZone.identifier) ?? TimeZone.current)
            }
        )
        from.present(popupVC, animated: true)
    }

    public func getMeetingSummaryBadgeStatus(_ chatId: String, handler: @escaping (Result<Bool, Error>) -> Void) {
        calendarApi.getChatCalendarEventInstanceViewRequest(chatIds: [chatId])
            .flatMap { [weak self] (eventInstanceViewResponse) -> Observable<Bool> in
                guard let self = self else { return .empty() }

                let chatEventInstanceTimeMap = eventInstanceViewResponse.chatEventInstanceTimeMap
                let uniqueKey = chatEventInstanceTimeMap[chatId]?.uniqueKey
                let originalTime = chatEventInstanceTimeMap[chatId]?.originalTime

                return self.getMeetingSummaryUpdatedStatus(uniqueKey: uniqueKey, originalTime: originalTime).catchErrorJustReturn(false)
            }.subscribe(onNext: { (shouldShow) in
                handler(.success(shouldShow))
            }, onError: { (error) in
                handler(.failure(error))
            }).disposed(by: disposeBag)
    }

    public func registerMeetingSummaryPush() -> Observable<(String, Int)> {
        return pushService.rxMeetingMinuteEditors.map({ (item) -> (String, Int) in
            return (item.chatID, Int(item.expireTime))
        })
    }

    public func toNormalGroup(chatID: String) -> Observable<Void> {
        return getToNormalGroup(chatID: chatID)
    }

    public func searchCalendarEvent(query: String) -> Observable<[LarkCalendarEventSearchResult]> {
        return calendarApi.generalCalendarSearchEvent(query: query, is12Hour: SettingService.shared().is12HourStyle.value)
            .map { results -> [LarkCalendarEventSearchResult] in
                return results.map { EventSearchResult(searchContent: $0) }
            }
    }

    public func getEventInfo(chatId: String) -> Observable<(CalendarChatMeetingEventInfo?)> {
        return calendarApi.getChatCalendarEventInstanceViewRequest(chatIds: [chatId])
            .flatMap { [weak self] eventInstanceViewResponse -> Observable<CalendarChatMeetingEventInfo?> in
                guard let self = self else { return .just(nil) }

                let chatEventInstanceTimeMap = eventInstanceViewResponse.chatEventInstanceTimeMap
                let chatMeetingMap = eventInstanceViewResponse.chatMeetingMap
                let url = URL(string: chatMeetingMap[chatId]?.docsURL ?? "")

                guard let serverId = chatEventInstanceTimeMap[chatId]?.calendarEventRefID else {
                    return .just(nil)
                }

                return self.calendarApi.getServerPBEvent(serverId: serverId)
                    .map { [weak self] updatedEvent -> CalendarChatMeetingEventInfo? in
                        guard let self = self else { return nil }
                        guard let event = updatedEvent else { return CalendarChatMeetingEventInfo(meetingEventInfo: nil, url: url) }

                        return CalendarChatMeetingEventInfo(meetingEventInfo: MeetingEventInfo(
                            startTime: chatEventInstanceTimeMap[chatId]?.startTime ?? Int64(0),
                            endTime: chatEventInstanceTimeMap[chatId]?.endTime ?? Int64(0),
                            alertName: self.getMeetingMinutesRestrictAlertName(event)), url: url)
                    }
            }
    }

    private func getMeetingMinutesRestrictAlertName(_ event: Calendar_V1_CalendarEvent) -> String {
        let name: String
        let hasOrganizer = !event.organizer.displayName.isEmpty
        let hasSuccessor = !event.successor.displayName.isEmpty
        let hasCreator = !event.creator.displayName.isEmpty
        if hasSuccessor {
            name = event.successor.displayName
        } else if hasOrganizer {
            name = event.organizer.displayName
        } else if hasCreator {
            name = event.creator.displayName
        } else {
            name = BundleI18n.Calendar.Lark_Legacy_TagCalendarOrganizer
        }
        return name
    }

    public func getSearchController(query: String?, searchNavBar: SearchNaviBar? = nil) -> UIViewController {
        let calendarManagerDataLoader = self.calendarManagerDataLoader

        let userId = dependency.currentUser.id
        let searchViewController = CalendarSearchViewController(
                                    userResolver: self.userResolver,
                                    getDetailController: getNormalDetailController,
                                    subscribeViewController: getSubscribeViewController(nil),
                                                                calenderLoader: {
            calendarManagerDataLoader.fetchSidebarCalendars(userId: userId)
        },
                                    calendarApi: calendarApi,
                                    skinType: settingProvider.getSetting().skinTypeIos,
                                    startWeekday: self.settingProvider.getEventViewSetting().firstWeekday,
                                    is12Hour: SettingService.shared().is12HourStyle,
                                    query: query ?? "",
                                    currentTenantId: dependency.currentUser.tenantId,
                                    searchNaviBar: searchNavBar)
        return searchViewController
    }

    public func getOldGroupFreeBusyController(chatId: String, chatType: String, createEventBody: CalendarCreateEventBody? = nil) -> UIViewController {
        let layoutAlgorithm = getInstancesLayoutAlgorithm()
        let currentUserCalendarId = calendarManager.primaryCalendarID
        let groupFreeBusyLoader = FreeBusyLoader(userResolver: self.userResolver,
            calendarApi: calendarApi,
            currentUserCalendarId: currentUserCalendarId,
            layoutAlgorithm: layoutAlgorithm.layoutInstances,
            eventViewSettingGetter: eventViewSettingGetter()
        )
        let viewController = OldGroupFreeBusyController(userResolver: self.userResolver,
                                                        chatId: chatId,
                                                        chatType: chatType,
                                                        firstWeekday: self.settingProvider.getEventViewSetting().firstWeekday,
                                                        getNewEventMinute: defaultDurationGetter,
                                                        calendarApi: calendarApi,
                                                        attendeesGetter: calendarApi.getAttendees,
                                                        dataLoader: groupFreeBusyLoader,
                                                        getCreateEventCoordinator: getCreateEventCoordinator(contextBuilder:),
                                                        createEventSucceedHandler: handleCreateEventSucceed(pbEvent:fromVC:),
                                                        getNormalDetailController: getNormalDetailController,
                                                        is12HourStyle: SettingService.shared().is12HourStyle,
                                                        timeZoneService: timeZoneService,
                                                        createEventBody: createEventBody
        )
        return viewController
    }

    public func getEventDetailFromShare(getterModel: DetailControllerGetterModel) -> UIViewController {
        if getterModel.source == CalendarAssembly.AppLinkUniqueFields {
            let vc = EventDetailBuilder.buildByFourFoldTuplesWith(userResolver: self.userResolver,
                                                                  key: getterModel.key,
                                                                  calendarID: getterModel.calendarId,
                                                                  originalTime: getterModel.originalTime,
                                                                  startTime: getterModel.startTime,
                                                                  isFromAPNS: getterModel.isFromAPNS,
                                                                  scene: getterModel.scene)
            return vc
        } else if getterModel.source == CalendarAssembly.AppLinkFromApproval {
            let vc = EventDetailBuilder.buildByFourFoldTuplesWith(userResolver: self.userResolver,
                                                                  key: getterModel.key,
                                                                  calendarID: getterModel.calendarId,
                                                                  originalTime: getterModel.originalTime,
                                                                  startTime: getterModel.startTime,
                                                                  source: getterModel.source,
                                                                  isFromAPNS: getterModel.isFromAPNS,scene: getterModel.scene)
            return vc
        } else {
            let vc = EventDetailBuilder.build(userResolver: self.userResolver,
                                              key: getterModel.key,
                                              calendarID: getterModel.calendarId,
                                              originalTime: getterModel.originalTime,
                                              token: getterModel.token,
                                              messageId: getterModel.messageId,
                                              isFromAPNS: getterModel.isFromAPNS,
                                              scene: getterModel.scene)
            return vc
        }
    }

    public func getCalendarEventCardBinder(controllerGetter: @escaping () -> UIViewController, model: InviteEventCardModel) -> EventCardBinder {
        return EventCardBinder(
            controllerGetter: controllerGetter,
            getNormalDetailController: eventDetailFromCard,
            getRsvpDetailController: getRSVPDetail,
            userID: dependency.currentUser.id,
            currentTenantId: dependency.currentUser.tenantId,
            is12HourStyle: dependency.is12HourStyle,
            model: model,
            userResolver: self.userResolver)
    }

    func eventDetailFromCard(key: String,
                             calendarId: String,
                             originalTime: Int64,
                             startTime: Int64?,
                             endTime: Int64?,
                             eventType: EventType,
                             scene: EventDetailScene) -> UIViewController {
        getEventContentController(with: key,
                                  calendarId: calendarId,
                                  originalTime: originalTime,
                                  startTime: startTime,
                                  endTime: endTime,
                                  instanceScore: "",
                                  isFromTransferEvent: eventType == .transfer,
                                  isFromInviteEvent: eventType == .invite,
                                  scene: scene)
    }

    public func getCalendarEventShareBinder(controllerGetter: @escaping () -> UIViewController, model: ShareEventCardModel) -> EventShareBinder {
        return EventShareBinder(userResolver: userResolver,
                                model: model,
                                currentTenantId: dependency.currentUser.tenantId,
                                primaryCalendarID: calendarManager.primaryCalendarID,
                                controllerGetter: controllerGetter,
                                detailControllerGetter: getEventDetailFromShare,
                                is12HourStyle: dependency.is12HourStyle)
    }

    public func appLinkEventEditController(calendarId: String,
                                           key: String,
                                           originalTime: Int64,
                                           startTime: Int64?) -> Observable<(UIViewController?, Bool)> {
        return eventEditControllerWrapper.appLinkEditEvent(calendarId: calendarId,
                                        key: key,
                                        originalTime: originalTime,
                                        startTime: startTime)
    }
    
    public func appLinkEventEditController(token: String) -> Observable<UIViewController?> {
        return eventEditControllerWrapper.appLinkEditEvent(token: token)
    }
    
    public func getCalendarEventRSVPCardBinder(controllerGetter: @escaping () -> UIViewController, model: RSVPCardModel) -> EventRSVPBinder {
        return EventRSVPBinder(model: model,
                               currentTenantId: dependency.currentUser.tenantId,
                               controllerGetter: controllerGetter,
                               detailControllerGetter: getEventDetailFromShare,
                               is12HourStyle: dependency.is12HourStyle,
                               userResolver: userResolver)
    }

    public func getEventEditController(legoInfo: EventEditLegoInfo,
                                       editMode: EventEditMode,
                                       interceptor: EventEditInterceptor,
                                       title: String?) -> GetControllerResult {
        let disableEncrypt = SettingService.shared().tenantSetting?.disableEncrypt ?? false
        if disableEncrypt {
            return .error(I18n.Calendar_NoKeyNoCreate_Toast)
        }
        var input = EventEditInput.from(mode: editMode)
        if !legoInfo.shouldShow(.calendar),
           case .createWithContext(var context) = input {
            // 不展示 calendar 时，创建日程时优先选择主日历
            context.calendarID = calendarManager.primaryCalendarID
            input = .createWithContext(context)
        }

        let coordinator = EventEditCoordinator(userResolver: self.userResolver,
                                               editInput: input,
                                               dependency: EventEditCoordinator.DependencyImpl(userResolver: userResolver),
                                               legoInfo: legoInfo,
                                               interceptor: interceptor,
                                               title: title)
        return .success(coordinator.prepare())
    }

    public func appLinkNewEventController(startTime: Date?, endTime: Date?, summary: String?) -> UIViewController {
        let coordinator = getCreateEventCoordinator { contextPointer in
            contextPointer.pointee.summary = summary
            contextPointer.pointee.startDate = startTime
            contextPointer.pointee.endDate = endTime
        }
        return coordinator.prepare()
    }

    // 详情页优先用传参的 endtime 作为显示时间，entime = nil 用event.endTime，对于重复性日程这个逻辑不对。要改的话成本较大，先让用户传endTime
    public func applinkEventDetailController(key: String,
                                             calendarId: String,
                                             source: String,
                                             token: String?,
                                             originalTime: Int64,
                                             startTime: Int64?,
                                             endTime: Int64? = nil,
                                             isFromAPNS: Bool = false) -> UIViewController {
        let joinEventAction: JoinEventAction = { [weak self] (success, failure) -> Void in
            guard let self = self else { return }
            self.calendarApi.joinToEvent(calendarID: calendarId, key: key, token: token, originalTime: originalTime, messageID: "")
                .subscribe(onNext: { (_) in
                    success()
                }, onError: { (error) in
                    failure?(error)
                }).disposed(by: self.disposeBag)
        }

        let model = DetailControllerGetterModel(scene: isFromAPNS ? .offlineNotification : .url,
                                                key: key,
                                                calendarId: calendarId,
                                                source: source,
                                                originalTime: originalTime,
                                                startTime: startTime,
                                                endTime: endTime,
                                                isJoined: false,
                                                messageId: "",
                                                token: token ?? "",
                                                isFromAPNS: isFromAPNS,
                                                joinEventAction: joinEventAction)
        let controller = getEventDetailFromShare(getterModel: model)
        return controller
    }

    public func appLinkCalendarSettingController(calendarId: String) -> UIViewController? {
        if FG.optimizeCalendar {
            var tempCalendar = CalendarModelFromPb.defaultCalendar(skinType: .light)
            tempCalendar.serverId = calendarId
            let vm = CalendarEditViewModel(from: .fromEdit(calendar: tempCalendar.getCalendarPB()), userResolver: self.userResolver)
            let vc = CalendarEditViewController(viewModel: vm)
            let nav = LkNavigationController(rootViewController: vc)
            nav.update(style: .default)
            nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            return nav
        }
        return getCalendarSettingController(calendarId, nil)
    }

    public func appLinkNewCalendarController(summary: String?,
                                             _ willShowSidebar: @escaping () -> Void) -> UINavigationController {
        let showSidebar = { [weak self] in
            willShowSidebar()
            self?.localRefreshService.rxCalendarNeedRefresh.onNext(())
        }

        if FG.optimizeCalendar {
            let vm = CalendarEditViewModel(from: .fromCreate, userResolver: self.userResolver)
            if let summary = summary { vm.updateSummary(with: summary) }
            let vc = CalendarEditViewController(viewModel: vm)
            let nav = LkNavigationController(rootViewController: vc)
            nav.update(style: .default)
            nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            return nav
        }

        return CalendarManagerFactory.newController(selfUserId: dependency.currentUser.id,
                                                    calendarAPI: calendarApi, calendarDependency: self.calendarDependency,
                                                    skinType: settingProvider.getSetting().skinTypeIos,
                                                    showSidebar: showSidebar,
                                                    disappearCallBack: nil,
                                                    finishSharingCallBack: nil,
                                                    summary: summary)
    }

    public func appLinkExternalAccountManageController() -> UINavigationController {
        let viewController = getAccountManageViewController(presentStyle: .present)
        let nav = LkNavigationController(rootViewController: viewController)
        nav.update(style: .default)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        return nav
    }
}

extension CalendarInterfaceImpl: CalendarContext {
    /// 日程详情页
    public func getEventContentController(with key: String,
                                          calendarId: String,
                                          originalTime: Int64,
                                          startTime: Int64? = nil,
                                          endTime: Int64? = nil,
                                          instanceScore: String,
                                          isFromChat: Bool = false,
                                          isFromNotification: Bool = false,
                                          isFromMail: Bool = false,
                                          isFromTransferEvent: Bool = false,
                                          isFromInviteEvent: Bool = false,
                                          scene: EventDetailScene
        ) -> UIViewController {
        let actionSource: CalendarTracer.ActionSource
        if isFromMail {
            actionSource = .mail
        } else if isFromTransferEvent {
            actionSource = .msg_transfer
        } else if isFromInviteEvent {
            actionSource = .msg_invite
        } else if isFromChat {
            actionSource = .side_bar
        } else {
            /// 日历助手弹窗通知和从会议群浮窗进入日程详情页都是进 remind 的 action source
            actionSource = .remind
        }

        return getNormalDetailController(scene: scene,
                                         key: key,
                                         calendarId: calendarId,
                                         originalTime: originalTime,
                                         startTime: startTime,
                                         endTime: endTime,
                                         instanceScore: instanceScore,
                                         isFromChat: isFromChat,
                                         actionSource: actionSource)
    }

    public func getLocalDetailController(ekEvent: EKEvent) -> UIViewController {
        let vc = EventDetailBuilder.build(userResolver: userResolver, ekEvent: ekEvent)
        return vc
    }

}

public final class CalendarInterfaceImpl: UserResolverWrapper {

    let disposeBag = DisposeBag()

    internal let settingProvider: SettingProvider

    internal let dependency: CalendarDependency

    let pushService: RustPushService
    let localRefreshService: LocalRefreshService
    let additionalTimeZoneOption: Bool
    @ScopedInjectedLazy var meetingRoomHomeTracer: MeetingRoomHomeTracer?
    @ScopedInjectedLazy var settingService: LarkSetting.SettingService?

    private let eventCreateRelay: PublishRelay<String> = PublishRelay<String>() // 用于会议室视图指定会议室的轮询

    private let updateRemindOnAcceptOnly = PublishSubject<Void>()

    private let instanceViewPool = Pool<DaysInstanceView>()

    private lazy var instanceSnapshot: InstanceSnapshot = {
        let user = dependency.currentUser
        let cipher = CalendarCipher(userId: user.id, tenentId: user.tenantId)
        let snapshot = InstanceSnapshotImpl(cipher: cipher, calendarDependency: dependency)
        return snapshot
    }()

    private lazy var instanceCacheOld: InstanceCacheOld = {
        let cache = InstanceCacheImplOld(instanceSnapShot: instanceSnapshot)
        return cache
    }()

    private lazy var instanceService: InstanceServiceImpl = {
        return InstanceServiceImpl(snapshot: instanceSnapshot,
                                   localInstanceChangedPush: LocalCalendarManager.eventStoreChangedSubject,
                                   calendarApi: calendarApi,
                                   userResolver: self.userResolver,
                                   visibleCalendarsIDsGetter: { [weak self] () -> [String] in
            return self?.calendarManager.visibleCalendarsIDs ?? []
                                   })
    }()

    private lazy var monthLoader: MonthLoader = {
        return MonthDaysLoader(
            calendarApi: calendarApi,
            cache: self.instanceCacheOld,
            instanceSnapshot: self.instanceSnapshot,
            userResolver: self.userResolver,
            visibleCalendarsIDs: { [weak self] () -> [String] in
                return self?.calendarManager.visibleCalendarsIDs ?? []
            },
            eventViewSettingGetter: eventViewSettingGetter())
    }()// 月视图

    let calendarManager: CalendarManager
    let calendarApi: CalendarRustAPI
    let timeZoneService: TimeZoneService
    let calendarDependency: CalendarDependency
    let timeDataService: TimeDataService
    let calendarSelectTracer: CalendarSelectTracer
    private let calendarWorkQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "calendar.work.queue", qos: .userInteractive)
        return queue
    }()

    private var prepareFinish = false

    deinit {
        NotificationCenter.default.removeObserver(self)
        SettingService.shared().stateManager.reset()
    }

    public let userResolver: UserResolver

    public init(with dependency: CalendarDependency, userResolver: UserResolver) throws {
        TimerMonitorHelper.shared.launchTimeTracer = LaunchTimeTracer()
        TimerMonitorHelper.shared.launchTimeTracer?.launchLaterApp.start()
        let dependency = dependency
        self.dependency = dependency
        self.userResolver = userResolver
        self.additionalTimeZoneOption = FeatureGating.additionalTimeZoneOption(userID: userResolver.userID)

        calendarManager = try self.userResolver.resolve(assert: CalendarManager.self)
        calendarApi = try self.userResolver.resolve(assert: CalendarRustAPI.self)
        timeZoneService = try self.userResolver.resolve(assert: TimeZoneService.self)
        pushService = try self.userResolver.resolve(assert: RustPushService.self)
        localRefreshService = try self.userResolver.resolve(assert: LocalRefreshService.self)
        calendarDependency = try self.userResolver.resolve(assert: CalendarDependency.self)
        calendarSelectTracer = try self.userResolver.resolve(assert: CalendarSelectTracer.self)
        timeDataService = try self.userResolver.resolve(assert: TimeDataService.self)

        let user = dependency.currentUser
        let cipher = CalendarCipher(userId: user.id, tenentId: user.tenantId)

        SettingService.shared().setDependency(
            calendarWorkQueue: self.calendarWorkQueue,
            cipher: cipher
        )
        self.settingProvider = SettingProviderMock()

        calendarManager.updateAllCalendar()

        LocalCalendarManager.updateLocalCalSourceVisibilty(for: .preloadLocalCalendarSourceVisibilityOnInit)

        EKRecurrenceRule.snycGetReadableRruleGetter = { [weak self] in
            return self?.calendarApi.snycGetReadableRrule
        }
        LocalCalHelper.calendarApiGetter = { [weak self] in
            return self?.calendarApi
        }
        
        if SettingService.shared().tenantSetting == nil {
            SettingService.rxTenantSetting().subscribe().disposed(by: disposeBag)
        }
    }

    private func prepareInstance(loggerModel: CaVCLoggerModel, date: Date = Date()) {
        let mode = CalendarDayViewSwitcher().mode
        switch mode {
        case .threeDay, .week, .singleDay:
            let setting = self.settingProvider.getSetting()
            let timeZone: TimeZone
            if case .schedule = mode {
                timeZone = .current
            } else {
                if additionalTimeZoneOption {
                    timeZone = TimeZone.current
                } else {
                    timeZone = TimeZone(identifier: setting.timeZone) ?? TimeZone.current
                }
            }
            let sceneMode = HomeSceneMode(from: mode)
            HomeScene.setColdLaunchContext(with: sceneMode, timeZone: timeZone, viewSetting: setting, settingService: settingService, loggerModel: loggerModel)
            guard let coldLaunchContext = HomeScene.coldLaunchContext else {
                return
            }
            HomeScene.coldLaunchTracker?.insertPoint(.prepareInstance)
            self.instanceService.prepareColdLaunch(with: coldLaunchContext)
            self.timeDataService.prepareDiskData(firstScreenDayRange: coldLaunchContext.dayRange)
        case .month:
            self.monthLoader.prepareData(date: date)
        case .schedule:
                let setting = self.settingProvider.getSetting()
                let timeZone: TimeZone = .current
                let sceneMode = HomeSceneMode(from: mode)
                HomeScene.setColdLaunchContext(with: sceneMode, timeZone: timeZone, viewSetting: setting, settingService: settingService, loggerModel: loggerModel)
                guard let coldLaunchContext = HomeScene.coldLaunchContext else {
                    return
                }
                HomeScene.coldLaunchTracker?.insertPoint(.prepareInstance)
                self.instanceService.prepareColdLaunch(with: coldLaunchContext)
        }
    }

    private lazy var calendarManagerDataLoader = CalendarManagerDataLoader(userResolver: self.userResolver)

    private func prefetchData() {
        calendarManagerDataLoader.fetchSidebarCalendars(userId: dependency.currentUser.id)
            .subscribe(onNext: { _ in })
            .disposed(by: disposeBag)
    }

    public func getSettingsController(fromWhere: CalendarSettingBody.FromWhere = .none) -> UIViewController {
        let settingsDependency = getSettingsDependency()
        let settingController = SettingsInLarkController(userResolver: self.userResolver,
                                                         dependency: settingsDependency,
                                                         fromWhere: fromWhere)
        return settingController
    }

    private func getSettingsDependency() -> DefaultSettingsControllerDependency {
        let settingDependency = DefaultSettingsControllerDependency(
            settingProvider: settingProvider,
            is12HourStyle: SettingService.shared().is12HourStyle,
            accountManageVCGetter: getAccountManageViewController
        )
        return settingDependency
    }

    private func defaultDurationGetter() -> Int {
        return Int(settingProvider.getSetting().defaultEventDuration)
    }

    /// 左右两边缓存的页数
    private var cachePageCount = 2

    private let daysPerPageMap: [DayViewSwitcherMode: Int] = [.singleDay: 1,
                                                              .threeDay: 7,
                                                              .week: 7,
                                                              .schedule: 0]
    // 加载数据的天数
    private func getDaysPerPage(mode: DayViewSwitcherMode) -> Int {
        var mode = mode
        if mode == .threeDay && Display.pad {
            mode = .week
        }
        guard let value = daysPerPageMap[mode] else {
            assertionFailure()
            return 1
        }
        return value
    }

    private let displayPageCountMap: [DayViewSwitcherMode: Int] = [.singleDay: 1,
                                                                   .threeDay: 3,
                                                                   .week: 7,
                                                                   .month: 0,
                                                                   .schedule: 0]

    public func calendarHome() -> CalendarHome {
        HomeScene.setupColdLaunchTracker()
        HomeScene.coldLaunchTracker?.start()
        meetingRoomHomeTracer?.start()

        let firstScreenDataReady = BehaviorRelay<Bool>(value: false)
        if case .month = CalendarDayViewSwitcher().mode {
            CalendarMonitorUtil.startTrackHomePageLoad(firstScreenDataReady: firstScreenDataReady)
        }
        TimerMonitorHelper.shared.launchTimeTracer?.launchLaterApp.end()
        TimerMonitorHelper.shared.traceCalendarLaunchMem()

        let dependency =
            CalendarViewControllerDependency(
                calendarApi: self.calendarApi,
                calendarDependency: self.calendarDependency,
                timeDataService: self.timeDataService,
                instanceService: instanceService,
                getCreateEventCoordinator: getCreateEventCoordinator(contextBuilder:),
                createEventSucceedHandler: handleCreateEventSucceed(pbEvent:fromVC:),
                getLocalDetailController: getLocalDetailController,
                getCalendarSettingController: getCalendarSettingController,
                getCurrentSkinType: getCurrentSkinType,
                timeZoneService: self.timeZoneService,
                getDaysPerPage: getDaysPerPage,
                cachePageCount: cachePageCount,
                firstScreenDataReady: firstScreenDataReady,
                getImportCalendarViewController: getImportViewController,
                updateEventRelay: eventCreateRelay,
                getAccountManageViewController: getAccountManageViewController
            )
        let vc = CalendarViewController(dependency: dependency, delegate: self, userResolver: self.userResolver)
        vc.rx.deallocated.subscribe(onNext: { [weak self] (_) in
            self?.prepareFinish = false
        }).disposed(by: disposeBag)
        return vc
    }

    func getCurrentSkinType() -> CalendarSkinType {
        return self.settingProvider.getSetting().skinTypeIos
    }

    private func getEventCoordinator(
        event: CalendarEventEntity,
        instance: CalendarEventInstanceEntity
    ) -> EventEditCoordinator {
        let editInput: EventEditInput
        if event.isLocalEvent() {
            if let ekEvent = event.getEKEvent() {
                editInput = .editFromLocal(ekEvent: ekEvent)
            } else {
                assertionFailureLog()
                editInput = .editFrom(pbEvent: event.getPBModel(), pbInstance: instance.toPB())
            }
        } else {
            editInput = .editFrom(pbEvent: event.getPBModel(), pbInstance: instance.toPB())
        }
        return EventEditCoordinator(
            userResolver: self.userResolver,
            editInput: editInput,
            dependency: EventEditCoordinator.DependencyImpl(userResolver: userResolver)
        )
    }

    private lazy var eventEditControllerWrapper = EventEditControllerWrapper(
        userResolver: self.userResolver,
        getEventEditCoordinator: getEventCoordinator(event:instance:),
        getCreateEventCoordinator:  getCreateEventCoordinator(contextBuilder:))

    func getCreateEventCoordinator(
        contextBuilder: (UnsafeMutablePointer<EventCreateContext>) -> Void = { _ in }
    ) -> EventEditCoordinator {
        var createContext = EventCreateContext()
        contextBuilder(&createContext)
        return EventEditCoordinator(
            userResolver: self.userResolver,
            editInput: .createWithContext(createContext),
            dependency: EventEditCoordinator.DependencyImpl(userResolver: userResolver)
        )
    }

    public func getEventContentController(with pbEvent: Rust.Event, scene: EventDetailScene) -> UIViewController? {
        var eventEntity = PBCalendarEventEntity(pb: pbEvent)
        guard let calendar = calendarManager.calendar(with: eventEntity.calendarId) else {
            assertionFailureLog("找不到日历")
            return nil
        }
        eventEntity.needUpdate = false
        let instance = eventEntity.instance(with: calendar,
                                            instanceStartTime: eventEntity.startTime,
                                            instanceEndTime: eventEntity.endTime,
                                            instanceScore: "")// 新建的日程没有分数
        return getNormalDetailController(scene: scene,
                                         key: instance.key,
                                         calendarId: instance.calendarId,
                                         originalTime: instance.originalTime,
                                         startTime: instance.startTime,
                                         endTime: instance.endTime,
                                         instanceScore: instance.importanceScore,
                                         isFromChat: false,
                                         isFromNew: true,
                                         actionSource: .instance)
    }

    public func handleCreateEventSucceed(pbEvent: Rust.Event, fromVC: UIViewController) {
        self.showDetailAfterNewEvent(pbEvent: pbEvent, presentingVC: fromVC)
        saveAndUpdateCalendar(event: pbEvent)
    }

    private func saveAndUpdateCalendar(event: Rust.Event) {
        if var calendar = calendarManager.calendar(with: event.calendarID) {
            // 保存日程的所属日历不可见 则主动设置为可见
            if calendar.isVisible == false {
                calendar.isVisible = true
                calendarManager.updateCalendarVisibility(serverId: calendar.serverId,
                                                                     visibility: calendar.isVisible,
                                                                     isLocal: false)
                    .subscribe(onError: { error in
                        if error.errorType() == .exceedMaxVisibleCalNum,
                           let window = self.userResolver.navigator.mainSceneWindow {
                            UDToast.showFailure(with: I18n.Calendar_Detail_TooMuchViewReduce, on: window)
                        }
                    })
                    .disposed(by: self.disposeBag)
            }
        }
        // 通知有会议室更新
        event.attendees
            .filter { $0.category == .resource }
            .forEach { meetingRoom in
                self.eventCreateRelay.accept(meetingRoom.attendeeCalendarID)
            }
        localRefreshService.rxEventNeedRefresh.onNext(())

    }

    private func showDetailAfterNewEvent(pbEvent: Rust.Event,
                                         presentingVC: UIViewController?) {
        if let detailVC = getEventContentController(with: pbEvent, scene: .calendarView) {
            self.showDetail(vc: detailVC, from: presentingVC)
        }
    }

    private func showDetail(vc: UIViewController, from presentingVC: UIViewController?) {
        var navgation: UINavigationController?
        if presentingVC is UINavigationController {
            let nav = presentingVC as? UINavigationController
            navgation = nav
        } else {
            navgation = presentingVC?.navigationController
        }

        if Display.pad {
            let navi = LkNavigationController(rootViewController: vc)
            navi.modalPresentationStyle = .formSheet
            DispatchQueue.main.async {
                presentingVC?.present(navi, animated: true)
            }
        } else {
            navgation?.pushViewController(vc, animated: true)
        }

    }

    public func getLocalDetailController(identifier: String) -> UIViewController {
        let ekEvent = LocalCalendarManager.getEvent(for: .readEventOnEventDetailView, by: identifier)?.getEKEvent() ?? EKEvent()
        return getLocalDetailController(ekEvent: ekEvent) as UIViewController
    }
    
    public func getCreateEventController(for createBody: CalendarCreateEventBody) -> UIViewController {
        if createBody.attendees.count == 1 && createBody.perferredScene == .freebusy {
            switch createBody.attendees[0] {
            case .p2p(let chatId, let chatterId):
                // 单聊，进编辑页
                break
            case .meWithMeetingRoom(let meetingRoom):
                if FG.freebusyOpt {
                    return getFreeBusyController(meetingRoom: meetingRoom, createEventBody: createBody)
                } else {
                    return getOldFreeBusyController(meetingRoom: meetingRoom, createEventBody: createBody)
                }
            case .group(let chatId, let memberCount), .meetingGroup(let chatId, let memberCount):
                guard memberCount <= 30 else {
                    // 成员偏多，进编辑页
                    break
                }
                if let endDate = createBody.endDate, !endDate.isInSameDay(createBody.startDate) {
                    // 跨天，进编辑页
                    break
                }
                
                if FG.freebusyOpt {
                    var vc = getGroupFreeBusyController(chatId: chatId, chatType: "group", createEventBody: createBody)
                    vc = LkNavigationController(rootViewController: vc)
                    vc.modalPresentationStyle = .fullScreen
                    if Display.pad {
                        vc.modalPresentationStyle = .pageSheet
                    }
                    return vc
                } else {
                    var vc = getOldGroupFreeBusyController(chatId: chatId, chatType: "group", createEventBody: createBody)
                    vc = LkNavigationController(rootViewController: vc)
                    vc.modalPresentationStyle = .fullScreen
                    if Display.pad {
                        vc.modalPresentationStyle = .pageSheet
                    }
                    return vc
                }
            case .partialGroupMembers(let chatId, let memberChatterIds), .partialMeetingGroupMembers(let chatId, let memberChatterIds):
                guard memberChatterIds.count <= 30 else {
                    // 成员偏多，进编辑页
                    break
                }
                if let endDate = createBody.endDate, !endDate.isInSameDay(createBody.startDate) {
                    // 跨天，进编辑页
                    break
                }
                if FG.freebusyOpt {
                    var vc = getGroupFreeBusyController(chatId: chatId, chatType: "group", createEventBody: createBody)
                    vc = LkNavigationController(rootViewController: vc)
                    vc.modalPresentationStyle = .fullScreen
                    if Display.pad {
                        vc.modalPresentationStyle = .pageSheet
                    }
                    return vc
                } else {
                    var vc = getOldGroupFreeBusyController(chatId: chatId, chatType: "group", createEventBody: createBody)
                    vc = LkNavigationController(rootViewController: vc)
                    vc.modalPresentationStyle = .fullScreen
                    if Display.pad {
                        vc.modalPresentationStyle = .pageSheet
                    }
                    return vc
                }
            }
        } else if createBody.perferredScene == .webinar {
            let editCoordinator = EventEditCoordinator(userResolver: self.userResolver,
                                                       editInput: .createWebinar,
                                                       dependency: EventEditCoordinator.DependencyImpl(userResolver: userResolver),
                                                       legoInfo: .webinar())
            editCoordinator.autoSwitchToDetailAfterCreate = true
            return editCoordinator.prepare()
        }
        let editCoordinator = getCreateEventCoordinator { context in
            context.pointee.summary = createBody.summary
            context.pointee.startDate = createBody.startDate
            context.pointee.endDate = createBody.endDate
            context.pointee.isAllDay = false
            context.pointee.timeZone = .current
            context.pointee.meetingRooms = createBody.meetingRoom
            context.pointee.isOpenLarkVC = createBody.isOpenLarkVC
            var attendeeSeeds = [EventAttendeeSeed]()
            for attendee in createBody.attendees {
                switch attendee {
                case .p2p(let chatId, let chatterId):
                    let currentChatterId = dependency.currentUser.id
                    if currentChatterId != chatterId {
                        attendeeSeeds.append(.user(chatterId: currentChatterId))
                    }
                    attendeeSeeds.append(.user(chatterId: chatterId))
                    context.pointee.chatIdForSharing = chatId
                case .meWithMeetingRoom:
                    attendeeSeeds.append(.user(chatterId: dependency.currentUser.id))
                case .group(let chatId, _), .meetingGroup(let chatId, _):
                    attendeeSeeds.append(.group(chatId: chatId))
                    context.pointee.chatIdForSharing = chatId
                case .partialGroupMembers(let chatId, let memberChatterIds),
                     .partialMeetingGroupMembers(let chatId, let memberChatterIds):
                    attendeeSeeds.append(contentsOf: memberChatterIds.map { EventAttendeeSeed.user(chatterId: $0) })
                    context.pointee.chatIdForSharing = chatId
                }
            }
            context.pointee.attendeeSeeds = attendeeSeeds
        }
        editCoordinator.autoSwitchToDetailAfterCreate = true

        return editCoordinator.prepare()
    }

    /// 从会议的侧边栏设置进入
    public func getEventContentController(with chatId: String,
                                          isFromChat: Bool) -> UIViewController {
        let vc = EventDetailBuilder.build(userResolver: userResolver, chatId: chatId)
        return vc
    }

    /// 从视频卡片进入日程详情
    public func getEventContentController(with uniqueID: String,
                                          startTime: Int64,
                                          instance_start_time: Int64,
                                          instance_end_time: Int64,
                                          original_time: Int64,
                                          vchat_meeting_id: String,
                                          key: String) -> UIViewController {
        let vc = EventDetailBuilder.build(userResolver: self.userResolver,
                                          uniqueId: uniqueID,
                                          startTime: startTime,
                                          instance_start_time: instance_start_time,
                                          instance_end_time: instance_end_time,
                                          original_time: original_time,
                                          vchat_meeting_id: vchat_meeting_id,
                                          key: key)
        return vc
    }

    /// 订阅日历页面
    func getSubscribeViewController(_ disappearCallBack: (() -> Void)?) -> UINavigationController {
        let controller = SubscribeViewController(userResolver: self.userResolver,
                                                 calendarApi: calendarApi,
                                                 currentTenantID: dependency.currentUser.tenantId,
                                                 disappearCallBack: disappearCallBack)

        let nav = LkNavigationController(rootViewController: controller)
        nav.update(style: .default)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        return nav
    }

    func getImportViewControllerDependency(disappearCallBack: (() -> Void)? = nil) -> ImportCalendarViewControllerDependency {
        return ImportCalendarViewControllerDependency(
            bindGoogleCalAddrGetter: calendarApi.getBindGoogleCalAddr,
            disappearCallBack: disappearCallBack)
    }

    private func getCalendarSettingController(_ calendarId: String, _ disappearCallBack: (() -> Void)?) -> UINavigationController? {
        let controller = CalendarManagerFactory.settingController(with: calendarId,
                                                                  selfCalendarId: calendarManager.primaryCalendarID,
                                        selfUserId: dependency.currentUser.id,
                                                                  calendarAPI: calendarApi,
                                                                  calendarManager: calendarManager,
                                                                  calendarDependency: calendarDependency,
                                        skinType: settingProvider.getSetting().skinTypeIos,
                                                                  navigator: self.userResolver.navigator,
                                        eventDeleted: { [weak self] in
                                            self?.localRefreshService.rxCalendarNeedRefresh.onNext(())
                                        },
                                        disappearCallBack: disappearCallBack)
        if Display.pad {
            controller?.modalPresentationStyle = .formSheet
        }
        return controller
    }

    public func getRSVPDetail(entity: Any?,
                              rsvpStatusString: String?) -> UIViewController {
        guard let calendarEventEntity = entity as? PBCalendarEventEntity else {
            assertionFailureLog("getRSVPDetail error")
            return UIViewController()
        }

        let detailVC = EventDetailBuilder.build(userResolver: self.userResolver,
                                                rsvpEvent: calendarEventEntity.getPBModel(),
                                                rsvpString: rsvpStatusString ?? "")
        return detailVC
    }

    private func eventViewSettingGetter() -> () -> EventViewSetting {
        return { [weak self] in
            guard let self = self else { return SettingModel() }
            return self.settingProvider.getEventViewSetting()
        }
    }

    private func getAlternateCalendar() -> AlternateCalendarEnum {
        let alternateCalendar = self.settingProvider.getEventViewSetting().alternateCalendar ?? self.settingProvider.getEventViewSetting().defaultAlternateCalendar
        return alternateCalendar
    }

    func getImportCalendarViewController() -> UIViewController {
        return ImportCalendarViewController.controllerWithBack(userResolver: userResolver, dependency: getImportViewControllerDependency())
    }

    func getAccountManageViewController(presentStyle: AccountManageViewControllerDependency.PresentStyle = .push) -> AccountManageViewController {

        let dependency = AccountManageViewControllerDependency(
            getAllCalendars: calendarApi.getUserCalendars,
            getImportCalendarViewController: getImportCalendarViewController,
            getShouldSwitchToOAuthExchangeAccounts: calendarApi.getShouldSwitchToOAuthExchangeAccounts,
            bindGoogleCalAddrGetter: calendarApi.getBindGoogleCalAddr,
            presentStyle: presentStyle)
        let controller = AccountManageViewController(dependency: dependency, userResolver: self.userResolver)
        return controller
    }

    // 同步接口,仅仅提供给忙闲(个人,群,安排时间)使用,因为在infiniteScrollView只能同步调用,如果有机会重构不要照搬,用异步接口
    private func getInstancesLayoutAlgorithm() -> InstancesLayoutAlgorithm {
        return InstancesLayoutAlgorithm(layoutRequest: calendarApi.getInstancesLayoutRequest)
    }

    // 二维码签到专用 不对外暴露
    private func getOldFreeBusyController(meetingRoom: Rust.MeetingRoom, createEventBody: CalendarCreateEventBody? = nil) -> UIViewController {
        let layoutAlgorithm = getInstancesLayoutAlgorithm()
        let currentUserCalendarId = calendarManager.primaryCalendarID
        let freeBusyLoader = FreeBusyLoader(
            userResolver: userResolver,
            calendarApi: calendarApi,
            currentUserCalendarId: currentUserCalendarId,
            layoutAlgorithm: layoutAlgorithm.meetingRoomLayoutInstances,
            eventViewSettingGetter: eventViewSettingGetter(),
            meetingRoom: meetingRoom
        )
        let userIds = [dependency.currentUser.id]
        func specialAttendeesGetter(uids: [String]) -> Observable<[PBAttendee]> {
            .just([CalendarMeetingRoom.toAttendeeEntity(fromResource: meetingRoom, buildingName: "", tenantId: meetingRoom.tenantID)])
        }

        let viewController = OldFreeBusyController(
            userResolver: self.userResolver,
            userIds: userIds,
            currentUserCalendarId: currentUserCalendarId,
            firstWeekday: self.settingProvider.getEventViewSetting().firstWeekday,
            getNewEventMinute: defaultDurationGetter,
            attendeesGetter: specialAttendeesGetter(uids:),
            dataLoader: freeBusyLoader,
            getCreateEventCoordinator: getCreateEventCoordinator(contextBuilder:),
            createEventSucceedHandler: handleCreateEventSucceed(pbEvent:fromVC:),
            getNormalDetailController: getNormalDetailController,
            is12HourStyle: SettingService.shared().is12HourStyle,
            timeZoneService: timeZoneService,
            isFromProfile: false,
            eventCreateBody: createEventBody,
            meetingRoom: meetingRoom,
            startDate: createEventBody?.startDate ?? Date()
        )
        viewController.eventCreateBody = createEventBody
        let nav = LkNavigationController(rootViewController: viewController)
        nav.update(style: .default)
        nav.modalPresentationStyle = .fullScreen
        CalendarTracer.shareInstance.enterFreeBusy(meetingRoomCount: 0,
                                                   actionSource: .calProfile,
                                                   groupCount: 0,
                                                   userCount: 1)
        return nav
    }

    public func getOldFreeBusyController(userId: String, isFromProfile: Bool) -> UIViewController {
        let layoutAlgorithm = getInstancesLayoutAlgorithm()
        let currentUserCalendarId = calendarManager.primaryCalendarID
        let freeBusyLoader = FreeBusyLoader(
            userResolver: userResolver,
            calendarApi: calendarApi,
            currentUserCalendarId: currentUserCalendarId,
            layoutAlgorithm: layoutAlgorithm.layoutInstances,
            eventViewSettingGetter: eventViewSettingGetter()
        )
        let userIds = [userId, dependency.currentUser.id]
        let viewController = OldFreeBusyController(
            userResolver: self.userResolver,
            userIds: userIds,
            currentUserCalendarId: currentUserCalendarId,
            firstWeekday: self.settingProvider.getEventViewSetting().firstWeekday,
            getNewEventMinute: defaultDurationGetter,
            attendeesGetter: calendarApi.getAttendees,
            dataLoader: freeBusyLoader,
            getCreateEventCoordinator: getCreateEventCoordinator(contextBuilder:),
            createEventSucceedHandler: handleCreateEventSucceed(pbEvent:fromVC:),
            getNormalDetailController: getNormalDetailController,
            is12HourStyle: SettingService.shared().is12HourStyle,
            timeZoneService: timeZoneService,
            isFromProfile: isFromProfile
        )
        let nav = LkNavigationController(rootViewController: viewController)
        nav.update(style: .default)
        nav.modalPresentationStyle = .fullScreen
        CalendarTracer.shareInstance.enterFreeBusy(meetingRoomCount: 0,
                                                   actionSource: .calProfile,
                                                   groupCount: 0,
                                                   userCount: 1)
        return nav
    }

    public func getSeizeMeetingroomController(token: String) -> UIViewController {
        let viewController = SeizeMeetingRoomController(
            userResolver: self.userResolver,
            dependency: SeizeMeetingRoomDependencyImpl(userResolver: self.userResolver),
            token: token
        ) { (eventEntity) -> UIViewController in
                return self.getEventContentController(with: eventEntity.key,
                                                      calendarId: eventEntity.calendarId,
                                                      originalTime: eventEntity.originalTime,
                                                      instanceScore: "", // 从抢占会议室进入详情页没有分数
                                                      isFromChat: false,
                                                      scene: .calendarView)
        }
        return viewController
    }

    public func eventTimeDescription(start: Int64,
                                     end: Int64,
                                     isAllDay: Bool) -> String {
        return getTimeString(startDateTS: start,
                             endDateTS: end,
                             isAllDayEvent: isAllDay,
                             isInOneLine: true,
                             is12HourStyle: SettingService.shared().is12HourStyle.value)
    }

    public func getMeetingSummaryUpdatedStatus(uniqueKey: String?, originalTime: Int64?) -> Observable<Bool> {
        if let uid = uniqueKey, let originalTime = originalTime {
            return calendarApi.getMeetingSummaryUpdated(uid: uid, originalTime: originalTime)
        } else {
            return .just(false)
        }
    }

    // 端上约定 默认返回false，此接口用于退出群聊时相关逻辑判断，已无用 后续删除
    public func getIsOrganizer(chatID chatId: String) -> Observable<Bool> {
        return .just(false)
    }

    public func getToNormalGroup(chatID: String) -> Observable<Void> {
        return calendarApi.transferToNormalGroup(chatID: chatID)
    }

    public func showAddExternalAccountHint(in viewController: UIViewController) -> Observable<Bool> {
        let obv = PublishSubject<Bool>()
        return obv.asObservable()
    }
    
    public func getGroupFreeBusyController(chatId: String, chatType: String, createEventBody: CalendarCreateEventBody? = nil) -> UIViewController {
        
        let viewModel = FreeBusyMetaViewModel(userResolver: userResolver,
                                              chatId: chatId,
                                              chatType: chatType,
                                              createEventBody: createEventBody,
                                              createEventSucceedHandler: handleCreateEventSucceed(pbEvent:fromVC:))

        let viewController = FreeBusyMetaViewController(viewModel: viewModel)
        return viewController
    }
    
    // 二维码签到专用 不对外暴露
    private func getFreeBusyController(meetingRoom: Rust.MeetingRoom, createEventBody: CalendarCreateEventBody? = nil) -> UIViewController {
        
        let viewMdoel = FreeBusyMetaViewModel(userResolver: userResolver,
                                              userIds: [dependency.currentUser.id],
                                              meetingRoom: meetingRoom,
                                              createEventBody: createEventBody,
                                              createEventSucceedHandler: handleCreateEventSucceed(pbEvent:fromVC:))
        let viewController = FreeBusyMetaViewController(viewModel: viewMdoel)
        let nav = LkNavigationController(rootViewController: viewController)
        nav.update(style: .default)
        nav.modalPresentationStyle = .fullScreen
        CalendarTracer.shareInstance.enterFreeBusy(meetingRoomCount: 0, actionSource: .calProfile, groupCount: 0, userCount: 1)
        return nav
    }

    public func getFreeBusyController(body: CalendarFreeBusyBody) -> UIViewController {
        let viewModel = FreeBusyMetaViewModel(userResolver: userResolver,
                                              userIds:[body.uid, dependency.currentUser.id],
                                              isFromProfile: body.isFromProfile,
                                              createEventSucceedHandler: handleCreateEventSucceed(pbEvent:fromVC:))
        let viewController = FreeBusyMetaViewController(viewModel: viewModel)
        let nav = LkNavigationController(rootViewController: viewController)
        nav.update(style: .default)
        nav.modalPresentationStyle = .fullScreen
        CalendarTracer.shareInstance.enterFreeBusy(meetingRoomCount: 0,
                                                   actionSource: .calProfile,
                                                   groupCount: 0,
                                                   userCount: 1)
        return nav
    }
}
extension CalendarInterfaceImpl: CalendarViewControllerDelegate {

    internal func getEventListController(date: Date, containerWidthChange: Driver<CGFloat>, width: CGFloat, fromSceneMode: HomeSceneMode?) -> EventViewController {
        let vm = ListSceneViewModel(instanceService: instanceService, date: date, userResolver: self.userResolver)
        return ListSceneViewController(userResolver: self.userResolver, viewModel: vm, width: width, containerWidthChange: containerWidthChange, fromSceneMode: fromSceneMode)
    }

    internal func getMonthViewController(date: Date) -> MonthViewController {
        let loader = self.monthLoader
        let vc = MonthViewController(date: date,
                                   dataLoader: loader,
                                   workQueue: calendarWorkQueue,
                                   firstWeekday: self.settingProvider.getEventViewSetting().firstWeekday,
                                   is12HourStyle: SettingService.shared().is12HourStyle.value,
                                   localRefreshService: self.localRefreshService,
                                   calendarSelectTracer: self.calendarSelectTracer,
                                   alternateCalendar: getAlternateCalendar())
        
        return vc
    }

    /// 日历设置
    internal func getSettingsNavController() -> UINavigationController {
        let settingsDependency = getSettingsDependency()
        let settingController = DefaultSettingsController(userResolver: self.userResolver, dependency: settingsDependency)
        let nav = LkNavigationController(rootViewController: settingController)
        nav.update(style: .default)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        return nav
    }

    /// 导入日历页面
    internal func getImportViewController(_ disappearCallBack: (() -> Void)?) -> UINavigationController {
        let dependency = getImportViewControllerDependency(disappearCallBack: disappearCallBack)
        let navi = LkNavigationController(rootViewController: ImportCalendarViewController.controllerWithClose(userResolver: self.userResolver, dependency: dependency))
        navi.update(style: .default)
        navi.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        return navi
    }

    internal func getNormalDetailController(
        scene: EventDetailScene,
        key: String,
        calendarId: String,
        originalTime: Int64,
        startTime: Int64?,
        endTime: Int64?,
        instanceScore: String,
        isFromChat: Bool,
        isFromNew: Bool = false,
        actionSource: CalendarTracer.ActionSource) -> UIViewController {

        let viewController = EventDetailBuilder
            .prepare(options: isFromChat ? [.isFromChat] : [], scene: scene)
            .build(userResolver: self.userResolver,
                   key: key,
                   calendarId: calendarId,
                   originalTime: originalTime,
                   startTime: startTime,
                   endTime: endTime,
                   actionSource: actionSource)
        return viewController
    }

    internal func prepareForHomeIfNeeded(loggerModel: CaVCLoggerModel) {
        let loggerModel = loggerModel.createNewModelByTask(.process)
        guard !prepareFinish else { return }
        defer { prepareFinish = true }

        HomeScene.coldLaunchTracker?.insertPoint(.prepareSetting)

        // 子线程初始化数据
        DispatchQueue.global().async {
            loadData()
        }
        func loadData() {
            /// 确保有 Calendar 数据再执行其他请求
            calendarManager.loadPrimaryCalendarIfNeeded()
                .subscribe(onNext: { [weak self] () in
                    guard let self = self else { return }
                    let startTime = CACurrentMediaTime()
                    self.settingProvider.prepare(onFinish: { [weak self] in
                        guard let self = self else { return }
                        let cost = CACurrentMediaTime() - startTime
                        HomeScene.coldLaunchTracker?.addStage(.prepareSetting, with: cost)
                        self.prepareInstance(loggerModel: loggerModel)
                    }, loadSettingOnFinish: { [weak self] setting in
                        guard let self = self else { return }
                        if additionalTimeZoneOption {
                            SettingService.additionalTimeZoneUpgrade(setting: setting,
                                                                     timeZoneService: timeZoneService,
                                                                     settingProvider: settingProvider,
                                                                     disposeBag: disposeBag)
                        }
                    })

                    self.calendarManager.updateLocalCalendar()
                    self.calendarApi.startSyncCalendarsAndEvents()
                    self.timeZoneService.prepare()
                    self.prefetchData()
                    LarkConfigManager.initialize(with: self.calendarApi) // 加载小红点数据
                    if CalConfig.isMultiTimeZone {
                        let setting = self.settingProvider.getSetting()
                        let timeZone: TimeZone
                        if additionalTimeZoneOption {
                            timeZone = TimeZone.current
                        } else {
                            timeZone = TimeZone(identifier: setting.timeZone) ?? TimeZone.current
                        }
                        self.timeZoneService.preferredTimeZone.accept(timeZone)
                    }
                }).disposed(by: disposeBag)
            // 异步拉取timeContainer
            timeDataService.fetchTimeContainers()
        }
    }
}

extension CalendarInterfaceImpl {
    public func traceEventDetailVideoMeetingShowIfNeed(event: Rust.Event, with isInMeeting: Bool) {
        CalendarTracerV2.EventDetailVideoMeeting.traceView {
            $0.is_in_meeting = isInMeeting.description
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: event))
        }
    }

    public func traceEventDetailVideoMeetingClick(event: Rust.Event, click: String, target: String) {
        CalendarTracerV2.EventDetail.traceClick {
            $0.click(click).target(target)
            $0.event_type = event.category == .webinar ? "webinar" : "normal"
            $0.vchat_type = "lark"
            $0.link_type = "original"
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: event))
        }
    }

    // 详情页 cal_event_detail_click 的埋点不再使用下面三个方法了
    public func traceEventDetailOpenVideoMeeting(event: Rust.Event) {
        let type: CalendarTracer.EventType = event.type == .meeting ? .meeting : .event
        CalendarTracer.shareInstance.calOpenVideoMeeting(eventType: type)
    }

    public func traceEventDetailJoinVideoMeeting(event: Rust.Event) {
        let type: CalendarTracer.EventType = event.type == .meeting ? .meeting : .event
        CalendarTracer.shareInstance.calJoinVideoMeeting(eventType: type)
    }

    public func traceEventDetailCopyVideoMeeting(event: Rust.Event) {
        let type: CalendarTracer.EventType = event.type == .meeting ? .meeting : .event
        CalendarTracer.shareInstance.calCopyVideoMeeting(eventType: type)
    }

    public func traceEventDetailVCSetting() {
        CalendarTracer.shareInstance.calEventDetailVCSetting()
    }

    public func reciableTraceEventDetailStartEnterMeeting() {
        ReciableTracer.shared.recStartJumpVideo()
    }

    public func reciableTraceEventDetailEndEnterMeeting() {
        ReciableTracer.shared.recEndJumpVideo()
    }

    public func reciableTraceEventDetailEnterMeetingFailed(errorCode: Int, errorMessage: String) {
        ReciableTracer.shared.recTracerError(errorType: ErrorType.Unknown,
                                                                scene: .CalEventDetail,
                                                                event: .enterMeeting,
                                                                userAction: "cal_enter_meeting",
                                                                page: "cal_event_detail",
                                                                errorCode: errorCode,
                                                                errorMessage: errorMessage)
    }
}

extension CalendarInterfaceImpl {
    public func getAllCalendarsForSearchBiz() -> Observable<[CalendarForSearch]> {
        return calendarApi.getAllCalendars()
            .map { response -> [CalendarForSearch] in
                response.calendars.values
                    .compactMap { calendar -> CalendarForSearch? in
                        guard calendar.isSubscriber else { return nil }
                        return .init(
                            serverId: calendar.serverID,
                            summary: calendar.localizedSummary.isEmpty ? calendar.summary : calendar.localizedSummary,
                            isVisible: calendar.isVisible,
                            isOwnerAccessRole: calendar.selfAccessRole == .owner,
                            color: SkinColorHelper.pickerColor(of: calendar.personalizationSettings.colorIndex.rawValue)
                        )
                    }
            }
    }
}
