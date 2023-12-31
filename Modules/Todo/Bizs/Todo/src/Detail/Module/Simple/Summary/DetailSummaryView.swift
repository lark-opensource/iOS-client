//
//  DetailSummaryView.swift
//  Todo
//
//  Created by 张威 on 2021/1/6.
//

import SnapKit
import EditTextView
import LarkUIKit
import CTFoundation
import RustPB
import UniverseDesignFont

/// Detail - Summary - View

class DetailSummaryView: UIView {

    let textView = LarkEditTextView()
    /// checkbox
    let checkbox = Todo.Checkbox()

    /// 是否可编辑
    var isEditable: Bool = true {
        didSet {
            guard oldValue != isEditable else { return }
            textView.isEditable = isEditable
            if !isEditable {
                textView.addGestureRecognizer(uneditableTapGesture)
            } else {
                textView.removeGestureRecognizer(uneditableTapGesture)
            }
        }
    }

    var placeholder: String = I18N.Todo_Task_AddTask {
        didSet {
            var placeholderAttrs = baseAttributes
            placeholderAttrs[.foregroundColor] = UIColor.ud.textPlaceholder
            textView.attributedPlaceholder = AttrText(
                string: placeholder,
                attributes: placeholderAttrs
            )
        }
    }

    var isCheckBoxHidden: Bool = false {
        didSet {
            guard oldValue != isCheckBoxHidden else { return }
            checkbox.isHidden = isCheckBoxHidden
            remakeSubViews()
        }
    }

    /// 是否有删除线
    var hasStrikethrough: Bool = false {
        didSet {
            guard oldValue != hasStrikethrough else { return }
            var typingAttributes = baseAttributes
            if hasStrikethrough {
                typingAttributes[.strikethroughStyle] = NSNumber(value: 1)
            }
            textView.defaultTypingAttributes = typingAttributes
        }
    }

    var onUneditableTap: (() -> Void)?

    private(set) lazy var baseAttributes: [AttrText.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        return [
            .foregroundColor: UIColor.ud.textTitle,
            .font: UDFont.systemFont(ofSize: 20, weight: .medium),
            .paragraphStyle: paragraphStyle
        ]
    }()
    private let richTextMaxHeight = CGFloat(10_000)
    private lazy var uneditableTapGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(handleUneditableTapTap))
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        setupViews()
        configTextView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(checkbox)
        checkbox.hitTestEdgeInsets = UIEdgeInsets(top: -12, left: -12, bottom: -12, right: -12)
        addSubview(textView)
        remakeSubViews()
    }

    private func remakeSubViews() {
        if checkbox.isHidden {
            textView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(12)
                make.right.equalToSuperview().offset(-12)
                make.top.equalToSuperview().offset(6)
                make.bottom.equalToSuperview().offset(-10)
                make.height.greaterThanOrEqualTo(24)
            }
        } else {
            checkbox.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(17)
                make.width.height.equalTo(18)
                make.top.equalTo(textView).offset(3.5)
            }
            textView.snp.remakeConstraints { make in
                make.left.equalTo(checkbox.snp.right).offset(6)
                make.right.equalToSuperview().offset(-12)
                make.top.equalToSuperview().offset(6)
                make.bottom.equalToSuperview().offset(-10)
                make.height.greaterThanOrEqualTo(24)
            }
        }

    }

    private func configTextView() {
        textView.textDragInteraction?.isEnabled = false
        // EditTextView在判断字体需要的显示高度超过高度限制后会自动设置为scrollEnabled
        // 初始化需要置为false，不然textView会撑不开
        textView.isScrollEnabled = false
        textView.maxHeight = richTextMaxHeight
        textView.placeholderTextColor = (baseAttributes[.foregroundColor] as? UIColor) ?? UIColor.ud.textPlaceholder
        textView.font = (baseAttributes[.font] as? UIFont) ?? UDFont.systemFont(ofSize: 20, weight: .medium)
        textView.textColor = UIColor.ud.textTitle
        textView.backgroundColor = UIColor.ud.bgBody

        textView.linkTextAttributes = [:]
        textView.defaultTypingAttributes = baseAttributes
        textView.textAlignment = .left
        textView.textContainerInset = .zero
    }

    @objc
    private func handleUneditableTapTap() {
        onUneditableTap?()
    }
}
