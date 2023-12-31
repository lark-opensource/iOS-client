//
//  SuiteLoginWebViewManager.swift
//  LarkCreateTeam
//
//  Created by quyiming@bytedance.com on 2019/10/15.
//

import Foundation
import LarkCore
import LarkAccountInterface
import WebBrowser

class SuiteLoginWebViewFactoryImpl: SuiteLoginWebViewFactory {
    func createWebViewController(_ url: URL, customUserAgent: String?) -> UIViewController {
        return controllerCreator(url, customUserAgent)
    }

    func createFailView() -> UIView {
        return LoadWebFailPlaceholderView()
    }

    private let controllerCreator: (URL, String?) -> WebBrowser

    init(controllerCreator: @escaping (URL, String?) -> WebBrowser) {
        self.controllerCreator = controllerCreator
    }
}
