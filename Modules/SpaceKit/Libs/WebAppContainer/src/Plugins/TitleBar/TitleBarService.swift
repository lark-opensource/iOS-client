//
//  TitleBarService.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/17.
//

import Foundation
import LarkWebViewContainer
import UniverseDesignIcon
import SKFoundation
import SKUIKit

class TitleBarService: WASimpleContainerBridgeService {
    
    override var name: WABridgeName {
        .configTitleBar
    }
    
    var callback: APICallbackProtocol?
    weak var hostPlugin: TitleBarPlugin?
    
    
    override func handle(invocation: WABridgeInvocation) {
        guard let data: WATitleBarConfig =
                try? CodableUtility.decode(WATitleBarConfig.self, withJSONObject: invocation.params) else {
            Self.logger.info("titlebar params err")
            assertionFailure()
            return
        }
        self.callback = invocation.callback
        self.container?.hostVC?.updateTitleBar(data, target: self, selector: #selector(onTitleBarItemClick))
    }
    
    @objc
    func onTitleBarItemClick(sender: NSObject) {
        guard let barBtn = sender as? SKBarButton, let item = barBtn.item else {
            return
        }
        var strItemId: String
        Self.logger.info("onTitleBarItemClick \(item.id)")
        
        switch item.id {
        case .back:
            self.container?.hostVC?.goBackPage()
            strItemId = WABarNaviItemID.back.rawValue
        case .more:
            strItemId = WABarNaviItemID.more.rawValue
            hostPlugin?.showMoreMenu(sourceView: barBtn)
        case .unknown(let barId):
            strItemId = barId
            if strItemId == WABarNaviItemID.refresh.rawValue {
                self.container?.hostVC?.refreshPage()
            }
        default:
            spaceAssertionFailure("click unknown bar item")
            return
        }
        self.callback?.callbackSuccess(param: ["itemIdClick": strItemId])
    }
}


