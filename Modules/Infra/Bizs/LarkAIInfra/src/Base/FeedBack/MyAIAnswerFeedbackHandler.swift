//
//  MyAIAnswerFeedbackHandler.swift
//  LarkAIInfra
//
//  Created by 李勇 on 2023/6/16.
//

import Foundation
import EENavigator
import LarkNavigator
import LarkContainer
import LarkUIKit

final public class MyAIAnswerFeedbackHandler: UserTypedRouterHandler {
    public func handle(_ body: MyAIAnswerFeedbackBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let viewModel = AnswerFeedbackViewModel(userResolver: self.userResolver, aiMessageId: body.aiMessageId, scenario: body.scenario, mode: body.mode)
        let viewController = AnswerFeedbackViewController(viewModel: viewModel)
        res.end(resource: viewController)
    }
}
