//
//  CalendarViewController.swift
//  Calendar
//
//  Created by zhouyuan on 2018/9/11.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import LarkSetting
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import SnapKit
import RxSwift
import RxCocoa
import LarkRustClient
import RustPB
import NotificationCenter
import EventKit
import LarkUIKit
import RoundedHUD
import LarkGuide
import LarkGuideUI
import LarkContainer
import LarkInteraction
import LarkFeatureGating
import LarkNavigation
import EENavigator
import UniverseDesignDialog
import UniverseDesignActionPanel
import LKCommonsLogging

public protocol CalendarHome: NavigatorFrom {
    var controller: UIViewController { get }

    func jumpToSlideView(calendarID: String?, source: String?)

    func jumpToCalendarWithDateAndType(date: Date?, type: String?, toTargetTime: Bool)
}

protocol EventViewController: UIViewController {
    typealias ScrollDriction = ArrowDirection
    func reloadData(with date: Date)
    func currentPageDate() -> Date
    func getCurrentSelectDate() -> Date
    func scrollToRedLine(animated: Bool)
    func dayViewContentOffset() -> CGPoint?
    var tabBarDirection: ScrollDriction { get }
    var delegate: EventViewControllerDelegate? { get set }
}

final class MockEventViewController: UIViewController, EventViewController {
    func reloadData(with date: Date) {}
    func currentPageDate() -> Date { return Date() }
    func getCurrentSelectDate() -> Date { return Date() }
    func scrollToRedLine(animated: Bool) {}
    func dayViewContentOffset() -> CGPoint? { return nil }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {}
    var controller: UIViewController = UIViewController()
    var tabBarDirection: ScrollDriction = .horizontal
    weak var delegate: EventViewControllerDelegate?
}

protocol EventViewControllerDelegate: AnyObject {
    func eventCreateActionTaped(_ eventViewController: EventViewController)

    func dateDidChanged(_ eventViewController: EventViewController, date: Date)

    func displayRangeDidChanged(_ eventViewController: EventViewController, startDate: Date, endDate: Date)

    func eventViewController(_ eventViewController: EventViewController,
                             didSelected model: BlockDataProtocol)
    func onFastNewEvent(_ eventViewController: EventViewController, startTime: Date, endTime: Date)

    /// 滚动回调，用于tab翻页动画
    func eventViewController(_ eventViewController: EventViewController,
                             pagingProgress: CGFloat,
                             isJump: Bool,
                             shouldGradual: Bool)
}

extension EventViewControllerDelegate {
    func eventViewController(_ eventViewController: EventViewController,
                             pagingProgress: CGFloat,
                             isJump: Bool,
                             shouldGradual: Bool = true) {
        self.eventViewController(eventViewController,
                                 pagingProgress: pagingProgress,
                                 isJump: isJump,
                                 shouldGradual: shouldGradual)
    }
}

struct CalendarViewControllerDependency {
    typealias CalendarID = String
    var calendarApi: CalendarRustAPI
    var calendarDependency: CalendarDependency?
    var timeDataService: TimeDataService
    var settingProvier = SettingProviderMock()
    var instanceService: InstanceService
    lazy var is12HourStyle: BehaviorRelay<Bool> = {
        return calendarDependency?.is12HourStyle ?? BehaviorRelay<Bool>(value: false)
    }()
    var getCreateEventCoordinator: GetCreateEventCoordinator
    var createEventSucceedHandler: CreateEventSucceedHandler
    var getLocalDetailController: (EKEvent) -> UIViewController
    lazy var eventViewSettingSubject: PublishSubject<Void> = {
        settingProvier.updateViewSettingPublish
    }()
    var getCalendarSettingController: (_ calendarId: String, _ disappearCallBack: (() -> Void)?) -> UINavigationController?
    var getCurrentSkinType: () -> CalendarSkinType
    var timeZoneService: TimeZoneService
    let getDaysPerPage: (_ mode: DayViewSwitcherMode) -> Int
    let cachePageCount: Int
    let firstScreenDataReady: BehaviorRelay<Bool>
    let getImportCalendarViewController: (_ disappearCallBack: (() -> Void)?) -> UINavigationController
    let updateEventRelay: PublishRelay<CalendarID>
    let getAccountManageViewController: (AccountManageViewControllerDependency.PresentStyle) -> AccountManageViewController
}

protocol CalendarViewControllerDelegate: AnyObject {
    func getEventListController(date: Date, containerWidthChange: Driver<CGFloat>, width: CGFloat, fromSceneMode: HomeSceneMode?) -> EventViewController
    func getMonthViewController(date: Date) -> MonthViewController
    func getNormalDetailController(scene: EventDetailScene,
                                   key: String,
                                   calendarId: String,
                                   originalTime: Int64,
                                   startTime: Int64?,
                                   endTime: Int64?,
                                   instanceScore: String,
                                   isFromChat: Bool,
                                   isFromNew: Bool,
                                   actionSource: CalendarTracer.ActionSource) -> UIViewController
    func getSettingsNavController() -> UINavigationController
    func prepareForHomeIfNeeded(loggerModel: CaVCLoggerModel)
}

public final class CalendarViewController: CalendarController, CalendarHome, Timable, LarkNaviBarAbility, UserResolverWrapper {
    @ScopedInjectedLazy var tabBarView: TabBarView?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var navigationService: NavigationService?
    @ScopedInjectedLazy var docsDispatherSerivce: DocsDispatherSerivce?
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var meetingRoomHomeTracer: MeetingRoomHomeTracer?
    @ScopedInjectedLazy var newGuideManager: NewGuideService?
    @ScopedInjectedLazy var timeDataService: TimeDataService?

    typealias AddNewEventButtonStyle = CalendarViewStyle.AddNewEventButton
    typealias Style = CalendarViewStyle
    private weak var delegate: CalendarViewControllerDelegate?
    let disposeBag = DisposeBag()
    private(set) var dependency: CalendarViewControllerDependency
    private var jumpToAccount: String?
    var feelGoodDisposable: Disposable?
    let updateCalendarInterval: TimeInterval = 60 * 5
    var lastUpdateTime: TimeInterval?

    private var isCurrentVCActive = false

    private let logger = Logger.log(CalendarViewController.self, category: "calendar.CalendarViewController")

    private let containerWidthChangePub: BehaviorSubject<CGFloat> = BehaviorSubject<CGFloat>(value: .zero)
    /// 满意度调研
    private var magicRegister: CalendarMagicRegister?
    private lazy var containerWidthChangeDriver: Driver<CGFloat> = {
        return self.containerWidthChangePub.asDriver(onErrorJustReturn: 0.0).skip(1)
    }()
    // 影响 scene mode 相关的 context 信息
    private var sceneModeContext = (
        sizeClass: UIUserInterfaceSizeClass,
        displayWidth: CGFloat
    )?.none
    var timer: Timer?
    private let loggerModel = CaVCLoggerModel(task: .action)
    public let userResolver: UserResolver
    
