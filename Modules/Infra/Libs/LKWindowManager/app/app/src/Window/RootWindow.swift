//
//  File.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/22.
//

import Foundation
import UIKit

// swiftlint:disable all
class RootWindow: UIWindow {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {
        windowLevel = UIWindow.Level.normal
    }
}
