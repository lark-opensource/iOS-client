//
//  SearchUITextField.swift
//  Lark
//
//  Created by 刘晚林 on 2017/5/16.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//
import UIKit
import UniverseDesignColor
import UniverseDesignIcon

open class SKSearchUITextField: SKTextField {

    public var initialPlaceHolder: String = "" {
        didSet {
            self.updateSearchField()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        font = UIFont.systemFont(ofSize: 14)
        layer.masksToBounds = true
        layer.cornerRadius = 6
        borderStyle = .none
        clearButtonMode = .whileEditing
        textColor = UDColor.textTitle
        backgroundColor = UDColor.bgFiller
        exitOnReturn = true

        addTarget(self, action: #selector(searchEditingChanged), for: .editingChanged)
        addTarget(self, action: #selector(searchEditingChanged), for: .editingDidBegin)
        addTarget(self, action: #selector(searchEditingChanged), for: .editingDidEnd)
        updateSearchField()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    fileprivate func searchEditingChanged() {
        self.updateSearchField()
    }

    func updateSearchField() {
        let updateLeftView = { [weak self] in
            guard let weakSelf = self else {
                return
            }
            if weakSelf.leftView == nil {
                let image = UDIcon.searchOutlineOutlined.ud.withTintColor(UDColor.iconN3)
                let icon = UIImageView(image: image)
                icon.frame = CGRect(x: 12, y: 9, width: 16, height: 16)
                let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 34))
                leftView.addSubview(icon)
                weakSelf.leftView = leftView
                weakSelf.leftViewMode = .always
            }
        }
        let updatePlaceHolder = { [weak self] () -> Void in
            guard let weakSelf = self else {
                return
            }

            let searchPlaceHolder = weakSelf.initialPlaceHolder
            if weakSelf.attributedPlaceholder == nil {
                let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                                  NSAttributedString.Key.foregroundColor: UDColor.textPlaceholder]
                let attributeStr = NSAttributedString(string: searchPlaceHolder, attributes: attributes)
                weakSelf.attributedPlaceholder = attributeStr

            }
        }

        self.textAlignment = .left
        updateLeftView()
        updatePlaceHolder()
    }

    @objc
    fileprivate func clearTextField() {
        self.text = ""
    }
}
