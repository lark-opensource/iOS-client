//
//  DocBrowserViewController+DocComponent.swift
//  SKDoc
//
//  Created by lijuyou on 2023/5/25.
//  


import Foundation
import SpaceInterface
import SKBrowser
import SKCommon

extension DocBrowserViewController: DocComponentHost {

    public var browserView: BrowserModelConfig? {
        self.editor
    }
    
    public var showCloseInDocComponent: Bool {
        guard let pageConfig = self.docComponentHostDelegate?.config.pageConfig else {
            return false
        }
        return pageConfig.showCloseButton
    }
    
    public func onSetup(hostDelegate: DocComponentHostDelegate?) {
        self.docComponentHostDelegate = hostDelegate
        self.editor.docComponentDelegate = hostDelegate
        if let observer = hostDelegate {
            self.editor.browserViewLifeCycleEvent.addObserver(observer)
        }
    }

    public func invokeDCCommand(function: String, params: [String: Any]?) {
        self.editor.callFunction(DocsJSCallBack(rawValue: function), params: params, completion: nil)
    }
}
