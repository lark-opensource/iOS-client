//
//  PageTestEntranceController.swift
//  LarkUIKitDemo
//
//  Created by KongKaikai on 2018/12/13.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkPageController

class PageTestEntranceController: UIViewController {

    let button = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        button.frame = CGRect(x: 100, y: 100, width: 80, height: 35)
        button.backgroundColor = UIColor.yellow
        button.setTitleColor(UIColor.darkText, for: .normal)
        button.clipsToBounds = true
        button.layer.cornerRadius = 4
        button.setTitle("Show", for: .normal)
        button.addTarget(self, action: #selector(showPage), for: .touchUpInside)

        view.addSubview(button)
        view.backgroundColor = UIColor.white
    }

    @objc
    private func showPage() {
        let page = PageTestViewController()
        let navigation = UINavigationController(rootViewController: page)
        navigation.modalPresentationStyle = .overCurrentContext
        self.present(navigation, animated: false, completion: nil)
    }
}
