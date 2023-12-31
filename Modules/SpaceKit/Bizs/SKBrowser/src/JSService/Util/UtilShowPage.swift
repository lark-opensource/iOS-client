//
//  UtilShowPage.swift
//  SKBrowser
//
//  Created by LiXiaolin on 2021/2/24.
//  


import Foundation
import SKCommon
import SKUIKit

public final class UtilShowPage: BaseJSService { }

extension UtilShowPage: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilShowPage]
    }

    public func handle(params: [String: Any], serviceName: String) {
        guard let appealUrl = params["appealUrl"] as? String,
              let linkURl = URL(string: appealUrl) else { return }

        if let browserVC = self.navigator?.currentBrowserVC as? BrowserViewController {
            browserVC.browerEditor?.requiresOpen(url: linkURl)
        }
    }
}
