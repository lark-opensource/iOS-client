//
//  DayAllDayViewModel.swift
//  Calendar
//
//  Created by 张威 on 2020/7/14.
//  Copyright © 2020 ByteDance. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import EventKit
import LarkContainer

/// DayScene - AllDay - ViewModel

final class DayAllDayViewModel: UserResolverWrapper {
    typealias Section = Int
    typealias ItemDrawRectFunc = (_ pageCount: Int) -> CGRect

    let dayStore: DaySceneStore

    // MARK: State From ViewController

    // visiblePageRange
    let rxVisiblePageRange = BehaviorRelay(value: 0..<1)
    let rxAdditionalTimeZoneRelay: BehaviorRelay<Void> = .init(value: ())

    // 根据 pageCount 获取 itemView 的 rect
    var rxItemDrawRectFunc = BehaviorRelay(value: ItemDrawRectFunc?.none)

    // MARK: ViewData

    // All viewData Rx properties published in main thread

    // 控制展开按钮（是否该显示，是否展开）
    let rxExpandViewData = BehaviorRelay(value: (shouldShow: false, isExpand: false))

    // 刷新
    let rxUpdate = (
        // 更新 section
        sectionAt: PublishSubject<Section>(),
        // 全量刷新
        allSections: PublishSubject<Void>()
    )

    private(set) var pageConfiguration: DayAllDayPageView.Configuration

    // MARK: Private Properties

    private let viewDataScheduler = ConcurrentDispatchQueueScheduler(qos: .userInteractive)

    // dependencies
    private let instanceSource: DayAllDayInstanceSource
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarSelectTracer: CalendarSelectTracer?
    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var timeDataService: TimeDataService?

    private let rxViewSetting: BehaviorRelay<DayScene.ViewSetting>
    private lazy var rxTimeBlocksChange: Observable<Void> = timeDataService?.rxTimeBlocksChange ?? .empty()

    let userResolver: UserResolver

    // 描述可用的 viewData 版本
    private var targetViewDataVersion = 0

    private var needsUpdateExpandHidden = false

    // 已经被 vc 请求过的 SectionViewData，最多维护 10 个
    private var loadedSectionData = (
        maxCount: 10,
        storage: [(section: Int, viewData: SectionViewData)]()
    )

    // 冷启动结束了
    private var rxFinishColdLaunch = PublishSubject<Void>()

    private lazy var viewDataManager = ViewDataManager(
        timeZone: dayStore.state.timeZoneModel.timeZone,
        currentDay: dayStore.state.currentDay,
        viewSetting: rxViewSetting.value,
        calendarGetter: { [weak self] in self?.calendarManager?.calendar(with: $0) },
        itemDrawRectFunc: { [weak self] in self?.rxItemDrawRectFunc.value?($0) ?? CGRect.zero }
    )

    private let disposeBag = DisposeBag()

    init(
        userResolver: UserResolver,
        dayStore: DaySceneStore,
        instanceSource: DayAllDayInstanceSource,
        rxViewSetting: BehaviorRelay<DayScene.ViewSetting>
    ) {
        self.userResolver = userResolver
        self.dayStore = dayStore
        self.instanceSource = instanceSource
        self.rxViewSetting = rxViewSetting
        self.pageConfiguration = Self.calPageConfiguration(with: rxViewSetting.value.firstWeekday,
                                                           and: dayStore.state.daysPerScene)
    }

    private var setupFlag = false
    func setup() {
        guard !setupFlag else { return }
        defer { setupFlag = true }
        setupReload()
    }

    func didFinishColdLaunch() {
        rxFinishColdLaunch.onNext(())
    }

}

// MARK: - Setup Reload

extension DayAllDayViewModel {

    private static func calPageConfiguration(with firstWeekday: DaysOfWeek, and daysPerScene: Int) -> DayAllDayPageView.Configuration {
        let firstWeekday = EKWeekday(rawValue: firstWeekday.rawValue) ?? .sunday
        if daysPerScene <= 1 {
            // 日视图
            return .init(
                getSectionByPage: { $0 },
                getPageRangeFromSection: { $0..<$0 + 1 }
            )
        } else {
            // 三日/周视图
            let baseDay = DayScene.baseJulianDay
            let baseDayRange = DayScene.julianDayRange(inSameWeekAs: baseDay, with: firstWeekday)
            return .init(
                getSectionByPage: { page in
                    return (page + baseDay - baseDayRange.lowerBound) / DayScene.daysPerWeek
                },
                getPageRangeFromSection: { section in
                    let lowerBound = baseDayRange.lowerBound - baseDay + section * DayScene.daysPerWeek
                    return lowerBound..<lowerBound + DayScene.daysPerWeek
                }
            )
        }
    }

