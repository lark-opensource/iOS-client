//
//  DayNonAllDayViewModel.swift
//  Calendar
//
//  Created by 张威 on 2020/7/30.
//

import UIKit
import RxSwift
import RxCocoa
import CalendarFoundation
import LarkTimeFormatUtils
import EventKit
import CTFoundation
import LarkContainer

/// DayScene - NonAllDay - ViewModel

final class DayNonAllDayViewModel: UserResolverWrapper {
    struct DisplayModel: Equatable {
        static func == (lhs: DayNonAllDayViewModel.DisplayModel, rhs: DayNonAllDayViewModel.DisplayModel) -> Bool {
            return (lhs.isAppeared == rhs.isAppeared) && (lhs.didAppeared == rhs.didAppeared)
        }

        let isAppeared: Bool
        let didAppeared: Bool
        let launchModel: CaVCLoggerModel?
    }
    typealias PageDrawRectFunc = () -> CGRect

    let dayStore: DaySceneStore

    // MARK: State From ViewController

    // view 当前是否处于 appeared 状态
    let rxViewAppeared = BehaviorRelay(value: DisplayModel(isAppeared: false, didAppeared: false, launchModel: nil))

    // visiblePageRange
    let rxVisiblePageRange = BehaviorRelay(value: CAValue<PageRange>(0..<1, .init()))

    let rxPageDrawRectFunc = BehaviorRelay(value: PageDrawRectFunc?.none)

    // MARK: ViewData Event

    // viewData 相关 rx 的 event 都在主线程被 published

    // current JulianDay + TimeScale
    typealias JulianDayTimeScale = (julianDay: JulianDay, timeScale: TimeScale)
    private(set) var rxJulianDayTimeScale = BehaviorRelay<JulianDayTimeScale>(value: (julianDay: 0, timeScale: TimeScale.mininum))

    // 刷新
    let rxUpdate = (
        // 更新 page
        pageAt: PublishSubject<CAValue<PageIndex>>(),
        // 全量刷新
        allPages: PublishSubject<CaVCLoggerModel>()
    )

    private let instanceSource: DayNonAllDayInstanceSource

    let userResolver: UserResolver
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarSelectTracer: CalendarSelectTracer?
    private let rxViewSetting: BehaviorRelay<DayScene.ViewSetting>

    private var timer: Timer?

    private let disposeBag = DisposeBag()

    private let viewDataScheduler = ConcurrentDispatchQueueScheduler(qos: .userInteractive)

    // 描述可用的 viewData 版本
    private var targetViewDataVersion = 0

    // 已经被 vc 请求过的 pageViewData, 根据 visiblePageRange 淘汰
    private var loadedPageViewData: LRUCache<JulianDay, PageViewData>

    // 冷启动结束了
    private var rxFinishColdLaunch = PublishSubject<CaVCLoggerModel>()
    let rxIs12HourStyle: BehaviorRelay<Bool>
    private let rxTimeBlocksChange: Observable<Void>
    private lazy var viewDataManager = ViewDataManager(
        timeZone: dayStore.state.timeZoneModel.timeZone,
        currentDay: dayStore.state.currentDay,
        viewSetting: rxViewSetting.value,
        calendarGetter: { [weak self] in self?.calendarManager?.calendar(with: $0) },
        pageDrawRectFunc: { [weak self] in
            self?.rxPageDrawRectFunc.value?() ?? UIScreen.main.bounds
        }
    )

    init(
        userResolver: UserResolver,
        dayStore: DaySceneStore,
        instanceSource: DayNonAllDayInstanceSource,
        rxTimeBlocksChange: Observable<Void>,
        rxIs12HourStyle: BehaviorRelay<Bool>,
        rxViewSetting: BehaviorRelay<DayScene.ViewSetting>
    ) {
        self.userResolver = userResolver
        self.dayStore = dayStore
        self.instanceSource = instanceSource
        self.rxViewSetting = rxViewSetting
        self.rxIs12HourStyle = rxIs12HourStyle
        self.rxTimeBlocksChange = rxTimeBlocksChange
        self.loadedPageViewData = .init(capacity: dayStore.state.daysPerScene + 5, useLock: false)
        self.rxJulianDayTimeScale = .init(value: (julianDay: dayStore.state.currentDay, timeScale: currentTimeScale()))
    }

