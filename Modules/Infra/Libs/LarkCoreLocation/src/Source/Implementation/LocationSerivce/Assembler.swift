//
//  LarkCoreLocationAssembly.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/31/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import LarkAssembler
import LarkContainer
/// 定位服务
public final class LarkCoreLocationAssembly: LarkAssemblyInterface {

    public init() {}

    public func registContainer(container: Container) {

        container.register(LocationService.self) { _ in
            LocationServiceFactory().getLocationService(type: nil)
        }

        container.register(LocationService.self) {
            LocationServiceFactory().getLocationService(type: $1)
        }

        container.register(SingleLocationTask.self) {
            LocationTaskFactory().singleLocationTask(request: $1)
        }

        container.register(ContinueLocationTask.self) {
            LocationTaskFactory().continueLocationTask(request: $1)
        }

        container.register(LocationAuthorization.self) { _ in
            LocationAuthorizationImp.shared
        }.inObjectScope(.container)
    }
}