    /// Guide，按照顺序添加引导Block
    private var hasStartShowGuide: Bool = false
    private lazy var guideBlocks: [GuideBlock] = {
        [self.showOnboardingGuideIfNeed,
         self.showTaskInCalendarGuideIfNeeded,
         self.showNewCalendarSettingGuideIfNeeded]
    }()
    /// 收到一个信号表示可以执行下一个引导
    private var rxGuideBlock: BehaviorRelay<Void> = .init(value: ())
    private var guideDisposeBag = DisposeBag()

    init(dependency: CalendarViewControllerDependency, delegate: CalendarViewControllerDelegate, userResolver: UserResolver) {
        HomeScene.coldLaunchTracker?.insertPoint(.initHomeScene)
        self.dependency = dependency
        self.delegate = delegate
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        HomeScene.coldLaunchState = .start
        self.addTimeChangeNotifications()
        initTimeZone()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let debounce = Debouncer(delay: 0.05)

    // 监听 eventViewController 的 instance cache strategy
    private var instanceCacheStrategyDisposable: Disposable?
    // 包括三日视图 列表视图 月视图 需要满足的协议
    private var eventViewController: EventViewController? {
        didSet {
            // eventViewController 变了，切换 instanceCache provider
            instanceCacheStrategyDisposable?.dispose()
            instanceCacheStrategyDisposable = nil
            if let daySceneChild = eventViewController as? InstanceCacheStrategyProvider {
                instanceCacheStrategyDisposable = daySceneChild.rxInstanceCacheStrategy?
                    .subscribe(onNext: { [weak self] in
                        self?.dependency.instanceService.cacheStrategy = $0
                    })
            } else {
                self.dependency.instanceService.cacheStrategy = nil
            }
        }
    }

    private var calendarWrapperView = UIView()
    private var meetingRoomWrapperView = UIView()

    private(set) lazy var switcher: CalendarMeetingRoomSwitchView = {
        let entries: [CalendarMeetingRoomSwitchView.Entry]
            entries = [.calendar(.init(title: BundleI18n.Calendar.Calendar_NewSettings_Calendar)), .meetingRoom(.init(title: BundleI18n.Calendar.Calendar_Common_Room))]

        var defaultEntry = entries.first!

        if let lastUsedTitle = KVValues.lastUsedEntry,
           let lastUsedEntry = entries.first(where: { $0.title == lastUsedTitle }) {
            defaultEntry = lastUsedEntry
        }
        let switcher = CalendarMeetingRoomSwitchView(userResolver: userResolver, entries: entries, defaultEntry: defaultEntry)

        return switcher
    }()

    private var meetingRoomHomeVCCreated = false

    private lazy var meetingRoomHomeViewController: LoadingShellViewController = {
        let shellVC = LoadingShellViewController { [weak self] multiLevel, _ in
            guard let self = self else { return UIViewController() }
            let vm = MeetingRoomHomeViewModel(multiLevelResources: multiLevel, userResolver: self.userResolver)
            let vc = MeetingRoomHomeViewController(viewModel: vm, userResolver: self.userResolver)
            vc.calendarVCDependency = self.dependency
            return vc
        }
        meetingRoomHomeVCCreated = true
        return shellVC
    }()

    private let titleView = CalendarHomeViewHeaderView(frame: CGRect(x: 0,
                                                                     y: 0,
                                                                     width: UIScreen.main.nativeBounds.width,
                                                                     height: CalendarSidebarStyle.headerViewHeight))
    private let addButton = AddNewEventButton()

    private var lastSceneMode: HomeSceneMode?

    private let calendarSettingGuideImp = CalendarSettingGuideImp()

    override public func viewDidLoad() {
        HomeScene.coldLaunchTracker?.insertPoint(.homeSceneDidLoad)
        super.viewDidLoad()
        TimerMonitorHelper.shared.launchTimeTracer?.viewDidLoad.start()
        defer { TimerMonitorHelper.shared.launchTimeTracer?.viewDidLoad.end() }
        EffLogger.shouldLog = FeatureGating.viewPageLogChore(userID: self.userResolver.userID)
        self.delegate?.prepareForHomeIfNeeded(loggerModel: self.loggerModel)
        self.view.backgroundColor = UIColor.ud.bgBody

        self.isNavigationBarHidden = true
        self.navigationBarHiddenAnimated = true

        titleView.delegate = self
        view.addSubview(titleView)
        titleView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(CalendarSidebarStyle.headerViewHeight)
        }

        view.addSubview(switcher)
        switcher.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleView.snp.bottom)
        }

        view.addSubview(calendarWrapperView)
        calendarWrapperView.snp.makeConstraints { (make) in
            make.top.equalTo(switcher.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        view.addSubview(meetingRoomWrapperView)
        meetingRoomWrapperView.snp.makeConstraints { make in
            make.edges.equalTo(calendarWrapperView)
        }

        defer {
            DispatchQueue.main.async {
                self.showMeetingRoomGuideIfNeeded(targetView: self.switcher.meetingRoomEntryButton ?? self.switcher)
            }
        }

        // bindings
        switcher.rx.selectedEntry
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] entry in
                guard let self = self else { return }
                self.switchCalendarMeetingRoom(entry: entry)
                KVValues.lastUsedEntry = entry.title
            })
            .disposed(by: disposeBag)
        switcher.rx.slideViewButtonSelected
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self, let newGuideManager = self.newGuideManager else { return }
                CalendarTracer.shared.calMainClick(type: .calendar_list_open)
                self.showCalendarSlideView(sender: self.switcher.slideViewButton)
                GuideService.setGuideShown(newGuideManager: newGuideManager, key: .calendarOptimizeRedDotKey)
            })
            .disposed(by: disposeBag)
        addButton.addTarget(self, action: #selector(addButtonClicked), for: .touchUpInside)
        self.view.addSubview(addButton)
        addButton.snp.makeConstraints { (make) -> Void in
            make.right.equalToSuperview().offset(AddNewEventButtonStyle.rightMargin)
            make.height.width.equalTo(AddNewEventButtonStyle.buttonHeight)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-16)
        }
        addButton.layer.cornerRadius = AddNewEventButtonStyle.buttonHeight / 2

        self.setupListener(eventViewSettingSubject: dependency.eventViewSettingSubject)

        LocalCalendarManager.updateEKCalendars(for: .readCalendarWhenCalendarViewShowed)
        
        // 从后台进入前台的通知函数
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(onEnterForeground),
                         name: UIApplication.willEnterForegroundNotification,
                         object: nil)

        // 从前台进入后台的通知函数，后台场景范围不包括非活跃状态(弹窗等)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(onEnterBackground),
                         name: UIApplication.didEnterBackgroundNotification,
                         object: nil)

        TimerMonitorHelper.shared.launchTimeTracer?.didAppearGap.start()
        registerMagicIfNeeded()
        observeTabSwitch()

        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {

        sceneModeContext?.displayWidth = size.width
        let duration = coordinator.transitionDuration
        DispatchQueue.main.async {
            self.switchSceneModeIfNeeded(with: duration)
        }
        super.viewWillTransition(to: size, with: coordinator)
    }

    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        sceneModeContext?.sizeClass = newCollection.horizontalSizeClass
        let duration = coordinator.transitionDuration
        DispatchQueue.main.async {
            self.reloadNaviBar()
            self.switchSceneModeIfNeeded(with: duration)
        }
        super.willTransition(to: newCollection, with: coordinator)
    }

    @objc
    private func onEnterForeground() {
        pullDataFromServer()

        // 如果进入前台，本地日历正常获取，不阻塞加载
        LocalCalendarManager.blockedLoad = false
        refreshLocalEvent()
    }

    @objc
    private func onEnterBackground() {
        // 如果进入后台，本地日历阻止获取，阻塞加载
        LocalCalendarManager.blockedLoad = true
    }
    
    private func pullDataFromServer() {
        // 后台切前台在日历首页时，调用一次同步接口
        if self.isViewLoaded && self.view?.window != nil {
            self.dependency.calendarApi.startSyncCalendarsAndEvents()
            self.dependency.timeDataService.forceUpdateTimeBlockData()
        }
    }

    /// 皮肤、蒙层、每周开始时间设置，直接刷新整个controller，因为不仅是数据变了，view也需要变
    private func setupListener(eventViewSettingSubject: PublishSubject<Void>) {
        eventViewSettingSubject.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.resetController()
        }).disposed(by: disposeBag)
    }

    public var viewDidRefreshed: (() -> Void)?
    public var controller: UIViewController {
        return self
    }
    public var iPadNaviView: UIView {
        let container = UIView()
        let stackView = UIStackView()
        stackView.spacing = 24
        stackView.alignment = .center

        container.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.bottom.top.equalToSuperview()
            $0.left.right.equalToSuperview().inset(10)
        }
        return container
    }

    public var isAllowSearch: Bool {
        return !Display.pad
    }

    public var naviHeaderTitle: BehaviorRelay<String> = BehaviorRelay(value: CalendarHomeViewHeaderView.getMonthTitle(date: Date()))

    private func addTimeChangeNotifications() {
        let action = { [weak self] (_: Notification) in
            Calendar.gregorianCalendar = Calendar(identifier: .gregorian)
            guard let `self` = self else {
                return
            }
            self.resetController()
            operationLog(optType: CalendarOperationType.timeNotification.rawValue)
        }
        /// 系统时间变化相关通知
        NotificationCenter.default.rx
            .notification(UIApplication.significantTimeChangeNotification)
            .subscribe(onNext: action)
            .disposed(by: self.disposeBag)
        self.dependency.is12HourStyle.asDriver().skip(1).drive(onNext: { [weak self] (_) in
            self?.resetController()
        }).disposed(by: self.disposeBag)
    }

    private func resetController() {
        self.setupController(with: HomeSceneMode.current,
                             date: self.currentPageDate(),
                             wrapper: self.calendarWrapperView,
                             width: self.view.frame.size.width,
                             contentOffset: self.eventViewController?.dayViewContentOffset())
    }

    private func setupController(with mode: HomeSceneMode,
                                 date: Date? = nil,
                                 wrapper: UIView,
                                 width: CGFloat,
                                 contentOffset: CGPoint?,
                                 toTargetTime: Bool = false) {
        let date = date ?? getCurrentTimeUiDate()
        let eventViewController: EventViewController
        switch mode {
        case .day(let dayCategory):
            let daysPerScene = dayCategory.daysPerScene
            if let daySceneChild = self.eventViewController as? DaySceneViewController,
                daySceneChild.parent == self,
                daySceneChild.daysPerScene == daysPerScene {
                // 在日视图之间切换 不动vc层级
                eventViewController = daySceneChild
                daySceneChild.updateDate(date, toTargetTime: toTargetTime)
            } else {
                eventViewController = createDaySceneViewController(date: date, daysPerScene: daysPerScene)
                if let daySceneChild = self.eventViewController as? DaySceneViewController {
                    daySceneChild.willMove(toParent: nil)
                    daySceneChild.view.removeFromSuperview()
                    daySceneChild.removeFromParent()
                }
                self.replaceEventViewController(controller: eventViewController, wrapper: wrapper)
                self.lastSceneMode = .day(dayCategory)
            }
        case .list:
            eventViewController = createEventListViewController(date: date, width: width)
            self.replaceEventViewController(controller: eventViewController, wrapper: wrapper)
            self.lastSceneMode = .list
        case .month:
            eventViewController = createMonthViewController(date: date)
            self.replaceEventViewController(controller: eventViewController, wrapper: wrapper)
            self.lastSceneMode = .month
            if toTargetTime {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    (eventViewController as? MonthViewController)?.scrollToDate(date)
                }
            }
        }
        self.shouldChangeDateImage()
        let progress = CGFloat(daysBetween(date1: Date.today(), date2: date))
        tabBarView?.animation(with: progress,
                             shouldGradual: true,
                             direction: eventViewController.tabBarDirection)
        changeHeaderViewMonth(date: date)
    }

    private func currentPageDate() -> Date {
        switch switcher.currentSelected {
        case .calendar: return self.eventViewController?.currentPageDate() ?? Date()
        case .meetingRoom: return (self.meetingRoomHomeViewController.childVC as? MeetingRoomHomeViewController)?.currentDate ?? Date()
        }
    }

    @objc
    func addButtonClicked(_ sender: UIButton) {
        if FG.enableWebinar {
            calendarDependency?.pullVCQuotaHasWebinar(completion: { [weak self] result in
                DispatchQueue.main.async {
                    if case .success(let enableWebinar) = result, enableWebinar {
                        let source = UDActionSheetSource(sourceView: sender,
                                                            sourceRect: sender.bounds,
                                                            arrowDirection: .down)
                        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(style: .autoPopover(popSource: source)))

                        actionSheet.addDefaultItem(text: BundleI18n.Calendar.Calendar_Edit_CreateEvent, action: {
                            self?.prepareCreateEvent()
                        })
                        actionSheet.addDefaultItem(text: BundleI18n.Calendar.Calendar_Edit_CreateWebinar, action: {
                            self?.createWebinarEvent()
                        })
                        actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel)

                        self?.present(actionSheet, animated: true)
                    } else {
                        self?.prepareCreateEvent()
                    }
                }
            })
        } else {
            prepareCreateEvent()
        }
    }

    private func createWebinarEvent() {
        CalendarTracer.shared.calendarMeetingRoomSwitcherActions(action: .createWebinar)
        let eventEditCoordinator = EventEditCoordinator(userResolver: self.userResolver,
                                                        editInput: .createWebinar,
                                                        dependency: EventEditCoordinator.DependencyImpl(userResolver: userResolver),
                                                        legoInfo: .webinar())
        eventEditCoordinator.delegate = self
        eventEditCoordinator.actionSource = .addButton
        eventEditCoordinator.start(from: self)
    }

    private func prepareCreateEvent() {
        ReciableTracer.shared.recStartAddFull()
        let date = currentPageDate()
        let completionHandle: (() -> Void) = { [weak self] in
            self?.eventViewController?.reloadData(with: date)
        }
        let diff = Int(getJulianDay(date: date) - getJulianDay(date: Date()))
        let newEventDate = (Date() + diff.days) ?? Date()
        let newEventModel = NewEventModel.defaultNewModel(startTime: newEventDate)
        CalendarTracer.shareInstance.calFullEditEvent(actionSource: .createEventButton,
                                                      editType: .new,
                                                      mtgroomCount: 0,
                                                      thirdPartyAttendeeCount: 0,
                                                      groupCount: 0,
                                                      userCount: 0,
                                                      timeConfilct: .unknown)
        createNewEvent(newEventModel: newEventModel, fromAddButton: true, completionHandle: completionHandle)
        operationLog(optType: CalendarOperationType.eventAdd.rawValue)
        ReciableTracer.shared.recEndAddFull()
        CalendarTracer.shared.calendarMeetingRoomSwitcherActions(action: .createEvent)
    }

    private func createNewEvent(newEventModel: NewEventModel,
                                fromAddButton: Bool,
                                completionHandle: @escaping () -> Void) {
        let editCoordinator = dependency.getCreateEventCoordinator { contextPointer in
            contextPointer.pointee.startDate = newEventModel.startTime
            contextPointer.pointee.endDate = newEventModel.endTime
        }
        editCoordinator.delegate = self
        editCoordinator.actionSource = fromAddButton ? .addButton : .timeBlock
        editCoordinator.start(from: self)
    }

    func showDetail(model: BlockDataProtocol) {
        model.process { type in
            switch type {
            case .event(let instance):
                switch instance {
                case .local(let localInstance):
                    processInstance(CalendarEventInstanceEntityFromLocal(event: localInstance))
                case .rust(let rustInstance):
                    processInstance(CalendarEventInstanceEntityFromPB(withInstance: rustInstance))
                }
            case .timeBlock(let timeBlock):
                processTimeBlock(timeBlock)
            case .instanceEntity(let entity):
                processInstance(entity)
            case .none:
                assertionFailure("unknown model type")
            }
        }
        func processInstance(_ instance: CalendarEventInstanceEntity) {
            CalendarTracerV2.CalendarMain.traceClick {
                $0.click("event_details").target("cal_event_detail_view")
                $0.type = "event"
                $0.mergeEventCommonParams(commonParam: CommonParamData(instance: instance.toPB()))
            }
            
            let detailViewController: UIViewController
            if instance.isLocalEvent() {
                guard let ekEvent = instance.originalModel() as? EKEvent else {
                    assertionFailureLog()
                    return
                }
                detailViewController = dependency.getLocalDetailController(ekEvent)
            } else {
                guard let normalDetail = self.delegate?.getNormalDetailController(scene: .calendarView,
                                                                                  key: instance.key,
                                                                                  calendarId: instance.calendarId,
                                                                                  originalTime: instance.originalTime,
                                                                                  startTime: instance.startTime,
                                                                                  endTime: instance.endTime,
                                                                                  instanceScore: instance.importanceScore,
                                                                                  isFromChat: false,
                                                                                  isFromNew: false,
                                                                                  actionSource: .instance) else { return }
                detailViewController = normalDetail
            }
            
            if Display.pad {
                let nav = LkNavigationController(rootViewController: detailViewController)
                nav.modalPresentationStyle = .formSheet
                nav.update(style: .default)
                self.present(nav, animated: true, completion: nil)
            } else {
                self.navigationController?.pushViewController(detailViewController, animated: true)
            }
        }
        
        func processTimeBlock(_ timeBlock: TimeBlockModel) {
            CalendarTracerV2.CalendarMain.normalTrackClick {
                var map: [String: Any] = [:]
                map["click"] = "event_details"
                if timeBlock.source == .task {
                    map["type"] = "task"
                    map["task_id"] = timeBlock.taskId
                }
                return map
            }
            timeDataService?.enterDetail(from: self, id: timeBlock.taskId)
        }
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle { .default }

    private var initWidth: CGFloat?
    public func initEventViewController() {
        if initWidth == nil {
            ViewPageDowngradeTaskManager.addTask(scene: .localCalendarLoad,
                                                 way: .delay1s) { _ in
                LocalCalendarManager.firstTimeInit(for: .readLocalEventInstanceOnEventView)
            }
            HomeSceneMode.current = desiredSceneMode()
            sceneModeContext = (traitCollection.horizontalSizeClass, view.bounds.width)
        }
        guard initWidth != view.frame.width else {
            return
        }
        self.setupController(with: HomeSceneMode.current,
                                 wrapper: self.calendarWrapperView,
                                 width: view.frame.width,
                                 contentOffset: nil)
        initWidth = view.frame.width
        self.view.layoutIfNeeded()

    }

    var isCodeStartLoading: Bool?

    var hud: RoundedHUD?

    // 轮询200次 -> 1分钟
    var pollingLimit: Int = 200

    @objc
    private func coldStartLoading() {
        pollingLimit -= 1
        guard pollingLimit > 0 else {
            hud?.remove()
            self.hud = nil
            return
        }
        DispatchQueue.global().async {
            task()
        }
        func task() {
            dependency.calendarApi.getPrimaryCalendarLoadingStatus()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (isLoading) in
                    guard let `self` = self else {
                        return
                    }
                    self.isCodeStartLoading = isLoading
                    if isLoading && !CalendarMonitorUtil.hadTrackPerfCalLaunch {
                        if self.hud == nil {
                            self.hud = RoundedHUD()
                            self.hud?.showLoading(with: BundleI18n.Calendar.Calendar_Common_LoadingCommon,
                                                  on: self.view,
                                                  disableUserInteraction: false)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: self.coldStartLoading)
                    } else {
                        self.hud?.remove()
                        self.hud = nil
                    }
                }).disposed(by: disposeBag)
        }
        tryCheckOAuthStatus()
    }

    override public func viewDidAppear(_ animated: Bool) {
        if isCodeStartLoading == nil {
            HomeScene.coldLaunchTracker?.insertPoint(.homeSceneDidAppear)
        }

        super.viewDidAppear(animated)
        TimerMonitorHelper.shared.launchTimeTracer?.didAppearGap.end()
        TimerMonitorHelper.shared.launchTimeTracer?.showGrid.start()

        if isCodeStartLoading == nil {
            coldStartLoading()
        }
        self.dependency.calendarApi.startSyncCalendarsAndEvents()
        self.dependency.timeDataService.forceUpdateTimeBlockData()
        TimerMonitorHelper.shared.launchTimeTracer?.initEventVC.start()
        TimerMonitorHelper.shared.launchTimeTracer?.initEventVC.end()
        startTimer(&timer) { [weak self] in
            guard let `self` = self else { return }
            if self.isViewLoaded && self.view?.window != nil {
                self.localRefreshService?.rxMainViewNeedRefresh.onNext(())
            } else {
                assertionFailureLog("calendar timer stop fail")
            }
        }
        TimerMonitorHelper.shared.launchTimeTracer?.instanceRenderGap.start()
        
        self.startShowOnboarding()
        
        let now = Date().timeIntervalSince1970
        if now - (lastUpdateTime ?? 0) >= updateCalendarInterval {
            calendarManager?.updateAllCalendar()
            lastUpdateTime = now
        }
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopTimer(&timer)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingService.shared().stateManager.activate()
        isCurrentVCActive = true
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingService.shared().stateManager.inActivate()
        isCurrentVCActive = false
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        docsDispatherSerivce?.clear()
    }

    public func jumpToSlideView(calendarID: String?, source: String?) {
        showCalendarSlideView(sender: switcher.slideViewButton, highlightCalendarID: calendarID, source: source)
    }

    public func jumpToCalendarWithDateAndType(date: Date?, type: String?, toTargetTime: Bool = false) {
        let sceneModeMap: [String: HomeSceneMode] = [
            "three_day": Display.pad ? .day(.week) : .day(.three),
            "day": .day(.single),
            "list": Display.pad ? HomeSceneMode.current : .list,
            "month": .month
        ]

        // 复用同一AppLink的会议室特化逻辑
        guard type != "meeting" else {
            if let meetingRoomEntry = switcher.entries.first(where: { $0 == .meetingRoom(.init(title: "")) }) {
                switcher.currentSelected = meetingRoomEntry
                switcher.sendActions(for: .valueChanged)
            }
            return
        }

        guard type != nil || date != nil else {
            // 只跳转到日历tab，不做任何操作
            return
        }

        if switcher.currentSelected != .calendar(.init(title: "")) {
            if let calendarEntry = switcher.entries.first(where: { $0 == .calendar(.init(title: "")) }) {
                switcher.currentSelected = calendarEntry
                switcher.sendActions(for: .valueChanged)
            }
        }

        let mode = sceneModeMap[type ?? ""] ?? HomeSceneMode.current
        if mode == HomeSceneMode.current && date == nil {
            return
        }
        if var date = date {
            date = CalendarViewController.getUIDate(timeStamp: date, mode: mode, timeZoneId: getCurrentTimeZoneId())
        }

        // App link 调用到这个函数时还未 setupController，由于initEventViewController在viewDidAppear中调用。所以加了个main.asyncz保证时序
        DispatchQueue.main.async {
            self.switchSceneMode(mode, withDate: date, toTargetTime: toTargetTime)
        }

    }

    public func onTabbarItemTapped() {
        guard let tabBarView = self.tabBarView else {
            operationLog(message: "onTabbarItemTapped failed, can not get tabbarview from larkcontainer")
            return
        }
        if meetingRoomHomeVCCreated && meetingRoomHomeViewController.parent != nil {
            guard let vc = meetingRoomHomeViewController.childVC as? MeetingRoomHomeViewController else {
                return
            }
            tabBarView.endAnimation()
            vc.changeSelectedDate(date: Date())
        } else {
            /// 执行自己的结束动画，不跟随scrollViewm，必须在scrollView前面，不然 动画会跟随 scrollView
            tabBarView.endAnimation()
            self.eventViewController?.scrollToRedLine(animated: true)
            operationLog(optType: CalendarOperationType.tabToRedLine.rawValue)
            /// 回到今天打点
            CalendarTracer.shareInstance.calNavigation(actionSource: .defaultView,
                                                       navigationType: .today,
                                                       viewType: .init(mode: HomeSceneMode.current.convertToOldType()))
        }
    }

    private let itemTapedTimeS: TimeInterval = 0
    public func tabItemDidTapped() {
        let mode = HomeSceneMode.current.convertToOldType()
        let skinType = dependency.getCurrentSkinType()
        CalendarTracer.shareInstance.calTab(viewType: .init(mode: mode),
                                            calendarID: calendarManager?.visibleCalendarsIDs.joined(separator: ",") ?? "",
                                            themeType: .init(skinType: skinType))
    }

    private func onClickNewEventButtonView(startTime: Date, endTime: Date) {
        let calendarEvent = NewEventModel.defaultNewModel(startTime: startTime, endTime: endTime)
        createNewEvent(newEventModel: calendarEvent, fromAddButton: false, completionHandle: { [weak self] in
            self?.eventViewController?.reloadData(with: startTime)
        })
    }
}

