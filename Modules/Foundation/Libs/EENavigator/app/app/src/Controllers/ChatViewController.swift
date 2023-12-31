//
//  ChatViewController.swift
//  EENavigatorDemo
//
//  Created by liuwanlin on 2018/9/12.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import EENavigator

class ChatViewController: BaseUIViewController {

    var chatId: String = ""

    let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Chat"
        self.view.backgroundColor = UIColor.white

        label.text = "Chat: \(chatId)"
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
}

extension ChatViewController: FragmentLocate {
    func customLocate(by fragment: String, with context: [String: Any], animated: Bool) {
        print(fragment, context, animated)
    }
}
