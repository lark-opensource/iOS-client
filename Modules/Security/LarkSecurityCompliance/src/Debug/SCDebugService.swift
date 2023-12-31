//
//  SCDebugService.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/9/18.
//

import UIKit
import SwiftyJSON
import LarkSecurityComplianceInfra
import LarkEMM
import LarkContainer

public protocol SCDebugService: UserResolverWrapper {
    var enableFileOperateLog: (() -> Bool)? { get set }
    func gotoNoPermissionPage(_ cellName: String, cellParams: [String: JSON])
    func getSimulatorAlertView() -> UIView?
    func getJailBreakAlertView() -> UIView?
    func showViewController(_ viewController: UIViewController)
    func dismissCurrentWindow()

    // encryption upgrade
    func isRekeyTokenOn() -> Bool
    func updateRekeyTokensOnDebugSwitch(_ isOn: Bool)
    func isMockRekeyFailureOn() -> Bool
    func mockRekeyFailure(_ isOn: Bool)
    
    // device status
    func showDeviceStatusPage(isLimited: Bool)
    func showDeviceDeclarationPage()
}

public final class SCDebugServiceImp: SCDebugService {

    public let userResolver: UserResolver

    public init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    public var enableFileOperateLog: (() -> Bool)?

    public func gotoNoPermissionPage(_ cellName: String, cellParams: [String: JSON]) {
        let action = NoPermissionRustActionModel.ActionModel(name: cellName, params: cellParams)
        let model = NoPermissionRustActionModel(actions: [action])
        guard let viewModel = try? NoPermissionViewModel(resolver: self.userResolver, model: model) else { return }
        let controller = NoPermissionViewController(viewModel: viewModel)
        let service = try? userResolver.resolve(assert: NoPermissionService.self)
        service?.showViewController(controller)
    }
    
    public func showDeviceStatusPage(isLimited: Bool) {
        guard let viewModel = try? DeviceStatusViewModel(resolver: userResolver, isLimited: isLimited),
              let service = try? userResolver.resolve(assert: NoPermissionService.self) else { return }
        let controller = DeviceStatusViewController(viewModel: viewModel)
        service.showViewController(controller)
    }
    
    public func showDeviceDeclarationPage() {
        guard let viewModel = try? DeviceStatusViewModel(resolver: userResolver, isLimited: false),
              let service = try? userResolver.resolve(assert: NoPermissionService.self) else { return }
        let controller = DeviceDeclarationViewController(viewModel: viewModel)
        service.showViewController(controller)
    }

    public func getSimulatorAlertView() -> UIView? {
        SimulatorAndJailBreakAlertViewController(detectedType: .simulator).view
    }

    public func getJailBreakAlertView() -> UIView? {
        SimulatorAndJailBreakAlertViewController(detectedType: .jailBreak).view
    }

    public func showViewController(_ viewController: UIViewController) {
        let service = try? userResolver.resolve(assert: NoPermissionService.self)
        service?.showViewController(viewController)
    }

    public func dismissCurrentWindow() {
        let service = try? userResolver.resolve(assert: NoPermissionService.self)
        service?.dismissCurrentWindow()
    }
}

// encryption upgrade
public extension SCDebugServiceImp {
    func updateRekeyTokensOnDebugSwitch(_ isOn: Bool) {
        EncryptionUpgradeStorage.shared.updateShouldRekey(value: isOn)
        EncryptionUpgradeStorage.shared.updateShouldSkipOnce(value: false)
    }

    func isRekeyTokenOn() -> Bool {
        EncryptionUpgradeStorage.shared.shouldRekey
    }

    func isMockRekeyFailureOn() -> Bool {
        EncryptionUpgradeStorage.shared.forceFailure
    }

    func mockRekeyFailure(_ isOn: Bool) {
        EncryptionUpgradeStorage.shared.mockForceFailure(isOn)
    }
}
