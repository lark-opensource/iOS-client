//
//  ImagePickerViewController.swift
//  LarkUIKitDemo
//
//  Created by Supeng on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import LarkAssetsBrowser

class ImagePickerViewControllerDemo: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton()
        button.setTitle("点我选图片", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(buttonDidClick(_:)), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        view.backgroundColor = .white
    }

    @objc
    private func buttonDidClick(_ button: UIButton) {
        let imagePicker = ImagePickerViewController()
        imagePicker.showMultiSelectAssetGridViewController()
        present(imagePicker, animated: true, completion: nil)
    }
}
