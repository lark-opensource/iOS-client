//
//  WikiContainerViewController+DocComponent.swift
//  SKWikiV2
//
//  Created by lijuyou on 2023/6/10.
//  


import SKFoundation
import SpaceInterface
import SKBrowser
import SKCommon

extension WikiContainerViewController: DocComponentHost {
    
    public var isDocComponent: Bool {
        self.docComponentHostDelegate != nil
    }

    public var componentConfig: [String: Any]? {
        DocComponentManager.getSceneConfig(for: viewModel.wikiURL)?.setting
    }

    public var browserView: BrowserModelConfig? {
        guard let host = lastChildVC as? DocComponentHost else {
            spaceAssertionFailure("must be DocComponentHost vc")
            return nil
        }
        return host.browserView
    }
    
    func onDocComponentHostLoaded() {
        guard let hostDelegate =  self.docComponentHostDelegate else { return }
        guard let host = lastChildVC as? DocComponentHost else {
            spaceAssertionFailure("must be DocComponentHost vc")
            return
        }
        host.onSetup(hostDelegate: hostDelegate)
        hostDelegate.docComponentHostLoaded(self)
    }
    
    public func onSetup(hostDelegate: DocComponentHostDelegate?) {
        self.docComponentHostDelegate = hostDelegate
    }

    public func invokeDCCommand(function: String, params: [String: Any]?) {
        guard let host = lastChildVC as? DocComponentHost else {
            spaceAssertionFailure("must be DocComponentHost vc")
            return
        }
        host.invokeDCCommand(function: function, params: params)
    }
}
