//
//  NativeBrowserView+Invoke.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2021/7/9.
//

import SKFoundation
import SKUIKit
import SKCommon
import SKEditor

extension NativeBrowserView: EditorInvokeDelegate {
    public func invoke(method: String, params: [String: Any]?) {
        DocsLogger.debug("收到内部编辑器消息，派发到对应插件, messge=\(method)")
        jsServiceManager.handle(message: method, params ?? [:])
    }
}
