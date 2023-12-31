//
//  UDDrawerGridViewController.swift
//  UDCCatalog
//
//  Created by 龙伟伟 on 2021/1/10.
//  Copyright © 2021 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignColor
import SnapKit
import UniverseDesignFont

public class UDDrawerGridViewController: UIViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UDColor.N00

        let titleLabel = UILabel()
        titleLabel.text = "侧拉窗标题"
        titleLabel.textColor = UDColor.N900
        titleLabel.font = UDFont.title2
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(48)
            make.leading.equalTo(20)
            make.trailing.equalTo(-20)
            make.height.equalTo(28)
        }
    }
}
