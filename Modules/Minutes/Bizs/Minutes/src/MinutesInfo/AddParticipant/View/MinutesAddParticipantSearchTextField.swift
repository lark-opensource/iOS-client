//
//  MinutesAddParticipantSearchTextField.swift
//  Minutes
//
//  Created by panzaofeng on 2021/6/16.
//  Copyright © 2021年 panzaofeng. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import UniverseDesignIcon

public final class MinutesAddParticipantSearchTextField: UITextField {

    public var textCleared: (() -> Void)?

    public override var placeholder: String? {
        didSet {
            self.attributedPlaceholder = NSAttributedString(
                string: self.placeholder ?? "",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.ud.textPlaceholder
                ]
            )
        }
    }

    private lazy var left: UIView = {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 24, height: 34)))
        let imageView = UIImageView(frame: CGRect(x: 0, y: 8, width: 16, height: 16))
        imageView.image = UDIcon.getIconByKey(.searchOutlineOutlined, iconColor: UIColor.ud.iconN1)
        view.addSubview(imageView)
        return view
    }()

    private lazy var right: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.closeFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: 18, height: 18)), for: .normal)
        button.addTarget(self, action: #selector(clearTextField), for: .touchUpInside)
        return button
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.text = nil
        self.returnKeyType = .search
        self.textColor = UIColor.ud.textTitle
        self.placeholder = ""
        self.leftView = self.left
        self.leftViewMode = .always
        self.rightView = self.right
        self.rightViewMode = .always
        self.addTarget(self, action: #selector(editingChangedAction(sender:)), for: .editingChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func clearTextField() {
        self.text = nil
        self.textCleared?()
        self.sendActions(for: .editingChanged)
    }

    @objc
    private func editingChangedAction(sender: UITextField) {
        // 有内容的时候显示
        self.right.isHidden = self.text?.isEmpty == true
    }

    public override var text: String? {
        get { return super.text }
        set {
            super.text = newValue
            self.right.isHidden = self.text?.isEmpty == true
        }
    }

    public override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 0, y: 0, width: 28, height: bounds.height)
    }

    public override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.width - 28, y: 0, width: 42, height: bounds.height)
    }
}
