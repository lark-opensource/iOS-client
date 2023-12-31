//
//  SplitViewController+SplitBehavior.swift
//  SplitViewControllerDemo
//
//  Created by Yaoguoguo on 2022/8/15.
//

import UIKit
import Foundation
import UniverseDesignColor

extension SplitViewController {
    public enum SplitBehavior: Int {

        // The sidebars and secondary view controller appear tiled side-by-side.
        case tile = 0

        // The sidebars are layered on top of the secondary view controller, leaving the secondary view controller partially visible.
        case overlay = 1

        // The sidebars displace the secondary view controller instead of overlapping it, moving it partially offscreen.
        case displace = 2
    }
}

final class SplitMaskView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.ud.bgMask
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
