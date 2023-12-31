//
//  LarkOpenPlatformMyAIService.swift
//  LarkOPInterface
//
//  Created by ByteDance on 2023/5/29.
//

import Foundation
import ECOProbe
import EENavigator
import LarkTab
import LarkQuickLaunchBar
import LarkQuickLaunchInterface


public enum OPAIChatThreadState : Int {
    public typealias RawValue = Int
    
    case unknownState
    case `open`
    case closed
    
    public init() {
      self = .unknownState
    }

    public init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .unknownState
      case 1: self = .open
      case 2: self = .closed
      default: return nil
      }
    }

    public var rawValue: Int {
      switch self {
      case .unknownState: return 0
      case .open: return 1
      case .closed: return 2
      }
    }
}

public enum OPMyAIQuickLaunchBarExtraItemType {
    case ai
    case more
}

public typealias OPMyAIQuickLaunchBarEventHandler = ((OPMyAIQuickLaunchBarExtraItemType) -> Void)



public protocol LarkOpenPlatformMyAIService {
    
    // 功能开关接口,控制QuickLaunchBar是否展示, 关联fg key:lark.navigation.superapp
    func isQuickLaunchBarEnable() -> Bool
    
    // 创建MyAIQuickLaunchBar
    func createAIQuickLaunchBar(items: [QuickLaunchBarItem],
                                enableTitle: Bool,
                                enableAIItem: Bool,
                                quickLaunchBarEventHandler: OPMyAIQuickLaunchBarEventHandler?) -> MyAIQuickLaunchBarInterface?
    
    // 是否开启ipad标签页
    func isTemporaryEnabled() -> Bool
    
    // 展示tabvc(标签页)
    func showTabVC(_ vc: UIViewController)
    
    // 更新tabvc信息(标签页)
    func updateTabVC(_ vc: UIViewController)
    
    // 移除tabvc信息(标签页)
    func removeTabVC(_ vc: UIViewController)
}

extension OPMonitorCode {
    public static let myAIServiceNil = OPMonitorCode(domain: "client.open_platform.web.myai", code: 10000, level: OPMonitorLevelError, message: "my ai service is nil")
    
    public static let myAIQuickLaunchBarServiceNil = OPMonitorCode(domain: "client.open_platform.web.myai", code: 10001, level: OPMonitorLevelError, message: "my ai quicklaunchbar service is nil")
    
    // 域名级别私有api调用监控
    public static let myAIDataException = OPMonitorCode(domain: "client.open_platform.web.myai", code: 10002, level: OPMonitorLevelError, message: "data exception")
}
