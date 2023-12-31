//  Created by weidong fu on 5/2/2018.

import Foundation
import WebKit
import SKCommon

// 前端调用拉起键盘的 JS Bridge，webview 里面收起键盘要前端主动 editor.blur()，严重不建议使用 webView.resignFirstResponder()。
// 原因可以参考 https://bytedance.feishu.cn/wiki/wikcn9TwCmp4cVAxO4zEhwTw0Ef


//window.webkit.messageHandlers.invoke.postMessage({'method': 'biz.util.showKeyboard', 'args': {}})
public final class UtilKeyboardService {
    weak var browserViewResponder: BrowserUIResponder?
    lazy var internalPlugin: SKBaseRespondH5KeyboardPlugin = {
        let config = SKBaseRespondH5KeyboardPluginConfig(responder: browserViewResponder, trigger: DocsKeyboardTrigger.editor.rawValue)
        let plugin = SKBaseRespondH5KeyboardPlugin(config: config)
        return plugin
    }()
    init(_ responder: BrowserUIResponder) {
        self.browserViewResponder = responder
    }
}

extension UtilKeyboardService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return internalPlugin.handleServices
    }

    public func handle(params: [String: Any], serviceName: String) {
        internalPlugin.handle(params: params, serviceName: serviceName)
    }
}