// MARK: 视图页
extension CalendarViewController: EventViewControllerDelegate {

    func eventViewController(_ eventViewController: EventViewController,
                             pagingProgress: CGFloat,
                             isJump: Bool,
                             shouldGradual: Bool) {
        if isJump {
            tabBarView?.jumpToProgress(pagingProgress)
            return
        }
        tabBarView?.animation(with: pagingProgress,
                                  shouldGradual: shouldGradual,
                                  direction: eventViewController.tabBarDirection)
    }

    private func createDaySceneViewController(date: Date, daysPerScene: Int) -> EventViewController {
        let daySceneVC = DaySceneViewController(
            userResolver: self.userResolver,
            settingProvier: dependency.settingProvier,
            timeZoneService: dependency.timeZoneService,
            instanceService: dependency.instanceService,
            rxIs12HourStyle: dependency.is12HourStyle,
            calendarApi: dependency.calendarApi,
            timeDataService: dependency.timeDataService,
            daysPerScene: daysPerScene,
            fromSceneMode: lastSceneMode,
            launchLoggerModel: loggerModel
        )
        daySceneVC.newDelegate = self
        daySceneVC.updateDate(date)
        return daySceneVC
    }

    private func createEventListViewController(date: Date, width: CGFloat) -> EventViewController {
        guard let controller = self.delegate?.getEventListController(date: date, containerWidthChange: containerWidthChangeDriver, width: width, fromSceneMode: self.lastSceneMode) else {
            return MockEventViewController()
        }
        return controller
    }

