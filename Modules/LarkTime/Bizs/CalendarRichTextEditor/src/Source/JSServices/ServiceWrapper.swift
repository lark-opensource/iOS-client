//
//  ServiceWrapper.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/8/2.
//

import Foundation

// SDK 2.0适配1.0接口的service
// 2.0接口通过bridge调用，即前端告知 js callback，native回调时通过该动态生成的callback回调
// 1.0则是直来直去，直接evaluateJS(xxxxx)，没有动态的callback
extension JSService {
    // https://bytedance.feishu.cn/space/doc/doccnKborZ42znZ3ox8oRpWrF3b

}

final class ServiceWrapper {
    weak var bridgeConfig: RichTextViewBridgeConfig?
    var avaiabledService: Set<JSService> = [
        .richTextSetStyle,
        .richTextGetContent,
        .richTextGetHtml,
        .richTextGetRect,
        .richTextRender,
        .richTextGetText,
        .richTextSetContent,
        .richTextClearContent,
        .richTextIsChanged,
        .richTextSetEditable,
        .richTextSetPlaceholder,
        .rtDocsAutoAuthFG
    ]

    init (bridgeConfig: RichTextViewBridgeConfig) {
        self.bridgeConfig = bridgeConfig
    }
}

extension ServiceWrapper: JSServiceHandler {
    var handleServices: [JSService] {
        return Array(avaiabledService)
    }

    func handle(params: [String: Any], serviceName: String) {
        guard avaiabledService.contains(where: { return $0.rawValue == serviceName }) else { return }
        Logger.info("RichText v2 wrapper did recive bridge callback", extraInfo: [serviceName: params])
        if let callback = params["callback"] as? String {
            bridgeConfig?.setJSBridge(callback, for: serviceName)
        }
    }
}
