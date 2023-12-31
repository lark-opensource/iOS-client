//
//  FakeAddFriendsViewController.swift
//  LarkTourDev
//
//  Created by Jiayun Huang on 2020/7/17.
//

import UIKit
import Foundation
import LarkUIKit

class FakeAddFriendsViewController: FakeDependencyController {
    var nextHandler: (() -> Void)?
    var skipText: String?

    override var description: String {
        return "假装你在添加好友"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleString = "FakeInviteController"
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: (skipText ?? "跳过"), style: .plain, target: self, action: #selector(skip))
    }

    @objc private func skip() {
        nextHandler?()
    }
}
