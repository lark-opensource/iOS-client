//
//  iPadPresentViewController.swift
//  LarkUIKitDemo
//
//  Created by 李晨 on 2020/1/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit

class iPadPresentViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        let button = UIButton(type: .system)
        button.setTitle("present1", for: .normal)
        button.addTarget(self, action: #selector(present1), for: .touchUpInside)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(-100)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(44)
        }

        let button2 = UIButton(type: .system)
        button2.setTitle("present2", for: .normal)
        button2.addTarget(self, action: #selector(present2), for: .touchUpInside)
        self.view.addSubview(button2)
        button2.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(100)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
    }

    @objc
    func present1() {
        let vc = iPadPresentViewController1()
        vc.view.backgroundColor = UIColor.red
        vc.modalPresentationStyle = .pageSheet
        vc.modalPresentationControl.dismissEnable = true
        self.present(vc, animated: true, completion: nil)
    }

    @objc
    func present2() {
        let vc = iPadPresentViewController1()
        vc.view.backgroundColor = UIColor.blue
        let nav = LkNavigationController(rootViewController: vc)
        nav.modalPresentationControl.dismissEnable = true
        nav.modalPresentationStyle = .formSheet
        self.present(nav, animated: true, completion: nil)
    }
}

class iPadPresentViewController1: BaseUIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
        let button = UIButton(type: .system)
        button.setTitle("present1", for: .normal)
        button.addTarget(self, action: #selector(present1), for: .touchUpInside)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(-100)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(44)
        }

        let button2 = UIButton(type: .system)
        button2.setTitle("present2", for: .normal)
        button2.addTarget(self, action: #selector(present2), for: .touchUpInside)
        self.view.addSubview(button2)
        button2.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(100)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
    }

    @objc
    func present1() {
        let vc = iPadPresentViewController1()
        vc.view.backgroundColor = UIColor.green
        vc.modalPresentationStyle = .formSheet
        vc.modalPresentationControl.dismissEnable = true
        vc.modalPresentationControl.dismissAnimation = false
        vc.modalPresentationControl.dismissCallback = {
            print("dismissed")
        }
        self.present(vc, animated: true, completion: nil)
    }

    @objc
    func present2() {
        let vc = iPadPresentViewController1()
        vc.view.backgroundColor = UIColor.green
        vc.modalPresentationStyle = .formSheet
        vc.modalPresentationControl.dismissEnable = true
        vc.modalPresentationControl.handleDismiss = {
            let handle = Int(Date().timeIntervalSince1970) % 2 == 0
            print("handle dismiss is \(handle)")
            if handle {
                return true
            }
            return false
        }
        self.present(vc, animated: true, completion: nil)
    }
}
