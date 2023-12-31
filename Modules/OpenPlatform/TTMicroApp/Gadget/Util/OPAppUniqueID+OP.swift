//
//  OPAppUniqueID+OP.swift
//  TTMicroApp
//
//  Created by yinyuan on 2021/7/18.
//

import Foundation
import OPSDK
import UniverseDesignTheme
import OPFoundation
import ECOProbe
import OPBlockInterface
import OPJSEngine

extension OPAppUniqueID {
    
    /// 当前开放应用是否已支持 DarkMode（不代表当前一定是 Dark Mode，只是表示是否支持）
    @objc public var isAppSupportDarkMode: Bool {
        get {
            if let container = opContainer {
                return container.isSupportDarkMode
            }
            // 降级为老容器逻辑
            if let task = BDPTaskManager.shared()?.getTaskWith(self) {
                return task.config?.darkmode ?? false
            }
            return false
        }
    }
    
    /// 当前开放应用是否是 DarkMode（应用已支持 DarkMode & 当前是 DarkMode ）
    @objc public var isAppDarkMode: Bool {
        get {
            return isAppSupportDarkMode && OPIsDarkMode()
        }
    }

    /// 开放容器运行时环境的版本号，目前在业务层只对 Block 生效，对 gadget 屏蔽
    @objc public var runtimeVersion: String? {
        opContainer?.runtimeVersion
    }

    /// 开放容器运行时的 package version
    @objc public var packageVersion: String? {
        opContainer?.containerContext.meta?.appVersion
    }

    /// 开放容器运行时为 Block 时的 Block id
    @objc public var blockID: String {
        (opConfig as? OPBlockContainerConfigProtocol)?.blockInfo?.blockID ?? ""
    }
    
    /// 开放容器运行时为 Block 时的 Block 宿主环境
    @objc public var host: String {
        (opConfig as? OPBlockContainerConfigProtocol)?.host ?? ""
    }

    @objc public var blockTrace: OPTraceProtocol? {
        opContainer?.containerContext.baseBlockTrace?.trace
    }
   
    /// 设置 true 后保活，小心使用该接口
    @objc public var isEnableAutoDestroy: Bool {
        set {
            opConfig?.enableAutoDestroy = newValue
        }
        get {
            opConfig?.enableAutoDestroy ?? false
        }
    }
    
    private var opConfig: OPContainerConfigProtocol? {
        opContainer?.containerContext.containerConfig
    }
    
    // 获取开放容器
    private var opContainer: OPContainerProtocol? {
        OPApplicationService.current.getContainer(uniuqeID: self)
    }
    
    @objc public var jsEngineType: OPRuntimeType {
        if let task = BDPTaskManager.shared()?.getTaskWith(self), let runtime = task.context as? OPMicroAppJSRuntime {
            return runtime.runtimeType
        }
        return .unknown
    }
}
