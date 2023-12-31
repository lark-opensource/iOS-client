//
//  NoPermissionRustActionHandler.swift
//  LarkSecurityAndCompliance
//
//  Created by qingchun on 2022/4/8.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInfra

protocol NoPermissionRustActionHandler {
    func execute(with value: NoPermissionRustActionModel, resolver: UserResolver) throws
    var action: NoPermissionRustActionModel.Action { get }
}

struct NoPermissionRustActionDeviceOwnershipHandler: NoPermissionRustActionHandler {

    func execute(with value: NoPermissionRustActionModel, resolver: UserResolver) throws {
        let viewModel = try NoPermissionViewModel(resolver: resolver, model: value)
        let controller = NoPermissionViewController(viewModel: viewModel)
        let service = try resolver.resolve(assert: NoPermissionService.self)
        service.showViewController(controller)
    }

    var action: NoPermissionRustActionModel.Action { return .deviceOwnership }
}

struct NoPermissionRustActionDeviceCredibilityHandler: NoPermissionRustActionHandler {

    func execute(with value: NoPermissionRustActionModel, resolver: UserResolver) throws {
        let viewModel = try NoPermissionViewModel(resolver: resolver, model: value)
        let controller = NoPermissionViewController(viewModel: viewModel)
        let service = try resolver.resolve(assert: NoPermissionService.self)
        service.showViewController(controller)
    }

    var action: NoPermissionRustActionModel.Action { return .deviceCredibility }
}

struct NoPermissionRustActionNetworkHandler: NoPermissionRustActionHandler {

    func execute(with value: NoPermissionRustActionModel, resolver: UserResolver) throws {
        let viewModel = try NoPermissionViewModel(resolver: resolver, model: value)
        let controller = NoPermissionViewController(viewModel: viewModel)
        let service = try resolver.resolve(assert: NoPermissionService.self)
        service.showViewController(controller)
    }

    var action: NoPermissionRustActionModel.Action { return .network }
}

struct NoPermissionRustActionMFAHandler: NoPermissionRustActionHandler {

    func execute(with value: NoPermissionRustActionModel, resolver: UserResolver) throws {
        let viewModel = try NoPermissionViewModel(resolver: resolver, model: value)
        let controller = NoPermissionViewController(viewModel: viewModel)
        let service = try resolver.resolve(assert: NoPermissionService.self)
        service.showViewController(controller)
    }

    var action: NoPermissionRustActionModel.Action { return .mfa }
}

struct SecurityPolicyFileBlockHandler: NoPermissionRustActionHandler {

    func execute(with value: NoPermissionRustActionModel, resolver: UserResolver) throws {
        let controlService = try resolver.resolve(assert: SecurityPolicyInterceptService.self)
        controlService.showInterceptDialog(interceptorModel: value)
    }

    var action: NoPermissionRustActionModel.Action { return .fileblock }
}

struct SecurityPolicyDLPHandler: NoPermissionRustActionHandler {
    func execute(with value: NoPermissionRustActionModel, resolver: UserResolver) throws {
        SCLogger.info("execute DLP handler")
    }

    var action: NoPermissionRustActionModel.Action { return .dlp }
}

struct SecurityPolicyTTCrossTenantSpreadHandler: NoPermissionRustActionHandler {
    func execute(with value: NoPermissionRustActionModel, resolver: UserResolver) throws {
        SCLogger.info("execute TT_BLOCK handler")
    }

    var action: NoPermissionRustActionModel.Action { return .ttBlock }
}

struct SecurityPolicyPointDowngradeHandler: NoPermissionRustActionHandler {

    func execute(with value: NoPermissionRustActionModel, resolver: UserResolver) throws {
        let controlService = try resolver.resolve(assert: SecurityPolicyInterceptService.self)
        controlService.showDowngradeDialog()
    }

    var action: NoPermissionRustActionModel.Action { return .pointDowngrade }
}

struct SecurityPolicyUniversalFallbackHandler: NoPermissionRustActionHandler {

    func execute(with value: NoPermissionRustActionModel, resolver: UserResolver) throws {
        let controlService = try resolver.resolve(assert: SecurityPolicyInterceptService.self)
        controlService.showUniversalFallbackToast()
    }

    var action: NoPermissionRustActionModel.Action { return .universalFallback }
}
