//
//  BTConditionCheckBoxCell.swift
//  SKBitable
//
//  Created by ZhangYuanping on 2022/7/5.
//  

import UIKit
import SKResource
import UniverseDesignColor

final class BTConditionCheckBoxCell: UICollectionViewCell {
    
    private lazy var label = UILabel().construct { it in
        it.text = BundleI18n.SKResource.Bitable_BTModule_Equal
        it.font = .systemFont(ofSize: 16)
        it.textColor = UDColor.textTitle
    }
    
    lazy var checkButton = UIButton(type: .custom).construct { it in
        it.setImage(BundleResources.SKResource.Bitable.icon_bitable_checkbox_off, for: .normal)
        it.setImage(BundleResources.SKResource.Bitable.icon_bitable_checkbox_on, for: .selected)
        it.contentHorizontalAlignment = .fill
        it.contentVerticalAlignment = .fill
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    private func setUpView() {
        self.backgroundColor = .clear
        self.clipsToBounds = true

        checkButton.isUserInteractionEnabled = false
        contentView.addSubview(label)
        contentView.addSubview(checkButton)
        label.snp.makeConstraints { make in
            make.centerY.left.equalToSuperview()
            make.right.equalTo(checkButton.snp.left).offset(-8)
        }
        checkButton.snp.makeConstraints { (make) in
            make.left.equalTo(label.snp.right).offset(8)
            make.centerY.right.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }

    public func updateCheckBox(isSelected: Bool, text: String) {
        checkButton.isSelected = isSelected
        label.text = text
    }

    public func getCellWidth(height: CGFloat) -> CGFloat {
        let textWidth = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)).width
        return textWidth + 24 + 8
    }
}
