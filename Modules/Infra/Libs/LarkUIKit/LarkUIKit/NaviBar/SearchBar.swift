//
//  SearchBar.swift
//  Lark
//
//  Created by liuwanlin on 2018/1/17.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import LarkInteraction

/// 左边按钮风格
public enum SearchBarLeftButtonStyle {
    case search
    case back
}

open class SearchBar: UIView {
    public let style: SearchBarLeftButtonStyle

    public let leftButton = UIButton()

    public let searchTextField = SearchUITextField()

    public let cancelButton = UIButton()

    private let diposeBag = DisposeBag()

    public init(style: SearchBarLeftButtonStyle) {
        self.style = style
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 24, height: 44))
        backgroundColor = UIColor.ud.bgBody
        leftButton.setImage(Resources.navigation_back_light.withRenderingMode(.alwaysTemplate), for: .normal)
        leftButton.tintColor = UIColor.ud.iconN1
        addSubview(leftButton)

        searchTextField.placeholder = BundleI18n.LarkUIKit.Lark_Legacy_SearchViewPlaceholder
        // searchTextField.tintColor = UIColor.ud.colorfulBlue
        searchTextField.font = UIFont.systemFont(ofSize: 16)
        searchTextField.textColor = UIColor.ud.textTitle
        addSubview(searchTextField)

        cancelButton.setTitle(BundleI18n.LarkUIKit.Lark_Legacy_Cancel, for: .normal)
        cancelButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        addSubview(cancelButton)
        cancelButton.sizeToFit()

        leftButton.sizeToFit()

        self.setupStyle()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.setupStyle()
    }

    private func setupStyle() {
        cancelButton.frame.centerY = bounds.centerY
        cancelButton.frame.right = bounds.width

        switch style {
        case .search:
            leftButton.isHidden = true
            searchTextField.frame = CGRect(x: 0, y: 6, width: bounds.width - cancelButton.bounds.width - 12, height: 32)
        case .back:
            leftButton.isHidden = false
            leftButton.frame.centerY = bounds.centerY
            leftButton.frame.left = 0

            searchTextField.frame = CGRect(
                x: leftButton.frame.maxX + 12,
                y: 6,
                width: bounds.width - leftButton.frame.maxX - 12 - cancelButton.bounds.width - 12,
                height: 32)
        }
        if #available(iOS 13.4, *) {
            func expand(size: CGSize) -> CGSize {
                var size = size
                size.width += 8
                size.height += 6
                return size
            }
            // layout会调用这个函数，只做一次性设置, 修复真机问题
            if leftButton.lkPointerStyle == nil {
                let leftButtonSize = expand(size: leftButton.frame.size)
                leftButton.lkPointerStyle = PointerStyle(
                    effect: .highlight,
                    shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                        return (leftButtonSize, 8)
                    }))
            }

            if cancelButton.lkPointerStyle == nil {
                let cancelButtonSize = expand(size: cancelButton.frame.size)
                cancelButton.lkPointerStyle = PointerStyle(
                    effect: .highlight,
                    shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                        return (cancelButtonSize, 8)
                    }))
            }
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var intrinsicContentSize: CGSize {
        return self.frame.size
    }
}
