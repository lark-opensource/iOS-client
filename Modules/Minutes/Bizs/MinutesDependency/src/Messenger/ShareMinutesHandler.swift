//
//  ShareMinutesHandler.swift
//  MinutesMod
//
//  Created by Todd Cheng on 2021/2/3.
//

#if MessengerMod

import Foundation
import EENavigator
import Swinject
import MinutesInterface
import MinutesNavigator
import LarkNavigation
import LarkUIKit
import LarkTab
import Minutes
import LKCommonsLogging
import LarkNavigator
import LarkFeatureGating
import LKCommonsLogging
import LarkForward
import LarkMessengerInterface
import LarkAccountInterface
import LarkSDKInterface

public final class ShareMinutesHandler: UserTypedRouterHandler, ForwardAndShareHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }

    static let shareLogger = Logger.log(ShareMinutesHandler.self, category: "Module.Minutes.Share")

    @FeatureGating("im.chatterpicker.forward") var chatterpickerFG: Bool

    public func handle(_ body: ShareMinutesBody, req: Request, res: Response) throws {
        try createForward(body: body, request: req, response: res)
    }

    private func createForward(body: ShareMinutesBody, request: EENavigator.Request, response: Response) throws {
        let content = ShareMinutesAlertContent(minutesURLString: body.minutesURLString)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        if let router = try? userResolver.resolve(assert: ForwardViewControllerRouterProtocol.self) {
            let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
            let nvc = LkNavigationController(rootViewController: vc)
            response.end(resource: nvc)
        }
    }
}

#endif
