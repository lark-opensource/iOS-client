//
//  ByteViewTabScrollView.swift
//  ByteViewTab
//
//  Created by helijian on 2022/2/23.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

final class ByteViewTabScrollView: UIScrollView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        delaysContentTouches = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view.isKind(of: UIButton.self) { return true }
        return super.touchesShouldCancel(in: view)
    }
}
