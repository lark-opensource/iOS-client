//
//  LarkDowngradeAssembly.swift
//  LarkDowngradeDependency
//
//  Created by ByteDance on 2023/5/4.
//

import Foundation
import BootManager
import LarkAssembler
import LarkSetting
import LarkDowngrade
import LarkContainer

public final class LarkDowngradeAssembly: LarkAssemblyInterface {
    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(LarkDowngradeTask.self)
    }
}

/*
 降级Task
*/
final class LarkDowngradeTask: FlowBootTask, Identifiable {

    override var runOnlyOnce: Bool { return true }

    static var identify: TaskIdentify = "LarkDowngradeTask"

    /// 日志
    // private let logger = Logger.log(LarkDowngradeTask.self, category: "LarkDowngradeTask")

    override func execute(_ context: BootContext) {
        
        //读取设备评分
        _ = SettingManager.shared.observe(key: .make(userKeyLiteral: "get_device_classify"))
            .subscribe(onNext: { (value) in
                if let device_score = value["cur_device_score"] as? Double {
                    if device_score > 0 {
                        LarkDowngradeService.shared.deviceScore = Double(device_score)
                        LarkUniversalDowngradeService.shared.deviceScore = Double(device_score)
                    }
                }
            })
        //读取setting
        _ = SettingManager.shared.observe(key: .make(userKeyLiteral: "lark_ios_downgrade_config"))
            .subscribe(onNext: { (value) in
                LarkDowngradeService.shared.updateWithDic(dictionary: value)
            })
        
        _ = SettingManager.shared.observe(key: .make(userKeyLiteral: "lark_ios_universal_downgrade_config"))
            .subscribe(onNext: { (value) in
                LarkUniversalDowngradeService.shared.updateWithDic(dictionary: value)
            })
        //开始监听
        LarkDowngradeService.shared.Start()
        LarkPerformanceAppStatues.shared.startCollectData()
      
    }
}
