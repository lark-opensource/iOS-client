//
//  OPBlockComponentWebBrowserItem.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/3/28.
//

import Foundation
import WebBrowser

// 注册 web API 扩展，WebBrowserExtensionSingleItemProtocol
// 注册 web lifecycle 扩展，WebBrowserExtensionItemProtocol
class OPBlockComponentWebBrowserItem: WebBrowserExtensionItemProtocol, WebBrowserExtensionSingleItemProtocol {

    private weak var blockWebRender: OPBlockWebRender?
    private weak var blockWebWorker: OPBlockWebWorker?

    init(render: OPBlockWebRender, worker: OPBlockWebWorker) {
        self.blockWebRender = render
        self.blockWebWorker = worker
    }

    var navigationDelegate: WebBrowserNavigationProtocol? {
        return blockWebRender
    }

    var callAPIDelegate: WebBrowserCallAPIProtocol? {
        return blockWebWorker
    }
}
