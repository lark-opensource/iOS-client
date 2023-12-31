//
//  ZoomCommonUITextField.swift
//  Calendar
//
//  Created by pluto on 2022/11/2.
//

import UIKit
import Foundation
import UniverseDesignIcon
import LarkUIKit

final class ZoomCommonUITextField: BaseTextField {

    lazy var right: UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UDIcon.getIconByKey(.closeFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: 18, height: 18)), for: .normal)
        b.addTarget(self, action: #selector(clearText), for: .touchUpInside)
        b.isHidden = true
        return b
    }()

    override var text: String? {
        didSet {
            right.isHidden = text?.isEmpty == true
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBodyOverlay
        layer.cornerRadius = 6
        rightView = right
        rightViewMode = .whileEditing
        textColor = UIColor.ud.textTitle
        font = UIFont.systemFont(ofSize: 14)
        addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 0, y: 0, width: 36, height: bounds.height)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.width - 36, y: 0, width: 36, height: bounds.height)
    }

    @objc private func clearText() {
        text = nil
        sendActions(for: .editingChanged)
    }

    @objc private func textChanged() {
        right.isHidden = text?.isEmpty == true
    }
}
