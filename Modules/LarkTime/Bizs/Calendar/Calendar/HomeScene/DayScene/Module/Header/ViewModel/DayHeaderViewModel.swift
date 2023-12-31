//
//  DayHeaderViewModel.swift
//  Calendar
//
//  Created by 张威 on 2020/7/29.
//

import RxSwift
import RxCocoa
import EventKit
import LarkTimeFormatUtils
import CTFoundation
import LarkUIKit
import LarkContainer

/// DayScene - Header - ViewModel

final class DayHeaderViewModel: UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver

    var dayStore: DaySceneStore

    // MARK: ViewData Properties

    // All viewData Rx properties published in main thread

    typealias ViewMode = DayHeaderViewController.ViewMode
    let rxViewMode: BehaviorRelay<DayHeaderViewController.ViewMode>

    let rxTimeZoneText: BehaviorRelay<String?>
    let rxAdditionalTimeZoneText: BehaviorRelay<String?>

    // week ViewData updated
    let rxWeekViewDataUpdate = (
        pageAt: PublishSubject<PageIndex>(),
        allPages: PublishSubject<Void>()
    )

    // day ViewData updated
    let rxDayViewDataUpdate = (
        pageAt: PublishSubject<PageIndex>(),
        allPages: PublishSubject<Void>()
    )

    // MARK: Private Properties

    private let rxViewSetting: BehaviorRelay<DayScene.ViewSetting>
    private let disposeBag = DisposeBag()

    init(dayStore: DaySceneStore,
         rxViewSetting: BehaviorRelay<DayScene.ViewSetting>,
         userResolver: LarkContainer.UserResolver) {
        self.dayStore = dayStore
        self.rxViewSetting = rxViewSetting
        self.rxViewMode = .init(value: .day(daysPerScene: 3, isAlternateCalendarActive: true))
        self.rxTimeZoneText = .init(value: "")
        self.rxAdditionalTimeZoneText = .init(value: nil)
        self.userResolver = userResolver
        setupViewMode(fromInitializer: true)
        setupTimeZoneText(fromInitializer: true)
    }

    private var setupFlag = false
    func setup() {
        guard !setupFlag else { return }
        defer { setupFlag = true }
        setupViewMode(fromInitializer: false)
        setupTimeZoneText(fromInitializer: false)
        subscribeStoreState()
    }

}

// MARK: - Setup

extension DayHeaderViewModel {

