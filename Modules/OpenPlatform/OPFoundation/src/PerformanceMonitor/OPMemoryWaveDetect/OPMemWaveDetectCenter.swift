//
//  OPMemWaveDetectCenter.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/25.
//

import Foundation
import OPFoundation
import LKCommonsLogging

fileprivate let logger = Logger.oplog(OPMemWaveDetectCenter.self, category: "performanceMonitor")

/// 内存波动增量最大值的默认值（MB为单位）
fileprivate let DefaultMaxMemoryIncrementNumber: Float = 80

/// 负责检测内存波动增量
class OPMemWaveDetectCenter {

    /// singleton
    static let shared = OPMemWaveDetectCenter()
    private init() {
        setupTimerSubscription()
    }

    deinit {
        OPPerformanceMonitorTimer.shared.dispose(with: "\(self)")
    }

    /// 持有wrapper，防止释放
    private var wrappers: [Wrapper] = []

    /// 用于保护wrapper数组线程安全的锁
    private var semaphore = DispatchSemaphore(value: 1)

    private func setupTimerSubscription() {
        OPPerformanceMonitorTimer.shared.subscribe(with: "\(self)") { [weak self] in
            guard let self = self else { return }

            self.semaphore.wait()
            // 首先去除掉所有target已经销毁的wrapper
            self.wrappers.removeAll(where: {$0.targetObject == nil})
            let wrappers = self.wrappers
            self.semaphore.signal()

            for wrapper in wrappers {
                wrapper.checkIncrement()
            }
        }
    }

    func setupMemoryWaveDetect(with target: OPMemoryMonitoredObjectType) {
        guard let enableMemoryWave = type(of:target).enableMemoryWaveDetect, enableMemoryWave else {
            return
        }

        semaphore.wait()
        if !wrappers.contains(where: {$0.targetObject == target}) {
            let wrapper = Wrapper(with: target)
            wrapper.run()
            wrappers.append(wrapper)
        }
        semaphore.signal()
    }

    func run(with target: OPMemoryMonitoredObjectType) {
        semaphore.wait()
        wrappers.first {$0.targetObject == target}?.run()
        semaphore.signal()
    }

    func pause(with target: OPMemoryMonitoredObjectType) {
        semaphore.wait()
        wrappers.first {$0.targetObject == target}?.pause()
        semaphore.signal()
    }

}

private extension OPMemWaveDetectCenter {
    /// 负责某个特定对象相关的内存波动增量的计算、检查以及信息上报
    class Wrapper {
        /// 检查的目标对象
        weak var targetObject: NSObject?

        /// 先前统计的内存增量的总量
        private var previousIncrement: Float = 0

        /// 本次启动之后初始的应用内存占用总量，为nil代表还未启动(run)
        private var runningMemoryUsage: Float?

        /// 用于上传内存波动超限事件信息的上传器
        private let uploader = OPMemoryInfoUploader(with: .memoryWave)

        /// 是否已经触发过内存波动警告，埋点上报与调试弹窗仅在第一次触发警告时执行
        private var hasWaved = false

        init(with target: OPMemoryMonitoredObjectType) {
            targetObject = target
        }

        /// 开始计算内存增量
        func run() {
            // 如果runningMemoryUsage不为空，代表为running状态，不可以再次run
            if runningMemoryUsage != nil {
                return
            }
            runningMemoryUsage = OPPerformanceHelper.usedMemoryInMB
        }

        /// 暂停计算内存增量
        func pause() {
            guard let runningMemoryUsage = runningMemoryUsage else {
                return
            }

            checkIncrement()

            let currentIncrement = OPPerformanceHelper.usedMemoryInMB - runningMemoryUsage
            self.runningMemoryUsage = nil
            previousIncrement += currentIncrement

        }

        /// 检查内存增量是否超出限制
        func checkIncrement() {
            // 如果targetObject已经销毁，则没有必要再检查内存增量了
            if targetObject == nil {
                return
            }
            guard let runningMemoryUsage = runningMemoryUsage else {
                return
            }

            let currentMemoryUsage = OPPerformanceHelper.usedMemoryInMB
            let currentIncrement = currentMemoryUsage - runningMemoryUsage
            let totalIncrement = previousIncrement + currentIncrement
            // 如果内存波动增量超过了限制，则上报信息
            let maxMemIncrementNumber = OPPerformanceMonitorConfigProvider.maxMemoryIncrementNumber ?? DefaultMaxMemoryIncrementNumber
            if let targetObject = targetObject, totalIncrement > maxMemIncrementNumber {
                // 打日志
                logger.warn("Memory wave increment over the limit. Current memory increment:\(totalIncrement), related target object: \(targetObject)")
                // 第一次触发内存波动警告
                if !hasWaved {
                    hasWaved = true
                    execActionWhenFirstWaved(targetObject)
                }
            }

        }

        /// 在第一次内存波动警告触发时需要执行的逻辑
        private func execActionWhenFirstWaved(_ target: NSObject) {
            // 如果在Debug模式下就针对此次内存波动弹窗提示
            #if DEBUG
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Memory waved!", message: "Memory wave increment has been over the limit", preferredStyle: .alert)
                let action = UIAlertAction(title: "Confirm", style: .cancel)
                alertController.addAction(action)
                OPWindowHelper.fincMainSceneWindow()?.rootViewController?.present(alertController, animated: true)
            }
            #endif
            uploader.uploadLeakInfo(with: target)
        }

    }

}
