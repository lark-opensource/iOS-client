//
//  PickerTextField.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/8/17.
//

import UIKit

class PickerTextField: UIControl {
    private let textLabel: UILabel
    private let rightImage: UIImageView

    private(set) var didSetValue: Bool = false
    
    var text: String? {
        textLabel.text
    }

    init() {
        textLabel = UILabel()
        textLabel.font = UIFont.systemFont(ofSize: 16)
        rightImage = UIImageView(image: BundleResources.UDIconResources.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3))
        super.init(frame: .zero)

        addSubview(textLabel)
        addSubview(rightImage)

        textLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(CL.itemSpace)
            make.top.bottom.equalToSuperview()
        }

        rightImage.snp.makeConstraints { (make) in
            make.left.equalTo(textLabel.snp.right).offset(22)
            make.right.equalToSuperview().inset(CL.itemSpace)
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }

        layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        layer.borderWidth = 1.0
        layer.cornerRadius = Common.Layer.commonTextFieldRadius
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateText(_ text: String, isPlaceHolder: Bool) {
        textLabel.text = text
        if isPlaceHolder {
            textLabel.textColor = UIColor.ud.textPlaceholder
            didSetValue = false
        } else {
            textLabel.textColor = UIColor.ud.textTitle
            didSetValue = true
        }
    }
}