    private var setupFlag = false
    func setup(loggerModel: CaVCLoggerModel) {
        guard !setupFlag else { return }
        defer { setupFlag = true }
        setupJulianDayTimeScale()
        setupReload(loggerModel: loggerModel)
        setupSubscriptionOnVisiblePageRange()
    }

    func didFinishColdLaunch(loggerModel: CaVCLoggerModel) {
        rxFinishColdLaunch.onNext(loggerModel)
    }

}

// MARK: JulianDay + TimeScale

// 定时器，每 15 秒执行一次
private let timerInterval: TimeInterval = 15

extension DayNonAllDayViewModel: Timable {

    private func setupJulianDayTimeScale() {
        // 系统时间/时区变化
        let rxSystemTime = NotificationCenter.default.rx
            .notification(UIApplication.significantTimeChangeNotification)
            .map { _ in "significantTimeChangeNotification posted" }
            // 用户勾选时区变化
        let rxTimeZone = dayStore.rxValue(forKeyPath: \.timeZoneModel)
            .distinctUntilChanged { $0.timeZone.identifier == $1.timeZone.identifier }
            .skip(1)
            .map { _ in "time zone changed" }

        Observable.merge([rxSystemTime, rxTimeZone])
            .observeOn(MainScheduler.asyncInstance)
            .bind { [weak self] reason in
                let loggerModel = CaVCLoggerModel(task: .change)
                EffLogger.log(model: loggerModel, toast: "bind action triggered, reason: \(reason)")
                DayScene.logger.info("bind action triggered, reason: \(reason)")
                guard let self = self, self.rxViewAppeared.value.isAppeared else { return }
                EffLogger.log(model: loggerModel, toast: "timeZoneChange - will update currenDay, timescale, julianDay")
                DayScene.logger.info("timeZoneChange - will update currenDay, timescale, julianDay")
                self.updateCurrentDayIfNeeded()
                self.updateJulianDayTimeScale(loggerModel: loggerModel)
            }
            .disposed(by: disposeBag)

        // view Appeared
        rxViewAppeared.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .bind { [weak self] model in
                guard let self = self else { return }
                if model.isAppeared {
                    self.updateCurrentDayIfNeeded()
                    let loggerModel: CaVCLoggerModel
                    if !model.didAppeared, let model = model.launchModel {
                        loggerModel = model
                    } else {
                        loggerModel = CaVCLoggerModel(task: .action)
                    }
                    EffLogger.log(model: loggerModel, toast: "View Did Appeared")
                    self.updateJulianDayTimeScale(loggerModel: loggerModel.createNewModelByTask(.process))
                    self.startTimer(&self.timer, timerInterval: timerInterval) { [weak self] in
                        DayScene.logger.info("ViewAppeared - will update currenDay, timescale, julianDay")
                        let loggerModel = CaVCLoggerModel(task: .change)
                        EffLogger.log(model: loggerModel, toast: "ViewAppeared - will update currenDay, timescale, julianDay")
                        self?.updateCurrentDayIfNeeded()
                        self?.updateJulianDayTimeScale(loggerModel: loggerModel.createNewModelByTask(.process))
                    }
                } else {
                    self.stopTimer(&self.timer)
                }
            }
            .disposed(by: disposeBag)
    }

    // 计算 currentDay，同步到 dayStore 中
    private func updateCurrentDayIfNeeded() {
        let currentDay = JulianDayUtil.julianDay(from: Date(), in: dayStore.state.timeZoneModel.timeZone)
        if dayStore.state.currentDay != currentDay {
            dayStore.setValue(currentDay, forKeyPath: \.currentDay)
        }
    }

