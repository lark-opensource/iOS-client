//   
//   LiveSettingLegalView.swift
//   ByteView
// 
//  Created by hubo on 2023/2/28.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//   


import UIKit
import Foundation
import SnapKit
import ByteViewCommon
import UniverseDesignCheckBox

final class LiveSettingLegalView: UIView, UITextViewDelegate {

    lazy var textView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        return textView
    }()

    lazy var checkbox = UDCheckBox(boxType: .multiple) { [weak self] _ in
        self?.onButtonClicked()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        addSubview(textView)
        addSubview(checkbox)

        checkbox.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalTo(textView.snp.left).offset(-6)
            make.width.equalTo(checkbox.snp.height)
        }

        textView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

    func onButtonClicked() {
        checkbox.isSelected.toggle()
    }

    func updateLink(link: URL) {
        let linkText = LinkTextParser.parsedLinkText(from: I18n.View_MV_LiveReadAndAgree)
        let attributeText = NSMutableAttributedString(string: linkText.result, attributes: [
            .font: UIFont(name: "PingFangSC-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textPlaceholder
        ])
        if let range = linkText.components.first?.range {
            attributeText.addAttributes([
                .link: link,
                .foregroundColor: UIColor.ud.primaryContentDefault
            ], range: range)
        }
        textView.attributedText = attributeText
    }

    func selectAndDisableCheckButton() {
        checkbox.isEnabled = false
    }

    func normalCheckButton() {
        checkbox.isEnabled = true
    }
}
