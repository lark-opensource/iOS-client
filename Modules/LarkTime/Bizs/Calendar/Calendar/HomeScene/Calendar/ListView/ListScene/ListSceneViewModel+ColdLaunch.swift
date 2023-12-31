//
//  ListSceneViewModel+ColdLaunch.swift
//  Calendar
//
//  Created by huoyunjie on 2022/8/22.
//

import UIKit
import Foundation
import RxSwift

// MARK: Cold Launch

extension ListSceneViewModel {

    func updateCellItemsWithColdLaunch() {
        guard let context = HomeScene.coldLaunchContext else { return }

        // 埋点：准备冷启动数据
        HomeScene.coldLaunchTracker?.insertPoint(.listScenePrepareViewData)

        // 冷启动 tableview 刷新方式
        let refreshType = BlockListRefreshType.scrollToDate(currentDate, false, true)

        // 冷启动数据资源管理
        var coldLaunchDataDisposable: Disposable?

        // 埋点：获取冷启动 instance 开始
        TimerMonitorHelper.shared.launchTimeTracer?.getInstance.start()
        let startTime1: CFTimeInterval = CACurrentMediaTime()
        switch getInstance(dayRange: context.dayRange, fromColdLaunch: true) {
        case .value(let data):
            // 冷启动场景不会有返回同步值的场景
            assertionFailure()
        case .preparing(rxFinalData: let rxData, temporaryData: let temporaryData):
//            self.cellItemsWillChangedRelay.accept((temporaryData, refreshType, self.currentDate, false))
            coldLaunchDataDisposable = rxData.asSingle()
                .subscribe(onSuccess: { [weak self] items in
                    ListScene.logInfo("list scene cold launch success!")

                    // 埋点：获取冷启动 instance 结束
                    var instanceCount = 0
                    items.values.forEach({ instanceCount += $0.count })
                    TimerMonitorHelper.shared.launchTimeTracer?.getInstance.end(extra: [.firstScreenInstancesLength: instanceCount])
                    HomeScene.coldLaunchTracker?.addStage(.requestListSceneInstance, with: CACurrentMediaTime() - startTime1)
                    HomeScene.coldLaunchTracker?.setValue(instanceCount, forMetricKey: .instanceCount)

                    self?.cellItemsWillChangedRelay.accept((items, refreshType, self?.currentDate, false))
                    self?.registerBlockUpdated() // 启动日程监听
                }, onError: { [weak self] _ in
                    guard let self = self else { return }
                    ListScene.logInfo("list scene cold launch failed!")
                    self.registerBlockUpdated() // 启动日程监听
                    self.updateCellItems(dayRange: context.dayRange, refreshType: refreshType, showEmptyDate: self.currentDate)
                    HomeScene.coldLaunchTracker?.finish(.failedForError)
                    TimerMonitorHelper.shared.launchTimeTracer?.getInstance.end(extra: [.firstScreenInstancesLength: 0])
                })
            coldLaunchDataDisposable?.disposed(by: self.disposeBag)
        }

        // Watch Dog. 800ms 还没完成冷启动，则强行结束
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
            guard let tracker = HomeScene.coldLaunchTracker else { return }
            ListScene.logInfo("list scene cold launch failed for time out!")
            coldLaunchDataDisposable?.dispose()
            tracker.finish(.failedForTimeout)
            self.registerBlockUpdated() // 启动日程监听
            self.updateCellItems(dayRange: context.dayRange, refreshType: refreshType, showEmptyDate: self.currentDate)
            TimerMonitorHelper.shared.launchTimeTracer?.getInstance.end(extra: [.firstScreenInstancesLength: 0])
        }
    }

    func makeColdLaunchRequest(dayRange: JulianDayRange) -> RxReturn<DayInstanceMap> {
        guard let context = HomeScene.coldLaunchContext else { return .value([:]) }

        // 从 instanceService 获取冷启动数据
        let rxColdLaunchInstances: Observable<ColdLaunchInstances>
        switch instanceService.rxColdLaunchInstance(for: .init(dayRange, .init()), in: timeZone) {
        case .value(let groupedInstances):
            rxColdLaunchInstances = .just(groupedInstances.value)
        case .rxValue(let _rxGroupedInstances):
            rxColdLaunchInstances = _rxGroupedInstances.map({ $0.value }).asObservable()
        }

        let single = rxColdLaunchInstances
            .do(onNext: { coldLaunchInstances in
                let instanceSource: String
                if coldLaunchInstances.isFromRust {
                    instanceSource = HomeScene.ColdLaunchCategory.instanceSourceValues.fromRust
                } else {
                    instanceSource = HomeScene.ColdLaunchCategory.instanceSourceValues.fromSnapshot
                }
                HomeScene.coldLaunchTracker?.setValue(instanceSource, forCategory: .instanceSource)
            }).map({ $0.instanceMap }).asSingle()
        return .rxValue(single)
    }

}
