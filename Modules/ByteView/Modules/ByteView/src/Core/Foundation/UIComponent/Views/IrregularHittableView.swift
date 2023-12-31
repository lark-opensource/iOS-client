//
//  IrregularHittableView.swift
//  ByteView
//
//  Created by kiri on 2021/4/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

/// 为不规则点击的view提供一个基类，该View只能点中子view而点不到自己
class IrregularHittableView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let view = super.hitTest(point, with: event), view != self {
            return view
        }
        return nil
    }
}
