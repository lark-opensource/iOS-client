//
//  KeyboardEventHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/27.
//

import WebBrowser
import LKCommonsLogging
import LarkKeyboardKit
import EENavigator
import RxSwift

class KeyboardEventHandler: JsAPIHandler {

    private static let logger = Logger.log(KeyboardEventHandler.self, category: "KeyboardEventHandler")
    private let disposeBag = DisposeBag()

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        KeyboardEventHandler.logger.debug("handle args = \(args))")
        self.registerKeyboardChange(args: args, api: api)
    }

    func registerKeyboardChange(args: [String: Any], api: WebBrowser) {
        guard let currentVC = Navigator.shared.navigation?.topViewController else { // Global
            return
        }

        KeyboardKit.shared.keyboardHeightChange(for: currentVC.view).drive(onNext: { (keyboardHeight) in
            api.sendKeyboardHeightChangeEvent(keyboardHeight: keyboardHeight)
        }).disposed(by: self.disposeBag)
    }
}

extension WebBrowser {

    func sendKeyboardHeightChangeEvent(keyboardHeight: CGFloat) {
        let arguments = ["currentHeight": keyboardHeight] as [String: Any]
        let eventScript = jsCustomEventScript(name: "sys.event.keyboard.heightChange",
                                              arguments: arguments)
        webView.evaluateJavaScript(eventScript)
    }
}
