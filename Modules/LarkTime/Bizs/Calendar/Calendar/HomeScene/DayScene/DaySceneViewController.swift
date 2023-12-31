//
//  DaySceneViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/7/28.
//

import UIKit
import RxSwift
import RxCocoa
import RoundedHUD
import LKCommonsLogging
import EventKit
import CTFoundation
import LarkContainer

/// DayScene （日/三日/周视图）

protocol DaySceneViewControllerDelegate: AnyObject {
    func createEvent(withStartDate startDate: Date, endDate: Date)
    func showDetail(for instance: BlockDataProtocol, sender: DaySceneViewController)
}

final class DaySceneViewController: UIViewController, InstanceCacheStrategyProvider, UserResolverWrapper {
    // NOTE: by zhangwei
    // 兼容老接口，后续需要删掉
    weak var delegate: EventViewControllerDelegate?
    weak var newDelegate: DaySceneViewControllerDelegate?
    let daysPerScene: Int

    // 页面划分为三个模块
    private lazy var modules = (
        header: initHeaderModule(),
        allday: initAllDayModule(),
        nonAllDay: initNonAllDayModule()
    )

    var rxInstanceCacheStrategy: BehaviorRelay<InstanceCacheStrategy>?

    private let fromSceneMode: HomeSceneMode?

    private let settingProvier: SettingProvider
    private let timeZoneService: TimeZoneService
    private let instanceService: InstanceService
    let rxIs12HourStyle: BehaviorRelay<Bool>
    private let disposeBag = DisposeBag()
    private let calendarApi: CalendarRustAPI
    private let timeDataService: TimeDataService

    lazy var dayStore: DaySceneStore = initDayStore()
    private lazy var rxViewSetting: BehaviorRelay<DayScene.ViewSetting> = initRxViewSetting(with: settingProvier)
    private lazy var instanceSourceImpl: DayInstanceSourceImpl = DayInstanceSourceImpl(
        instanceService: instanceService,
        calendarApi: calendarApi, 
        timeDataService: timeDataService,
        daysPerScene: daysPerScene,
        rxFirstWeekday: initRxFirstWeekday(with: rxViewSetting),
        coldLaunchContext: dayStore.state.coldLaunchContext)
    let userResolver: UserResolver
    let launchLoggerModel: CaVCLoggerModel

    init(
        userResolver: UserResolver,
        settingProvier: SettingProvider,
        timeZoneService: TimeZoneService,
        instanceService: InstanceService,
        rxIs12HourStyle: BehaviorRelay<Bool>,
        calendarApi: CalendarRustAPI,
        timeDataService: TimeDataService,
        daysPerScene: Int,
        fromSceneMode: HomeSceneMode?,
        launchLoggerModel: CaVCLoggerModel
    ) {
        self.userResolver = userResolver
        self.calendarApi = calendarApi
        self.settingProvier = settingProvier
        self.timeZoneService = timeZoneService
        self.timeDataService = timeDataService
        self.instanceService = instanceService
        self.rxIs12HourStyle = rxIs12HourStyle
        self.daysPerScene = daysPerScene
        self.fromSceneMode = fromSceneMode
        self.launchLoggerModel = launchLoggerModel

        let timeZone = TimeZone(identifier: timeZoneService.preferredTimeZone.value.identifier) ?? .current
        let currentDay = JulianDayUtil.julianDay(from: Date(), in: timeZone)
        let currentDayRange = currentDay..<currentDay + daysPerScene
        let instanceCacheStrategy = InstanceCacheStrategy(
            timeZone: timeZone,
            diskCacheRange: currentDayRange,
            memoryCacheDays: .init(currentDayRange)
        )
        self.rxInstanceCacheStrategy = BehaviorRelay(value: instanceCacheStrategy)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        EffLogger.log(model: launchLoggerModel, toast: "tap calendar")
        view.backgroundColor = UIColor.ud.bgBody

        addChild(modules.nonAllDay)
        view.addSubview(modules.nonAllDay.view)
        modules.nonAllDay.didMove(toParent: self)

        addChild(modules.allday)
        view.addSubview(modules.allday.view)
        modules.allday.didMove(toParent: self)

        addChild(modules.header)
        view.addSubview(modules.header.view)
        modules.header.didMove(toParent: self)

        observeAction()
        adjustHeaderModuleHeight()

        // 主线程初始化图片，供DayAllDayViewModel/DayNonAllDayViewModel子线程组装数据使用
        DispatchQueue.main.async {
            _ = DayScene.localIcon
            _ = DayScene.googleIcon
            _ = DayScene.exchangeIcon
        }
    }

