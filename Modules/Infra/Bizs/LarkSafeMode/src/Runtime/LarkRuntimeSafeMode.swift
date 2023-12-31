//
//  LarkRuntimeSafeMode.swift
//  LarkSafeMode
//
//  Created by luyz on 2022/11/4.
//

import Foundation
import LarkSetting
import LKCommonsLogging
import LKCommonsTracker

var RUNTIMECUSTOMEXCONFIG = UserSettingKey.make(userKeyLiteral: "custom_exception_config")
var RUNTIMELARKSAFEMODE: String = "lk_runtime_safe_mode"
var RUNTIMESAFEMODEKEY: String = "safe_mode_runtime"
var RUNTIMESAFEMODSTRATEGYEKEY: String = "lk_safe_mode_strategy"

class LarkRuntimeSafeMode {
    public func registerObserve() {
        _ = SettingManager.shared.observe(key: RUNTIMECUSTOMEXCONFIG)
            .subscribe(onNext: { value in
                guard let safeModeRuntime = value[RUNTIMESAFEMODEKEY] as? [String: Any] else { return }
                guard let safeModeStrategy = value[RUNTIMESAFEMODSTRATEGYEKEY] as? [String: Any] else { return }
                
                NotificationCenter.default.post(name: NSNotification.Name(RUNTIMESAFEMODSTRATEGYEKEY),
                                                object: safeModeStrategy,
                                                userInfo: nil)
            })
    }
}
