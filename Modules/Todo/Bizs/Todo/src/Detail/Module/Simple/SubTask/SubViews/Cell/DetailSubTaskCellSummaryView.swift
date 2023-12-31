//
//  DetailSubTaskCellSummaryView.swift
//  Todo
//
//  Created by baiyantao on 2022/8/1.
//

import Foundation
import EditTextView
import LarkContainer
import UniverseDesignFont

final class DetailSubTaskCellSummaryView: UIView {

    var richContent: Rust.RichContent? {
        didSet {
            guard let content = richContent, let inputController = inputController else {
                textView.attributedText = .init()
                return
            }
            var attr = Self.baseAttributes
            if hasStrikethrough {
                attr[.strikethroughStyle] = NSNumber(value: 1)
            }
            if !isEditMode && content.richText.isEmpty {
                textView.attributedText = MutAttrText(
                    string: I18N.Todo_Task_NoTitlePlaceholder,
                    attributes: attr
                )
            } else {
                let attrText = inputController.makeAttrText(
                    from: content,
                    with: attr
                )
                inputController.resetAtInfo(in: attrText)
                textView.attributedText = attrText
            }
            // ios15下，因为数据超过一行时，scrollEnable为true不触发扩充高度布局，需要再次进行布局计算，ios16下会进行一次自动布局
            if isEditMode {
                textView.setNeedsLayout()
                textView.layoutIfNeeded()
            }
        }
    }

    var hasStrikethrough: Bool = false {
        didSet {
            guard oldValue != hasStrikethrough else { return }
            var typingAttributes = Self.baseAttributes
            if hasStrikethrough {
                typingAttributes[.strikethroughStyle] = NSNumber(value: 1)
            }
            textView.defaultTypingAttributes = typingAttributes
        }
    }

    var isEditMode: Bool = true {
        didSet {
            guard oldValue != isEditMode else { return }
            if isEditMode {
                textView.textContainer.maximumNumberOfLines = 0
                textView.textContainer.lineBreakMode = .byWordWrapping
                textView.forceScrollEnabled = true
            } else {
                textView.textContainer.maximumNumberOfLines = 1
                textView.textContainer.lineBreakMode = .byWordWrapping
                textView.forceScrollEnabled = false
            }
        }
    }

    var inputController: InputController?
    private(set) lazy var textView = getTextView()
    static var baseAttributes: [AttrText.Key: Any] = {
        return [.foregroundColor: UIColor.ud.textTitle,
                .font: UDFont.systemFont(ofSize: 16)]
    }()

    init() {
        super.init(frame: .zero)

        addSubview(textView)
        textView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getTextView() -> LarkEditTextView {
        let textView = LarkEditTextView()
        textView.backgroundColor = UIColor.ud.bgBody
        textView.textAlignment = .left
        textView.textContainerInset = .zero
        textView.returnKeyType = .next
        textView.textDragInteraction?.isEnabled = false
        textView.maxHeight = 24

        var placeholderAttrs = Self.baseAttributes
        placeholderAttrs[.foregroundColor] = UIColor.ud.textPlaceholder
        textView.attributedPlaceholder = AttrText(string: I18N.Todo_AddSubTasks_Placeholder_Mobile, attributes: placeholderAttrs)
        textView.defaultTypingAttributes = Self.baseAttributes
        return textView
    }

}