    func updateDate(_ date: Date, toTargetTime: Bool = false) {
        let curJulianDay = JulianDayUtil.julianDay(from: date, in: dayStore.state.timeZoneModel.timeZone)
        if toTargetTime {
            dayStore.dispatch(.scrollToDate(date))
        } else {
            dayStore.dispatch(.scrollToDay(curJulianDay))
        }
        DispatchQueue.global().async {
            self.dayStore.setValue(curJulianDay, forKeyPath: \.activeDay)
        }
    }

    private var isViewAppeared = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isViewAppeared else { return }
        defer { isViewAppeared = true }

        syncModulePageOffset()
        observeJulianDays()
        setupCacheStrategy()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layoutModules()
    }

    // MARK: Cache Strategy

    @inline(__always)
    private static func makeCacheStrategy(
        with state: DaySceneState,
        firstWeekDay: EKWeekday,
        daysPerScene: Int
    ) -> InstanceCacheStrategy {
        var currentDayRange = state.currentDay..<state.currentDay + daysPerScene
        currentDayRange = DayScene.julianDayRange(inWeeksAs: currentDayRange, with: firstWeekDay)
        var activeDayRange = state.activeDay..<state.activeDay + daysPerScene
        activeDayRange = DayScene.julianDayRange(inWeeksAs: activeDayRange, with: firstWeekDay)
        activeDayRange = (activeDayRange.lowerBound - 7)..<(activeDayRange.upperBound + 7)
        return InstanceCacheStrategy(
            timeZone: state.timeZoneModel.timeZone,
            diskCacheRange: currentDayRange,
            memoryCacheDays: Set(currentDayRange).union(Set(activeDayRange))
        )
    }

    private func setupCacheStrategy() {
        let daysPerScene = self.daysPerScene
        Observable.combineLatest(dayStore.rxState(), rxViewSetting)
            .map { tuple -> InstanceCacheStrategy in
                let (state, viewSetting) = tuple
                let firstWeekday = EKWeekday(rawValue: viewSetting.firstWeekday.rawValue) ?? EKWeekday.sunday
                return Self.makeCacheStrategy(with: state, firstWeekDay: firstWeekday, daysPerScene: daysPerScene)
            }
            .distinctUntilChanged { (prev: InstanceCacheStrategy, next: InstanceCacheStrategy) -> Bool in
                return prev.timeZone.identifier == next.timeZone.identifier
                    && prev.diskCacheRange == next.diskCacheRange
                    && prev.memoryCacheDays == next.memoryCacheDays
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in
                self?.rxInstanceCacheStrategy?.accept($0)
            })
            .disposed(by: disposeBag)
    }

    // MARK: Sync Scrolling for Children

    // 同步 header、allDay、nonAllDay 三个模块的 pageOffset
    // `isSyncPageOffset` 用于避免回声：A.pageOffset.changed -> B.pageOffset.changed -> A.pageOffset.changed
    private var isSyncPageOffset = false
    private func syncModulePageOffset() {
        isSyncPageOffset = false
        children.compactMap({ $0 as? DayScenePagableChild }).forEach { vc in
            vc.onPageOffsetChange = { [weak self] (pageOffset, sourceChild) in
                guard let self = self, !self.isSyncPageOffset else { return }

                self.isSyncPageOffset = true
                defer { self.isSyncPageOffset = false }

                self.children
                    .filter { (sourceChild as UIViewController) != $0 }
                    .compactMap { $0 as? DayScenePagableChild }
                    .forEach { $0.scroll(to: pageOffset, animated: false) }
                let julianDay = DayScene.julianDay(from: PageIndex(round(pageOffset)))
                self.dayStore.setValue(julianDay, forKeyPath: \.activeDay)

                self.reportPagingProgress(pageOffset)
            }
        }
    }

}

// MARK: - Lazy Init

extension DaySceneViewController {