    private func updateJulianDayTimeScale(loggerModel: CaVCLoggerModel) {
        let timeScale = currentTimeScale()
        let julianDay = dayStore.state.currentDay
        let cur = rxJulianDayTimeScale.value

        guard cur.timeScale != timeScale || cur.julianDay != julianDay else {
            let new = loggerModel.createNewModelByTask(.abort)
            EffLogger.log(model: new, toast: "timeScale and not all not changed")
            return
        }
        defer { rxJulianDayTimeScale.accept((julianDay, timeScale)) }

        if cur.julianDay != julianDay {
            // 更新 page 的背景
            viewDataManager.updateCurrentDay(julianDay)
            if cur.julianDay + 1 == julianDay {
                // currentDay 正常变化（向前推进一天），更新两天 instance 的 maskOpacity
                viewDataManager.updateMaskOpacity(in: cur.julianDay)
                viewDataManager.updateMaskOpacity(in: julianDay)
            } else {
                // currentDay 非正常变化，直接更新所有 instance 的 maskOpacity
                viewDataManager.updateMaskOpacityForAll()
            }
            EffLogger.log(model: loggerModel, toast: "currentDay changed, publish update.allPages event")
            DayScene.logger.info("currentDay changed, publish update.allPages event")
            rxUpdate.allPages.onNext(loggerModel)
        } else {
            viewDataManager.updateMaskOpacity(in: julianDay)
            DayScene.logger.info("timeScale changed, publish update.pageAt event")
            EffLogger.log(model: loggerModel, toast: "timeScale changed, publish update.pageAt event")
            let pageIndex = DayScene.pageIndex(from: julianDay)
            rxUpdate.pageAt.onNext(.init(pageIndex, loggerModel))
        }
    }

    func currentTimeScale() -> TimeScale {
        let dateComps = Calendar.gregorianCalendar.dateComponents(in: dayStore.state.timeZoneModel.timeZone, from: Date())
        return TimeScale(components: (dateComps.hour!, dateComps.minute!, dateComps.second!))!
    }
}

// MARK: Setup Reload

extension DayNonAllDayViewModel {

