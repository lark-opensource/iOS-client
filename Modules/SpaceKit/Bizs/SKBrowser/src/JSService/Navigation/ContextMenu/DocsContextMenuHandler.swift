//
//  WebViewMenuHandler.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/29.
//  
//负责上下文菜单的创建/响应.不负责展示/隐藏

import Foundation
import SKCommon
import SKUIKit
import WebKit

protocol WebViewMenuHandlerDelegate: AnyObject {
    
}

extension BrowserView: WebViewMenuHandlerDelegate {
}

class DocsContextMenuHandler {
    private weak var editorView: DocsEditorViewProtocol?
    private unowned var uicontext: BrowserModelConfig?
    weak var delegate: WebViewMenuHandlerDelegate?
    init(editorView: DocsEditorViewProtocol?, context: BrowserModelConfig?) {
        self.editorView = editorView
        self.uicontext = context
    }
}

extension DocsContextMenuHandler: BrowserViewMenuHandler {
    func selectAction() {
        guard let webView = editorView as? DocsWebViewProtocol else {
            return
        }
        webView.safeSendMethod(selector: #selector(type(of: webView as WKWebView).select(_:)))
    }
    func selectAllAction() {
        guard let webView = editorView as? DocsWebViewProtocol else {
            return
        }
        webView.safeSendMethod(selector: #selector(type(of: webView as WKWebView).selectAll(_:)))
    }
    func cutAction() {
        var wikiToken: String?
        if let wikiInfo = self.uicontext?.browserInfo.docsInfo?.wikiInfo {
            wikiToken = wikiInfo.wikiToken
        }
        SecurityReviewManager.reportAction(self.uicontext?.browserInfo.docsInfo?.type ?? .doc,
                                           operation: OperationType.operationsCopy,
                                           token: self.uicontext?.browserInfo.docsInfo?.objToken ?? "",
                                           appInfo: nil,
                                           wikiToken: wikiToken)
        
        guard let webView = editorView as? DocsWebViewProtocol else {
            return
        }
        webView.safeSendMethod(selector: #selector(type(of: webView as WKWebView).cut(_:)))
    }
    func copyAction() {
        var wikiToken: String?
        if let wikiInfo = self.uicontext?.browserInfo.docsInfo?.wikiInfo {
            wikiToken = wikiInfo.wikiToken
        }
        SecurityReviewManager.reportAction(self.uicontext?.browserInfo.docsInfo?.type ?? .doc,
                                           operation: OperationType.operationsCopy,
                                           token: self.uicontext?.browserInfo.docsInfo?.objToken ?? "",
                                           appInfo: nil,
                                           wikiToken: wikiToken)

        guard let webView = editorView as? DocsWebViewProtocol else {
            return
        }
        webView.safeSendMethod(selector: #selector(type(of: webView as WKWebView).copy(_:)))
    }
    func pasteAction() {
        guard let webView = editorView as? DocsWebViewProtocol else {
            return
        }
        webView.safeSendMethod(selector: #selector(type(of: webView as WKWebView).paste(_:)))
    }

    func setContextMenus(items: [UIMenuItem]) {
        guard let webView = editorView as? DocsWebViewProtocol else {
            return
        }
        webView.skContextMenu.items = items
    }

    func makeContextMenuItem(with uid: String, title: String, action: @escaping () -> Void) -> UIMenuItem? {
        guard let webView = editorView as? DocsWebViewProtocol else {
            return nil
        }
        return webView.wkMenuItem(uid: uid, title: title, action: action)
    }
    
    
    func setEditMenus(menus: [EditMenuCommand]) {
        guard let webView = editorView as? DocsWebViewProtocol else {
            return
        }
        webView.skContextMenu.editMenuItems = menus
    }
    
    func makeEditMenuItem(with uid: String, title: String, action: @escaping () -> Void) -> EditMenuCommand? {
        guard let webView = editorView as? DocsWebViewProtocol else {
            return nil
        }
        return webView.wkEditMenuItem(uid: uid, title: title, action: action)
    }
    
}
