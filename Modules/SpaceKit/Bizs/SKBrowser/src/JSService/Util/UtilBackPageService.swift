//
//  UtilBackPageService.swift
//  SKBrowser
//
//  Created by zoujie on 2021/9/22.
//  

import SKFoundation
import SKCommon
import SKUIKit

public final class UtilBackPageService: BaseJSService { }

extension UtilBackPageService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.backPrePage]
    }

    public func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("前端调用退出当前文档页面")
        if let browserVC = self.navigator?.currentBrowserVC as? BrowserViewController {
            let popBlock = { [weak self] in
                self?.navigator?.popViewController(canEmpty: true)
            }
            if let presentedVC = browserVC.presentedViewController {
                presentedVC.dismiss(animated: false, completion: {
                    popBlock()
                })
            } else {
                popBlock()
            }
        }
    }
}
