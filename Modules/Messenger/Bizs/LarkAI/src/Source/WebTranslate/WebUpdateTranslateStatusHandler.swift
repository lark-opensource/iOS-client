//
//  WebUpdateTranslateStatusHandler.swift
//  JsSDK
//
//  Created by JackZhao on 2020/8/17.
//

import Foundation
import LKCommonsLogging
import WebBrowser
import Swinject

// a notification of update translation schedule
final class WebUpdateTranslateStatusHandler: LarkWebJSAPIHandler {

    static let logger = Logger.log(WebUpdateTranslateStatusHandler.self, category: "Module.LarkAI")
    private weak var translateViewModel: WebTranslateViewModel?

    init(translateViewModel: WebTranslateViewModel) {
        self.translateViewModel = translateViewModel
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: LarkWebJSSDK) {
        guard let translateStatus = args["translateStatus"] as? String,
            let targetLang = args["targetLang"] as? [String: String],
            let originLang = args["originLang"] as? [String: String] else { return }
        let webInfo = WebTranslateProcessInfo(status: WebTranslateStatus(rawValue: translateStatus) ?? .unknown,
                                              originLangName: originLang["name"] ?? "",
                                              originLangCode: originLang["code"] ?? "",
                                              targetLangName: targetLang["name"] ?? "",
                                              targetLangCode: targetLang["code"] ?? "")
        translateViewModel?.updateTranslateProcessInfo(webInfo)
        translateViewModel?.sendTranslateBarStateChangedEvent(true)
    }
}
