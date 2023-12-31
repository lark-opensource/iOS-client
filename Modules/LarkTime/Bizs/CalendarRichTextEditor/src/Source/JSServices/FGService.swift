//
//  FGService.swift
//  CalendarRichTextEditor
//
//  Created by Hongbin Liang on 11/22/22.
//

import Foundation
import LarkFeatureGating

final class FGService: JSServiceHandler {

    weak var jsEngine: RichTextViewJSEngine?
    weak var uiDisplayConfig: RichTextViewDisplayConfig?

    init(jsEngine: RichTextViewJSEngine, _ uiDisplayConfig: RichTextViewDisplayConfig) {
        self.jsEngine = jsEngine
        self.uiDisplayConfig = uiDisplayConfig
    }

    var handleServices: [JSService] {
        return [.rtDocsAutoAuthFG]
    }

    func handle(params: [String: Any], serviceName: String) {
        Logger.info("getFGValues", extraInfo: ["fgParams": params.debugDescription])
        guard let callback = params["callback"] as? String else {
            Logger.info("callback 传空了")
            return
        }

        guard let keys = params["keys"] as? [String] else { return }

        let fgValue = Dictionary(uniqueKeysWithValues: keys.map {
            ($0, LarkFeatureGating.shared.getStaticBoolValue(for: $0))
        })
        Logger.info("passFGValues", extraInfo: ["values": fgValue.debugDescription])
        jsEngine?.callFunction(JSCallBack(callback), params: fgValue, completion: nil)
    }
}
