//
//  PreloadLaunchTask.swift
//  LarkRustClientAssembly
//
//  Created by Yiming Qu on 2021/2/3.
//

import Foundation
import BootManager
import LarkContainer
import LarkAccountInterface
import LarkPerf
import RustPB
import LarkRustClient

/// 子线程初始化登录依赖的Service
final class PreloadLaunchTask: FlowBootTask, Identifiable {
    static var identify = "PreloadLaunchTask"

    @InjectedLazy private var rustService: LarkRustService
    @InjectedLazy private var rustClient: RustService
    @InjectedLazy private var dependency: RustClientDependency

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        // 启动Trace
//        LaunchOpenTracing.shared?.start()
        // 并行初始化
        NewBootManager.shared.addConcurrentTask {
            _ = self.rustService
            _ = self.rustClient
        }
        NewBootManager.shared.addConcurrentTask {
            _ = self.dependency.avatarPath
        }
    }

    private func setupRustTraffic() {
        @discardableResult
        func setTrafficData() -> Int64 {
            do {
                let res = RustPB.Statistics_V1_SetTrafficDataRequest()
                let response: RustPB.Statistics_V1_SetTrafficDataResponse = try rustClient.sendSyncRequest(res)
                return response.sdkTrafficData.wifiRecv + response.sdkTrafficData.mobileRecv
            } catch {
                return 0
            }
        }
        // Rust需要先调用一次
        setTrafficData()
        AppMonitor.shared.registRustFlow { () -> Int64? in
            return setTrafficData()
        }
    }
}
