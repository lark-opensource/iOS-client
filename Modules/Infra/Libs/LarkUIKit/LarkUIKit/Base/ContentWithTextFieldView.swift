//
//  ContentWithTextFieldView.swift
//  LarkDebug
//
//  Created by CharlieSu on 11/25/19.
//

import Foundation
import UIKit
import EditTextView

public final class ContentWithTextFieldView: UIView {
    public var textLabel: UILabel = UILabel()
    public let textField = LarkEditTextView()

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(text: String) {
        super.init(frame: .zero)
        addSubview(textLabel)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.ud.N900
        ]
        textLabel.attributedText = NSAttributedString(string: text, attributes: attributes)
        textLabel.numberOfLines = 0
        textLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalToSuperview().offset(-40)

        }

        addSubview(textField)
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.placeholderTextColor = UIColor.ud.N500
        textField.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 10, right: 10)
        textField.textColor = UIColor.ud.N900
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.ud.N300.cgColor
        textField.layer.cornerRadius = 6
        textField.maxHeight = 55

        textField.snp.makeConstraints { (make) in
            make.top.equalTo(textLabel.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
            make.height.lessThanOrEqualTo(36)
        }

        snp.makeConstraints { (make) in
            make.width.equalTo(260)
        }
    }
}
