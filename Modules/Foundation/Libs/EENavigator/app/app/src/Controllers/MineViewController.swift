//
//  MineViewController.swift
//  EENavigatorDemo
//
//  Created by liuwanlin on 2018/9/12.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

class MineViewController: BaseUIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Mine"
        self.view.backgroundColor = UIColor.green

        let panel = ActionPanel(frame: .zero)
        self.view.addSubview(panel)
        panel.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.left.right.equalToSuperview()
        }
    }

}