    private func createMonthViewController(date: Date) -> EventViewController {
        guard let controller = self.delegate?.getMonthViewController(date: date) else {
            return MockEventViewController()
        }
        return controller
    }

    // setup old day scene vc
    private func replaceEventViewController(controller: EventViewController, wrapper: UIView) {
        // remove old
        if let oldVC = eventViewController {
            oldVC.willMove(toParent: nil)
            oldVC.view.removeFromSuperview()
            oldVC.removeFromParent()
            eventViewController = nil
        }

        // add new
        addChild(controller)
        controller.delegate = self
        wrapper.insertSubview(controller.view, at: 0)
        controller.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        controller.didMove(toParent: self)
        eventViewController = controller
    }

    func onFastNewEvent(_ eventViewController: EventViewController, startTime: Date, endTime: Date) {
        CalendarTracer.shareInstance.calFullEditEvent(actionSource: .fastEventEditor,
                                                      editType: .new,
                                                      mtgroomCount: 0,
                                                      thirdPartyAttendeeCount: 0,
                                                      groupCount: 0,
                                                      userCount: 0,
                                                      timeConfilct: .unknown)
        self.onClickNewEventButtonView(startTime: startTime, endTime: endTime)
    }

    func eventCreateActionTaped(_ eventViewController: EventViewController) {
        self.addButtonClicked(self.addButton)
    }

