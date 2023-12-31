//
//  MainViewController.swift
//  LarkSettingsBundleDev
//
//  Created by Miaoqi Wang on 2020/3/29.
//

import Foundation
import UIKit
import LarkSettingsBundle

class MainViewController: UIViewController {

    var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let frame = CGRect(x: 50, y: view.bounds.height / 2, width: view.bounds.width, height: 20)
        label = UILabel(frame: frame)
        label.text = "Need reset"
        view.addSubview(label)

        ResetTaskManager.register(task: { (complete) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.label.text = "Already reset"
                print("settingsbundle reset default")
                complete()
            }
        })
    }
}
