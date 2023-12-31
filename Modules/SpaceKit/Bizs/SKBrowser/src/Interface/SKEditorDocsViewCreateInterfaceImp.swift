//
//  SKEditorDocsViewCreateInterfaceImp.swift
//  SKBrowser
//
//  Created by huangzhikai on 2023/4/21.
//

import Foundation
import SpaceInterface
import LarkWebViewContainer
import LarkContainer

public class SKEditorDocsViewCreateInterfaceImp: SKEditorDocsViewCreateInterface {
    
    public let userResolver: UserResolver
    
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    public func createEditorDocsView(jsEngine: LarkWebView?,
                              uiContainer: UIView,
                              delegate: SKEditorDocsViewRequestProtocol? ,
                              bridgeName: String) -> SKEditorDocsViewObserverProtocol {
        return SKEditorPlugin(jsEngine: jsEngine, uiContainer: uiContainer, userResolver: userResolver, delegate: delegate, bridgeName: bridgeName)
    }
}
