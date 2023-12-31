//
//  LynxUIViewExtension.swift
//  UniversalCardBase
//
//  Created by ByteDance on 2023/11/6.
//

import Foundation
import Lynx
import UniversalCardInterface

extension LynxUIView {
    func getCardContext() -> UniversalCardContext? {
        return (self.context?.contextDict?[UniversalCardTag] as? UniversalCardLynxBridgeContextWrapper)?.cardContext
    }

}

extension LynxShadowNode {
    func getCardContext() -> UniversalCardContext? {
        return (self.uiOwner?.uiContext.contextDict?[UniversalCardTag] as? UniversalCardLynxBridgeContextWrapper)?.cardContext
    }
}