    // Reload 触发源：
    //  - 时区变化
    //  - pageDrawRect 变化
    //  - instanceSource 变更
    //  - 冷启动结束
    //  - ViewSetting
    //      - 深浅皮肤
    //      - 过去日程是否显示蒙白
    private func setupReload(loggerModel: CaVCLoggerModel) {
        // 准备 PageViewData
        /// instace获取活动图: https://bytedance.feishu.cn/docx/OJVJdswanoirKvx2epyc02Ffn6g
        let rxPrepareViewData = { [weak self] (loggerModel: CaVCLoggerModel) -> Observable<CaVCLoggerModel> in
            guard let self = self else { return .just(.init()) }
            let visibleDayRange = DayScene.julianDayRange(from: self.rxVisiblePageRange.value.value)
            let processModel = loggerModel.createNewModelByTask(.process)
            return self.preparePageViewData(dayRangeWrapper: .init(visibleDayRange, processModel)).asObservable().map { $0.loggerModel }.catchErrorJustReturn(.init())
        }

        // 触发 pageReload
        let doUpdateAllPage = { [weak self] (loggerModel: CaVCLoggerModel) -> Void in
            var new = loggerModel
            new.updateTask(.process)
            EffLogger.log(model: new, toast: "NonAllDay publish reload event")
            DayScene.logger.info("NonAllDay publish reload event")
            self?.rxUpdate.allPages.onNext((new))
        }

        // 时区变化：更新 Cache 时区（清除缓存） -> 重新准备 PageViewData -> 触发 pageReload
        dayStore.rxValue(forKeyPath: \.timeZoneModel).asObservable()
            .observeOn(MainScheduler.instance)
            .filter { [weak self] new -> Bool in
                guard let old = self?.viewDataManager.timeZone else { return false }
                return old.identifier != new.timeZone.identifier
            }
            .do(onNext: { [weak self] timeZoneModel in
                let timeZone = timeZoneModel.timeZone
                DayScene.logger.info("timeZone Changed, newValue: \(timeZone.identifier)")
                self?.viewDataManager.updateTimeZone(timeZone)
                self?.targetViewDataVersion += 1
                DayScene.logger.info("targetViewDataVersion => timeZone Changed - version increase to \(self?.targetViewDataVersion ?? -1)")
            })
            .map { _ in
                let loggerModel = CaVCLoggerModel(task: .change)
                EffLogger.log(model: loggerModel, toast: "timeZone changed")
                return loggerModel
            }
            .flatMap(rxPrepareViewData)
            .subscribe(onNext: doUpdateAllPage)
            .disposed(by: disposeBag)

        // PageDrawRect 变化：清除缓存 -> 重新准备 PageViewData -> 触发 pageReload
        rxPageDrawRectFunc.asObservable()
            .skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] _ in
                DayScene.logger.info("PageDrawRectChanged")
                self?.viewDataManager.dropAllPageViewData()
                self?.targetViewDataVersion += 1
                DayScene.logger.info("targetViewDataVersion => PageDrawRectChanged - version increase to \(self?.targetViewDataVersion ?? -1)")
            })
            .map { _ in
                let loggerModel = CaVCLoggerModel(task: .change)
                EffLogger.log(model: loggerModel, toast: "PageDrawRect changed")
                return loggerModel
            }
            .flatMap(rxPrepareViewData)
            .subscribe(onNext: doUpdateAllPage)
            .disposed(by: disposeBag)

        // InstanceSource Updated: 重新准备 PageViewData -> 触发 pageReload
        // 此过程不清除缓存（基于之前的缓存准备 PageViewData 效率会更高）
        instanceSource.rxNonAllDayInstanceUpdated
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] _ in
                DayScene.logger.info("NonAllDayInstanceUpdated")
                self?.targetViewDataVersion += 1
                DayScene.logger.info("targetViewDataVersion => NonAllDayInstanceUpdated - version increase:\(self?.targetViewDataVersion ?? -1)")
            })
            .map { _ in
                let loggerModel = CaVCLoggerModel(task: .push)
                EffLogger.log(model: loggerModel, toast: "rxNonAllDayInstanceUpdated")
                return loggerModel
            }
            .flatMap(rxPrepareViewData)
            .subscribe(onNext: { doUpdateAllPage($0) })
            .disposed(by: disposeBag)

        // ViewSetting 变化: 基于现有 cache 更新 viewSetting -> 触发 pageReload
        // 此过程不清除缓存、不重新拉数据，基于现有 cached 数据重新构建 PageViewData，这不是一个耗时逻辑
        rxViewSetting
            .observeOn(MainScheduler.asyncInstance)
            .filter { [weak self] new -> Bool in
                guard let old = self?.viewDataManager.viewSetting else { return false }
                return old.skinTypeIos != new.skinTypeIos || old.showCoverPassEvent != new.showCoverPassEvent
            }
            .subscribe(onNext: { [weak self] viewSetting in
                let loggerModel = CaVCLoggerModel(task: .change)
                EffLogger.log(model: loggerModel, toast: "rxNonAllDayInstanceUpdated")
                DayScene.logger.info("viewSetting changed, update view data cache, and publish rxUpdate.allPages event")
                self?.viewDataManager.updateViewSetting(viewSetting)
                self?.rxUpdate.allPages.onNext((loggerModel))
            })
            .disposed(by: disposeBag)

        rxFinishColdLaunch
            .take(1)
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] v in
                DayScene.logger.info("didFinish Cold Launch, targetViewDataVersion: didFinish cold launch - viewDataVersion increase to \(self?.targetViewDataVersion ?? -1)")
                EffLogger.log(model: v, toast: "didFinish Cold Launch, targetViewDataVersion: didFinish cold launch - viewDataVersion increase to \(self?.targetViewDataVersion ?? -1)")
                self?.targetViewDataVersion += 1
            })
            .flatMap(rxPrepareViewData)
            .subscribe(onNext: { doUpdateAllPage($0) })
            .disposed(by: disposeBag)
        
        rxTimeBlocksChange
            .map { _ in
                let loggerModel = CaVCLoggerModel(task: .push)
                EffLogger.log(model: loggerModel, toast: "nonAllDay rxTimeBlocksChange")
                return loggerModel
            }
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] v in
                EffLogger.log(model: v, toast: "didFinish Cold Launch, targetViewDataVersion: didFinish cold launch - viewDataVersion increase to \(self?.targetViewDataVersion ?? -1)")
                self?.targetViewDataVersion += 1
            })
            .flatMap(rxPrepareViewData)
            .subscribe(onNext: { doUpdateAllPage($0) })
            .disposed(by: disposeBag)
    }
}

// MARK: Setup Subscription On VisiblePageRange

extension DayNonAllDayViewModel {

    func setupSubscriptionOnVisiblePageRange() {
        rxVisiblePageRange.distinctUntilChanged({
            $0.value == $1.value
        }).skip(1)
            .debounce(.milliseconds(150), scheduler: MainScheduler.asyncInstance)
            .observeOn(MainScheduler.asyncInstance)
            .bind { [weak self] range in
                self?.dropCachedViewData()
                self?.preloadAdjacentViewData(range: range)
            }
            .disposed(by: disposeBag)
    }

    private func dropCachedViewData() {
        guard let firstWeekday = EKWeekday(rawValue: rxViewSetting.value.firstWeekday.rawValue) else {
            DayScene.assertionFailure()
            return
        }
        viewDataManager.dropPageViewData(
            withVisiblePageRange: self.rxVisiblePageRange.value.value,
            firstWeekday: firstWeekday
        )
    }