    private func setupViewMode(fromInitializer: Bool) {
        let daysPerScene = dayStore.state.daysPerScene
        let updateViewMode = { [weak self] (firstWeekday: DaysOfWeek, isAlternateCalendarActive: Bool) in
            guard let self = self else { return }
            guard daysPerScene >= 1 else {
                DayScene.assertionFailure("daysPerScene should greater than or equal to 1")
                return
            }

            // viewMode 没变，直接返回
            if case .day(let curDaysPerScene, let curShowAlternateCalendar) = self.rxViewMode.value,
               curDaysPerScene == daysPerScene,
               curShowAlternateCalendar == isAlternateCalendarActive {
                return
            }
            if case .week(let curFirstWeekday, let curShowAlternateCalendar) = self.rxViewMode.value,
               daysPerScene == 1,
               curShowAlternateCalendar == isAlternateCalendarActive,
               curFirstWeekday == firstWeekday {
                return
            }
            let viewMode: DayHeaderViewController.ViewMode
            if daysPerScene == 1 {
                viewMode = .week(firstWeekDay: firstWeekday, isAlternateCalendarActive: isAlternateCalendarActive)
            } else {
                viewMode = .day(daysPerScene: daysPerScene, isAlternateCalendarActive: isAlternateCalendarActive)
            }
            self.rxViewMode.accept(viewMode)
        }

        if fromInitializer {
            // assiging viewMode for first time
            updateViewMode(rxViewSetting.value.firstWeekday, rxViewSetting.value.isAlternateCalendarActive)
            return
        }

        // binding viewMode. 三个自变量：每周的第一天、是否激活了农历
        let rxFirstWeekday = rxViewSetting.map({ $0.firstWeekday }).distinctUntilChanged()
        let rxIsAlternateCalendarActive = rxViewSetting
            .map { $0.isAlternateCalendarActive }
            .distinctUntilChanged()
        Observable.combineLatest(rxFirstWeekday, rxIsAlternateCalendarActive)
            .skip(1)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { (firstWeekday, isAlternateCalendarActive) in
                updateViewMode(firstWeekday, isAlternateCalendarActive)
            })
            .disposed(by: disposeBag)

    }

    private func setupTimeZoneText(fromInitializer: Bool) {
        guard CalConfig.isMultiTimeZone else {
            rxTimeZoneText.accept(nil)
            return
        }
        let transform = { (timeZone: TimeZone?, day: JulianDay) -> String? in
            guard let timeZone = timeZone else { return nil }
            let (year, month, day) = JulianDayUtil.yearMonthDay(from: day)
            var dateComps = DateComponents()
            dateComps.year = year
            dateComps.month = month
            dateComps.day = day
            dateComps.timeZone = .current
            dateComps.hour = 12
            dateComps.minute = 0
            dateComps.second = 0
            let date = Calendar.gregorianCalendar.date(from: dateComps) ?? Date()
            return timeZone.getGmtOffsetDescription(date: date)
        }
        if fromInitializer {
            rxTimeZoneText.accept(transform(dayStore.state.timeZoneModel.timeZone, dayStore.state.activeDay))
            if FeatureGating.additionalTimeZoneOption(userID: userResolver.userID) {
                rxAdditionalTimeZoneText.accept(transform(dayStore.state.additionalTimeZone?.timeZone, dayStore.state.activeDay))
            }
            return
        }
        let rxTimeZone = dayStore.rxValue(forKeyPath: \.timeZoneModel)
        let rxActiveDay = dayStore.rxValue(forKeyPath: \.activeDay)
        
        Observable.combineLatest(rxTimeZone, rxActiveDay)
            .distinctUntilChanged { (prev, next) -> Bool in
                if prev.0.timeZone.identifier != next.0.timeZone.identifier {
                    return false
                }
                if JulianDayUtil.someTimeZoneIdentifiersThatDoNotObserveDaylightSavingTime.contains(prev.0.timeZone.identifier) {
                    // 非夏令时时区，时区本身不变化的情况下，不关心 activeDay 的变化
                    return true
                }
                return false
            }
            .map { transform($0.timeZone, $1) }
            .observeOn(MainScheduler.instance)
            .bind(to: rxTimeZoneText)
            .disposed(by: disposeBag)
        
        if FeatureGating.additionalTimeZoneOption(userID: userResolver.userID) {
            let rxAdditionalTimeZone = dayStore.rxValue(forKeyPath: \.additionalTimeZone)
            Observable.combineLatest(rxAdditionalTimeZone, rxActiveDay)
                .distinctUntilChanged { (prev, next) -> Bool in
                    if prev.0?.timeZone.identifier != next.0?.timeZone.identifier {
                        return false
                    }
                    if JulianDayUtil.someTimeZoneIdentifiersThatDoNotObserveDaylightSavingTime.contains(prev.0?.timeZone.identifier ?? "") {
                        // 非夏令时时区，时区本身不变化的情况下，不关心 activeDay 的变化
                        return true
                    }
                    return false
                }
                .map { additionalTimeZone, activeDay -> String? in
                    return transform(additionalTimeZone?.timeZone, activeDay)
                }
                .observeOn(MainScheduler.instance)
                .bind(to: rxAdditionalTimeZoneText)
                .disposed(by: disposeBag)
        }
    }

}

// MARK: - Responds To DaySceneState

extension DayHeaderViewModel {

    private func subscribeStoreState() {
        subscribeActiveDay()
        subscribeCurrentDay()
    }

    // 订阅 DaySceneState#activeDay，更新日视图（weekMode）的选中状态
    private func subscribeActiveDay() {
        guard dayStore.state.daysPerScene == 1 else { return }

        var lastActiveDay = dayStore.state.activeDay
        dayStore.rxValue(forKeyPath: \.activeDay)
            .distinctUntilChanged()
            .skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] newActiveDay in
                guard let self = self else { return }
                defer { lastActiveDay = newActiveDay }
                let lastPage = self.pageIndexForWeekMode(from: lastActiveDay)
                let newPage = self.pageIndexForWeekMode(from: newActiveDay)
                self.rxWeekViewDataUpdate.pageAt.onNext(lastPage)
                self.rxWeekViewDataUpdate.pageAt.onNext(newPage)
            })
            .disposed(by: disposeBag)

    }

    // 订阅 DaySceneState#currentDay，更新 page view data
    private func subscribeCurrentDay() {
        dayStore.rxValue(forKeyPath: \.currentDay)
            .distinctUntilChanged()
            .skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                switch self.rxViewMode.value {
                case .week:
                    self.rxWeekViewDataUpdate.allPages.onNext(())
                case .day:
                    self.rxDayViewDataUpdate.allPages.onNext(())
                }
            })
            .disposed(by: disposeBag)
    }

}