    private func initDayStore() -> DaySceneStore {
        let timeZone: TimeZone
        let curJulianDay: JulianDay
        var coldLaunchContext: HomeScene.ColdLaunchContext?
        if self.fromSceneMode == nil, let context = HomeScene.coldLaunchContext {
            coldLaunchContext = context
            curJulianDay = context.dayRange.lowerBound
            assert(context.dayRange.count == daysPerScene)
            timeZone = context.timeZone
        } else {
            timeZone = TimeZone(identifier: timeZoneService.preferredTimeZone.value.identifier) ?? .current
            curJulianDay = JulianDayUtil.julianDay(from: Date(), in: timeZone)
        }
        let initialState = DaySceneState(
            daysPerScene: daysPerScene,
            coldLaunchContext: coldLaunchContext,
            currentDay: curJulianDay,
            activeDay: curJulianDay
        )
        let store = DaySceneStore(name: "DayScene", state: initialState)

        if FeatureGating.additionalTimeZoneOption(userID: userResolver.userID) {
            Observable.combineLatest(timeZoneService.additionalTimeZone,
                                     timeZoneService.showAdditionalTimeZone,
                                     timeZoneService.preferredTimeZone)
                .observeOn(MainScheduler.instance)
                .map { additionaltTimeZoneModel, isShow, current -> TimeZone? in
                    guard isShow,
                          let additionaltTimeZoneModel = additionaltTimeZoneModel,
                          additionaltTimeZoneModel.identifier != current.identifier,
                          let timeZone = TimeZone(identifier: additionaltTimeZoneModel.identifier) else { return nil }
                    return timeZone
                }.filter { [weak self] timeZone in
                    return timeZone != self?.dayStore.state.additionalTimeZone?.timeZone
                }.bind { [weak self] timeZone in
                    AdditionalTimeZone.logger.info("update DaySceneAdditionalTimeZone: \(timeZone?.identifier ?? "")")
                    if let timeZone = timeZone {
                        self?.dayStore.setValue(DaySceneTimeZoneModel(timeZone: timeZone), forKeyPath: \.additionalTimeZone)
                    } else {
                        self?.dayStore.setValue(nil, forKeyPath: \.additionalTimeZone)
                    }
                }.disposed(by: disposeBag)

            // 若用户当前未选择辅助时区，则帮用户选择第一个
            rxViewSetting
                .map { $0.additionalTimeZones }
                .distinctUntilChanged({ rhs, lhs -> Bool in
                    rhs == lhs
                })
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] additionalTimeZones in
                    guard let self = self else { return }
                    guard let additionalTimeZone = self.timeZoneService.additionalTimeZone.value,
                          additionalTimeZones.contains(additionalTimeZone.identifier) else {
                        if additionalTimeZones.isEmpty {
                            self.timeZoneService.setAdditionalTimeZone("")
                            AdditionalTimeZone.logger.info("reselect DaySceneAdditionalTimeZone: \("")")
                        } else {
                            self.timeZoneService.setAdditionalTimeZone(additionalTimeZones[0])
                            AdditionalTimeZone.logger.info("reselect DaySceneAdditionalTimeZone: \(additionalTimeZones[0])")
                        }
                        return
                    }
                }).disposed(by: disposeBag)
        }

        timeZoneService.preferredTimeZone
            .observeOn(MainScheduler.asyncInstance)
            .filter { [weak self] new -> Bool in
                guard let self = self else { return false }
                let old = self.dayStore.state.timeZoneModel.timeZone
                return old.identifier != new.identifier
            }
            .bind { [weak self] timeZoneModel in
                guard let self else { return }
                let timeZone = TimeZone(identifier: timeZoneModel.identifier) ?? .current
                self.dayStore.setValue(DaySceneTimeZoneModel(timeZone: timeZone, extraWidth: DayScene.UIStyle.Layout.timeZoneRightWidth),
                                       forKeyPath: \.timeZoneModel)
            }.disposed(by: disposeBag)
        return store
    }

    private func initRxViewSetting(with settingProvider: SettingProvider) -> BehaviorRelay<DayScene.ViewSetting> {
        let viewSetting = settingProvider.getSetting()
        let rx = BehaviorRelay<DayScene.ViewSetting>(value: viewSetting)
        settingProvider.updateViewSettingPublish
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak rx, weak settingProvider] in
                guard let rx = rx, let settingProvider = settingProvider else { return }
                let newViewSetting = settingProvider.getSetting()
                rx.accept(newViewSetting)
            })
            .disposed(by: disposeBag)
        return rx
    }

    private func initRxFirstWeekday(with rxViewSetting: BehaviorRelay<DayScene.ViewSetting>) -> BehaviorRelay<EKWeekday> {
        let transform = { (viewSetting: DayScene.ViewSetting) -> EKWeekday in
            return EKWeekday(rawValue: viewSetting.firstWeekday.rawValue) ?? EKWeekday.sunday
        }
        let rx = BehaviorRelay<EKWeekday>(value: transform(rxViewSetting.value))
        rxViewSetting.map(transform).subscribe(onNext: { [weak rx] in
            rx?.accept($0)
        }).disposed(by: disposeBag)
        return rx
    }

    // MARK: Modules

    private func initHeaderModule() -> DayHeaderViewController {
        let viewModel = DayHeaderViewModel(dayStore: dayStore, rxViewSetting: rxViewSetting, userResolver: userResolver)
        return DayHeaderViewController(viewModel: viewModel, rxIs12HourStyle: rxIs12HourStyle)
    }

    private func initAllDayModule() -> DayAllDayViewController {
        let viewModel = DayAllDayViewModel(
            userResolver: self.userResolver,
            dayStore: dayStore,
            instanceSource: instanceSourceImpl,
            rxViewSetting: rxViewSetting
        )
        return DayAllDayViewController(viewModel: viewModel, rxIs12HourStyle: rxIs12HourStyle)
    }

    private func initNonAllDayModule() -> DayNonAllDayViewController {
        let viewModel = DayNonAllDayViewModel(
            userResolver: self.userResolver,
            dayStore: dayStore,
            instanceSource: instanceSourceImpl,
            rxTimeBlocksChange: timeDataService.rxTimeBlocksChange,
            rxIs12HourStyle: rxIs12HourStyle,
            rxViewSetting: rxViewSetting
        )
        return DayNonAllDayViewController(
            viewModel: viewModel,
            calendarApi: calendarApi,
            settingService: settingProvier,
            launchLoggerModel: self.launchLoggerModel
        )
    }

}

