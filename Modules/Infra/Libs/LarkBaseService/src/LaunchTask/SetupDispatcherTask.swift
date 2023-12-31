//
//  SetupDispatcherTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import Foundation
import RunloopTools
import AppContainer
import LarkMonitor
import EETroubleKiller
import LarkContainer
import LarkRustClient
import RustPB
import RxSwift
import BootManager
import LarkDowngrade

final class SetupDispatcherTask: UserFlowBootTask, Identifiable {
    static var identify = "SetupDispatcherTask"

    private let disposeBag = DisposeBag()

    private var rustClient: RustService? { try? userResolver.resolve(assert: RustService.self) }

    override var runOnlyOnceInUserScope: Bool { return false }

    override func execute(_ context: BootContext) {
        RunloopDispatcher.enable = true
        TroubleKiller.config.enable = false

        RunloopDispatcher.shared.addTask(
            priority: .required,
            scope: .user,
            identify: "afterFirstRender") {
            self.noticeRustFirstRender()
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                self.noticeRustIdleAfterFirstScreen()
            }
            TroubleKiller.config.enable = true
        }
        sendCPUStatusToRust()
    }

    // 通知Rust首屏渲染完成
    private func noticeRustFirstRender() {
        var request = RustPB.Basic_V1_NoticeClientEventRequest()
        request.event = .firstScreenFinished
        rustClient?.sendAsyncRequest(request).subscribe().disposed(by: disposeBag)
    }

    // 通知Rust首屏渲染完成60s
    private func noticeRustIdleAfterFirstScreen() {
        var request = RustPB.Basic_V1_NoticeClientEventRequest()
        request.event = .idleAfterFirstScreen
        rustClient?.sendAsyncRequest(request).subscribe().disposed(by: disposeBag)
    }
    
    private func sendCPUStatusToRust() {
        let waitUploadTime: TimeInterval = 15
        let cpuDowngradeCount: Double = 0.8
        let cpuUpgradeCount: Double = 0.3
        let deviceCpuDowngradeCount: Double = 0.9
        let deviceCpuUpgradeCount: Double = 0.5
        let checkTimeInterval: Double = 10
        DispatchQueue.main.asyncAfter(deadline: .now() + waitUploadTime) {
            if LarkUniversalDowngradeService.shared.needDowngrade(key: "FetchFeedDowngradeTask",
                                                                  strategies: .overCPU(cpuDowngradeCount, 
                                                                                       cpuUpgradeCount,
                                                                                       checkTimeInterval) |&| .overDeviceCPU(deviceCpuDowngradeCount,
                                                                                                                             deviceCpuUpgradeCount,
                                                                                                                             checkTimeInterval)) {
                var request = RustPB.Basic_V1_NotifyAppPerformanceRequest()
                request.cpuState = .busy
                self.rustClient?.sendAsyncRequest(request).subscribe().disposed(by: self.disposeBag)
            } else {
                var request = RustPB.Basic_V1_NotifyAppPerformanceRequest()
                request.cpuState = .normal
                self.rustClient?.sendAsyncRequest(request).subscribe().disposed(by: self.disposeBag)
            }
        }
        LarkUniversalDowngradeService.shared.dynamicDowngrade(key: "FetchFeedDowngradeTask", 
                                                              strategies: .overCPU(cpuDowngradeCount,
                                                                                   cpuUpgradeCount,
                                                                                   checkTimeInterval) |&| .overDeviceCPU(deviceCpuDowngradeCount,
                                                                                                                         deviceCpuUpgradeCount,
                                                                                                                         checkTimeInterval),
                                                              timeInterval: 10,
                                                              doDowngrade: { _ in
            var request = RustPB.Basic_V1_NotifyAppPerformanceRequest()
            request.cpuState = .busy
            self.rustClient?.sendAsyncRequest(request).subscribe().disposed(by: self.disposeBag)
        }, doNormal: { _ in
            var request = RustPB.Basic_V1_NotifyAppPerformanceRequest()
            request.cpuState = .normal
            self.rustClient?.sendAsyncRequest(request).subscribe().disposed(by: self.disposeBag)
        })
    }
}