// MARK: - ViewData for Day Mode

extension DayHeaderViewModel {

    fileprivate struct DayItemData: DayHeaderDayViewDataType {
        var weekText: String
        var dayText: String
        var alternateDayText: String?
        var status: JulianDayStatus = .today
    }

    @inline(__always)
    func todayJulianDay() -> JulianDay {
        return dayStore.state.currentDay
    }

    func activeJulianDay() -> JulianDay {
        return dayStore.state.activeDay
    }

    private func alternateDayText(from julianDay: JulianDay) -> String? {
        let viewSetting = rxViewSetting.value
        guard viewSetting.isAlternateCalendarActive,
            julianDay >= JulianDayUtil.julianDayFrom1900_01_01 else {
            return nil
        }
        let alternateCal = viewSetting.alternateCalendar ?? viewSetting.defaultAlternateCalendar
        return AlternateCalendarUtil.getDisplayElement(julianDay: julianDay, type: alternateCal)
    }

    // 根据 dayPage 返回 dayView 的 viewData
    func dayViewData(forDayPage pageIndex: PageIndex) -> DayHeaderDayViewDataType? {
        let julianDay = DayScene.julianDay(from: pageIndex)
        let day = JulianDayUtil.yearMonthDay(from: julianDay).day
        let weekday = JulianDayUtil.weekday(from: julianDay).rawValue
        return DayItemData(
            weekText: TimeFormatUtils.weekdayShortString(weekday: weekday),
            dayText: String(day),
            alternateDayText: alternateDayText(from: julianDay),
            status: .make(from: julianDay, to: todayJulianDay())
        )
    }

}

// MARK: - ViewData for Week Mode

extension DayHeaderViewModel.DayItemData: DayHeaderWeekItemDataType { }

extension DayHeaderViewModel {

    fileprivate struct WeekViewData: DayHeaderWeekViewDataType {
        var dataArr: [DayItemData]
        var pageIndex: PageIndex
        var activeIndex: Int?
        var items: [DayHeaderWeekItemDataType] { dataArr }
    }

    // MARK: JulianDay <-> PageIndex

    func pageIndexForDayMode(from julianDay: JulianDay) -> PageIndex {
        return DayScene.pageIndex(from: julianDay)
    }

    private func baseJulianDayForWeekMode() -> JulianDay {
        let firstWeekday: EKWeekday
        if let weekday = EKWeekday(rawValue: rxViewSetting.value.firstWeekday.rawValue) {
            firstWeekday = weekday
        } else {
            DayScene.assertionFailure()
            firstWeekday = .sunday
        }
        return DayScene.julianDayRange(inSameWeekAs: DayScene.baseJulianDay, with: firstWeekday).lowerBound
    }

    func pageIndexForWeekMode(from julianDay: JulianDay) -> PageIndex {
        return (julianDay - baseJulianDayForWeekMode()) / 7
    }

    func julianDayForWeekMode(from pageIndex: PageIndex, at itemIndex: Int) -> JulianDay {
        return baseJulianDayForWeekMode() + pageIndex * 7 + itemIndex
    }

    // 根据 weekPage 返回 weekView 的 viewData
    func weekViewData(forWeekPage weekPage: PageIndex) -> DayHeaderWeekViewDataType {
        let fromDay = baseJulianDayForWeekMode() + 7 * max(0, weekPage)
        let jdRange = fromDay..<7 + fromDay
        let items = jdRange.map { julianDay -> DayItemData in
            let weekday = JulianDayUtil.weekday(from: julianDay).rawValue
            let day = JulianDayUtil.yearMonthDay(from: julianDay).day
            return DayItemData(
                weekText: TimeFormatUtils.weekdayAbbrString(weekday: weekday),
                dayText: String(day),
                alternateDayText: alternateDayText(from: julianDay),
                status: .make(from: julianDay, to: todayJulianDay())
            )
        }
        let activeJD = activeJulianDay()
        return WeekViewData(
            dataArr: items,
            pageIndex: weekPage,
            activeIndex: jdRange.contains(activeJD) ? activeJD - jdRange.lowerBound : nil
        )
    }

}
