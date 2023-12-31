//
//  NavBarTitleView.swift
//  Lark
//
//  Created by lichen on 2017/9/14.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import UIKit

open class NavBarTitleView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        return self.frame.size
    }
}
