//
//  MomentUserNoticeTextCell.swift
//  Moment
//
//  Created by bytedance on 2021/2/22.
//

import Foundation
import UIKit
import RichLabel

final class MomentUserNoticeTextCell: MomentUserNotieBaseCell {
    lazy var label: LKLabel = {
        let label = LKLabel(frame: .zero).lu.setProps(
            fontSize: 12,
            numberOfLine: 3,
            textColor: UIColor.ud.textPlaceholder
        )
        label.autoDetectLinks = false
        label.backgroundColor = UIColor.clear
        label.preferredMaxLayoutWidth = 54
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: textAttribute)
        label.outOfRangeText = outOfRangeText
        return label
    }()

    lazy var textAttribute: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.lineSpacing = 2
        let attribute: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textPlaceholder,
            .font: UIFont.systemFont(ofSize: 12),
            .paragraphStyle: paragraphStyle
        ]
        return attribute
    }()

    override func configRightView() -> UIView {
        label.attributedText = NSAttributedString(string: "")
        label.numberOfLines = 3
        return label
    }

    override class func getCellReuseIdentifier() -> String {
        return "MomentUserNoticeTextCell"
    }

    override func layoutRightView(_ view: UIView) {
        view.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
            make.width.equalTo(54)
        }
    }

    override func updateRightViewWithVM(_ vm: MomentsNoticeBaseCellViewModel) {
        label.attributedText = vm.rightText ?? NSAttributedString()
    }
}
