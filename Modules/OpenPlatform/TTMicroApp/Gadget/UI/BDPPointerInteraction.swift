//
//  BDPPointerInteraction.swift
//  TTMicroApp
//
//  Created by Nicholas Tau on 2021/1/26.
//

import Foundation
import LarkInteraction

@objc
extension UIView {
    public func addBDPPointerInteraction() {
        if #available(iOS 13.4, *) {
            let action = PointerInteraction(style: PointerStyle(effect: .highlight,
                                                                shape: .roundedSize({ (interaction, region) -> PointerInfo.ShapeSizeInfo in
                                                                    return PointerInfo.ShapeSizeInfo(CGSize(width: 44, height: 36), 8)
                                                                })))
            self.addLKInteraction(action)
        }
    }
    
    public func addBDPMorePanelPointerInteraction() {
        if #available(iOS 13.4, *) {
            let action = PointerInteraction(style: PointerStyle(effect: .hover()))
            self.addLKInteraction(action)
        }
    }
    
    public func addBDPWebBarButtonItemPointerInteraction() {
        if #available(iOS 13.4, *) {
            let action = PointerInteraction(style: PointerStyle(effect: .highlight))
            self.addLKInteraction(action)
        }
    }
}
