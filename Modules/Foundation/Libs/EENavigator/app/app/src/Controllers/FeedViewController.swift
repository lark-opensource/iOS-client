//
//  FeedViewController.swift
//  EENavigatorDemo
//
//  Created by liuwanlin on 2018/9/12.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import EENavigator

class FeedViewController: BaseUIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Feed"
        self.view.backgroundColor = UIColor.blue

        let panel = ActionPanel(frame: .zero)
        self.view.addSubview(panel)
        panel.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.left.right.equalToSuperview()
        }
    }
}

extension FeedViewController: FragmentLocate {
    func customLocate(by fragment: String, with context: [String: Any], animated: Bool) {
        print(fragment)
    }
}