    func dateDidChanged(_ eventViewController: EventViewController, date: Date) {
        self.changeHeaderViewMonth(date: date)
        self.viewDidRefreshed?()
    }

    func displayRangeDidChanged(_ eventViewController: EventViewController, startDate: Date, endDate: Date) {
        calendarManager?.setEventViewRange(start: startDate, end: endDate)
    }

    func eventViewController(_ eventViewController: EventViewController,
                             didSelected model: BlockDataProtocol) {
        self.showDetail(model: model)
    }
}

// MARK: DaySceneViewControllerDelegate

extension CalendarViewController: DaySceneViewControllerDelegate {

    func createEvent(withStartDate startDate: Date, endDate: Date) {
        let editCoordinator = dependency.getCreateEventCoordinator { contextPointer in
            contextPointer.pointee.startDate = startDate
            contextPointer.pointee.endDate = endDate
        }
        editCoordinator.delegate = self
        editCoordinator.actionSource = .timeBlock
        editCoordinator.start(from: self)
    }

    func showDetail(for data: BlockDataProtocol, sender: DaySceneViewController) {
        showDetail(model: data)
    }
}

extension CalendarViewController: CalendarHomeViewHeaderViewDelegate {
    func calendarHomeViewHeaderView(_ view: CalendarHomeViewHeaderView,
                                    didTapSetting: UIButton) {
        guard let vc = self.delegate?.getSettingsNavController() else { return }
        self.present(vc, animated: true, completion: nil)
    }

