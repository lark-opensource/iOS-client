//
//  LastingColorView.swift
//  LarkUIKit
//
//  Created by 吴子鸿 on 2017/6/23.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

open class LastingColorView: UIView {
    open var lastingColor: UIColor = UIColor.ud.colorfulRed

    open override func draw(_ rect: CGRect) {
        lastingColor.setFill()
        UIRectFill(rect)
        super.draw(rect)
    }
}
