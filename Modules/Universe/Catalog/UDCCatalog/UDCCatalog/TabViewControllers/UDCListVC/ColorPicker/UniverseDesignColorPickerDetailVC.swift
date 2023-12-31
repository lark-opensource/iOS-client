//
//  UniverseDesignColorPickerDetailVC.swift
//  UDCCatalog
//
//  Created by admin on 2020/11/20.
//  Copyright © 2020 潘灶烽. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColorPicker

class UniverseDesignColorPickerDetailVC: UIViewController {

    public let config: UDColorPickerConfig

    private lazy var container = UIView()
    private lazy var colorPickerPanel = UDColorPickerPanel(config: config)
    
    var titleData: [String] = ["常规颜色Panel"]

    init(config: UDColorPickerConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UniverseDesignColorPickerDetail"
        view.backgroundColor = UIColor.ud.bgBody
        container.backgroundColor = UIColor.ud.bgFloatBase
        container.layer.cornerRadius = 10
        container.layer.masksToBounds = true
        
        layoutSubviews()
    }

    private func layoutSubviews() {
        view.addSubview(container)
        container.addSubview(colorPickerPanel)
        container.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.width.equalToSuperview().offset(-32)
            // 打开可以测试一下约束高度的场景
            // make.height.equalTo(160)
        }
        colorPickerPanel.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview().inset(10)
        }
    }
}
