//
//  LarkSnsShareBaseAssembly.swift
//  AFgzipRequestSerializer
//
//  Created by shizhengyu on 2020/3/19.
//

import Foundation
import AppContainer
import LKCommonsLogging
import Swinject
import LarkAssembler

// MARK: - Assembly
public final class LarkSnsShareBaseAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        container.register(LarkShareBaseService.self) { (_) -> LarkShareBaseService in
            return LarkShareBasePresenter.shared
        }
    }

    public func registBootLoader(container: Container) {
        #if LarkSnsShare_InternalSnsShareDependency
        (SnsHandleOpenURLDelegate.self, DelegateLevel.default)
        #endif
    }
}
