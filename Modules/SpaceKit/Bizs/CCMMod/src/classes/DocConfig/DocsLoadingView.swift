//
//  DocsLoadingView.swift
//  Lark
//
//  Created by liuwanlin on 2018/7/6.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import SpaceKit
import SKCommon
import SpaceInterface

class DocsLoadingView: DocsUDLoadingImageView, DocsLoadingViewProtocol {
    var text: String = "" {
        didSet {
            self.label.text = self.text
        }
    }

    public var displayContent: UIView {
        return self
    }

    public func startAnimation() {
        self.isHidden = false
    }

    public func stopAnimation() {
        self.isHidden = true
    }
}
