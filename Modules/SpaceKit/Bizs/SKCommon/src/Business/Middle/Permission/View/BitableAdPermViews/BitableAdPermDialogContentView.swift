//
//  BitableAdPermDialogContentView.swift
//  SKCommon
//
//  Created by zhysan on 2022/7/18.
//

import UIKit
import SnapKit
import SKResource
import UniverseDesignColor
import UniverseDesignSwitch
import UniverseDesignCheckBox
import UniverseDesignFont

public final class BitableAdPermDialogContentView: UIView {
    public var checkBoxValueChange: ((Bool) -> Void)?
    
    private let checkBox: UDCheckBox = {
        let vi = UDCheckBox(boxType: .multiple)
        return vi
    }()
    
    private let descLabel: UILabel = {
        UILabel()
    }()
    
    private let checkBoxLabel: UILabel = {
        UILabel()
    }()
    
    private let checkBoxWrapper: UIView = {
        UIView()
    }()
    
    public init(contentText: String, confirmText: String, frame: CGRect = .zero, confirmAction: ((Bool) -> Void)? = nil) {
        super.init(frame: frame)
        subviewsInit()
        descLabel.sk_setText(contentText, expectedLineHeight: 24.0, font: UIFont.ud.body0, textColor: UIColor.ud.textTitle)
        checkBoxLabel.sk_setText(confirmText)
        checkBoxValueChange = confirmAction
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func onCheckAreaTapped(_ sender: UITapGestureRecognizer) {
        checkBox.isSelected = !checkBox.isSelected
        checkBoxValueChange?(checkBox.isSelected)
    }
    
    private func subviewsInit() {
        addSubview(descLabel)
        addSubview(checkBoxWrapper)
        checkBoxWrapper.addSubview(checkBox)
        checkBoxWrapper.addSubview(checkBoxLabel)
        
        checkBox.isUserInteractionEnabled = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onCheckAreaTapped(_:)))
        checkBoxWrapper.addGestureRecognizer(tap)
        
        descLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        checkBoxWrapper.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.right.equalTo(descLabel)
            make.top.equalTo(descLabel.snp.bottom).offset(12)
        }
        checkBox.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.width.height.equalTo(18)
        }
        checkBoxLabel.snp.makeConstraints { make in
            make.left.equalTo(checkBox.snp.right).offset(8)
            make.right.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
        }
    }
}
