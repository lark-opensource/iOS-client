//
//  BlockFGKey.swift
//  OPBlockInterface
//
//  Created by Meng on 2023/3/20.
//

import Foundation
import LarkSetting

public enum BlockFGKey: String {
    /// 用户态隔离改造
    case userScopeFG = "ios.container.scope.user.block"

    /// 超时改造
    case enableTimeoutOptimize = "openplatform.blockit.timeout_optimize"

    case enableBasicLibVersionCheck = "openplatform.blockit.basic_lib_version_check"

    case enableLoadAsync = "openplatform.blockit.load.async.enable"

    /// 相同 BlockTypeID 的 Block 的 lynx view 共享上下文
    case enableMultiContext = "openplatform.block.enable.multicontext"

    /// 是否支持工作台首页 Block 添加 Console 菜单项
    case enableBlockConsole = "openplatform.workplace.block.console"

    case enableWebImage = "openplatform.blockit.webimage"

    // block picker支持配置显示层级（显示在window上或显示在当前vc）
    case enableShowPickerInWindow = "openplatform.block.show_picker_in_window"

    // block 加载component流程是否不依赖lynx渲染结果（与Android端对齐）
    case enableFixComponentFinish = "openplatform.block.fix_component_finish"

    case enableOfflineWKURLSchemaHandler = "openplatform.offline.wkurlschemehandler"
    case enableOfflineUseFallback = "openplatform.offline.usefallback"

    public var key: FeatureGatingManager.Key {
        FeatureGatingManager.Key(stringLiteral: rawValue)
    }
}
