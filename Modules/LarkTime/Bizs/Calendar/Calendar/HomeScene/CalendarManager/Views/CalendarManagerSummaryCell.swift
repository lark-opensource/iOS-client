//
//  CalendarManagerSummaryCell.swift
//  Calendar
//
//  Created by harry zou on 2019/3/22.
//

import UIKit
import Foundation
import CalendarFoundation
import SnapKit

final class CalendarManagerSummaryCell: UIControl, AddBottomLineAble {
    private let icon: UIImageView
    private let textView: KMPlaceholderTextView = {
        let view = KMPlaceholderTextView()
        view.font = UIFont.cd.regularFont(ofSize: 16)
        return view
    }()
    private let textChanged: (String) -> Void
    // swiftlint:disable weak_delegate
    let textViewDelegate = TextViewLengthLimitedDelegate(maxLength: 100)
    // swiftlint:enable weak_delegate
    init(iconImage: UIImage,
         placeHolder: String,
         isEditable: Bool,
         textChanged: @escaping (String) -> Void) {
        self.icon = UIImageView(image: iconImage)
        self.textChanged = textChanged
        super.init(frame: .zero)
        textView.textColor = isEditable ? UIColor.ud.textTitle : UIColor.ud.textDisable
        textView.isEditable = isEditable
        textView.placeholder = placeHolder
        textView.placeholderColor = UIColor.ud.textPlaceholder
        textView.isScrollEnabled = false
        textView.contentInset = UIEdgeInsets(top: -7, left: -5, bottom: 0, right: -5)
        textView.frame.size.height = 30
        textViewDelegate.onTextChanged = textChanged
        textView.delegate = textViewDelegate
        layout(icon: icon)
        layout(textView: textView, leftItem: icon.snp.right)
        backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout(icon: UIView) {
        addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(18)
            make.width.height.equalTo(16)
        }
    }

    private func layout(textView: UIView, leftItem: ConstraintItem) {
        addSubview(textView)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(1)
            make.left.equalTo(leftItem).offset(18)
            make.right.equalToSuperview().offset(-16)
        }
    }

    func update(with summary: String) {
        textView.text = summary
    }
}