// MARK: - JulianDays

extension DaySceneViewController {

    private func makeDate(for julianDay: JulianDay) -> Date {
        let (year, month, day) = JulianDayUtil.yearMonthDay(from: julianDay)
        var dateComps = DateComponents()
        dateComps.day = day
        dateComps.month = month
        dateComps.year = year
        dateComps.timeZone = dayStore.state.timeZoneModel.timeZone
        dateComps.hour = 12
        guard let date = Calendar.gregorianCalendar.date(from: dateComps) else {
            assertionFailure()
            return Date()
        }
        return date
    }

    // 监听 dayStore.currentDay 和 dayStore.activeDay
    private func observeJulianDays() {
        dayStore.rxValue(forKeyPath: \.activeDay)
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] julianDay in
                guard let self = self, self.parent != nil else { return }
                let date = self.makeDate(for: julianDay)
                self.delegate?.dateDidChanged(self, date: date)

                let activeJulianDay = self.modules.header.viewModel.activeJulianDay()
                let currentJulianRange: PageRange = activeJulianDay..<activeJulianDay + self.daysPerScene
                let startDate = getDate(julianDay: Int32(currentJulianRange.lowerBound))
                let endDate = getDate(julianDay: Int32(currentJulianRange.upperBound))
                self.delegate?.displayRangeDidChanged(self, startDate: startDate, endDate: endDate)
            })
            .disposed(by: disposeBag)

        dayStore.rxValue(forKeyPath: \.currentDay)
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let progress = CGFloat(self.dayStore.state.activeDay - self.dayStore.state.currentDay)
                self.delegate?.eventViewController(self, pagingProgress: progress, isJump: false)
            })
            .disposed(by: disposeBag)
    }

    private func reportPagingProgress(_ pageOffset: CGFloat) {
        // 整数部分
        let i = PageIndex(pageOffset)
        // 小数部分
        let f = pageOffset - CGFloat(i)
        let julianDay = DayScene.julianDay(from: i)
        let progress = f + CGFloat(julianDay - dayStore.state.currentDay)
        delegate?.eventViewController(self, pagingProgress: progress, isJump: false)
    }

}

// MARK: - Module Layout

extension DaySceneViewController {