    private func preloadViewData(for dayRange: JulianDayRange, in timeZone: TimeZone, loggerModel: CaVCLoggerModel) {
        let version = targetViewDataVersion
        preparePageViewData(dayRangeWrapper: .init(dayRange, loggerModel), autoUpdateCache: false)
            .subscribe(onSuccess: { [weak self] res in
                let pageViewDataDict = res.value
                guard let self = self else { return }
                pageViewDataDict.forEach { tuple in
                    let (day, pageViewData) = tuple
                    guard self.viewDataManager.pageViewData(for: day, in: timeZone) == nil else { return }
                    self.viewDataManager.updatePageViewData(pageViewData, for: day, in: timeZone, version: version, loggerModel: loggerModel)
                }
            })
            .disposed(by: disposeBag)
    }

    // 预加载相邻的 ViewData（不包括当前 weeks）
    private func preloadAdjacentViewData(range: CAValue<PageRange>) {
        let visiblePageRange = range.value
        let loggerModel = range.loggerModel.createNewModelByAddAsyncTask(.process)
        let visibleDayRange = DayScene.julianDayRange(from: visiblePageRange)
        guard visibleDayRange.lowerBound >= JulianDayUtil.julianDayFrom2000_01_01,
              visibleDayRange.upperBound <= JulianDayUtil.julianDayFrom2100_01_01 else {
            return
        }
        let lowerDate = JulianDayUtil.date(from: visibleDayRange.lowerBound)
        let upperDate = JulianDayUtil.date(from: visibleDayRange.upperBound)

        let timeZone = dayStore.state.timeZoneModel.timeZone

        // 确保 visibleDayRange 范围的 viewData 都 ok 了，才准备相邻的 viewData
        let version = targetViewDataVersion
        var visibleDayRangeIsReady = true
        for day in visibleDayRange {
            guard viewDataManager.hasViewData(for: day, in: timeZone, version: version) else {
                visibleDayRangeIsReady = false
                break
            }
        }
        guard visibleDayRangeIsReady else {
            return
        }
        // 预加载左邻 ViewData
        let leftStartDay = visibleDayRange.lowerBound - dayStore.state.daysPerScene
        var leftEndDay = visibleDayRange.upperBound - 1
        while leftEndDay >= leftStartDay, viewDataManager.hasViewData(for: leftEndDay, in: timeZone, version: version) {
            leftEndDay -= 1
        }
        if leftEndDay >= leftStartDay {
            EffLogger.log(model: loggerModel, toast: "preloadAdjacentViewData range: (\(leftStartDay), \(leftEndDay + 1))")
            preloadViewData(for: leftStartDay..<leftEndDay + 1, in: timeZone, loggerModel: loggerModel)
        }

        // 预加载右邻 ViewData
        let rightToDay = visibleDayRange.upperBound + dayStore.state.daysPerScene
        var rightFromDay = visibleDayRange.upperBound
        while rightFromDay < rightToDay, viewDataManager.hasViewData(for: rightFromDay, in: timeZone, version: version) {
            rightFromDay += 1
        }
        if rightFromDay < rightToDay {
            EffLogger.log(model: loggerModel, toast: "preloadAdjacentViewData range: (\(rightFromDay), \(rightToDay))")
            preloadViewData(for: rightFromDay..<rightToDay, in: timeZone, loggerModel: loggerModel)
        }
    }
}

extension DayNonAllDayViewModel {

    static func formattedText(for timeScale: TimeScale,
                              is12HourStyle: Bool,
                              activateDay: JulianDay = JulianDayUtil.julianDay(from: Date(), in: .current),
                              timeZone: TimeZone = .current) -> String {
        let (hour, minute, second) = timeScale.components()
        let (year, month, day) = JulianDayUtil.yearMonthDay(from: activateDay)
        var dateComponents = DateComponents()
        dateComponents.timeZone = .current
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second

        let date = Calendar.gregorianCalendar.date(from: dateComponents) ?? Date()
        var newDateComponents = Calendar.gregorianCalendar.dateComponents(in: timeZone, from: date)
        newDateComponents.timeZone = .current
        if is12HourStyle {
            let customOptions = Options(
                is12HourStyle: true,
                timePrecisionType: .minute,
                shouldRemoveTrailingZeros: true
            )
            let newDate = Calendar.gregorianCalendar.date(from: newDateComponents) ?? date
            return TimeFormatUtils.formatTime(from: newDate, with: customOptions)
        } else {
            let newHour: Int
            if timeScale.offset == TimeScale.maxOffset && newDateComponents.hour == 0 {
                newHour = 24
            } else {
                newHour = newDateComponents.hour ?? hour
            }
            let newMinute = newDateComponents.minute ?? minute
            let hourStr = newHour < 10 ? "0\(newHour)" : "\(newHour)"
            let minutesStr = newMinute < 10 ? "0\(newMinute)" : "\(newMinute)"
            return "\(hourStr):\(minutesStr)"
        }
    }

}

