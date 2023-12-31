//
//  OpenShareHandler.swift
//  LarkForward
//
//  Created by huangjianming on 2020/2/14.
//

import Foundation
import UIKit
import EENavigator
import LarkMessengerInterface
import Swinject
import LarkAccountInterface
import LarkSDKInterface
import LarkFeatureGating
import LarkUIKit
import UniverseDesignToast
import LKCommonsLogging
import LarkOpenFeed
import LarkNavigator

final class OpenShareHandler: UserTypedRouterHandler, ForwardAndShareHandler {
    static let logger = Logger.log(OpenShareHandler.self, category: "LarkForward.OpenShareHandler")

    func isOversea() -> Bool {
        /// 租户维度的，非飞书租户即海外租户
        guard let passportUserService = try? userResolver.resolve(assert: PassportUserService.self) else { return false }
        return !passportUserService.isFeishuBrand
    }

    public func handle(_ body: OpenShareBody, req: EENavigator.Request, res: Response) throws {
        createForward(body: body, request: req, response: res)
    }

    private func createForward(body: OpenShareBody, request: EENavigator.Request, response: Response) {
        // 非登录状态延迟至登录成功后触发
        if (try? userResolver.resolve(assert: PassportUserService.self))?.user == nil {
            Self.logger.info("OpenShare: account logout")
            ForwardSetupTask.markShowOpenShare()
            return
        }
        Self.logger.info("OpenShare: account login")

        // 海外版屏蔽该功能
        if self.isOversea() {
            guard let from = request.context.from(),
                  let window = from.fromViewController?.view.window else {
                      Self.logger.info("OpenShare: window is nil")
                      assertionFailure()
                      return
                  }
            UDToast.showTips(
                with: BundleI18n.LarkForward.Lark_Legacy_ErrorMessageTip,
                on: window
            )
            response.end(resource: nil)
            Self.logger.info("OpenShare: oversea version forbidden")
            return
        }

        let content = OpenShareContentAlertContent()
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else {
            Self.logger.info("OpenShare: ForwardAlertProvider create failed")
            return
        }

        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        vc.shouldDismissWhenResignActive = true
        let nvc = LkNavigationController(rootViewController: vc)
        response.end(resource: nvc)
        Self.logger.info("OpenShare: NewForwardViewController present")
    }
}
