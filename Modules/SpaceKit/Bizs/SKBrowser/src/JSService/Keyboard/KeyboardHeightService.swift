//
//  KeyboardHeightService.swift
//  SKBrowser
//
//  Created by liujinwei on 2023/1/4.
//  


import Foundation
import SKCommon

class KeyboardHeightService: BaseJSService {}

extension KeyboardHeightService: JSServiceHandler {
    
    var handleServices: [DocsJSService] {
        return [.keyboardHeight]
    }
    
    func handle(params: [String : Any], serviceName: String) {
        if let active = params["active"] as? Bool {
            ///设置keyboardType为keyboard，biz.util.onKeyboardChanged会返回前端webview被键盘遮挡住的高度
            let trigger = active ? DocsKeyboardTrigger.keyboard.rawValue : DocsKeyboardTrigger.editor.rawValue
            ui?.uiResponder.setTrigger(trigger: DocsKeyboardTrigger.keyboard.rawValue)
        }
    }
    
}
