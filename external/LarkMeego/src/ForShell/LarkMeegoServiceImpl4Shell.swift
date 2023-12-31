//
//  LarkMeegoServiceImpl4Shell.swift
//  LarkMeego
//
//  Created by shizhengyu on 2022/9/8.
//

import Foundation
import LarkContainer
import LarkMeegoInterface

public protocol LarkMeegoServiceShellInterface {
    func register4shell(user: ContainerWithScope<UserResolver>)
    func registerUrlHooks(with configs: [String: Any])
}

public class LarkMeegoServiceShell: LarkMeegoServiceShellInterface {
    public let userResolver: UserResolver

    public init(userResovler: UserResolver) {
        self.userResolver = userResovler
    }

    public func register4shell(user: ContainerWithScope<UserResolver>) {
        user.register(LarkMeegoService.self) { r in
            return try LarkMeegoServiceImpl4Shell(userResolver: r)
        }
    }

    public func registerUrlHooks(with configs: [String: Any]) {
        ((try? userResolver.resolve(assert: LarkMeegoService.self)) as? LarkMeegoServiceImpl)?.registerURLHooks(with: configs)
    }
}

final class LarkMeegoServiceImpl4Shell: LarkMeegoServiceImpl {
    override func canTouch(for entry: EntryType, needDiagnosis: Bool = true) -> Bool {
        return true
    }

    override func isPaidUser() -> Bool {
        return true
    }

    override func isNotMemoryProtectedDevice() -> Bool {
        return true
    }
}
