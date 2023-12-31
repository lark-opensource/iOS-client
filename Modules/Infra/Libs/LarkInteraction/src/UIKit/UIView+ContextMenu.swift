//
//  UIView+ContextMenu.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/12/20.
//

import UIKit
import Foundation

extension UIView {
    public func addContextMenu(_ menu: ContextMenu) {
        if #available(iOS 13.0, *) {
            let context = ContextMenuInteraction()
            context.configProvider = { (interaction, point) -> UIContextMenuConfiguration? in
                return menu.config
            }
            self.addLKInteraction(context)
        }
    }
}
