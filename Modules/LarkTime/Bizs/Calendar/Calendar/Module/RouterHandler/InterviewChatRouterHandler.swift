//
//  InterviewChatRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class InterviewChatRouterHandler: UserRouterHandler {

    private let useV1: Bool

    init(resolver: UserResolver, useV1: Bool) {
        self.useV1 = useV1
        super.init(resolver: resolver)
    }

    func handle(req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let handler = try resolver.resolve(assert: InterviewChatService.self)
        if useV1 {
            handler.handleV1(req: req, res: res)
        } else {
            handler.handleV2(req: req, res: res)
        }
    }

}
