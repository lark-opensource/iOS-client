//
//  ActivityIndicatorViewController.swift
//  LarkUIKitDemo
//
//  Created by zhouyuan on 2018/4/11.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LarkActivityIndicatorView

class ActivityIndicatorViewController: BaseUIViewController {
    private let activityIndicatorView = ActivityIndicatorView(color: UIColor.red)
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
        activityIndicatorView.startAnimating()

        let button = UIButton(type: .system)
        button.setTitle("disable", for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(4)
        }
    }

    @objc
    func buttonTapped() {
        self.activityIndicatorView.stopAnimating()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
