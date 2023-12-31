//
//  DetailNotesInputView.swift
//  Todo
//
//  Created by 张威 on 2021/2/6.
//

import SnapKit
import EditTextView
import LarkUIKit
import CTFoundation
import UniverseDesignIcon
import UIKit
import UniverseDesignFont

/// Detail - NotesInput - View

class DetailNotesInputView: BasicCellLikeView {

    private(set) lazy var textView = Self.makeEditTextView()
    private lazy var containerView: UIView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        addSubview(containerView)

        content = .customView(containerView)
        let image = UDIcon.detailsOutlined
            .ud.resized(to: CGSize(width: 16, height: 16))
            .ud.withTintColor(UIColor.ud.iconN3)
        icon = .customImage(image)
        iconAlignment = .topByOffset(2.5)

        containerView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(0)
            make.right.equalToSuperview().offset(-16)
            make.height.lessThanOrEqualTo(134)
            make.height.greaterThanOrEqualTo(17)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DetailNotesInputView {

    static func makeEditTextView() -> LarkEditTextView {
        let textView = LarkEditTextView()
        textView.font = UDFont.systemFont(ofSize: 14)
        textView.textColor = UIColor.ud.textTitle
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        textView.defaultTypingAttributes = [
            .foregroundColor: UIColor.ud.textTitle,
            .font: UDFont.systemFont(ofSize: 14),
            .paragraphStyle: paragraphStyle
        ]
        textView.linkTextAttributes = [:]
        textView.textAlignment = .left
        textView.maxHeight = 134
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainerInset = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        textView.backgroundColor = UIColor.ud.bgBody
        textView.placeholder = I18N.Todo_Task_AddNotesPlaceholder
        textView.placeholderTextColor = UIColor.ud.textPlaceholder
        return textView
    }

}