    func calendarHomeViewHeaderView(
        _ view: CalendarHomeViewHeaderView,
        didTapFilter: UIButton) {
        // do nothing
    }

    func changeHeaderViewMonth(date: Date) {
        debounce
            .call { [weak self] in
                self?.titleView.changeMonthButton(date: date)
                self?.naviHeaderTitle.accept(CalendarHomeViewHeaderView.getMonthTitle(date: date))
            }
    }
}

// MARK: Switch Scene

extension CalendarViewController {

    private func desiredSceneMode() -> HomeSceneMode {
        guard let sceneModeContext = sceneModeContext else {
            return HomeSceneMode.current
        }
        return HomeSceneMode.fixedMode(
            from: HomeSceneMode.current,
            withSizeClass: sceneModeContext.sizeClass,
            displayWidth: sceneModeContext.displayWidth
        )
    }

    private func switchSceneModeIfNeeded(with animationDuration: TimeInterval) {
        guard Display.pad,
            let daySceneChildBeforeSwitching = eventViewController as? DaySceneViewController else {
            return
        }
        let targetSceneMode = desiredSceneMode()
        guard targetSceneMode != HomeSceneMode.current else {
            return
        }
        switchSceneMode(targetSceneMode)
        guard daySceneChildBeforeSwitching.view.superview == nil,
            daySceneChildBeforeSwitching.parent == nil,
            case .day(let dayCate) = HomeSceneMode.current else {
            print("cannot generate snapshot")
            return
        }

        let daySceneSnapshot = DaySceneViewController.makeSnapshot(from: daySceneChildBeforeSwitching,
                                                                   with: dayCate)
        addChild(daySceneSnapshot)
        daySceneSnapshot.view.frame = calendarWrapperView.frame
        view.insertSubview(daySceneSnapshot.view, aboveSubview: calendarWrapperView)
        daySceneSnapshot.view.snp.makeConstraints {
            $0.edges.equalTo(calendarWrapperView)
        }
        daySceneSnapshot.didMove(toParent: self)
        view.layoutIfNeeded()

        var didRemoveSnapshot = false
        let doRemoveSnapshotIfNeeded = {
            guard !didRemoveSnapshot else { return }
            defer { didRemoveSnapshot = true }

            daySceneSnapshot.willMove(toParent: nil)
            daySceneSnapshot.view.removeFromSuperview()
            daySceneSnapshot.removeFromParent()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.01) {
            doRemoveSnapshotIfNeeded()
        }
    }

    // 切换 scene mode
    private func switchSceneMode(_ newMode: HomeSceneMode, withDate date: Date? = nil, toTargetTime: Bool = false) {
        guard newMode != HomeSceneMode.current || date != currentPageDate() || toTargetTime else { return }

        ReciableTracer.shared.recStartSwitch()
        defer { ReciableTracer.shared.recEndSwitch() }

        HomeSceneMode.current = newMode
        EffLogger.log(model: loggerModel, toast: "switchSceneMode, newMode = \(newMode)")
        setupController(
            with: newMode,
            date: date ?? currentPageDate(),
            wrapper: calendarWrapperView,
            width: view.frame.size.width,
            contentOffset: eventViewController?.dayViewContentOffset(),
            toTargetTime: toTargetTime
        )
    }

    private func switchCalendarMeetingRoom(entry: CalendarMeetingRoomSwitchView.Entry) {
        switch entry {
        case .calendar:
            // 首次点击是日程视图，忽略会议室视图冷启动埋点
            meetingRoomHomeTracer?.cancel()

            calendarWrapperView.isHidden = false
            meetingRoomWrapperView.isHidden = true
            if meetingRoomHomeVCCreated {
                // remove meetingroom
                meetingRoomHomeViewController.willMove(toParent: nil)
                meetingRoomHomeViewController.view.removeFromSuperview()
                meetingRoomHomeViewController.removeFromParent()
            }
            initEventViewController()
            // add calendar
            if let eventViewController = eventViewController, let tabBarView = self.tabBarView {
                addChild(eventViewController)
                calendarWrapperView.insertSubview(eventViewController.view, at: 0)
                eventViewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
                eventViewController.didMove(toParent: self)

                // 切到会议室tab时 顶部月份跟着选择变动 底tab根据页面状态显示动画
                self.shouldChangeDateImage()
                let progress = CGFloat(daysBetween(date1: Date.today(), date2: eventViewController.currentPageDate()))
                tabBarView.animation(with: progress,
                                     shouldGradual: true,
                                     direction: eventViewController.tabBarDirection)
                changeHeaderViewMonth(date: eventViewController.currentPageDate())
            }
        case .meetingRoom:
            // 更新tab图标
            self.shouldChangeDateImage()
            // 首次点击是会议室视图，忽略日程视图页冷启动埋点
            HomeScene.clearColdLaunchTracker()
            CalendarMonitorUtil.cancelTrackHomePageLoad()

            calendarWrapperView.isHidden = true
            meetingRoomWrapperView.isHidden = false
            // remove calendar
            eventViewController?.willMove(toParent: nil)
            eventViewController?.view.removeFromSuperview()
            eventViewController?.removeFromParent()
            // add meetingroom
            addChild(meetingRoomHomeViewController)
            meetingRoomWrapperView.addSubview(self.meetingRoomHomeViewController.view)
            meetingRoomHomeViewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
            meetingRoomHomeViewController.didMove(toParent: self)

            // 切到会议室tab时 顶部月份跟着选择变动 底tab始终显示当前日期不动
            guard let homeVC = meetingRoomHomeViewController.childVC as? MeetingRoomHomeViewController else { return }
            homeVC.selectedDateDidChange = { [weak self] date in
                self?.changeHeaderViewMonth(date: date)

                let progress = CGFloat(daysBetween(date1: Date.today(), date2: date))
                self?.tabBarView?.animation(with: progress,
                                            shouldGradual: true,
                                            direction: .horizontal)
            }
        }
    }
    
