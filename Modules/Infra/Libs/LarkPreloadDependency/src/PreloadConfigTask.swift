//
//  PreloadConfigTask.swift
//  LarkPreloadDependency
//
//  Created by huanglx on 2023/5/4.
//

import Foundation
import LarkSetting
import BootManager
import LarkFeatureGating
import RxSwift
import LarkPreload
import LarkDowngrade
import LarkPerf

class PreloadConfigTask: UserFlowBootTask, Identifiable {
    
    static var identify = "PreloadConfigTask"
    
    private static let disposeBag = DisposeBag()
    
    //监听settings变化，不释放。
    override var deamon: Bool { return true }
    
    override func execute(_ context: BootContext) {
        //预加载相关配置
        let preloadConfig = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "lark_preload_config"))
        let deviceClassify = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "get_device_classify"))
        let downgradeLaunchTask = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "lark_ios_downgrade_launch_task"))
        if LarkUniversalDowngradeService.shared.needDowngrade(key: "LaunchDowngradeTask", strategies: [.lowDevice()]) {
            if let delayLaunchTask = downgradeLaunchTask?["delayLaunchTask"] as? [String] {
                PreloadMananger.shared.needDelayTaskInLowDevice = delayLaunchTask
            }
            if let delayLaunchTask = downgradeLaunchTask?["removeLaunchTask"] as? [String] {
                PreloadMananger.shared.needRemoveTaskInLowDevice = delayLaunchTask
            }
            if let delayLaunchTask = downgradeLaunchTask?["delayRunloopTask"] as? [String] {
                PreloadMananger.shared.needDelayRunloopTaskInLowDevice = delayLaunchTask
            }
            if let delayLaunchTask = downgradeLaunchTask?["removeRunloopTask"] as? [String] {
                PreloadMananger.shared.needRemoveRunloopTaskInLowDevice = delayLaunchTask
            }
            
        }
        preloadConfig?.forEach({ (key, value) in
            PreloadSettingsManager.preloadConfig[key] = value
        })
        deviceClassify?.forEach({ (key, value) in
            PreloadSettingsManager.deviceClassify[key] = value
        })
        
        //预加载接入相关配置
        //启动时机的闲时任务，异步任务和runlooptools触发的任务由预加载触发。
        NewBootManager.shared.bootSchedulerByPreload =  userResolver.fg.staticFeatureGatingValue(with: "boot.scheduler.preload.enable")
        //配置runloopTools通过preload管理。 
        NewBootManager.shared.runloopDispatchByPreload()
        
        //注册监听器
        //注册启动一分钟监听器
        PreloadMananger.shared.registMomentTrigger(momentTrigger: StartOneMinuteMonitor())
        //注册CPU闲时监听
        PreloadMananger.shared.registMomentTrigger(momentTrigger: CpuIdleMonitor())
        
        //启动阶段CPU采集相关信息配置
        let bootCpuConfig = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "lark_boot_cpu_config"))
        bootCpuConfig?.forEach({ (key, value) in
            ColdStartCpuConfig.cpuConfig[key] = value
        })
    }
}
