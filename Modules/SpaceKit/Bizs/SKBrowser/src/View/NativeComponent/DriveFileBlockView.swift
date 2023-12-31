//
//  DriveFileBlockView.swift
//  SKBrowser
//
//  Created by bupozhuang on 2021/9/28.
//

import UIKit
import SKFoundation

class DriveFileBlockView: UIView {
    var didAddToSuperView: (() -> Void)?
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        DocsLogger.info("DriveFileBlockComponent -- will move to superView \(String(describing: superview))")
        if superview != nil {
            didAddToSuperView?()
        }
    }
}
