//
//  MonitorAPPLagPushHandler.swift
//  LarkSDK
//
//  Created by zc09v on 2021/4/9.
//

import UIKit
import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import RxSwift

//当rust侧发现有大量push数据积攒时，会通知端上进行性能检测，反馈给rust做降频处理
final class MonitorAPPLagPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static var logger = Logger.log(MonitorAPPLagPushHandler.self, category: "Rust.PushHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    private lazy var timer = {
        return DispatchSource.makeTimerSource(queue: monitorQueue)
    }()
    private var inMoniting: Bool = false
    private var monitorQueue: DispatchQueue = DispatchQueue(label: "MonitorQueue")
    private var lock: NSRecursiveLock = NSRecursiveLock()
    private let disposeBag = DisposeBag()

    private let monitorRepeatingTime = 5
    @ScopedProvider private var userGeneralSettings: UserGeneralSettings?
    private var lagConfig: PushDowngradeAppLagConfig? {
        return self.userGeneralSettings?.pushDowngradeAppLagConfig
    }
    @ScopedProvider private var rustClient: SDKRustService?

    override init(resolver: UserResolver) {
        super.init(resolver: resolver)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enterBackGround),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        timer.schedule(deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(monitorRepeatingTime))
        timer.setEventHandler(handler: doMonitor)
    }

    func process(push message: RustPB.Basic_V1_PushMonitorAppLagStatusResponse) {
        //applicationState 要在主线程调用
        DispatchQueue.main.async {
            guard UIApplication.shared.applicationState != .background else {
                Self.logger.info("applicationState in background")
                return
            }
            self.lock.lock()
            switch message.status {
            case .start:
                if !self.inMoniting {
                    self.inMoniting = true
                    self.timer.resume()
                    Self.logger.info("start moniting")
                } else {
                    Self.logger.info("inMoniting return")
                }
            @unknown default: break
            }
            Self.logger.info("handle status: \(message.status.rawValue)")
            self.lock.unlock()
        }
    }

    private func doMonitor() {
        let cpuUsaged = cpuMonitor()
        let level = self.calulateLagLevel(cpuUsaged: cpuUsaged)
        self.notifyAppLag(level: level)
    }

    private func suspendMonitor() {
        Self.logger.info("suspendMonitor")
        lock.lock()
        guard inMoniting else {
            lock.unlock()
            return
        }
        timer.suspend()
        inMoniting = false
        lock.unlock()
    }

    //进入后台后，rust会清空缓存的push数据，此时可停止监控，状态设置回none
    @objc
    private func enterBackGround() {
        Self.logger.info("enterBackGround")
        self.suspendMonitor()
    }

    private func calulateLagLevel(cpuUsaged: Float) -> RustPB.Basic_V1_NotifyAppLagRequest.LagLevel {
        guard let lagConfig = self.lagConfig else {
            Self.logger.info("lagConfig miss")
            return .none
        }
        let processCount = ProcessInfo.processInfo.activeProcessorCount
        let averagePersent: Int = Int(cpuUsaged) / processCount
        let result: RustPB.Basic_V1_NotifyAppLagRequest.LagLevel
        if averagePersent < lagConfig.slightly {
            result = .none
        } else if averagePersent >= lagConfig.slightly && averagePersent < lagConfig.moderately {
            result = .slightly
        } else if averagePersent >= lagConfig.moderately && averagePersent < lagConfig.severely {
            result = .moderately
        } else if averagePersent >= lagConfig.severely && averagePersent < lagConfig.fatally {
            result = .severely
        } else {
            result = .fatally
        }
        Self.logger.info("calulateLagLevel \(result.rawValue) \(cpuUsaged) \(processCount)")
        return result
    }

    private func notifyAppLag(level: RustPB.Basic_V1_NotifyAppLagRequest.LagLevel) {
        var request = RustPB.Basic_V1_NotifyAppLagRequest()
        request.lagLevel = level
        let ob: Observable<Basic_V1_NotifyAppLagResponse>? = self.rustClient?.sendAsyncRequest(request)
        ob?.subscribe(onNext: { [weak self] (res) in
            if res.pushStatus == .normal {
                self?.suspendMonitor()
                Self.logger.info("rust pushStatus in normal")
            } else {
                Self.logger.info("rust pushStatus in downgrade")
            }
        }, onError: { (error) in
            Self.logger.error("Basic_V1_NotifyAppLagResponse error", error: error)
        }).disposed(by: disposeBag)
    }

    private func cpuMonitor() -> Float {
        var totalUsageOfCPU: Float = 0
        var threadsList = UnsafeMutablePointer(mutating: [thread_act_t]())
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
          return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
            task_threads(mach_task_self_, $0, &threadsCount)
          }
        }

        if threadsResult == KERN_SUCCESS {
          for index in 0..<threadsCount {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
              $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
              }
            }
            if infoResult == KERN_SUCCESS {
                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                  totalUsageOfCPU = (totalUsageOfCPU + (Float(threadBasicInfo.cpu_usage) / Float(TH_USAGE_SCALE) * 100.0))
                }
            } else {
                Self.logger.error("one thread cpu monitor fail")
            }
          }
        } else {
            Self.logger.error("cpuMonitor fail")
        }
        vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        return totalUsageOfCPU
    }
}
