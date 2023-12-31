//
//  SearchUITextField.swift
//  Lark
//
//  Created by 刘晚林 on 2017/5/16.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkInteraction
import UniverseDesignIcon

open class SearchUITextField: BaseTextField {
    public var canEdit: Bool = true {
        didSet {
            handleTapView.isUserInteractionEnabled = !canEdit

            guard Display.pad else { return }
            if canEdit {
                self.lkTextDropDelegate = nil
            } else {
                /// 不支持编辑的时候同时禁止 drop
                let textDropDelegate = TextViewDropDelegate()
                textDropDelegate.dropProposalBlock = { _, _ in
                    return UITextDropProposal(operation: .cancel)
                }
                self.lkTextDropDelegate = textDropDelegate
            }
        }
    }
    /// if autoFocus and canEdit is true
    /// auto focus when text field first appear
    public var autoFocus: Bool = false
    private var autoFocusChecked: Bool = false

    private let handleTapView = UIView()

    public var tapBlock: ((SearchUITextField) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        handleTapView.backgroundColor = UIColor.clear
        handleTapView.isUserInteractionEnabled = false
        self.addSubview(handleTapView)
        handleTapView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(searchFieldTapHandler))
        handleTapView.addGestureRecognizer(tapGesture)

        self.font = UIFont.systemFont(ofSize: 16)
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 6
        self.borderStyle = .none
        self.clearButtonMode = .always
        self.exitOnReturn = true

        let icon = UIImageView(image: UDIcon.searchOutlined.withRenderingMode(.alwaysTemplate))
        icon.tintColor = UIColor.ud.iconN3
        icon.frame = CGRect(x: 12, y: 11, width: 16, height: 16)
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 38, height: 38))
        leftView.addSubview(icon)
        self.leftView = leftView
        self.leftViewMode = .always

        backgroundColor = UIColor.ud.bgBodyOverlay
        placeholder = BundleI18n.LarkUIKit.Lark_Legacy_Search
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    fileprivate func searchFieldTapHandler() {
        self.tapBlock?(self)
    }

    open override var placeholder: String? {
        didSet {
            self.attributedPlaceholder = NSAttributedString(
                string: self.placeholder ?? "",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.ud.textCaption
                ]
            )
        }
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.canEdit,
            self.autoFocus,
            !self.autoFocusChecked,
            self.window != nil {
            self.autoFocusChecked = true
            self.becomeFirstResponder()
        }
    }
}

open class SearchUITextFieldWrapperView: UIView {
    public let searchUITextField = SearchUITextField(frame: CGRect.zero)

    public init() {
        super.init(frame: CGRect.zero)

        backgroundColor = UIColor.ud.bgBody

        addSubview(searchUITextField)
        searchUITextField.snp.makeConstraints({ make in
            make.top.equalTo(6)
            make.height.equalTo(36)
            make.left.equalTo(16)
            make.right.equalTo(-16)
        })

        snp.makeConstraints { (make) in
            make.height.equalTo(52)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
