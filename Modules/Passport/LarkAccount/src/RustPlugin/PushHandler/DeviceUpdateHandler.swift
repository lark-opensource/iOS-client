//
//  DeviceUpdateHandler.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2020/9/28.
//

import Foundation
import LarkRustClient
import RxSwift
import RustPB
import LarkContainer
import LKCommonsLogging
import LarkAccountInterface

class DeviceUpdatePushHandler: BaseRustPushHandler<RustPB.Device_V1_PushDeviceNotifySettingResponse> {

    static let logger = Logger.plog(DeviceUpdatePushHandler.self, category: "SuiteLogin.DeviceUpdatePushHandler")

    @Provider var deviceService: DeviceManageServiceProtocol // user:checked (global-resolve)

    override func doProcessing(message: RustPB.Device_V1_PushDeviceNotifySettingResponse) {
        Self.logger.info("Receive PushDeviceNotifySetting", method: .local)
        self.deviceService.fetchLoginDevices()
    }
}

// 用户态 DeviceUpdatePushHandler
final class ScopedDeviceUpdatePushHandler: UserPushHandler {

    static let logger = Logger.log(ScopedDeviceUpdatePushHandler.self, category: "LarkAccount.ScopedDeviceUpdatePushHandler")

    @ScopedInjectedLazy var deviceService: DeviceManageServiceProtocol?

    func process(push: RustPB.Device_V1_PushDeviceNotifySettingResponse) throws {
        guard PassportUserScope.enableUserScopeTransitionRust else {
            Self.logger.warn("n_action_push_handler: disable user scoped rust handler PushDeviceNotifySetting")
            return
        }
        Self.logger.info("n_action_push_handler: receive PushDeviceNotifySetting")
        guard let deviceService = deviceService else {
            Self.logger.error("n_action_push_handler: PushDeviceNotifySetting no device service")
            return
        }
        deviceService.fetchLoginDevices()
    }
}

class ValidDevicesUpdatePushHandler: BaseRustPushHandler<RustPB.Device_V1_PushValidDevicesResponse> {

    static let logger = Logger.plog(ValidDevicesUpdatePushHandler.self, category: "SuiteLogin.ValidDevicesUpdatePushHandler")

    @Provider var deviceService: DeviceManageServiceProtocol // user:checked (global-resolve)

    override func doProcessing(message: RustPB.Device_V1_PushValidDevicesResponse) {
        Self.logger.info("Receive PushValidDevices", method: .local)
        self.deviceService.updateLoginDevices(message.devices.map {
            LoginDevice(
                id: $0.id,
                name: $0.name,
                os: $0.os,
                model: $0.model,
                terminal: LoginDevice.Terminal(rawValue: $0.terminal.rawValue) ?? .unknown,
                tenantName: "",
                loginTime: TimeInterval($0.loginTime),
                loginIP: "",
                isCurrent: $0.isCurrentDevice
            )
        })
    }
}

// 用户态 ValidDevicesUpdatePushHandler
final class ScopedValidDevicesUpdatePushHandler: UserPushHandler {

    static let logger = Logger.log(ScopedValidDevicesUpdatePushHandler.self, category: "LarkAccount.ScopedValidDevicesUpdatePushHandler")

    @ScopedInjectedLazy var deviceService: DeviceManageServiceProtocol?

    func process(push: RustPB.Device_V1_PushValidDevicesResponse) throws {
        guard PassportUserScope.enableUserScopeTransitionRust else {
            Self.logger.warn("n_action_push_handler: disable user scoped rust handler PushValidDevices")
            return
        }
        Self.logger.info("n_action_push_handler: receive PushValidDevices")
        guard let deviceService = deviceService else {
            Self.logger.error("n_action_push_handler: PushValidDevices no device service")
            return
        }
        deviceService.updateLoginDevices(push.devices.map {
            LoginDevice(
                id: $0.id,
                name: $0.name,
                os: $0.os,
                model: $0.model,
                terminal: LoginDevice.Terminal(rawValue: $0.terminal.rawValue) ?? .unknown,
                tenantName: "",
                loginTime: TimeInterval($0.loginTime),
                loginIP: "",
                isCurrent: $0.isCurrentDevice
            )
        })
    }
}
