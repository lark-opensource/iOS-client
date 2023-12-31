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

final class SetupDispatcherTask: FlowBootTask, Identifiable {
    static var identify = "SetupDispatcherTask"

    private let disposeBag = DisposeBag()

    @InjectedLazy private var rustClient: RustService

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
    }

    // 通知Rust首屏渲染完成
    private func noticeRustFirstRender() {
        var request = RustPB.Basic_V1_NoticeClientEventRequest()
        request.event = .firstScreenFinished
        rustClient.sendAsyncRequest(request).subscribe().disposed(by: disposeBag)
    }

    // 通知Rust首屏渲染完成60s
    private func noticeRustIdleAfterFirstScreen() {
        var request = RustPB.Basic_V1_NoticeClientEventRequest()
        request.event = .idleAfterFirstScreen
        rustClient.sendAsyncRequest(request).subscribe().disposed(by: disposeBag)
    }
}
