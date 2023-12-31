//
//  WebGetDetectSettingHandler.swift
//  JsSDK
//
//  Created by JackZhao on 2020/8/17.
//

import Foundation
import LKCommonsLogging
import WebBrowser
import RxSwift
import Swinject
import LarkSDKInterface

// get detect setting from settingV3
final class WebGetDetectSettingHandler: LarkWebJSAPIHandler {

    static let logger = Logger.log(WebGetDetectSettingHandler.self, category: "Module.LarkAI")

    private let webTranslateAppSetting: WebTranslateAppSettingHelper
    private let disposeBag = DisposeBag()

    init(webTranslateAppSetting: WebTranslateAppSettingHelper) {
        self.webTranslateAppSetting = webTranslateAppSetting
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: LarkWebJSSDK) {
        let sampleTextMaxContentLength = webTranslateAppSetting.getSampleMaxLength()
        Self.logger.info("sampleTextMaxContentLength=\(sampleTextMaxContentLength)")
        if let callback = args["callback"] as? String {
            api.call(funcName: callback, arguments: [[
                "maxContentLen": sampleTextMaxContentLength ?? 1000
            ]])
        }
        if let onFailed = args["onFailed"] as? String {
            api.call(funcName: onFailed, arguments: [[
            ]])
        }
    }
}
