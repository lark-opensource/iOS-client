//
//  GadgetSetupTask.swift
//  LarkMicroApp
//
//  Created by KT on 2020/7/8.
//

import Foundation
import BootManager
import LarkPerf
import LarkContainer
import EEMicroAppSDK
import LarkDebugExtensionPoint
import LarkRustClient
import LarkSetting
import RustPB
import OPFoundation
import LKLoadable
import TTMicroApp

class GadgetSetupTask: UserFlowBootTask, Identifiable {
    static var identify = "GadgetSetupTask"

    override var scope: Set<BizScope> { return [.openplatform] }
    
    override class var compatibleMode: Bool { OPUserScope.compatibleModeEnabled }

    @ScopedProvider
    private var microAppService: MicroAppService?
    
    @ScopedProvider
    private var timorStateListener: BDPTimorStateListener?
    
    @ScopedProvider
    private var metaLoadStatusListener: MetaLoadStatusListener?

    @ScopedProvider
    private var rustService: RustService?

    override func execute(_ context: BootContext) {
        let isFastLogin = context.isFastLogin
        if isFastLogin { AppStartupMonitor.shared.start(key: .microSDK) }

        /// 注册 Rust push handler
        rustService?.registerPushHandler(factories: [
            /// 注册 Rust 网络变化通知
            ///
            /// 原逻辑是 GadgetObservableManager 在 assembly 时使用 addObservableWhenAssemble 注册来自 Messenger 的通知。
            /// 实际效果:
            ///     1. Messenger 的 PushDynamicNetStatus 通知也是监听了 Rust 的 push 发出（参考 DynamicNetStatusPushHandler）。
            ///     2. Messenger 的监听时机在 afterLogin 阶段（参考 LarkSDKRegistPushTask）。
            ///     3. 原 GadgetObservableManager 逻辑中使用 assembleDone 标志位避免重复监听。
            /// 等效于此处通过自行注册 Rust push 实现：
            ///     1. 直接监听 Rust push 与原 Messenger 逻辑等效。
            ///     2. 当前 GadgetSetupTask 也是在 afterLogin 阶段，时机等效。
            ///     3. 注册在 RustService 上的 pushHandler 跟随 RustService 生命周期，Task 在登陆/切租户默认重新 execute 注册，不需要再手动关心标志位，与 Messenger 逻辑等效。
            ///
            /// 原依赖链: LarkMicroApp -> LarkSDK(Messenger) -> RustPush
            /// 新依赖链: LarkMicroApp -> RustPush
            .pushDynamicNetStatus: { RustNetStatusPushHandler() }
        ])

        self.microAppService?.setup()
        MicroAppAssembly.gadgetOB?.addObservableAfterAccountLoaded()
        assembleDebugItem()
        // 启动对应用状态的监听, 目的是在 rust 层能正确的收发消息
        timorStateListener?.setup()
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webcomponent.safedomain.doublecheck")) {
            metaLoadStatusListener?.addObserver()
        }

        if isFastLogin { AppStartupMonitor.shared.end(key: .microSDK) }
    }

    private func assembleDebugItem() {
        DebugRegistry.registerDebugItem(MicroAppDebugItem(), to: .debugTool)
        DebugRegistry.registerDebugItem(MicroAppDebugPageItem(), to: .debugTool)
    }
}