    private func layoutModules() {
        let headerHeight: CGFloat
        if daysPerScene > 1 {
            // 三日/周视图
            headerHeight = 62
        } else {
            // 日视图
            headerHeight = rxViewSetting.value.isAlternateCalendarActive ? 83 : 63
        }
        modules.header.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: headerHeight)
        modules.allday.view.frame = CGRect(
            origin: CGPoint(x: 0, y: headerHeight),
            size: CGSize(width: view.bounds.width, height: modules.allday.visibleHeight)
        )
        modules.nonAllDay.view.frame = CGRect(
            origin: CGPoint(x: 0, y: headerHeight),
            size: CGSize(width: view.bounds.width, height: view.bounds.height - headerHeight)
        )
    }

    private func adjustHeaderModuleHeight() {
        // 日视图模式下，header 的高度会随着农历变化
        guard daysPerScene == 1 else { return }
        rxViewSetting
            .map { viewSetting -> Bool in
                return viewSetting.isAlternateCalendarActive
            }
            .skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.layoutModules()
            })
            .disposed(by: disposeBag)
    }

    private func adjustAllDayModuleHeight(_ height: CGFloat, animated: Bool) {
        if animated {
            UIView.animate(withDuration: DayScene.UIStyle.Const.allDayAnimationDuration) {
                self.modules.allday.view.frame.size.height = height
            }
        } else {
            modules.allday.view.frame.size.height = height
        }
    }

}

// MARK: Handle Action

extension DaySceneViewController {

    private func observeAction() {
        // 处理 adjust allDayModule 的高度，初始不加动画；后续（1s）再加动画
        var adjustAllDayModuleHeightAnimated = false
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            adjustAllDayModuleHeightAnimated = true
        }

        dayStore.responds { [weak self] (action, _) in
            guard let self = self else { return }
            switch action {
            case .showTimeZonePopup:
                self.showTimeZonePopup()
                self.dayStore.dispatch(.clearEditingContext, on: MainScheduler.asyncInstance)
            case .createEvent(let startDate, let endDate):
                CalendarTracer.shared.calMainClick(type: .quick_create_event)
                self.newDelegate?.createEvent(withStartDate: startDate, endDate: endDate)
            case .showDetail(let instance):
                self.newDelegate?.showDetail(for: instance, sender: self)
            case .adjustAllDayVisibleHeight(let height):
                self.adjustAllDayModuleHeight(height, animated: adjustAllDayModuleHeightAnimated)
            case .tapIconTapped(let model, let isSelected):
                timeDataService.tapIconTapped(model: model, isCompleted: isSelected, from: self)
            default: break
            }
        }.disposed(by: disposeBag)
    }

    // 展示时区弹窗
    private func showTimeZonePopup() {
        if FeatureGating.additionalTimeZoneOption(userID: self.userResolver.userID) {
            let body = CalendarAdditionalTimeZoneBody(activateDay: dayStore.state.activeDay)
            userResolver.navigator.present(body: body, from: self)
        } else {
            var previousTimeZone = timeZoneService.preferredTimeZone.value
            let popupVC = getPopupTimeZoneSelectViewController(
                with: timeZoneService,
                selectedTimeZone: timeZoneService.preferredTimeZone,
                anchorDate: currentPageDate(),
                onTimeZoneSelect: { [weak self] timeZone in
                    guard let self = self else { return }
                    if previousTimeZone.identifier != timeZone.identifier {
                        let anchor = self.currentPageDate()
                        let timeZoneName = timeZone.standardName(for: anchor)
                        RoundedHUD.showSuccess(with: "\(timeZoneName)(\(timeZone.getGmtOffsetDescription(date: anchor)))", on: self.view)
                    }
                    previousTimeZone = timeZone
                    _ = self.timeZoneService.setPreferredTimeZone(timeZone).subscribe(onDisposed: { })
                }
            )
            present(popupVC, animated: true)
        }
    }

}

// MARK: 兼容旧版接口

typealias HomeSceneViewControlelr = EventViewController

extension DaySceneViewController: HomeSceneViewControlelr {
    func reloadData(with date: Date) {
        assertionFailure("error flow")
    }

    func currentPageDate() -> Date {
        return makeDate(for: dayStore.state.activeDay)
    }

    func getCurrentSelectDate() -> Date {
        return makeDate(for: dayStore.state.currentDay)
    }

    func scrollToRedLine(animated: Bool) {
        // 滚动到当前时刻
        dayStore.dispatch(.scrollToNow)
    }

    func dayViewContentOffset() -> CGPoint? {
        return nil
    }

    var controller: UIViewController { self }

    var tabBarDirection: ScrollDriction { .horizontal }

}
