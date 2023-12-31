//
//  ForwardSetupTask.swift
//  LarkForward
//
//  Created by liuxianyu on 2022/3/2.
//

import Foundation
import BootManager
import LarkResource
import LKCommonsLogging
import LarkAccountInterface
import LarkMessengerInterface
import LarkStorage
import EENavigator
import RxCocoa
import RxSwift
import Swinject

final class ForwardSetupTask: UserFlowBootTask, Identifiable {
    static var identify = "ForwardSetupTask"

    static let logger = Logger.log(ForwardSetupTask.self, category: "Module.LarkForward")

    override var scheduler: Scheduler { return .main }
    override class var compatibleMode: Bool { ForwardUserScope.userScopeCompatibleMode }

    private static let globalStore = KVStores.udkv(space: .global, domain: Domain.biz.messenger.child("Forward"))
    private static let defaultOpenShareKey = KVKey("ForwardSetupTask.defaultOpenShare", default: false)

    static public func markShowOpenShare() {
        globalStore[defaultOpenShareKey] = true
    }

    private func removeShowOpenShare() {
        Self.globalStore[Self.defaultOpenShareKey] = false
    }

    override func execute(_ context: BootContext) {
        Self.logger.info("ForwardSetupTask: new excute process")

        guard Self.globalStore[Self.defaultOpenShareKey] else {
            Self.logger.info("ForwardSetupTask: showOpenShare is false")
            return
        }
        guard let from = userResolver.navigator.mainSceneWindow else {
            Self.logger.info("ForwardSetupTask: window is nil")
            return
        }
        self.removeShowOpenShare()
        Self.logger.info("ForwardSetupTask: present from \(from)")
        self.userResolver.navigator.present(body: OpenShareBody(), from: from)
    }
}
