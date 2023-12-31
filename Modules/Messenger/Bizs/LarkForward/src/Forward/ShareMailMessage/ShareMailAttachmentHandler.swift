//
//  ShareMailAttachmentProvider.swift
//  LarkForward
//
//  Created by Ryan on 2020/9/29.
//
import Foundation
import UIKit
import RxSwift
import UniverseDesignToast
import LarkModel
import Kingfisher
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import LKCommonsLogging
import EENavigator
import Homeric
import LKCommonsTracker
import Swinject
import LarkFeatureGating
import LarkAccountInterface
import LarkUIKit
import LarkOpenFeed
import LarkNavigator

public final class ShareMailAttachmentHandler: UserTypedRouterHandler {
    static let shareLogger = Logger.log(ShareMailAttachmentHandler.self, category: "Module.IM.Share")

    public func handle(_ body: ShareMailAttachementBody, req: EENavigator.Request, res: Response) throws {
        createForward(body: body, request: req, response: res)
    }
    private func createForward(body: ShareMailAttachementBody, request: EENavigator.Request, response: Response) {

        let content = ShareMailAttachmentAlertContent(title: body.title, img: body.img, token: body.token, isLargeAttachment: body.isLargeAttachment)

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        vc.forwardResultsCallBack = body.forwardResultsCallBack
        let nvc = LkNavigationController(rootViewController: vc)
        response.end(resource: nvc)
    }
}