    private func shouldChangeDateImage() {
        self.tabBarView?.shouldChangeDateImage(uiCurrentDate: self.getCurrentTimeUiDate())
    }
}

// MARK: TimeZone

extension CalendarViewController {

    func initTimeZone() {
        guard !Display.pad else { return }
        self.dependency.timeZoneService.preferredTimeZone.asDriver().drive(onNext: { [weak self] (_) in
            self?.shouldChangeDateImage()
        }).disposed(by: disposeBag)
    }

    func getCurrentTimeZoneId() -> String {
        if Display.pad {
            return TimeZone.current.identifier
        }
        switch HomeSceneMode.current {
        case .day:
            return self.dependency.timeZoneService.preferredTimeZone.value.identifier
        default:
            return TimeZone.current.identifier
        }
    }

    func getCurrentTimeUiDate() -> Date {
        return CalendarViewController.getUIDate(timeStamp: Date(), mode: HomeSceneMode.current, timeZoneId: getCurrentTimeZoneId())
    }

    static func getUIDate(timeStamp: Date, mode: HomeSceneMode, timeZoneId: String) -> Date {
        if Display.pad {
            return timeStamp
        }
        switch mode {
        case .day:
            return TimeZoneUtil.dateTransForm(srcDate: timeStamp, srcTzId: timeZoneId, destTzId: TimeZone.current.identifier)
        default:
            return timeStamp
        }
    }
}

extension CalendarViewController: EventEditCoordinatorDelegate {
    func coordinator(_ coordinator: EventEditCoordinator, didSaveEvent pbEvent: Rust.Event, span: Span, extraData: EventEditExtraData?) {
        dependency.createEventSucceedHandler(pbEvent, self)
    }
}

// MARK: - Slide View
extension CalendarViewController {
    func showCalendarSlideView(sender: UIView, highlightCalendarID: String? = nil, source: String? = nil) {
        let vc = CalendarSlideViewController(with: dependency, userResolver: self.userResolver)
        vc.highlightCalendarID = highlightCalendarID
        vc.source = source
        vc.modalPresentationStyle = Display.pad ? .popover : .overFullScreen
        vc.popoverPresentationController?.sourceView = sender
        vc.popoverPresentationController?.permittedArrowDirections = .up
        vc.sceneModeDidChange = { [weak self] mode in
            self?.switchSceneMode(mode)
        }
        vc.dismissCompleted = { [weak self] in
            self?.startShowOnboarding()
        }
        vc.setDefaultMode(mode: HomeSceneMode.current)
        vc.popoverPresentationController?.delegate = self
        present(vc, animated: false)
    }
}

// MARK: Guide

extension CalendarViewController: GuideSingleBubbleDelegate {
    typealias GuideBlock = () -> Void
    
    /// 通知展示下一个onboarding
    private func showNextOnboarding() {
        if self.guideBlocks.isEmpty {
            self.stopShowOnboarding()
        } else {
            self.rxGuideBlock.accept(())
        }
    }
    
    /// 终止展示onboarding
    private func stopShowOnboarding() {
        self.guideDisposeBag = DisposeBag()
    }
    
