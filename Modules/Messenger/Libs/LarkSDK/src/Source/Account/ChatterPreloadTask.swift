//
//  ChatterPreloadTask.swift
//  LarkSDK
//
//  Created by Supeng on 2021/5/28.
//

import Foundation
import BootManager
import LarkContainer
import LarkSDKInterface

final class ChatterPreloadTask: UserFlowBootTask, Identifiable {
    static var identify = "ChatterPreloadTask"

    @ScopedProvider var chatterManager: ChatterManagerProtocol?

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        // 初始化登录相关服务
        NewBootManager.shared.addConcurrentTask { [weak self] in
            _ = self?.chatterManager
        }
    }
}
