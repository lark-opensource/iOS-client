//
//  MergeForwardContentView.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/6/18.
//

import Foundation
import UIKit
import LarkExtensions

final class MergeForwardContentView: UIView {
    var tapContent: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.lu.addTapGestureRecognizer(action: #selector(tapHandler))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tapHandler() {
        self.tapContent?()
    }
}
