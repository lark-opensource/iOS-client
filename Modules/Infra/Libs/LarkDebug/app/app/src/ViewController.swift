//
//  ViewController.swift
//  LarkDebugDev
//
//  Created by Crazy凡 on 2023/5/10.
//

import UIKit
import SnapKit
import RxSwift
import EENavigator
import LarkDebug

class ViewController: UIViewController {
    private var button = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(button)
        button.backgroundColor = .gray
        button.setTitle("Show Debug", for: .normal)
        button.clipsToBounds = true
        button.layer.cornerRadius = 3.5
        button.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(45)
            make.width.equalTo(80)
        }
        button.addTarget(self, action: #selector(showDebug), for: .touchUpInside)
    }

    @objc
    private func showDebug() {
        Navigator.shared.push(body: DebugBody(), from: self)
    }
}
