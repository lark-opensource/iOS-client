//
//  FakeInviteController.swift
//  LarkTourDev
//
//  Created by Meng on 2020/6/12.
//

import UIKit
import Foundation
import LarkUIKit

class FakeInviteController: FakeDependencyController {
    var nextHandler: (() -> Void)?

    override var description: String {
        return "假装你在添加成员"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleString = "FakeInviteController"
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "跳过", style: .plain, target: self, action: #selector(skip))
    }

    @objc private func skip() {
        nextHandler?()
    }
}
