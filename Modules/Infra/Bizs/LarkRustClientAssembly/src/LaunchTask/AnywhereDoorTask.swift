//
//  AnywhereDoorTask.swift
//  LarkRustClientAssembly
//
//  Created by wangyuanxun on 2022/10/27.
//

import Foundation
#if canImport(AWEAnywhereArena)
import AWEAnywhereArena
import BootManager
import Swinject
import LarkAccountInterface
import AppContainer
import LarkReleaseConfig
import LKCommonsLogging

class AnywhereDoorTask: FlowBootTask, Identifiable {
    static var identify: BootManager.TaskIdentify = "AnywhereDoorTask"
    override var runOnlyOnce: Bool { true }
    override func execute(_ context: BootContext) {
        // lint:disable:next lark_storage_check
        guard UserDefaults.standard.bool(forKey: AnyWhereDoorItem.itemKey) else { return }
        AWEArenaMessageCenter.shared().addObserver(Proxy.self, forMessageProtocol: AWEArenaManagerMessageProtocol.self)
    }
}

@objc
private class Proxy: NSObject, AWEArenaManagerMessageProtocol {
    private static let logger = Logger.log(Proxy.self)

    static func deviceId() -> String { BootLoader.container.resolve(DeviceService.self)?.deviceId ?? "" }

    static func appId() -> String { ReleaseConfig.appId }

    static func log(_ log: AWEArenaLog) {
        switch log.level {
        case .debug: Self.logger.debug(log.msg)
        case .error: Self.logger.error(log.msg)
        case .info: Self.logger.info(log.msg)
        @unknown default: Self.logger.info(log.msg)
        }
    }
}
#endif
