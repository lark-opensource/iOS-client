//
//  ActionPanel.swift
//  EENavigatorDemo
//
//  Created by liuwanlin on 2018/9/12.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import EENavigator

class BaseUIViewController: UIViewController {
    deinit {
        print("deinit: \(String(describing: type(of: self)))")
    }
}

class ActionPanel: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        let size = CGSize(width: 150, height: 40)

        let button = UIButton(type: .custom)
        button.setTitle("进入chat", for: .normal)
        button.backgroundColor = UIColor.red
        button.addTarget(self, action: #selector(gotoChat), for: .touchUpInside)
        self.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.size.equalTo(size)
            make.top.equalTo(10)
            make.left.equalTo(20)
        }

        let button2 = UIButton(type: .custom)
        button2.setTitle("进入setting", for: .normal)
        button2.backgroundColor = UIColor.red
        button2.addTarget(self, action: #selector(gotoChatSetting), for: .touchUpInside)
        self.addSubview(button2)
        button2.snp.makeConstraints { (make) in
            make.size.equalTo(size)
            make.top.equalTo(button.snp.bottom).offset(10)
            make.left.equalTo(20)
        }

        let button3 = UIButton(type: .custom)
        button3.setTitle("切换tab到feed", for: .normal)
        button3.backgroundColor = UIColor.red
        button3.addTarget(self, action: #selector(switchToFeed), for: .touchUpInside)
        self.addSubview(button3)
        button3.snp.makeConstraints { (make) in
            make.size.equalTo(size)
            make.top.equalTo(button2.snp.bottom).offset(10)
            make.left.equalTo(20)
        }

        let button4 = UIButton(type: .custom)
        button4.setTitle("present", for: .normal)
        button4.backgroundColor = UIColor.red
        button4.addTarget(self, action: #selector(present), for: .touchUpInside)
        self.addSubview(button4)
        button4.snp.makeConstraints { (make) in
            make.size.equalTo(size)
            make.top.equalTo(button3.snp.bottom).offset(10)
            make.left.equalTo(20)
        }

        let button5 = UIButton(type: .custom)
        button5.setTitle("Not found", for: .normal)
        button5.backgroundColor = UIColor.red
        button5.addTarget(self, action: #selector(notFound), for: .touchUpInside)
        self.addSubview(button5)
        button5.snp.makeConstraints { (make) in
            make.size.equalTo(size)
            make.top.equalTo(button4.snp.bottom).offset(10)
            make.left.equalTo(20)
        }

        let button6 = UIButton(type: .custom)
        button6.setTitle("Push async", for: .normal)
        button6.backgroundColor = UIColor.red
        button6.addTarget(self, action: #selector(async), for: .touchUpInside)
        self.addSubview(button6)
        button6.snp.makeConstraints { (make) in
            make.size.equalTo(size)
            make.top.equalTo(button5.snp.bottom).offset(10)
            make.left.equalTo(20)
            make.bottom.equalToSuperview()
        }

        let button7 = UIButton(type: .custom)
        button7.setTitle("Pop", for: .normal)
        button7.backgroundColor = UIColor.red
        button7.addTarget(self, action: #selector(pop), for: .touchUpInside)
        self.addSubview(button7)
        button7.snp.makeConstraints { (make) in
            make.size.equalTo(size)
            make.top.equalTo(button6.snp.bottom).offset(10)
            make.left.equalTo(20)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func gotoChat() {
        print("push start:", Date().timeIntervalSince1970)
        guard let window = self.window else { return }
        Navigator.shared.push(URL(string: "//chat/123#abc")!, from: window) { (req, res) in
            print("push end:", Date().timeIntervalSince1970)
        }
    }

    @objc
    func gotoChatSetting() {
        guard let window = self.window else { return }
        Navigator.shared.push(URL(string: "//chat/setting/123")!, from: window)
    }

    @objc
    func switchToFeed() {
        guard let window = self.window else { return }
        Navigator.shared.switchTab(URL(string: "//feed#abc")!, from: window)
    }

    @objc
    func present() {
        guard let window = self.window else { return }
        Navigator.shared.present(URL(string: "//present/222")!, wrap: UINavigationController.self, from: window)
    }

    @objc
    func notFound() {
        guard let window = self.window else { return }
        Navigator.shared.present(URL(string: "//notFound")!, wrap: UINavigationController.self, from: window)
    }

    @objc
    func async() {
        guard let window = self.window else { return }
        Navigator.shared.push(URL(string: "//async")!, from: window) { _, _ in
            print("done")
        }
    }

    @objc
    func pop() {
        guard let window = self.window else { return }
        print("pop start:", Date().timeIntervalSince1970)
        Navigator.shared.pop(from: window) {
            print("pop end:", Date().timeIntervalSince1970)
        }
    }
}
