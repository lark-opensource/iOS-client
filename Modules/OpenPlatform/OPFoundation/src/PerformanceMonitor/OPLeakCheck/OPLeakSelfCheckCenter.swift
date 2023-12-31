//
//  OPLeakSelfCheckCenter.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/8.
//

import Foundation
import LKCommonsLogging

fileprivate let logger = Logger.oplog(OPLeakSelfCheckCenter.self, category: "performanceMonitor")

/// 小程序对象从预期销毁到真正销毁之间能够容忍的默认延迟
fileprivate let DefaultExpectedDestroyDelay: TimeInterval = 5

/// 用于管理所有的自检器，单例
@objcMembers
final class OPLeakSelfCheckCenter: NSObject {
    /// 单例
    public static let shared = OPLeakSelfCheckCenter()

    private override init() {
        super.init()
        setupCheckTimerSubscrption()
    }

    deinit {
        OPPerformanceMonitorTimer.shared.dispose(with: "\(self)")
    }

    /// 管理所有的CheckWrapper，key为自检目标对象的hashValue
    private var checkWrapperStorage: [Int: Wrapper] = [:]

    /// 上传器，用于上传内存泄漏事件
    private let uploader = OPMemoryInfoUploader(with: .objectLeak)

    /// 给一个NSObject对象设置状态
    func setState(_ state: OPMonitoredObjectState, for target: NSObject) {
        logger.info("set state: \(state.rawValue) to target: \(target)")
        
        objc_sync_enter(self)
        // 若checkWrapperStorage已经拥有对应的wrapper，直接更改状态
        // 如果没有就新创建一个
        if let wrapper = checkWrapperStorage[target.hashValue] {
            wrapper.objectState = state
        } else {
            let wrapper = Wrapper(with: target)
            wrapper.objectState = state
            checkWrapperStorage[target.hashValue] = wrapper
        }
        objc_sync_exit(self)
    }

    /// 启动一个对象的自检逻辑(受采样率控制)
    func startSelfCheck(with target: NSObject) {

        logger.info("self checker of gadgetLeak will start with \(target)")

        let selfCheckWrapper = Wrapper(with: target)

        objc_sync_enter(self)
        checkWrapperStorage[target.hashValue] = selfCheckWrapper
        objc_sync_exit(self)
    }
}

private extension OPLeakSelfCheckCenter {
    /// 建立定时检查的定时器订阅
    func setupCheckTimerSubscrption() {
        OPPerformanceMonitorTimer.shared.subscribe(with: "\(self)") { [weak self] in
            guard let self = self else {
                return
            }
            self.execCheck()
        }
    }

    /// 遍历所有的checkWrapper执行一次自检
    func execCheck() {
        // 先加锁(注意，这里用「递归锁」的原因是：下方存在隐式的对象 delloc 逻辑泄出并导致 setState 方法被调用，会导致死锁 http://t.wtturl.cn/eTU7P3d/ )
        objc_sync_enter(self)
        var targets: [NSObject] = []
        for (wrapperKey, wrapper) in checkWrapperStorage {
            // 要检测的目标对象已经销毁，不再进行监控，从字典中移除
            guard let target = wrapper.target else {
                checkWrapperStorage.removeValue(forKey: wrapperKey)
                continue
            }
            // 如果目标对象的状态不为预期销毁，检测逻辑就不需要进行下去了
            guard case .expectedDestroy = wrapper.objectState else {
                continue
            }
            // 如果距离给对象设置预期销毁状态的时间已经超过了最大能容忍的销毁延迟，对象依然没有被销毁，则认为发生了内存泄漏
            let destroyDelay = OPPerformanceMonitorConfigProvider.leakDestroyDelay ?? DefaultExpectedDestroyDelay
            if (wrapper.expectedDestroyTime+destroyDelay).compare(.init()) == .orderedAscending {
                targets.append(target)
                checkWrapperStorage.removeValue(forKey: wrapperKey)
            }
        }
        objc_sync_exit(self)
        
        targets.forEach { (target) in
            execActionWhenLeaked(target)
            uploader.uploadLeakInfo(with: target)
        }
    }

    /// 如果发生了泄漏，除了标准的埋点上报之外还需要执行的额外逻辑
    func execActionWhenLeaked(_ target: NSObject) {
        // 如果在Debug模式下就针对此次泄漏弹窗提示
        #if DEBUG
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Object Leaked!", message: "object: \(target) has leaked", preferredStyle: .alert)
            let action = UIAlertAction(title: "Confirm", style: .cancel)
            alertController.addAction(action)
            OPWindowHelper.fincMainSceneWindow()?.rootViewController?.present(alertController, animated: true)
        }
        #endif
        // 上报错误日志
        logger.error("object: \(target) have leaked according to self check logic")
    }



}

private extension OPLeakSelfCheckCenter {
    /// 负责保存检测对象的状态
    class Wrapper {
        /// 自检的目标对象，使用weak不对原对象造成影响
        weak var target: NSObject?

        /// 自检目标对象进入预期销毁状态时的时间
        var expectedDestroyTime: Date = .init()

        /// 目标对象当前的状态
        var objectState: OPMonitoredObjectState = .expectedDestroy {
            willSet {
                // 如果将状态设置为预期销毁，就更新设置的时间
                if newValue == .expectedDestroy {
                    self.expectedDestroyTime = .init()
                }
            }
        }

        init(with target: NSObject) {
            self.target = target
        }
    }
}
