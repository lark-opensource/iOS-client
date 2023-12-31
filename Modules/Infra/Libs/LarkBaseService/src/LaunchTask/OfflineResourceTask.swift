//
//  OfflineResourceTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import AppContainer
import LarkAccountInterface
import LarkContainer

final class OfflineResourceTask: FlowBootTask, Identifiable {
    static var identify = "OfflineResourceTask"

    override func execute(_ context: BootContext) {
        // 初始化离线资源
        BootLoader.resolver(OfflineResourceApplicationDelegate.self)?.initOfflineResourceManager()
    }
}

final class UpdateOfflineResource: FlowBootTask, Identifiable {
    static var identify = "UpdateOfflineResource"

    override func execute(_ context: BootContext) {
        let delegate = Container.shared.resolve(OfflineResourceDelegate.self)! // Global
        delegate.updateDevice()
        NewBootManager.shared.addSerialTask {
            delegate.updateSetting()
        }
    }
}
