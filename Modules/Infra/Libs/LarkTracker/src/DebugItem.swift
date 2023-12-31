//
//  DebugItem.swift
//  LarkTracker
//
//  Created by 王元洵 on 2022/9/19.
//

#if !LARK_NO_DEBUG

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

import Foundation
import RangersAppLog
import LarkDebugExtensionPoint

public struct ETTrackerDebugItem: DebugCellItem {

    private static let switcherKey = "tracker.et.switch"

    /// 默认开关不开启，如果开发者开启过，则本地保留配置
    /// 避免普通用户过多上传埋点 增加耗电
    static var isOn = (TrackService.appID == "462391" && UserDefaults.standard.bool(forKey: switcherKey)) {
        didSet { UserDefaults.standard.setValue(isOn, forKey: switcherKey) }
    }

    public let title: String = "ET 埋點验证"
    public let type = DebugCellType.switchButton

    public var isSwitchButtonOn: Bool { Self.isOn }

    public let switchValueDidChange: ((Bool) -> Void)? = {
        ETTrackerDebugItem.isOn = $0
        // 该API直接传false会有问题，要么不传，要么传true，但是该功能按需开启，这里为false可能性很小
        BDAutoTrack.setETEnable($0, withAppID: TrackService.appID)
    }

    public init() {}
}

#endif
