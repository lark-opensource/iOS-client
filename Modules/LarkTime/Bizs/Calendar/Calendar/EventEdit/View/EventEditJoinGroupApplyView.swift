//
//  EventEditJoinGroupApplyView.swift
//  Calendar
//
//  Created by pluto on 2022/12/13.
//

import UIKit
import Foundation
import LarkUIKit

final class CalendarJoinGroupApplyTextField: BaseTextField {
    override func cut(_ text: String) -> (Bool, String) {
        let string = text as NSString
        let count = string.length
        return (count > maxLength,
                string.substring(with: NSRange(location: 0, length: min(count, maxLength))) as String)
    }
}

final class CalendarJoinGroupApplyView: UIView {
    let messageLabel = UILabel()
    let textField = CalendarJoinGroupApplyTextField()

    init(tips: String) {
        super.init(frame: .zero)
        addSubview(messageLabel)
        addSubview(textField)

        messageLabel.text = tips
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = UIColor.ud.N900
        messageLabel.numberOfLines = 0
        messageLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(6)
            maker.left.right.equalToSuperview()
            maker.width.lessThanOrEqualTo(263).priority(.required)
        }

        textField.exitOnReturn = true
        textField.textAlignment = .left
        textField.clearButtonMode = .whileEditing
        textField.textColor = UIColor.ud.N900
        textField.backgroundColor = UIColor.ud.bgFloat
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.returnKeyType = .done
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 6
        textField.layer.borderWidth = 1
        textField.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        textField.maxLength = 100
        textField.contentInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textField.attributedPlaceholder = NSAttributedString(string: I18n.Calendar_G_EnterBoxOptional, attributes: [.foregroundColor: UIColor.ud.textPlaceholder, .font: UIFont.systemFont(ofSize: 16)])
        textField.clearButtonMode = .never
        textField.setContentCompressionResistancePriority(.required, for: .horizontal)
        textField.setContentHuggingPriority(.required, for: .horizontal)
        textField.snp.makeConstraints { (maker) in
            maker.top.equalTo(messageLabel.snp.bottom).offset(8)
            maker.height.equalTo(48)
            maker.width.equalTo(263).priority(.required)
            maker.left.right.equalToSuperview()
            maker.bottom.equalToSuperview().offset(-6)
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
