//
//  NotFoundViewController.swift
//  EENavigatorDemo
//
//  Created by liuwanlin on 2018/9/12.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

class NotFoundViewController: BaseUIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Not found"
        self.view.backgroundColor = UIColor.red

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "关闭",
            style: .plain,
            target: self,
            action: #selector(back)
        )
    }

    @objc
    func back() {
        self.dismiss(animated: true, completion: nil)
    }
}
