//
//  WebChangeBannerHandler.swift
//  JsSDK
//
//  Created by JackZhao on 2020/8/17.
//

import Foundation
import LKCommonsLogging
import WebBrowser
import RxSwift
import Swinject

// change translation floating window state to display or hidden
final class WebChangeBannerHandler: LarkWebJSAPIHandler {

    static let logger = Logger.log(WebChangeBannerHandler.self, category: "Module.LarkAI")

    private weak var translateViewModel: WebTranslateViewModel?
    private let disposeBag = DisposeBag()

    init(translateViewModel: WebTranslateViewModel) {
        self.translateViewModel = translateViewModel
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: LarkWebJSSDK) {
        guard let isShow = args["isShow"] as? Bool else {
            return
        }
        let isBarClose = translateViewModel?.isBarClose ?? false
        Self.logger.debug("isShow = \(isShow), isBarClosed = \(isBarClose)")
        if !isBarClose {
            translateViewModel?.sendTranslateBarStateChangedEvent(isShow)
        }
        let callback = args["callback"] as? String
        self.callbackWith(api: api, funcName: callback, arguments: [[
            "isClose": isBarClose
        ]])
    }
}
