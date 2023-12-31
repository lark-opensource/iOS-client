//
//  DocTitleLabel.swift
//  Calendar
//
//  Created by huoyunjie on 2023/10/8.
//

import LarkUIKit
import LKRichView
import UniverseDesignIcon

class DocTitleLabel: UIView {
    typealias Tag = MeetingNotesTag

    lazy var text: LKTextElement = {
        let label = LKTextElement(text: "")
        return label
    }()

    lazy var documentElement: LKBlockElement = {
        let element = LKBlockElement(tagName: Tag.normal, style: LKRichStyle().verticalAlign(.middle))
        return element
    }()

    private lazy var label: LKRichView = {
        let label = LKRichView()
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContent(text: String,
                       color: UIColor,
                       font: UIFont,
                       hiddenImg: Bool,
                       fontWeight: FontWeight? = nil,
                       numberOfLine: Int = 0,
                       wrapEllipsis: Bool = true) {
        self.text.text = text
        /// 控制单行展示时，文本垂直居中，高度等于 lineHeight
        let empty = LKInlineBlockElement(tagName: Tag.normal).style(.init().minHeight(.point(20)).width(.point(0)))
        if hiddenImg {
            documentElement.children([empty, self.text])
        } else {
            let attachment = getAttachmentElement(color: color)
            documentElement.children([attachment, self.text])
        }
        self.text.style.textOverflow(wrapEllipsis ? LKTextOverflow.none : .noWrapEllipsis)
        documentElement.style
            .lineCamp(.init(maxLine: numberOfLine))
            .color(color)
            .font(font)
            .fontWeight(fontWeight)
            .fontSize(.point(font.pointSize))
            .lineHeight(.point(22))
            .verticalAlign(.middle)

        setNeedsLayout()
        layoutIfNeeded()

        label.preferredMaxLayoutWidth = label.bounds.width
        label.documentElement = documentElement
    }

    private func getAttachmentElement(color: UIColor) -> LKInlineElement {
        let icon = UDIcon.fileLinkWordOutlined.ud.withTintColor(color)
        let imageView = UIImageView(image: icon)
        imageView.frame = CGRect(x: 0, y: 0, width: 14, height: 14)

        let attachment = LKRichAttachmentImp(view: imageView)
        let element = LKAttachmentElement(attachment: attachment)

        let block = LKInlineElement(tagName: Tag.normal)
        block.children([element])
        block.style.padding(right: .point(4), left: .point(0.7))

        return block
    }
}
