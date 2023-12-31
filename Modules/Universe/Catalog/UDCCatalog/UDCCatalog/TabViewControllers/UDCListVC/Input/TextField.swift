//
//  TextField.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/11/24.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import UIKit
import Foundation
import UniverseDesignInput
import UniverseDesignIcon

class TextFieldVC: UIViewController {

    var textFields: [UDTextField] = []

    var isShowBorder = true

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .clear

        let rightBar = UIBarButtonItem(title: "隐藏/显示边框",
                                       style: .plain,
                                       target: self,
                                       action: #selector(switchBorder))

        self.navigationItem.rightBarButtonItem = rightBar

        addNormalTextField()
        addTitleTextField()
        addRightIconTextField()
        addLeftIconTextField()
        addIconsTextField()
        addErrorTextField()
    }

    private func addNormalTextField() {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.backgroundColor = .clear
        textField.placeholder = "普通单行输入框"

        textFields.append(textField)

        self.view.addSubview(textField)

        textField.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(100)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
    }

    private func addTitleTextField() {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.backgroundColor = .clear
        textField.config.isShowTitle = true
        textField.placeholder = "标题单行输入框"
        textField.title = "标题"

        textFields.append(textField)

        self.view.addSubview(textField)

        textField.snp.makeConstraints { (make) in
            make.top.equalTo(textFields[0].snp.bottom).offset(50)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
    }

    private func addRightIconTextField() {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.backgroundColor = .clear
        textField.placeholder = "右侧图标单行输入框"
        textFields.append(textField)

        textField.setRightView(UIImageView(image: UDIcon
                                            .activityColorful
                                            .ud.resized(to: CGSize(width: 20, height: 20))))

        self.view.addSubview(textField)

        textField.snp.makeConstraints { (make) in
            make.top.equalTo(textFields[1].snp.bottom).offset(50)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
    }

    private func addLeftIconTextField() {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.backgroundColor = .clear
        textField.placeholder = "左侧图标单行输入框"

        textFields.append(textField)

        textField.setLeftView(UIImageView(image: UDIcon
                                            .activityColorful
                                            .ud.resized(to: CGSize(width: 20, height: 20))))

        self.view.addSubview(textField)

        textField.snp.makeConstraints { (make) in
            make.top.equalTo(textFields[2].snp.bottom).offset(50)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
    }

    private func addIconsTextField() {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.backgroundColor = .clear
        textField.placeholder = "两侧图标单行输入框"

        textFields.append(textField)

        textField.setLeftView(UIImageView(image: UDIcon
                                            .activityColorful
                                            .ud.resized(to: CGSize(width: 20, height: 20))))

        textField.setRightView(UIImageView(image: UDIcon
                                            .activityColorful
                                            .ud.resized(to: CGSize(width: 20, height: 20))))

        self.view.addSubview(textField)

        textField.snp.makeConstraints { (make) in
            make.top.equalTo(textFields[3].snp.bottom).offset(50)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
    }

    private func addErrorTextField() {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.errorMessege = "错误"
        textField.config.backgroundColor = .clear
        textField.placeholder = "警告单行输入框"
        textField.setStatus(.error)

        textFields.append(textField)

        self.view.addSubview(textField)

        textField.snp.makeConstraints { (make) in
            make.top.equalTo(textFields[4].snp.bottom).offset(50)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
    }

    @objc
    private func switchBorder() {
        isShowBorder = !isShowBorder
        for textField in textFields {
            textField.config.isShowBorder = isShowBorder
            if isShowBorder {
                textField.backgroundColor = .white
                textField.config.contentMargins = UIEdgeInsets(top: 0,
                                                               left: 0,
                                                               bottom: 0,
                                                               right: 0)
            } else {
                textField.backgroundColor = .white
                textField.config.contentMargins = UIEdgeInsets(top: 13,
                                                               left: 16,
                                                               bottom: 13,
                                                               right: 16)
            }

        }

        self.view.backgroundColor = isShowBorder ? .white : UIColor.ud.N100
    }
}
