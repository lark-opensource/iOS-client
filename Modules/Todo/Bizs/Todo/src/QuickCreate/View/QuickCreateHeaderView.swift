//
//  QuickCreateHeaderView.swift
//  Todo
//
//  Created by wangwanxin on 2021/3/17.
//

import CTFoundation
import EditTextView
import UniverseDesignIcon
import UniverseDesignFont

/// QuickCreate - HeaderView

class QuickCreateHeaderView: UIStackView {

    var onExpand: (() -> Void)?

    let textView: LarkEditTextView = LarkEditTextView()

    var placeholder: String = I18N.Todo_Task_AddTask {
        didSet {
            textView.attributedPlaceholder = AttrText(
                string: placeholder,
                attributes: [
                    .foregroundColor: UIColor.ud.textPlaceholder,
                    .font: UDFont.systemFont(ofSize: 16, weight: .regular)
                ]
            )
        }
    }

    private(set) lazy var expandButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage((UDIcon.expandOutlined).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        btn.addTarget(self, action: #selector(expandAction), for: .touchUpInside)
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        axis = .horizontal
        spacing = 17
        alignment = .top
        isLayoutMarginsRelativeArrangement = true
        setupTextView()
        addArrangedSubview(textView)
        addArrangedSubview(expandButton)

        expandButton.snp.makeConstraints { $0.size.equalTo(CGSize(width: 24, height: 24)) }
        expandButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        textView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(-4)
            make.centerY.equalToSuperview()
            make.height.lessThanOrEqualTo(77)
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let height = textView.intrinsicContentSize.height > 24 ? textView.intrinsicContentSize.height : 24
        return CGSize(width: Self.noIntrinsicMetric, height: height)
    }

    private func setupTextView() {
        textView.isScrollEnabled = false
        textView.maxHeight = 77
        textView.font = UDFont.systemFont(ofSize: 16, weight: .regular)
        textView.backgroundColor = UIColor.ud.bgBody
        textView.textColor = UIColor.ud.textTitle
        textView.returnKeyType = .next
        textView.enablesReturnKeyAutomatically = true
        textView.linkTextAttributes = [:]
        textView.defaultTypingAttributes = [
            .foregroundColor: UIColor.ud.textTitle,
            .font: UDFont.systemFont(ofSize: 16, weight: .regular)
        ]
        textView.textContainerInset = .zero
        textView.attributedPlaceholder = AttrText(
            string: I18N.Todo_Task_AddTask,
            attributes: [
                .foregroundColor: UIColor.ud.textPlaceholder,
                .font: UDFont.systemFont(ofSize: 16, weight: .regular)
            ]
        )
    }

    @objc
    private func expandAction() {
        onExpand?()
    }
}