    // Reload 触发源：
    //  - expand 显隐变化
    //  - currentDay 变化
    //  - 时区变化
    //  - drawRect 变化
    //  - instanceSource 变更
    //  - 冷启动结束
    //  - ViewSetting
    //      - 每周的第一天变化
    //      - 深浅皮肤
    //      - 过去日程是否显示蒙白
    private func setupReload() {
        // 准备 SectionViewData
        let rxPrepareViewData = { [weak self] () -> Observable<Void> in
            guard let self = self else { return .just(()) }
            let visiblePageRange = self.rxVisiblePageRange.value
            let getSectionByPage = self.pageConfiguration.getSectionByPage
            let lowerSection = getSectionByPage(visiblePageRange.lowerBound)
            let upperSection = getSectionByPage(visiblePageRange.upperBound - 1)
            let closedSectionRange = lowerSection...max(lowerSection, upperSection)
            return self.prepareSectionViewData(for: closedSectionRange).asObservable().map { _ in () }.catchErrorJustReturn(())
        }

        // 触发 sectionReload
        let doUpdateAllSection = { [weak self] () -> Void in
            DayScene.logger.info("AllDay publish reload event")
            self?.rxUpdate.allSections.onNext(())
        }

        // expand 变更：直接触发
        rxExpandViewData.map { $0.isExpand }
            .distinctUntilChanged()
            .skip(1)
            .subscribe(onNext: { _ in doUpdateAllSection() })
            .disposed(by: disposeBag)

        // CurrentDay 变化: 基于现有 cache 更新 currentDay -> 触发 pageReload
        dayStore.rxValue(forKeyPath: \.currentDay).asObservable()
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] currentDay in
                DayScene.logger.info("currentDay Changed, newValue: \(currentDay)")
                self?.viewDataManager.updateCurrentDay(currentDay)
            })
            .map { _ in () }
            .skipWhile { [weak self] in
                guard let self = self else { return false }
                return !self.rxViewSetting.value.showCoverPassEvent
            }
            .flatMap(rxPrepareViewData)
            .subscribe(onNext: doUpdateAllSection)
            .disposed(by: disposeBag)

        // 时区变化：更新 Cache 时区（清除缓存） -> 重新准备 SectionViewData -> 触发 pageReload
        dayStore.rxValue(forKeyPath: \.timeZoneModel).asObservable()
            .observeOn(MainScheduler.instance)
            .filter { [weak self] timeZoneModel -> Bool in
                guard let self = self else { return false }
                let timeZone = timeZoneModel.timeZone
                return self.viewDataManager.timeZone.identifier != timeZone.identifier
            }
            .do(onNext: { [weak self] timeZoneModel in
                let timeZone = timeZoneModel.timeZone
                DayScene.logger.info("timeZone Changed, newValue: \(timeZone.identifier)")
                self?.viewDataManager.updateTimeZone(timeZone)
                self?.targetViewDataVersion += 1
            })
            .map { _ in () }
            .flatMap(rxPrepareViewData)
            .subscribe(onNext: doUpdateAllSection)
            .disposed(by: disposeBag)

        if FeatureGating.additionalTimeZoneOption(userID: userResolver.userID) {
            dayStore.rxValue(forKeyPath: \.additionalTimeZone)
                .distinctUntilChanged()
                .observeOn(MainScheduler.instance)
                .map { _ in () }
                .bind(to: rxAdditionalTimeZoneRelay)
                .disposed(by: disposeBag)
        }

        // PageDrawRect 变化：清除缓存 -> 重新准备 PageViewData -> 触发 pageReload
        rxItemDrawRectFunc.asObservable()
            .skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] _ in
                DayScene.logger.info("ItemDrawRectFuncChanged")
                self?.viewDataManager.dropAllSectionViewData()
                self?.targetViewDataVersion += 1
            })
            .map { _ in () }
            .flatMap(rxPrepareViewData)
            .subscribe(onNext: doUpdateAllSection)
            .disposed(by: disposeBag)

        // InstanceSource Updated: 重新准备 PageViewData -> 触发 pageReload
        // 此过程不清除缓存（基于之前的缓存准备 PageViewData 效率会更高）
        instanceSource.rxAllDayInstanceUpdated
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] _ in
                DayScene.logger.info("AllDayInstanceUpdated")
                self?.targetViewDataVersion += 1
            })
            .map { _ in () }
            .flatMap(rxPrepareViewData)
            .subscribe(onNext: doUpdateAllSection)
            .disposed(by: disposeBag)

        // ViewSetting 变化: 基于现有 cache 更新 viewSetting -> 触发 pageReload
        // 此过程不清除缓存、不重新拉数据，基于现有 cached 数据重新构建 PageViewData，这不是一个耗时逻辑
        let isSingleDay = dayStore.state.daysPerScene <= 1
        var lastFirstWeekday = rxViewSetting.value.firstWeekday
        rxViewSetting
            .observeOn(MainScheduler.asyncInstance)
            .filter { [weak self] new -> Bool in
                guard let old = self?.viewDataManager.viewSetting else { return false }
                var ret = old.skinTypeIos != new.skinTypeIos || old.showCoverPassEvent != new.showCoverPassEvent
                if !isSingleDay {
                    // 日视图不关心 firstWeekday，其他视图关心
                    ret = ret || old.firstWeekday != new.firstWeekday
                }
                return ret
            }
            .do(onNext: { [weak self] viewSetting in
                guard let self = self else { return }
                if lastFirstWeekday != viewSetting.firstWeekday {
                    self.pageConfiguration = Self.calPageConfiguration(with: viewSetting.firstWeekday, and: self.dayStore.state.daysPerScene)
                    self.viewDataManager.dropAllSectionViewData()
                }
                lastFirstWeekday = viewSetting.firstWeekday
            })
            .subscribe(onNext: { [weak self] viewSetting in
                DayScene.logger.info("viewSetting changed, update view data cache, and publish rxUpdate.allSections event")
                self?.viewDataManager.updateViewSetting(viewSetting)
                self?.rxUpdate.allSections.onNext(())
            })
            .disposed(by: disposeBag)

        rxFinishColdLaunch
            .take(1)
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] _ in
                DayScene.logger.info("didFinish Cold Launch")
                self?.targetViewDataVersion += 1
            })
            .map { _ in () }
            .flatMap(rxPrepareViewData)
            .subscribe(onNext: doUpdateAllSection)
            .disposed(by: disposeBag)
        
        rxTimeBlocksChange
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] _ in
                DayScene.logger.info("allDay rxTimeBlocksChange")
                self?.targetViewDataVersion += 1
            })
            .map { _ in () }
            .flatMap(rxPrepareViewData)
            .subscribe(onNext: doUpdateAllSection)
            .disposed(by: disposeBag)
    }

}

