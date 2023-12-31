//
//  LarkGuideAssembly.swift
//  LarkGuide
//
//  Created by CharlieSu on 1/2/20.
//

import Foundation
import Swinject
import LarkContainer
import LarkRustClient
import LarkDebugExtensionPoint
import LarkAssembler

public final class LarkGuideAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        container.register(LarkGuideDependency.self) { _ -> LarkGuideDependency in
            return LarkGuideDependencyImpl(resolver: container)
        }

        container.register(ProductGuideAPI.self) { (r) -> ProductGuideAPI in
            return RustProductGuideAPI(client: r.resolve(RustService.self)!)
        }.inObjectScope(.user)

        container.register(GuideService.self) { r in
            return GuideManager(productGuideAPI: r.resolve(ProductGuideAPI.self)!,
                                pushObservable: r.pushCenter.observable(for: PushProductGuideMessage.self))
        }.inObjectScope(.user)

        container.register(UserGuideAPI.self) { (r) -> UserGuideAPI in
            return RustUserGuideAPI(client: r.resolve(RustService.self)!)
        }.inObjectScope(.user)

        container.register(NewGuideService.self) { r in
            let dependency = r.resolve(LarkGuideDependency.self)!
            let currentUserId = dependency.userId
            return NewGuideManager(pushGuideObservable: r.pushCenter.observable(for: PushUserGuideUpdatedMessage.self),
                                   currentUserId: currentUserId)
        }.inObjectScope(.user)
    }

    public func registDebugItem(container: Container) {
        ({LarkGuideDebugItem()}, SectionType.debugTool)
    }

    public func registPushHandler(container: Container) {
        getRegistPush(pushCenter: container.pushCenter)
    }

    private func getRegistPush(pushCenter: PushNotificationCenter) -> [Command: RustPushHandlerFactory] {
        let factories: [Command: RustPushHandlerFactory] = [
            .pushProductGuide: {
                ProductGuidePushHandler(pushCenter: pushCenter)
            },
            .userGuideUpdatedRequest: {
                UserGuideUpdatedPushHandler(pushCenter: pushCenter)
            }
        ]
        return factories
    }
}
