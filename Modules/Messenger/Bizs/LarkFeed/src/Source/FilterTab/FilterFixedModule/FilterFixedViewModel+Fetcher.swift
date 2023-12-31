//
//  FilterFixedViewModel+Fetcher.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/8/18.
//

import UIKit
import Foundation
import RxSwift
import RustPB

extension FilterFixedViewModel {
    func getThreeColumnsSettings(tryLocal: Bool) {
        dependency.getThreeColumnsSettings(tryLocal: tryLocal)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] setting in
            guard let self = self else { return }
            self.updateFixedFilterSetting(setting, isPushHandler: false)
        }).disposed(by: disposeBag)
    }

    func getUnreadFeedsNum() {
        dependency.getUnreadFeedsNum()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] unreadNum in
                if unreadNum >= Cons.unreadNum {
                    self?.updateThreeColumnsSettings(scene: .enoughUnreadFeeds)
                }
        }).disposed(by: disposeBag)
    }

    func bind() {
        Observable.combineLatest(
            filterSettingShowDriver.asObservable(),
            dependency.commonlyFiltersDSDriver.asObservable()
        ).observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (showEnable, dataSource) in
            guard let self = self else { return }
            let isShow = showEnable && !dataSource.isEmpty
            FeedContext.log.info("feedlog/filter/fixedTab/bind. isShow: \(isShow), settingShow: \(showEnable), dataSourceCount: \(dataSource.count)")
            self.filterShowRelay.accept(isShow)
        }).disposed(by: disposeBag)

        dependency.pushFeedFixedFilterSettings?
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] settingModel in
                guard let self = self else { return }
                self.updateFixedFilterSetting(settingModel, isPushHandler: true)
            }).disposed(by: disposeBag)

        dependency.pushDynamicNetStatus?
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                self.netStatus = push.dynamicNetStatus
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                let showFilter = self.defaultShowFilter ?? false
                if !showFilter { // 未展示过的情况下才需要触发
                    self.getUnreadFeedsNum()
                }
            }).disposed(by: disposeBag)
    }

    /// 未读feed数达标 or 侧滑过分栏 or 创建标签时主动调用
    func updateThreeColumnsSettings(scene: Feed_V1_ThreeColumnsSetting.TriggerScene) -> Bool {
        if defaultShowFilter == nil || defaultShowFilter == false {
            // 常规自动展示固定分组栏逻辑
            localTrigger = true
            FeedContext.log.info("feedlog/threeColumns/updateSetting: Auto show success, scene: \(scene)")
            dependency.updateThreeColumnsSettings(showEnable: true, scene: scene).subscribe().disposed(by: disposeBag)
            return true
        }

        if defaultShowFilter == true, filterSetting?.pcShowEnable == false, scene == .createTag {
            // 移动端默认已展示固定分组，但pc端没有展示，触发了创建标签条件
            FeedContext.log.info("feedlog/threeColumns/updateSetting: Mobile has shown, update for pc, scene: \(scene)")
            dependency.updateThreeColumnsSettings(showEnable: true, scene: scene).subscribe().disposed(by: disposeBag)
            return true
        }
        return false
    }

    enum Cons {
        static let unreadNum: Int = 20
    }
}
