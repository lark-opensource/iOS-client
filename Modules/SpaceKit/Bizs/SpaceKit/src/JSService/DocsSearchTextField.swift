//
//  DocsSearchTextField.swift
//  SpaceKit
//
//  Created by nine on 2019/1/18.
//

import Foundation
import SKUIKit
import UniverseDesignColor

class DocsSearchTextField: SKSearchUITextField {
    
    override func layoutSubviews() {
        UIView.performWithoutAnimation {
            super.layoutSubviews()
        }
    }
    
    func updateNumberLabel(with resultNum: SearchRestultNum) {
        guard resultNum.current <= resultNum.total else { return }
        numberLabel.text = (resultNum.total == 0 ? "0/0" : "\(resultNum.current + 1)/\(resultNum.total)")
    }

    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .right
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityIdentifier = "docs.navigation.find.textfield"
        accessibilityLabel = "docs.navigation.find.textfield"
        addSubview(numberLabel)
        rightViewMode = .never
        clearButtonMode = .never
        numberLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.height.equalTo(18)
            make.width.equalTo(70)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