// MARK: - ViewAction

extension DayNonAllDayViewModel {
    func model(forUniqueId uniqueId: String, in julianDay: JulianDay) -> BlockDataProtocol? {
        var pageViewData = loadedPageViewData.value(forKey: julianDay)
        if pageViewData == nil {
            DayScene.assertionFailure("pageViewData should not be nil")
            pageViewData = viewDataManager.pageViewData(for: julianDay, in: dayStore.state.timeZoneModel.timeZone)?.pageViewData
        }
        guard pageViewData != nil else {
            DayScene.assertionFailure("pageViewData should not be nil")
            return nil
        }
        if let first = pageViewData?.instanceItems.first(where: { $0.viewData.uniqueId == uniqueId }) {
            if let instance = (first as? InstanceViewData)?.instance {
                return instance
            }
            if let timeBlock = first as? TimeBlockViewData {
                return timeBlock.timeBlockData
            }
        }
        DayScene.assertionFailure("type error")
        return nil
    }

    func instance(forUniqueId uniqueId: String, in julianDay: JulianDay) -> Instance? {
        var pageViewData = loadedPageViewData.value(forKey: julianDay)
        if pageViewData == nil {
            DayScene.assertionFailure("pageViewData should not be nil")
            pageViewData = viewDataManager.pageViewData(for: julianDay, in: dayStore.state.timeZoneModel.timeZone)?.pageViewData
        }
        guard pageViewData != nil else {
            DayScene.assertionFailure("pageViewData should not be nil")
            return nil
        }
        guard let instance = (pageViewData?.instanceItems.first(where: { $0.viewData.uniqueId == uniqueId }) as? InstanceViewData)?.instance else {
            DayScene.assertionFailure("instance should not be nil")
            return nil
        }
        return instance
    }

    // 编辑日程时 block tip，nil 表示可以编辑日程，否则弹 toast 提示
    func blockTipForEditingInstance(withUniqueId uniqueId: String, in julianDay: JulianDay) -> String? {
        guard let model = model(forUniqueId: uniqueId, in: julianDay) else {
            return BundleI18n.Calendar.Calendar_Edit_PermissonErrorTip
        }
        return model.process { type in
            switch type {
            case .event(let instance):
                if instance.displayType == .undecryptable || instance.disableEncrypt {
                    return I18n.Calendar_NoKeyNoOperate_Toast
                }

                if !instance.isEditable {
                    return BundleI18n.Calendar.Calendar_Edit_PermissonErrorTip
                }
                if instance.isCrossDay(in: dayStore.state.timeZoneModel.timeZone) {
                    return BundleI18n.Calendar.Calendar_Edit_DragCrossDayEventTip
                }
                return nil
            case .timeBlock(let block):
                if !block.canDrag || !block.canMove || block.isOverOneDay {
                    return I18n.Calendar_G_CantDragThisTask_Toast
                }
                return nil
            case .instanceEntity, .none:
                return nil
            }
        }
    }

}

// MARK: - PageViewData

extension DayNonAllDayViewModel {

    // MARK: Get Page View Data

    /// `pageViewData(for:)` 返回值
    enum PageViewDataReturn {
        // 立即返回的 sectionItems
        case value(DayNonAllDayViewDataType)
        // 请求中的 disposable
        case requesting(disposable: Disposable, placeholder: DayNonAllDayViewDataType)
    }

