//
//  PhotoPickerBottomToolBar.swift
//  LarkUIKit
//
//  Created by SuPeng on 3/18/19.
//

import UIKit
import Foundation
import LarkButton
import LarkUIKit
import UniverseDesignCheckBox
import UniverseDesignColor
import UniverseDesignButton

protocol PhotoPickerBottomToolBarDelegate: AnyObject {
    func bottomToolBarDidClickOriginButton(_ bottomToolBar: PhotoPickerBottomToolBar)
    func bottomToolBarDidClickPreviewButton(_ bottomToolBar: PhotoPickerBottomToolBar)
    func bottomToolBarDidClickSendButton(_ bottomToolBar: PhotoPickerBottomToolBar)
}

final class PhotoPickerBottomToolBar: UIView {
    weak var delegate: PhotoPickerBottomToolBarDelegate?

    private let originalButton = OriginalButton()

    private lazy var previewButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.ud.body0(.fixed)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        if #available(iOS 15.0, *) {
            button.titleLabel?.showsExpansionTextWhenTruncated = true
        }
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.setTitle(BundleI18n.LarkAssetsBrowser.Lark_Legacy_ImagePreview, for: .normal)
        return button
    }()

    private lazy var sendButton: UDButton = {
        let button = UDButton(.primaryBlue.type(.small))
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.font = UIFont.ud.body0(.fixed)
        button.setTitle(sendButtonTitle, for: .normal)
        return button
    }()

    private let sendButtonTitle: String

    init(isOriginalButtonHidden: Bool, sendButtonTitle: String) {
        self.sendButtonTitle = sendButtonTitle
        super.init(frame: .zero)
        setupSubviews()
        backgroundColor = UIColor.ud.bgBody
        originalButton.isHidden = isOriginalButtonHidden
        originalButton.lu.addTapGestureRecognizer(action: #selector(originButtonDidClick), target: self)
        previewButton.addTarget(self, action: #selector(previewButtonDidClick), for: .touchUpInside)
        previewButton.isHidden = true
        sendButton.isEnabled = false
        sendButton.addTarget(self, action: #selector(sendButtonDidClick), for: .touchUpInside)
    }

    private func setupSubviews() {
        addSubview(originalButton)
        addSubview(previewButton)
        addSubview(sendButton)

        originalButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(32)
        }
        previewButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().priority(.low)
            make.left.greaterThanOrEqualTo(originalButton.snp.right).offset(8)
            make.right.lessThanOrEqualTo(sendButton.snp.left).offset(-8)
            // 设计不让留最小宽度，那就不留吧
            // make.width.greaterThanOrEqualToSuperview().multipliedBy(0.2)
        }
        sendButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
        sendButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        originalButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        // 分割线
        let topSeperator = UIView()
        topSeperator.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(topSeperator)
        topSeperator.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(selectCount: Int) {
        if selectCount > 0 {
            sendButton.setTitle(sendButtonTitle + "(\(selectCount))", for: .normal)
        } else {
            sendButton.setTitle(sendButtonTitle, for: .normal)
        }
        previewButton.isHidden = (selectCount == 0)
        sendButton.isEnabled = (selectCount != 0)
    }

    func set(isOriginEnable: Bool) {
        originalButton.set(isOriginEnable: isOriginEnable)
    }

    func set(isOrigin: Bool) {
        originalButton.set(isOrigin: isOrigin)
    }

    func isOriginal() -> Bool {
        originalButton.isOriginal
    }

    @objc
    private func originButtonDidClick() {
        if originalButton.isEnabled {
            delegate?.bottomToolBarDidClickOriginButton(self)
        }
    }

    @objc
    private func previewButtonDidClick() {
        delegate?.bottomToolBarDidClickPreviewButton(self)
    }

    @objc
    private func sendButtonDidClick() {
        delegate?.bottomToolBarDidClickSendButton(self)
    }
}

final class OriginalButton: UIStackView {

    var isEnabled: Bool {
        checkbox.isEnabled
    }

    var isOriginal: Bool {
        checkbox.isSelected
    }

    func set(isOriginEnable: Bool) {
        checkbox.isEnabled = isOriginEnable
        textLabel.textColor = isOriginEnable ? UIColor.ud.N900 : UIColor.ud.N400
    }

    func set(isOrigin: Bool) {
        checkbox.isSelected = isOrigin
    }

    let checkbox = UDCheckBox(boxType: .multiple)
    let textLabel = UILabel.lu.labelWith(fontSize: 16,
                                         textColor: UIColor.ud.textTitle,
                                         text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_OriginPic)

    override init(frame: CGRect) {
        super.init(frame: frame)
        spacing = 5
        alignment = .center
        checkbox.isEnabled = true
        textLabel.textColor = UIColor.ud.N900
        textLabel.numberOfLines = 1
        checkbox.isUserInteractionEnabled = false
        addArrangedSubview(checkbox)
        addArrangedSubview(textLabel)
        checkbox.snp.makeConstraints { make in
            make.width.height.equalTo(18)
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
