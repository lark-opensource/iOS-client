//
//  UIViewController+DynamicModal.swift
//  ByteViewUI
//
//  Created by Tobb Huang on 2023/5/15.
//

import Foundation

public extension UIViewController {
    // 更新modalSize，包括Popover、FormSheet等modal类型，会立刻生效
    func updateDynamicModalSize(_ size: CGSize, for category: DynamicModalConfig.Category = .both) {
        if category == .regular || category == .both {
            if self.traitCollection.isRegular {
                dynamicModalSize = size
            }
        }
        if category == .compact || category == .both {
            if !self.traitCollection.isRegular {
                dynamicModalSize = size
            }
        }
        self.dmPresentationController?.updateContentSizeConfig(size, for: category)
    }

    // 更新PopoverConfig，会立刻生效
    func updatePopoverConfig(_ config: DynamicModalPopoverConfig, for category: DynamicModalConfig.Category = .both) {
        if category == .regular || category == .both {
            if self.traitCollection.isRegular {
                self.decoratePopover(with: config)
            }
        }
        if category == .compact || category == .both {
            if !self.traitCollection.isRegular {
                self.decoratePopover(with: config)
            }
        }
        self.dmPresentationController?.updatePopoverConfig(config, for: category)
    }
}