    func pageViewData(for pageIndex: PageIndex, loggerModel: CaVCLoggerModel) -> PageViewDataReturn {
        assert(Thread.isMainThread)
        let is12HourStyle = self.rxIs12HourStyle.value

        let day = DayScene.julianDay(from: pageIndex)

        guard rxPageDrawRectFunc.value != nil else {
            return .value(PageViewData(julianDay: day))
        }
        let cached = viewDataManager.pageViewData(for: day, in: dayStore.state.timeZoneModel.timeZone)
        DayScene.logger.info("targetViewDataVersion => use cache: \(cached?.0 == targetViewDataVersion), and version:\(cached?.0 ?? -1), targetViewDataVersion: \(targetViewDataVersion)")
        EffLogger.log(model: loggerModel,
                      toast: "targetViewDataVersion => use cache: \(cached?.0 == targetViewDataVersion), and version:\(cached?.0 ?? -1), targetViewDataVersion: \(targetViewDataVersion)")
        if let (version, pageViewData) = cached, version == targetViewDataVersion {
            loadedPageViewData.setValue(pageViewData, forKey: day)
            return .value(pageViewData)
        }

        let visibleDayRange = DayScene.julianDayRange(from: rxVisiblePageRange.value.value)
        let dayRange = visibleDayRange.contains(day) ? visibleDayRange : day..<day + 1
        let disposable = preparePageViewData(dayRangeWrapper: .init(dayRange, loggerModel))
            .subscribe(onSuccess: { [weak self] v in
                DayScene.logger.info("publish update event. day: \(day), page: \(pageIndex)")
                EffLogger.log(model: v.loggerModel, toast: "publish update event. day: \(day), page: \(pageIndex)")
                self?.rxUpdate.pageAt.onNext(.init(pageIndex, loggerModel))
            })
        disposable.disposed(by: disposeBag)
        // 请求中用 cached.pageViewData 作为 placeholder data，避免闪烁
        let placeholder = cached?.pageViewData ?? viewDataManager.makePageViewData(from: [], forDay: day, is12HourStyle: is12HourStyle)
        return .requesting(disposable: disposable, placeholder: placeholder)
    }
}

// MARK: Prepare/Cache for PageViewData

extension DayNonAllDayViewModel {

    private func makePageViewData(
        from instanceMapWrapper: CAValue<[JulianDay: [DayNonAllDayLayoutedInstance]]>,
        for dayRange: JulianDayRange
    ) -> CAValue<[JulianDay: PageViewData]> {
        let instanceMap = instanceMapWrapper.value

        var pageViewDataMap = [JulianDay: PageViewData]()
        for day in dayRange {
            pageViewDataMap[day] = viewDataManager.makePageViewData(
                from: instanceMap[day] ?? [],
                forDay: day,
                is12HourStyle: self.rxIs12HourStyle.value
            )
        }
        logFrameInfo(pageViewDataMap: pageViewDataMap, loggerModel: instanceMapWrapper.loggerModel)
        return .init(pageViewDataMap, instanceMapWrapper.loggerModel)
    }

    private func logFrameInfo(pageViewDataMap: [JulianDay: PageViewData], loggerModel: CaVCLoggerModel) {
        guard EffLogger.shouldLog else { return }
        // 按照时间排序
        let newList = pageViewDataMap.sorted { lhs, rhs in
            let lhsDate = JulianDayUtil.date(from: lhs.key)
            let rhsDate = JulianDayUtil.date(from: rhs.key)
            return lhsDate.day < rhsDate.day
        }
        let frameInfo = newList.reduce("caculete instance frame: ") { partialResult, data in
            let instanceItemsDesc = data.value.instanceItems.reduce("") { partialResult, instanceItem in
                let id = EffLogger.isCutLog ? "\(instanceItem.viewData.uniqueId.prefix(10))" : instanceItem.viewData.uniqueId
                return partialResult + "key = \(id), y = \(Int(instanceItem.frame.origin.y)) | "
            }
            let date = JulianDayUtil.date(from: data.key)
            let desc = "day = \(date.month)-\(date.day): frame = { \(instanceItemsDesc) } "
            return partialResult + desc
        }
        EffLogger.log(model: loggerModel, toast: frameInfo)
        DayScene.logger.info(frameInfo)
    }
    
