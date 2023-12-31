//
//  ContainerTest.swift
//  LarkContainerDevEEUnitTest
//
//  Created by SolaWing on 2023/4/3.
//

import XCTest
import LarkContainer

// swiftlint:disable missing_docs

@objc
public protocol ObjcProp: NSObjectProtocol {
    func hello() -> String
}

@objc
public protocol ObjcProp2 {
    @objc
    optional func hello2() -> String
}

@objc
public final class ContainerTest: XCTestCase {
    @objc
    public class ObjcTypeA: NSObject, ObjcProp, ObjcProp2 {
        public func hello() -> String { "hello" }
        public func hello2() -> String { "hello" }
    }
    static let userTestContainer = {
        let container = Container()
        return container
    }()

    /// provider a UserResolver to test in objc environment
    @objc
    public static func setupContainer() -> LKUserResolver {
        Container.shared.register(ObjcTypeA.self) { _ in
            ObjcTypeA()
        }.objc()
        Container.shared.register(ObjcProp.self) { _ in
            ObjcTypeA()
        }.objc()
        Container.shared.register(ObjcProp2.self) { _ in
            ObjcTypeA()
        }.objc()

        return LKResolver.shared.getCurrentUserResolver()
    }

    class UserService {
        let userResolver: UserResolver
        init(userResolver: UserResolver) {
            self.userResolver = userResolver
        }
    }
    func setup(container: Container) {
        let foreground = container.inObjectScope(.user(type: .foreground))
        let background = container.inObjectScope(.user(type: .background))
        let both = container.inObjectScope(UserLifeScope(type: .both, compatible: { false }))
        let compatible = container.inObjectScope(UserLifeScope(type: .both, compatible: { true }))

        let foregroundGraph = container.inObjectScope(.user(type: .foreground, lifetime: .graph))
        let backgroundGraph = container.inObjectScope(.user(type: .background, lifetime: .graph))
        let bothGraph = container.inObjectScope(UserGraphScope(type: .both, compatible: { false }))
        let compatibleGraph = container.inObjectScope(UserGraphScope(type: .both, compatible: { true }))

        let foregroundTransient = container.inObjectScope(.user(type: .foreground, lifetime: .transient))
        let backgroundTransient = container.inObjectScope(.user(type: .background, lifetime: .transient))
        let bothTransient = container.inObjectScope(UserTransientScope(type: .both, compatible: { false }))
        let compatibleTransient = container.inObjectScope(UserTransientScope(type: .both, compatible: { true }))

        // user scope
        foreground.register(UserService.self, name: "foreground", factory: UserService.init)
        background.register(UserService.self, name: "background", factory: UserService.init)
        both.register(UserService.self, name: "both", factory: UserService.init)
        compatible.register(UserService.self, name: "compatible", factory: UserService.init)
        container.register(UserService.self, name: "global") { _ in
            UserService(userResolver: container.getCurrentUserResolver())
        }
        container.register(UserService.self, name: "globalSafe") { _ in
            UserService(userResolver: container.getCurrentUserResolver())
        }.userSafe()

        // graph scope
        foregroundGraph.register(UserService.self, name: "foregroundGraph", factory: UserService.init)
        backgroundGraph.register(UserService.self, name: "backgroundGraph", factory: UserService.init)
        bothGraph.register(UserService.self, name: "bothGraph", factory: UserService.init)
        compatibleGraph.register(UserService.self, name: "compatibleGraph", factory: UserService.init)

        // transient scope
        foregroundTransient.register(UserService.self, name: "foregroundTransient", factory: UserService.init)
        backgroundTransient.register(UserService.self, name: "backgroundTransient", factory: UserService.init)
        bothTransient.register(UserService.self, name: "bothTransient", factory: UserService.init)
        compatibleTransient.register(UserService.self, name: "compatibleTransient", factory: UserService.init)
    }
}

// swiftlint:enable missing_docs
