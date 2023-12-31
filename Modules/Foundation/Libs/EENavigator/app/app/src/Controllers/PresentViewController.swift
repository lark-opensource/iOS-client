//
//  PresentViewController.swift
//  EENavigatorDemo
//
//  Created by liuwanlin on 2018/9/12.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

class PresentViewController: BaseUIViewController {

    var chatId: String = ""

    let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "关闭",
            style: .plain,
            target: self,
            action: #selector(back)
        )

        self.title = "Present: \(chatId)"
        self.view.backgroundColor = UIColor.white

        label.text = "Present: \(chatId)"
        self.view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.left.equalTo(20)
        }

        let panel = ActionPanel(frame: .zero)
        self.view.addSubview(panel)
        panel.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
        }
    }

    @objc
    func back() {
        self.dismiss(animated: true, completion: nil)
    }

}
