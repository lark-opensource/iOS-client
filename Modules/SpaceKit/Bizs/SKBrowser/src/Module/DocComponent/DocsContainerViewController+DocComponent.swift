//
//  DocsContainerViewController+DocComponent.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/6/12.
//  



import SKFoundation
import SKUIKit
import SpaceInterface
import SKCommon

extension DocsContainerViewController: DocComponentContainerHost {
    
    var browserView: BrowserModelConfig? {
        self.contentVC.browserView
    }
    
    var contentHost: DocComponentHost? {
        self.contentVC
    }

    func invokeDCCommand(function: String, params: [String: Any]?) {
        self.contentVC.invokeDCCommand(function: function, params: params)
    }
    
    
    func onSetup(hostDelegate: SKCommon.DocComponentHostDelegate?) {
        self.docComponentHostDelegate = hostDelegate
        self.contentHost?.onSetup(hostDelegate: hostDelegate)
    }
    
    func changeContentHost(_ newHost: DocComponentHost) {
        DocsLogger.info("changeConentHost \(String(describing: type(of: newHost)))", component: LogComponents.docComponent)
        removeContentVC(contentVC)
        self.contentVC = newHost
        addContentVC(newHost)
    }
}
