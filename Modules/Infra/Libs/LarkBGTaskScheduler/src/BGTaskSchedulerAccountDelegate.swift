//
//  BGTaskSchedulerAccountDelegate.swift
//  LarkBaseService
//
//  Created by 李勇 on 2020/3/16.
//

import UIKit
import Foundation
import LarkAccountInterface
import Swinject
import LKCommonsTracker
import LarkBGTaskScheduler
import RunloopTools
import RxSwift
import LarkRustClient
import RustPB
import LarkContainer
import LarkKAFeatureSwitch

/// 是否启动BGTask 字节云平台配置项 https://cloud.bytedance.net/appSettings/config/119829/detail
public enum BGTaskConfig {
    public static let key = "bgtask_enable"
    /// BGTask可用时取值
    public static let enable = "enable"
}

/// 从User维度控制BGTask总开关
public final class BGTaskSchedulerAccountDelegate: PassportDelegate {
    public var name: String = "BGTaskSchedulerAccountDelegate"

    private var lastestUserID: String?
    private var hasAddedObserver: Bool = false

    public func userDidOnline(state: PassportState) {
        lastestUserID = state.user?.userID
        guard let user = state.user else { return }
        guard let userResolver = try? Container.shared.getUserResolver(userID: user.userID) else { return }

        if !hasAddedObserver {
            // 该通知只在 FeatureSwitch.share.bool(for: .ttAbTest) && 用户登陆/切换租户 才发出，此时一定有用户信息；
            // 详情见ABTestLaunchDelegate.updateABTestExperimentData()。
            if userResolver.fg.staticFeatureGatingValue(with: "tt_ab_test") {
                Tracker.registerFetchExperimentDataObserver(observer: self, selector: #selector(setEnableFromLibra))
            }
            hasAddedObserver = true
        }

        if case .switch = state.action { /// 切换租户
                // 如果为true则会转而执行finishFetchExperimentFromLibra
            if userResolver.fg.staticFeatureGatingValue(with: "tt_ab_test") { return }
            let rustService = try? userResolver.resolve(assert: RustService.self)
            RunloopDispatcher.shared.addTask(priority: 0.0) { self.setEnableFromSetting(rustService: rustService) }.waitCPUFree()
        }
    }

    /// 从Libra获取实验数据，设置enable参数
    @objc
    private func setEnableFromLibra() {
        guard let lastestUserID else { return }
        guard let userResolver = try? Container.shared.getUserResolver(userID: lastestUserID) else { return }
        // 从Libra获取实验值，并触发曝光
        let value = Tracker.experimentValue(key: BGTaskConfig.key, shouldExposure: true) as? String ?? ""
        // 获取不到说明：1、当前用户未命中该实验；2、实验已关闭。则需要从Setting平台获取兜底数据。
        if value.isEmpty {
            let rustService = try? userResolver.resolve(assert: RustService.self)
            setEnableFromSetting(rustService: rustService)
        } else {
            // 需要在主线程执行，因为UIApplication.setMinimumBackgroundFetchInterval()必须在主线程调用
            DispatchQueue.main.async { LarkBGTaskScheduler.shared.enable = (value == BGTaskConfig.enable) }
        }
    }

    /// 从Setting平台获取配置，设置enable参数
    func setEnableFromSetting(rustService: RustService?) {
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = [BGTaskConfig.key]
        _ = rustService?
            .sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
                response.fieldGroups
            })
            .subscribeOn(scheduler)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (fieldGroups) in
                let value = fieldGroups[BGTaskConfig.key]
                LarkBGTaskScheduler.shared.enable = (value == BGTaskConfig.enable)
            })
    }

    /// 退出登陆需要关闭BGTask
    public func afterLogout(_ context: LauncherContext) {
        // 需要在主线程执行，因为UIApplication.setMinimumBackgroundFetchInterval()必须在主线程调用
        DispatchQueue.main.async { LarkBGTaskScheduler.shared.enable = false }
    }
}