// MARK: - ViewAction

extension DayAllDayViewModel {

    // MARK: Toggle Expand

    // 翻转 expand 状态
    func toggleExpand() {
        var value = rxExpandViewData.value
        value.isExpand = !value.isExpand
        rxExpandViewData.accept(value)
    }

    // 更新 expand 的显隐
    func updateExpandHidden() {
        guard !needsUpdateExpandHidden else { return }
        needsUpdateExpandHidden = true
        DispatchQueue.main.async {
            self.doUpdateExpandHidden()
            self.needsUpdateExpandHidden = false
        }
    }

    private func doUpdateExpandHidden() {
        let visiblePageRange = rxVisiblePageRange.value
        let startSection = pageConfiguration.getSectionByPage(visiblePageRange.lowerBound)
        let endSection = pageConfiguration.getSectionByPage(visiblePageRange.upperBound - 1)
        let visibleSections = startSection...max(startSection, endSection)
        let showExpandButton = loadedSectionData.storage
            .filter { visibleSections.contains($0.section) }
            .flatMap { tuple -> [CollapsedTip] in
                tuple.viewData.collapsedItems.compactMap { item -> CollapsedTip? in
                    guard case .collapsedTip(let tip) = item else {
                        return nil
                    }
                    return tip
                }
            }
            .contains(where: { $0.layout.pageRange.overlaps(visiblePageRange) })
        var expandViewData = rxExpandViewData.value
        guard expandViewData.shouldShow != showExpandButton else {
            return
        }
        expandViewData.shouldShow = showExpandButton
        rxExpandViewData.accept(expandViewData)
    }

