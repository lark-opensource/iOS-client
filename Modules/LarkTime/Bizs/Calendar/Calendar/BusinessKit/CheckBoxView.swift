//
//  CheckBoxView.swift
//  Calendar
//
//  Created by yantao on 2019/12/11.
//

import UIKit
import Foundation
import UniverseDesignCheckBox
import LarkAlertController
import UniverseDesignDialog

final class CheckBoxView: UIView {

    private let checkBox = UDCheckBox(boxType: .multiple) { $0.isSelected.toggle() }

    private let titleLabel: UILabel = {
        let label = UILabel.cd.subTitleLabel(fontSize: 16)
        label.textColor = .ud.textTitle
        label.numberOfLines = 0
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title

        addSubview(checkBox)
        checkBox.snp.makeConstraints {
            $0.left.centerY.equalToSuperview()
        }
        checkBox.isSelected = true

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(checkBox.snp.right).offset(12)
            $0.centerY.top.bottom.right.equalToSuperview()
        }
        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCheckBox))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func toggleCheckBox() {
        checkBox.isSelected.toggle()
    }

    func isSelected() -> Bool {
        checkBox.isSelected
    }
}

final class NotiTitleView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel.cd.subTitleLabel(fontSize: 16)
        label.textColor = .ud.textTitle
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        
        if title.getWidth(font: UIFont.systemFont(ofSize: 16)) > 2*UDDialog.Layout.dialogWidth {
            titleLabel.textAlignment = .left
        }
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.centerY.centerX.top.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
