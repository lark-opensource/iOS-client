//
//  MemoryLeakExtensionItem.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/7/29.
//

import LarkSuspendable
import LarkUIKit
import OPFoundation

/// 内存泄漏检测
final public class MemoryLeakExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "MemoryLeak"
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = MemoryLeakWebBrowserLifeCycle()
    
    public init() {}
}

final public class MemoryLeakWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    public func viewDidLoad(browser: WebBrowser) {
        //  pageScene 不等于nomal，说明这个vc会被加到缓存队列里，不需要监控内存泄露
        if browser.pageScene != .normal {
            return
        }
        //  非Tab模式且非iPad场景下使用内存泄漏检测工具
        if !Display.pad {
            OPObjectMonitorCenter.setupMemoryMonitor(with: browser)
            OPObjectMonitorCenter.updateState(.expectedRetain, for: browser)
        }
    }
    
    public func viewWillAppear(browser: WebBrowser, animated: Bool) {
        //  pageScene 不等于nomal，说明这个vc会被加到缓存队列里，不需要监控内存泄露
        if browser.pageScene != .normal {
            return
        }
        //  非Tab模式且非iPad场景下使用内存泄漏检测工具
        if !Display.pad {
            OPObjectMonitorCenter.setMemoryWave(active: true, with: browser)
        }
    }
    
    public func viewDidDisappear(browser: WebBrowser, animated: Bool) {
        //  pageScene 不等于nomal，说明这个vc会被加到缓存队列里，不需要监控内存泄露
        if browser.pageScene != .normal {
            return
        }
        OPObjectMonitorCenter.setMemoryWave(active: false, with: browser)
        // 无parent，不是Tab模式下，且不是多任务模式下，且不是iPad场景，需要设置为预期释放模式
        if browser.parent == nil, !SuspendManager.shared.contains(suspendID: browser.configuration.webBrowserID), !Display.pad {
            OPObjectMonitorCenter.updateState(.expectedDestroy, for: browser)
        }
    }
}

extension WebBrowser: OPMemoryMonitorObjectProtocol {
    /// 开启实例数量检测
    public static var overcountNumber: UInt {
        12
    }
    /// 开启内存波动检测
    public static var enableMemoryWaveDetect: Bool {
        true
    }
}