    func model(forUniqueId uniqueId: String) -> BlockDataProtocol? {
        let items = loadedSectionData.storage.flatMap {
            return $0.viewData.expandedItems
        }
        for item in items {
            if case .instanceViewData(let viewData) = item,
                viewData.uniqueId == uniqueId {
                if let data = viewData as? InstanceViewData {
                    return data.instance
                } else if let data = viewData as? TimeBlockViewData {
                    return data.timeBlockData
                }
            }
        }
        return nil
    }

    // MARK: Get Instance By UniqueId
    func instance(forUniqueId uniqueId: String) -> Instance? {
        let items = loadedSectionData.storage.flatMap {
            return $0.viewData.expandedItems
        }
        for item in items {
            if case .instanceViewData(let viewData) = item,
               let data = viewData as? InstanceViewData,
                viewData.uniqueId == uniqueId {
                return data.instance
            }
        }
        return nil
    }

}

// MARK: - PageItem

extension DayAllDayViewModel {

    // MARK: Generate PageItems

    /// `pageItems(in:)` 返回值
    enum PageItemsReturn {
        // 立即返回的 sectionItems
        case value([SectionItem])
        // 请求中的 disposable
        case requesting(disposable: Disposable, placeholder: [SectionItem])
    }

    func pageItems(in section: Int) -> PageItemsReturn {
        assert(Thread.isMainThread)

        let cached = viewDataManager.sectionViewData(
            in: section,
            timeZone: dayStore.state.timeZoneModel.timeZone
        )
        var items: [SectionItem] = []
        if let sectionViewData = cached?.sectionViewData {
            if let index = loadedSectionData.storage.lastIndex(where: { $0.section == section }) {
                loadedSectionData.storage[index] = (section: section, viewData: sectionViewData)
            } else {
                loadedSectionData.storage.append((section: section, viewData: sectionViewData))
                if loadedSectionData.storage.count > loadedSectionData.maxCount {
                    _ = loadedSectionData.storage.dropFirst()
                }
            }
            items = rxExpandViewData.value.isExpand ? sectionViewData.expandedItems : sectionViewData.collapsedItems
        }
        if cached?.version == targetViewDataVersion {
            return .value(items)
        } else {
            let disposable = prepareSectionViewData(for: section...section)
                .subscribe(onSuccess: { [weak self] _ in self?.rxUpdate.sectionAt.onNext(section) })
            disposable.disposed(by: disposeBag)
            // 请求中用 cached.pageViewData 作为 placeholder data，避免闪烁
            return .requesting(disposable: disposable, placeholder: items)
        }
    }

}

// MARK: Prepare/Cache for SectionViewData

extension DayAllDayViewModel {

    private typealias SectionRange = (section: Int, pageRange: PageRange, dayRange: JulianDayRange)

    private func makeSectionViewData(
        from layoutedInstances: [DayAllDayLayoutedInstance],
        for sectionRanges: [SectionRange]
    ) -> [Int: SectionViewData] {
        var ret = [Int: SectionViewData]()
        for sectionRange in sectionRanges {
            let (section, pageRange, dayRange) = sectionRange
            let filtered = layoutedInstances.filter { ls in
                let dayRange = ls.dayRange
                let pr = DayScene.pageRange(from: dayRange)
                return pr.overlaps(pageRange)
            }
            ret[section] = viewDataManager.makeSectionViewData(
                from: filtered.map { $0.instance },
                clampedTo: dayRange,
                in: section
            )
        }
        return ret
    }

