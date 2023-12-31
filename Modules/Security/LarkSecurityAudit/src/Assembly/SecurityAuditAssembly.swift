//
//  SecurityAuditAssembly.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/24.
//
import Swinject
import BootManager
import LarkAccountInterface
import LarkRustClient
import LarkAssembler

/// assembly
public final class SecurityAuditAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(UpdateAuditTask.self)
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushPermission, PermissionPushHandler.init(resolver:))
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory {
            SecurityAuditLauncherDelegate()
        }, PassportDelegatePriority.middle)
    }

    public func registDebugItem(container: Container) {
    }

}
