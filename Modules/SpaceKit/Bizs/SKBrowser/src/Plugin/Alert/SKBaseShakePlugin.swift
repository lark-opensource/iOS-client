//
//  SKBaseShakePlugin.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/15.
//

import Foundation
import SKCommon

class SKBaseImpactFeedbackPlugin: JSServiceHandler {
    var logPrefix: String = ""

    var handleServices: [DocsJSService] = [.utilImpactEffect]
    func handle(params: [String: Any], serviceName: String) {
        let styleStr = params["grade"] as? String
        let style = UIImpactFeedbackGenerator.FeedbackStyle.typeFrom(styleStr)
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

extension UIImpactFeedbackGenerator.FeedbackStyle {
    static func typeFrom(_ str: String?) -> UIImpactFeedbackGenerator.FeedbackStyle {
        guard let str = str?.lowercased() else {
            return .medium
        }
        var style = UIImpactFeedbackGenerator.FeedbackStyle.medium
        if str == "light" {
            style = .light
        } else if str == "medium" {
            style =  .medium
        } else if str == "heavy" {
            style = .heavy
        }
        return style
    }
}
