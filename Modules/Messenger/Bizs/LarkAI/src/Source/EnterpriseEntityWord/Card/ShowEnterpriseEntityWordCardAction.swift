//
//  ShowEnterpriseEntityWordCardAction.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/1/12.
//

import Foundation
import UIKit
import LarkModel
import LarkUIKit
import LarkContainer
import LarkSDKInterface
import LarkMenuController
import EENavigator
import Swinject
import LKCommonsLogging
import LarkMessengerInterface
import RustPB

public final class ShowEnterpriseEntityWordCardMessage: LarkContainer.Request {
    public typealias Response = EmptyResponse

    let abbrId: String
    let chatId: String
    let triggerView: UIView
    let triggerLocation: CGPoint?

    public init(abbrId: String,
                chatId: String,
                triggerView: UIView,
                triggerLocation: CGPoint?) {
        self.abbrId = abbrId
        self.chatId = chatId
        self.triggerView = triggerView
        self.triggerLocation = triggerLocation
    }
}

public final class ShowEnterpriseEntityWordCardAction: LarkContainer.RequestHandler<ShowEnterpriseEntityWordCardMessage>, UserResolverWrapper {
    public let userResolver: UserResolver
    private weak var targetVC: UIViewController?
    private let enterpriseEntityWordService: EnterpriseEntityWordService?
    public init(userResolver: UserResolver, targetVC: UIViewController?) {
        self.userResolver = userResolver
        self.targetVC = targetVC
        self.enterpriseEntityWordService = try? userResolver.resolve(assert: EnterpriseEntityWordService.self)
    }

    public override func handle(_ request: ShowEnterpriseEntityWordCardMessage) -> EmptyResponse? {
        enterpriseEntityWordService?.showEnterpriseTopic(abbrId: request.abbrId,
                                                           query: "",
                                                           chatId: request.chatId,
                                                           sense: .messenger,
                                                           targetVC: targetVC,
                                                           completion: nil)
        return EmptyResponse()
    }
}
