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
import LKCommonsLogging
import LarkAccountInterface
import LarkAppLinkSDK
import Minutes
import LarkMessengerInterface


public final class ShareMinutesApplinkHandler {

    static let logger = Logger.log(ShareMinutesApplinkHandler.self, category: "Module.Minutes.applink.Share")

    public static let pattern = "/client/vc/minutes/share"
    
    public static func handle(applink: AppLink) {
        logger.info("start handle block share minutes applink", additionalData: ["url": applink.url.absoluteString])

        if let userID = try? Container.shared.resolve(assert: PassportService.self).foregroundUser?.userID,
           let resolver = try? Container.shared.getUserResolver(userID: userID),
           let from = resolver.navigator.mainSceneTopMost {
            let queryParameters = applink.url.queryParameters
            let url = queryParameters["mm_url"] ?? ""
            let body = ShareContentBody(title: "", content: url)
            resolver.navigator.present(body: body, from: from, prepare: { $0.modalPresentationStyle = .formSheet})
            let conferenceID = queryParameters["conference_id"] ?? ""
            BusinessTracker().tracker(name: .popupClick, params: ["click": "share_all", "conference_id": conferenceID])
        }
    }
}
#endif
