//
//  UniverseDesignToastEditVC.swift
//  UDCCatalog
//
//  Created by admin on 2020/11/19.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignToast

class UniverseDesignToastEditVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        let editTips = UILabel()
        editTips.text = "点击输入框可弹出键盘"
        editTips.textAlignment = .left
        editTips.numberOfLines = 0
        self.view.addSubview(editTips)
        editTips.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(120)
            make.width.equalTo(200)
            make.left.equalToSuperview().offset(20)
        }

        let textField = UITextField.init(frame: CGRect(x: 0, y: 0, width: 100, height: 30))

        textField.textAlignment = .left
        textField.returnKeyType = .done;
        textField.placeholder = "我是输入框"
        self.view.addSubview(textField)
        textField.becomeFirstResponder()
        textField.snp.makeConstraints { (make) in
            make.top.equalTo(editTips.snp.bottom).offset(10)
            make.width.equalTo(160)
            make.left.equalToSuperview().offset(20)
        }

        let toastTips = UILabel()
        toastTips.text = "点击按钮弹出toast"
        toastTips.textAlignment = .left
        toastTips.numberOfLines = 0
        self.view.addSubview(toastTips)
        toastTips.snp.makeConstraints { (make) in
            make.top.equalTo(textField.snp.bottom).offset(40)
            make.width.equalTo(150)
            make.left.equalToSuperview().offset(20)
        }

        let button = UIButton()
        button.backgroundColor = .blue
        button.setTitle("点击弹出toast", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.top.equalTo(toastTips.snp.bottom).offset(10)
            make.width.equalTo(150)
            make.left.equalToSuperview().offset(20)
        }
        // Do any additional setup after loading the view.
    }

    // 收起键盘
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    @objc func buttonClicked(sender: UIButton) {
        UDToast.showTips(with: "常规提示-文字", on: self.view, delay: 3)
    }
}
