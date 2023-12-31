//
//  UploadImageHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import WebBrowser
import RxSwift
import LKCommonsLogging
import EENavigator
import LarkMessengerInterface
import LarkContainer

class UploadImageHandler: JsAPIHandler {
    static let logger = Logger.log(UploadImageHandler.self, category: "Module.JSSDK")

    private let resolver: UserResolver
    
    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        UploadImageHandler.logger.info("UploadImageHandler call begin")
        let multiple = args["multiple"] as? Bool ?? false
        guard let max = args["max"] as? Int else {
            UploadImageHandler.logger.error("Parameters invalid \(args.description)")
            return
        }

        var body = UploadImageBody(multiple: multiple, max: max)
        body.uploadSuccess = { [weak api] urls in
            UploadImageHandler.logger.info("UploadImageHandler callback success")
            callback.callbackSuccess(param: urls)
        }
        resolver.navigator.present(
            body: body,
            from: api,
            prepare: { (vc) in
                vc.modalPresentationStyle = .overFullScreen
            },
            animated: false
        )
        UploadImageHandler.logger.info("UploadImageHandler call end")
    }
}
