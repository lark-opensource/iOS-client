//
//  KAExpiredObserverAssembly.swift
//
//  Created zhaoxiangyu on 2022/5/26.
//

import Foundation
import Swinject
import BootManager
import LarkAssembler
import AppContainer

public final class KAExpiredObserverAssembly: Assembly, LarkAssemblyInterface {
    public init() {}

    public func assemble(container: Container) {
        registLaunch(container: container)
        registContainer(container: container)
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(KAExpiredObserverTask.self)
    }

    public func registContainer(container: Container) {
        container.register(KAExpiredObserver.self) { _ in
            KAExpiredObserver()
        }.inObjectScope(.user)
    }
}

final class KAExpiredObserverTask: FlowBootTask, Identifiable {
    static var identify = "KAExpiredObserverTask"

    override func execute(_ context: BootContext) {
        guard let observer = BootLoader.container.resolve(KAExpiredObserver.self) else {
            return
        }
        observer.start()
    }
}