    // 根据 dayPage 准备 PageViewData，回调在主线程触发
    private func preparePageViewData(
        dayRangeWrapper: CAValue<JulianDayRange>,
        autoUpdateCache: Bool = true
    ) -> Single<CAValue<[JulianDay: PageViewData]>> {
        let is12HourStyle = self.rxIs12HourStyle.value
        let dayRange = dayRangeWrapper.value
        let loggerModel = dayRangeWrapper.loggerModel
        let timeZone = dayStore.state.timeZoneModel.timeZone
        let version = targetViewDataVersion

        guard rxPageDrawRectFunc.value != nil else {
            EffLogger.log(model: loggerModel, toast: "rxPageDrawRectFunc.value is nil")
            DayScene.logger.info("rxPageDrawRectFunc.value is nil")
            var pageViewDataMap = [JulianDay: PageViewData]()
            for day in dayRange {
                let pageViewData = viewDataManager.makePageViewData(from: [], forDay: day, is12HourStyle: is12HourStyle)
                viewDataManager.updatePageViewData(pageViewData, for: day, in: timeZone, version: version, loggerModel: loggerModel)
                pageViewDataMap[day] = pageViewData
            }
            return Observable.just(.init(pageViewDataMap, loggerModel))
                .asSingle()
                .observeOn(MainScheduler.asyncInstance)
        }
        let ret = instanceSource.rxNonAllDayInstances(for: dayRangeWrapper, in: timeZone)
        let rxLayoutedInstances: Single<CAValue<[JulianDay: [DayNonAllDayLayoutedInstance]]>>
        switch ret {
        case .value(let layoutedInstances):
            rxLayoutedInstances = Observable.just(layoutedInstances).asSingle()
        case .rxValue(let rx):
            rxLayoutedInstances = rx
        }

        return rxLayoutedInstances.retry(3)
            .subscribeOn(viewDataScheduler)
            .map { [weak self] instanceMapWrapper -> CAValue<[JulianDay: PageViewData]> in
                guard let self = self else { return .init([:], loggerModel) }
                return self.makePageViewData(from: instanceMapWrapper, for: dayRange)
            }
            .observeOn(MainScheduler.asyncInstance)
            .do(
                onSuccess: { [weak self] (updateItemsMapWrapper) in
                    if autoUpdateCache {
                        updateItemsMapWrapper.value.forEach { tuple in
                            let (day, pageViewData) = tuple
                            self?.viewDataManager.updatePageViewData(
                                pageViewData,
                                for: day,
                                in: timeZone,
                                version: version,
                                loggerModel: updateItemsMapWrapper.loggerModel
                            )
                        }
                    }
                },
                onError: { err in
                    let logMsg = "preparePageViewData failed. dayRange: \(dayRange), err: \(err)"
                    DayScene.logger.info(logMsg)
                    DayScene.assert(false, logMsg)
                }
            )
    }

}

// MARK: - Cold Launch

extension DayNonAllDayViewModel {

    /// 冷启动 viewData
    func rxColdLaunchViewData(with context: HomeScene.ColdLaunchContext) -> Single<CAValue<[JulianDay: PageViewData]>> {
        assert(Thread.isMainThread)
        let ret = instanceSource.rxNonAllDayInstances(for: .init(context.dayRange, context.loggerModel),
                                                      in: context.timeZone,
                                                      fromColdLaunch: true)
        let rxLayoutedInstances: Single<CAValue<[JulianDay: [DayNonAllDayLayoutedInstance]]>>
        switch ret {
        case .value(let layoutedInstances):
            rxLayoutedInstances = Observable.just(layoutedInstances).asSingle()
        case .rxValue(let rx):
            rxLayoutedInstances = rx
        }
        return rxLayoutedInstances
            .observeOn(viewDataScheduler)
            .map { [weak self] dayInstanceMapWrapper in
                guard let self = self else { return .init(.init(), .init()) }
                let res = self.makePageViewData(from: dayInstanceMapWrapper, for: context.dayRange)
                let timeZone = dayStore.state.timeZoneModel.timeZone
                let version = targetViewDataVersion
                // 更新内存缓存，防止出现闪烁
                DispatchQueue.main.async {
                    res.value.forEach { tuple in
                        let (day, pageViewData) = tuple
                        self.viewDataManager.updatePageViewData(
                            pageViewData,
                            for: day,
                            in: timeZone,
                            version: version,
                            loggerModel: dayInstanceMapWrapper.loggerModel
                        )
                    }
                }
                return res
            }
    }

    func emptyPageViewData(for day: JulianDay) -> DayNonAllDayViewDataType {
        return viewDataManager.makePageViewData(from: [], forDay: day, is12HourStyle: self.rxIs12HourStyle.value)
    }

}
