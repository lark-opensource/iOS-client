//
//  DocComponentHostDelegate.swift
//  SpaceInterface
//
//  Created by lijuyou on 2023/5/30.
//  


import Foundation
import LarkWebViewContainer
import SpaceInterface

public protocol DocComponentHostDelegate: BrowserViewLifeCycleEvent {
    
    var config: DocComponentConfig { get }
    
    func docComponentHost(_ host: DocComponentHost?,
                          onReceiveWebInvoke params: [String: Any],
                          callback: APICallbackProtocol?)
    
    func docComponentHost(_ host: DocComponentHost?, onOperation opeartion: DocComponentOperation) -> Bool
    
    func docComponentHost(_ host: DocComponentHost?, onEvent event: DocComponentEvent)
    
    func docComponentHostLoaded(_ host: DocComponentHost?)
    
    func docComponentHostWillClose(_ host: DocComponentHost?)
    
    func docComponentHost(_ host: DocComponentHost?, onMoveToWiki wikiUrl: String, originUrl: String)
}