    /// 开始展示onboarding
    private func startShowOnboarding() {
        // 按顺序展示用户引导
        if !self.guideBlocks.isEmpty {
            self.guideDisposeBag = DisposeBag()
            self.rxGuideBlock
                .subscribeForUI(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    if !self.guideBlocks.isEmpty {
                        let guideBlock = self.guideBlocks.removeFirst()
                        guideBlock()
                    }
                })
                .disposed(by: self.guideDisposeBag)
        }
    }
    
    // 新注册用户引导
    private func showOnboardingGuideIfNeed() {
        let newRegisterGuideEnbale: Bool = self.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: FeatureGatingKey.onboardingFlowOpt.rawValue))
        let guideKey = "all_calendar_create_button"
        guard newRegisterGuideEnbale,
              let newGuideManager = self.newGuideManager,
              newGuideManager.checkShouldShowGuide(key: guideKey) else {
            self.showNextOnboarding()
            return
        }

        // 创建单个气泡的配置
        let bubbleConfig = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetView(self.addButton)),
            textConfig: TextInfoConfig(title: BundleI18n.Calendar.Lark_Guide_SpotlightCalenarTabCreateTitle,
                                       detail: BundleI18n.Calendar.Lark_Guide_SpotlightCalenarTabCreateDesc)
        )
        let singleBubbleConfig = SingleBubbleConfig(delegate: self, bubbleConfig: bubbleConfig)
        newGuideManager.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                 bubbleType: .single(singleBubbleConfig),
                                                 dismissHandler: showNextOnboarding)
    }

    public func didClickLeftButton(bubbleView: GuideBubbleView) {
        // close guide
        self.newGuideManager?.closeCurrentGuideUIIfNeeded()
    }

    public func didClickRightButton(bubbleView: GuideBubbleView) {
        // close guide
        self.newGuideManager?.closeCurrentGuideUIIfNeeded()
        // 去添加日历页
        self.gotoImportCalendarController()
    }

    // 会议室引导
    private func showMeetingRoomGuideIfNeeded(targetView: UIView) {

        // 创建单个气泡的配置
        let guideKey = "all_calendar_tab_findrooms"
        guard let newGuideManager = self.newGuideManager,
              newGuideManager.checkShouldShowGuide(key: guideKey) else { return }
        let bubbleConfig = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetView(targetView), arrowDirection: .up),
            textConfig: TextInfoConfig(detail: BundleI18n.Calendar.Calendar_MeetingRoom_FindRoomOnboardingOne)
        )
        let singleBubbleConfig = SingleBubbleConfig(delegate: self, bubbleConfig: bubbleConfig)
        newGuideManager.showBubbleGuideIfNeeded(guideKey: guideKey, bubbleType: .single(singleBubbleConfig), dismissHandler: nil)
    }

    private func gotoImportCalendarController() {
        let naviController = self.dependency.getImportCalendarViewController(nil)
        self.navigationController?.present(naviController, animated: true, completion: nil)
        CalendarTracer.shareInstance.calAddAccount(actionSource: .defaultView)
    }

    // 「点点点」版本日历分享
    private func showNewCalendarSettingGuideIfNeeded() {
        let guidKey = GuideService.GuideKey.calendarSettingGuideKey
        guard FG.optimizeCalendar,
              let newGuideManager = self.newGuideManager,
              GuideService.isGuideNeedShow(newGuideManager: newGuideManager, key: guidKey),
              !switcher.slideViewButton.isHidden else {
            logger.info("FG value: \(FG.optimizeCalendar.description), guideValue: \(false.description)")
            self.showNextOnboarding()
            return
        }
        logger.info("CalendarSettingGuide should show")
        let targetAnchor = TargetAnchor(
            targetSourceType: .targetView(switcher.slideViewButton),
            arrowDirection: .up
        )
        calendarSettingGuideImp.rightBtnClicked = { [weak self] in
            guard let self = self, let newGuideManager = self.newGuideManager else { return }
            newGuideManager.closeCurrentGuideUIIfNeeded()
            self.showCalendarSlideView(sender: self.switcher.slideViewButton, source: guidKey.rawValue)
            GuideService.setGuideShown(newGuideManager: newGuideManager, key: guidKey)
            self.stopShowOnboarding()
        }

        calendarSettingGuideImp.leftBtnClicked = { [weak self] in
            guard let self = self, let newGuideManager = self.newGuideManager else { return }
            newGuideManager.closeCurrentGuideUIIfNeeded()
            GuideService.setGuideShown(newGuideManager: newGuideManager, key: guidKey)
            self.showNextOnboarding()
        }
        let bubbleConfig = BubbleItemConfig(
            guideAnchor: targetAnchor,
            textConfig: .init(detail: I18n.Calendar_Detail_SharingOnboarding),
            bottomConfig: .init(leftBtnInfo: .init(title: I18n.Calendar_Common_GotIt), rightBtnInfo: .init(title: I18n.Calendar_Common_TryItNow_Onboard))
        )
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: .clear, maskInteractionForceOpen: false)
        let singleBubbleConfig = SingleBubbleConfig(delegate: calendarSettingGuideImp, bubbleConfig: bubbleConfig, maskConfig: maskConfig)
        newGuideManager.showBubbleGuideIfNeeded(
            guideKey: guidKey.rawValue,
            bubbleType: .single(singleBubbleConfig),
            dismissHandler: showNextOnboarding
        )
    }
    
    // 任务进日历 onboarding
    private func showTaskInCalendarGuideIfNeeded() {
        let guideKey = GuideService.GuideKey.taskInCalendarOnboardingInHomeView
        guard FeatureGating.taskInCalendar(userID: self.userResolver.userID),
              let newGuideManager = newGuideManager,
              GuideService.isGuideNeedShow(newGuideManager: newGuideManager, key: guideKey),
              !switcher.slideViewButton.isHidden else {
            self.showNextOnboarding()
            return
        }
        calendarSettingGuideImp.rightBtnClicked = { [weak self] in
            guard let self = self, let newGuideManager = self.newGuideManager else { return }
            newGuideManager.closeCurrentGuideUIIfNeeded()
            self.showCalendarSlideView(sender: self.switcher.slideViewButton, source: guideKey.rawValue)
            GuideService.setGuideShown(newGuideManager: newGuideManager, key: guideKey)
            self.stopShowOnboarding()
        }

        calendarSettingGuideImp.leftBtnClicked = { [weak self] in
            guard let self = self, let newGuideManager = self.newGuideManager else { return }
            newGuideManager.closeCurrentGuideUIIfNeeded()
            GuideService.setGuideShown(newGuideManager: newGuideManager, key: guideKey)
            self.showNextOnboarding()
        }
        
        GuideService.showGuideForTimeContainerInHomeView(
            newGuideManager: newGuideManager,
            delegate: calendarSettingGuideImp,
            refreView: switcher.slideViewButton,
            completion: nil
        )
    }

    private class CalendarSettingGuideImp: GuideSingleBubbleDelegate {
        var leftBtnClicked: (() -> Void)?
        var rightBtnClicked: (() -> Void)?
        func didClickRightButton(bubbleView: GuideBubbleView) { rightBtnClicked?() }
        func didClickLeftButton(bubbleView: GuideBubbleView) { leftBtnClicked?() }
    }
}

// MARK: - Feed Good

extension CalendarViewController {
    private func registerMagicIfNeeded() {
        weak var navigationController = self.navigationController
        magicRegister = CalendarMagicRegister(userResolver: self.userResolver, containerProvider: {
            return navigationController
        })
    }
}

extension CalendarViewController {

    // 检查用户绑定的第三方日历授权是否需要更新为 OAuth，需要的话则弹窗提醒现在绑定的即将过期，需要更新
    // 弹窗只弹一次，提醒用户 exchange 授权即将过期，需要重新 oauth 授权
    private func tryCheckOAuthStatus() {
        logger.info("tryCheckOAuthStatus, has shown: \(KVValues.hasShownOAuthDialog)")
        if !KVValues.hasShownOAuthDialog {
            DispatchQueue.global().async {
                task()
            }
        }
        func task() {
            self.dependency.calendarApi.getShouldSwitchToOAuthExchangeAccounts()
                .asSingle()
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: {[weak self] (emailToAuthUrl) in
                    guard let `self` = self else { return }
                    self.logger.info("getShouldSwitchToOAuthExchangeAccounts, authurl is empty: \(emailToAuthUrl.isEmpty)")
                    if !emailToAuthUrl.isEmpty {
                        self.showShouldOAuthDialog()
                    }
                }, onError: {[weak self] error in
                    self?.logger.debug("getShouldSwitchToOAuthExchangeAccounts failed: \(error)")
                }).disposed(by: self.disposeBag)
        }
    }

    private func showShouldOAuthDialog() {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.Calendar.Calendar_Ex_AccountExpiring)
        dialog.setContent(text: BundleI18n.Calendar.Calendar_Ex_NoMoreSyncSoon)
        dialog.addCancelButton(dismissCompletion: {
            CalendarTracerV2.ExchangeAccountIsExpiring.traceClick {
                $0.click("cancel").target("none")
            }
        })
        dialog.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Ex_UpdateAuthorization, dismissCompletion: {[weak self] in
            guard let `self` = self else { return }
            self.gotoAccountManage()
            CalendarTracerV2.ExchangeAccountIsExpiring.traceClick {
                $0.click("redelegation").target("none")
            }
        })
        let completion: (() -> Void) = { [weak self] in
            guard let `self` = self else { return }
            self.logger.info("dialog shown")
            KVValues.hasShownOAuthDialog = true
            CalendarTracerV2.ExchangeAccountIsExpiring.traceView()
        }

        let isInCurrentView = isCurrentVCActive && !calendarWrapperView.isHidden
        logger.info("isInCurrentView: \(isInCurrentView)")
        if isInCurrentView && !KVValues.hasShownOAuthDialog {
            if let presentedVC = self.presentedViewController, presentedVC is CalendarSlideViewController {
                logger.info("present dialog use slideview")
                presentedVC.present(dialog, animated: true, completion: completion)
            } else {
                logger.info("present dialog by self")
                self.present(dialog, animated: true, completion: completion)
            }
        }
    }

    private func gotoAccountManage() {
        let viewController = self.dependency.getAccountManageViewController(.present)
        if Display.pad {
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            nav.update(style: .default)
            self.present(nav, animated: true, completion: nil)
        } else {
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

extension CalendarViewController {
    
    private func refreshLocalEvent() {
        self.localRefreshService?.reloadIfReadLocalBlocked()
    }
}
