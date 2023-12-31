//
//  DynamicHandlerGetter.swift
//  JsSDK
//
//  Created by Miaoqi Wang on 2021/1/14.
//

import Foundation
import Swinject
import WebBrowser
import ECOInfra
import LarkContainer

public struct DynamicJsAPIHandlerProvider: JsAPIHandlerProvider {

    public let handlers: JsAPIHandlerDict

    public init(api: WebBrowser, resolver: UserResolver) {
        self.handlers = [
            "biz.util.conf.fg.get": { FeatureGatingConfigHandler(resolver: resolver) },
            "biz.util.base.env.get": { LarkEnvHandler(resolver: resolver) },
            "biz.util.meta.check": { CheckJSAPIHandler(resolver: resolver) },
            "biz.contact.external.invite": { ContactExternalInviteHandler() },
            "biz.util.sys.share.external": { ShareSnsHandler() },
            "biz.util.sys.share.pastePanel": { SnsContentPasteHandler() }
        ]
    }
}