    // 根据 sections 准备 SectionViewData
    //  - 回调在主线程触发
    //  - 准备的 viewData 存到 cache 中
    //  - 拉取 instance，失败了会尝试 3 次
    private func prepareSectionViewData(for sections: ClosedRange<Int>) -> Single<[Int: SectionViewData]> {
        let version = targetViewDataVersion

        guard rxItemDrawRectFunc.value != nil else {
            var sectionViewDataMap = [Int: SectionViewData]()
            for section in sections {
                sectionViewDataMap[section] = SectionViewData(expandedItems: [], collapsedItems: [])
            }
            return Observable.just(sectionViewDataMap)
                .asSingle()
                .observeOn(MainScheduler.asyncInstance)
        }

        var sectionRanges = [(section: Int, pageRange: PageRange, dayRange: JulianDayRange)]()
        sections.forEach { section in
            let pageRange = self.pageConfiguration.getPageRangeFromSection(section)
            let dayRange = DayScene.julianDayRange(from: pageRange)
            sectionRanges.append((section: section, pageRange: pageRange, dayRange: dayRange))
        }

        let timeZone = dayStore.state.timeZoneModel.timeZone
        let fromPage = pageConfiguration.getPageRangeFromSection(sections.lowerBound).lowerBound
        let toPage = pageConfiguration.getPageRangeFromSection(sections.upperBound).upperBound
        let loadDataDayRange = DayScene.julianDayRange(from: fromPage..<toPage)

        let rxInstances: Single<[DayAllDayLayoutedInstance]>
        let ret = instanceSource.rxAllDayInstances(for: .init(loadDataDayRange, .init()), in: timeZone)
        switch ret {
        case .value(let layoutedInstances):
            rxInstances = Observable.just(layoutedInstances).asSingle()
        case .rxValue(let rx):
            rxInstances = rx
        }

        return rxInstances.retry(3)
            .subscribeOn(viewDataScheduler)
            .map { [weak self] layoutedInstances -> [Int: SectionViewData] in
                guard let self = self else { return .init() }
                return self.makeSectionViewData(from: layoutedInstances, for: sectionRanges)
            }
            .observeOn(MainScheduler.asyncInstance)
            .do(
                onSuccess: { [weak self] sectionViewDataMap in
                    sectionViewDataMap.forEach { tuple in
                        let (section, sectionViewData) = tuple
                        self?.viewDataManager.updateSectionViewData(
                            sectionViewData,
                            in: section,
                            version: version
                        )
                    }
                },
                onError: { err in
                    DayScene.assert(
                        false,
                        "prepareSectionViewData failed. dayRange: \(loadDataDayRange), err: \(err)",
                        type: .prepareAllDayViewDataFailed
                    )
                }
            )
    }

}

// MARK: - Cold Launch

extension DayAllDayViewModel {

    /// 冷启动 viewData
    func rxColdLaunchViewData(with context: HomeScene.ColdLaunchContext) -> Single<[Int: SectionViewData]> {
        assert(Thread.isMainThread)
        let ret = instanceSource.rxAllDayInstances(for: .init(context.dayRange, .init()), in: context.timeZone, fromColdLaunch: true)
        let rxLayoutedInstances: Single<[DayAllDayLayoutedInstance]>
        switch ret {
        case .value(let layoutedInstances):
            rxLayoutedInstances = Observable.just(layoutedInstances).asSingle()
        case .rxValue(let rx):
            rxLayoutedInstances = rx
        }

        // calculate sectionRanges
        let pageConf = Self.calPageConfiguration(with: context.viewSetting.firstWeekday, and: dayStore.state.daysPerScene)
        let lowerSection = pageConf.getSectionByPage(context.dayRange.lowerBound)
        let upperSection = pageConf.getSectionByPage(context.dayRange.upperBound - 1)
        let sectionRanges = (lowerSection...upperSection).map { section -> SectionRange in
            let pageRange = pageConf.getPageRangeFromSection(section)
            let dayRange = DayScene.julianDayRange(from: pageRange)
            return (section: section, pageRange: pageRange, dayRange: dayRange)
        }

        let tracker = HomeScene.coldLaunchTracker
        return rxLayoutedInstances
            .observeOn(MainScheduler.instance)
            .map { [weak self] dayInstances in
                guard let self = self else { return .init() }

                let startTime = CACurrentMediaTime()
                defer {
                    let cost = CACurrentMediaTime() - startTime
                    tracker?.addStage(.makeAllDayViewData, with: cost)
                    tracker?.setValue(dayInstances.count, forMetricKey: .allDayInstanceCount)
                }

                return self.makeSectionViewData(from: dayInstances, for: sectionRanges)
            }
    }

}
