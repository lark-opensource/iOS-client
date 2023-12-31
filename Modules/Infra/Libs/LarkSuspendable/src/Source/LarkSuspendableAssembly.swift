//
//  LarkSuspendableAssembly.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/24.
//

import UIKit
import Foundation
import Swinject
import RxSwift
import BootManager
import LarkAccountInterface
import LarkAssembler

public final class SuspendAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(LoadSuspendTask.self)
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory {
            return SuspendDelegate()
        }, PassportDelegatePriority.low)
    }
}

public final class SuspendDelegate: PassportDelegate {

    public var name: String = "LarkSuspendable+Account"

    /// online 的原因可能是 login、switch、fastLogin，请注意按需要排除 fastLogin 的场景，避免不需要的逻辑
    public func userDidOnline(state: PassportState) {
        guard let user = state.user else { return }
        loadSuspendItemsForCurrentAccount(user: user)
    }

    /// offline 的原因可能是 switch、logout
    public func userDidOffline(state: PassportState) {
        clearSuspendItems()
    }

    private func loadSuspendItemsForCurrentAccount(user: User) {
        SuspendManager.shared.clearSuspendItems()
        guard SuspendManager.isSuspendEnabled else { return }
        SuspendManager.shared.loadSuspendConfig(forUserId: user.userID)
    }

    private func clearSuspendItems() {
        guard SuspendManager.isSuspendEnabled else { return }
        SuspendManager.shared.clearSuspendItems()
    }
}

final class LoadSuspendTask: UserFlowBootTask, Identifiable {

    static var identify: TaskIdentify = "LoadSuspendTask"

    override var scheduler: Scheduler { return .main }

    override func execute(_ context: BootContext) {
        if SuspendManager.isTabEnabled {
            UIViewController.initializeSuspendOnceForViewController()
        }
        guard SuspendManager.isSuspendEnabled else { return }
        UINavigationController.initializeSuspendOnce()
        self.loadSuspendItemsForCurrentAccount()
    }

    private func loadSuspendItemsForCurrentAccount() {
        SuspendManager.shared.loadSuspendConfig(forUserId: userResolver.userID)
    }
}
