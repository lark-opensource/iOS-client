//
//  ImageEditBaseView.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/8/17.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

class ImageEditBaseView: UIView {
    var imageUndoManager: () -> UndoManager? = { return nil }

    var hasEverOperated: Bool = false

    weak var zoomView: ZoomScrollView?

    var isActive = false

    func becomeActive() {
        isUserInteractionEnabled = true
        isActive = true
        zoomView?.isScrollEnabled = false
    }

    func becomeDeactive() {
        isUserInteractionEnabled = false
        isActive = false
        zoomView?.isScrollEnabled = true
    }
}
