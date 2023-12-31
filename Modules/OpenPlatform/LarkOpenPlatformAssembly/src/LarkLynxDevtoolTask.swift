//
//  LarkLynxDevtoolTask.swift
//  Lark
//
//  Created by ChenMengqi on 2022/1/24.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import BootManager
import Lynx
import LarkDebugExtensionPoint
import LKLoadable
import LKCommonsLogging
#if canImport(DebugRouter)
import DebugRouter
#endif

final class LarkLynxDevtoolTask: UserFlowBootTask, Identifiable {
    static var identify: TaskIdentify = "LarkLynxDevtoolTask"
    override var runOnlyOnce: Bool {
        return true
    }

	static let logger = Logger.log(LarkLynxDevtoolTask.self, category: "LarkLynxDevtoolTask")

    override func execute(_ context: BootContext) {
        #if IS_LYNX_DEVTOOL_OPEN
		Self.logger.info("start LarkLynxDevtoolTask task for devtool open")
        // 关闭全局devtool开关
        LynxEnv.sharedInstance().devtoolEnabled = false
		// 禁用红屏
		LynxEnv.sharedInstance().redBoxEnabled = false
        //打开lynxview级devtool
        LynxEnv.sharedInstance().devtoolEnabledForDebuggableView = true
        // 禁用chrome本地调试模式
        LynxEnv.sharedInstance().setDevtool(false, forKey: SP_KEY_ENABLE_LONG_PRESS_MENU)
        // devtool DOM / CSS / Page domain全量开放，其他domain屏蔽
        LynxEnv.sharedInstance().setDevtool(true, forKey: SP_KEY_ENABLE_CDP_DOMAIN_DOM)
        LynxEnv.sharedInstance().setDevtool(true, forKey: SP_KEY_ENABLE_CDP_DOMAIN_CSS)
        LynxEnv.sharedInstance().setDevtool(true, forKey: SP_KEY_ENABLE_CDP_DOMAIN_PAGE)
        // 禁用断链后自动重连
        DebugRouter.instance().setConfig(true, forKey: "debugrouter_forbid_reconnect_on_close")
        #elseif ALPHA
		Self.logger.info("start LarkLynxDevtoolTask task for alpha")
        LynxDebugItem.syncLynxDevtoolState()
        #endif
    }
}

#if ALPHA
let devtoolEnableKey = "lark.lynx.devtool"

struct LynxDebugItem: DebugCellItem {

    let title: String = "Lynx Devtool"

    let type: LarkDebugExtensionPoint.DebugCellType = .switchButton

    var isSwitchButtonOn: Bool {
        UserDefaults.standard.bool(forKey: devtoolEnableKey)
    }

    let switchValueDidChange: ((Bool) -> Void)? = { (isOn: Bool) in
        UserDefaults.standard.set(isOn, forKey: devtoolEnableKey)
        LynxDebugItem.syncLynxDevtoolState()
    }

    static func syncLynxDevtoolState() {
        let devtoolEnable = UserDefaults.standard.bool(forKey: devtoolEnableKey)
        LynxEnv.sharedInstance().devtoolEnabled = devtoolEnable
        LynxEnv.sharedInstance().redBoxEnabled = devtoolEnable
    }
}
#endif
