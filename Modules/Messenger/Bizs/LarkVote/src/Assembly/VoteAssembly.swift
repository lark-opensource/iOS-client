//
//  VoteAssembly.swift
//  LarkVote
//
//  Created by phoenix on 2022/4/17.
//

import Foundation
import Swinject
import LarkAssembler
import LarkMessengerInterface
import EENavigator
import RustPB
import LarkRustClient
import LarkNavigator

/// VoteAssembly
public final class VoteAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        container.inObjectScope(.userGraph).register(LarkVoteService.self) { r -> LarkVoteService in
            return LarkVoteServiceImpl(resolver: r)
        }
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(CreateVoteBody.self).factory(CreateVoteHandler.init(resolver:))
    }
}

final class CreateVoteHandler: UserTypedRouterHandler {
    func handle(_ body: CreateVoteBody, req: EENavigator.Request, res: Response) throws {

        let vc = CreateVoteViewController(userResolver: userResolver, containerType: body.scene, scopeID: body.scopeID)
        res.end(resource: vc)
    }
}
