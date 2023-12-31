//
//  MomentsUserNameLabelComponent.swift
//  Moment
//
//  Created by ByteDance on 2023/1/5.
//

import Foundation
import AsyncComponent
import RichLabel
import UIKit

final class MomentsUserNameLabelComponent<C: AsyncComponent.Context>: ASComponent<MomentsUserNameLabelComponent.Props, EmptyState, MomentsUserNameLabel, C> {
    final class Props: ASComponentProps {
        var name: String = ""
        var isOfficialUser: Bool = false
        var textColor: UIColor = UIColor.ud.textTitle
        var font: UIFont = .systemFont(ofSize: 17, weight: .medium)
        var numberOfLines: Int = 2
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        var textSize = getAttributedString().componentTextSize(for: size, limitedToNumberOfLines: props.numberOfLines)
        /// https://bytedance.feishu.cn/wiki/wikcnjS9uVfFopQObxLkB0LwIoe#
        textSize.width += 2 / UIScreen.main.scale
        return textSize
    }

    private var attributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        return [.font: props.font,
                .paragraphStyle: paragraphStyle
        ]
    }

    private func getAttributedString() -> NSAttributedString {
        let attrText = NSMutableAttributedString(string: props.name, attributes: attributes)
        if props.isOfficialUser {
            let attachment = LKAsyncAttachment(viewProvider: { () -> UIView in
                //这里其实不会真正创建view，只是利用LKAsyncAttachment算一下文字宽度
                return UIView()
            }, size: OfficialUserLabel.suggestSize)
            attachment.margin = .init(top: 0, left: 6, bottom: 0, right: 0)
            attachment.fontAscent = props.font.ascender
            attachment.fontDescent = props.font.descender
            var attachmentAttr = self.attributes
            attachmentAttr[LKAttachmentAttributeName] = attachment
            attrText.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: attachmentAttr))
        }
        return attrText
    }

    public override func create(_ rect: CGRect) -> MomentsUserNameLabel {
        return MomentsUserNameLabel()
    }

    override func update(view: MomentsUserNameLabel) {
        super.update(view: view)
        view.numberOfLines = props.numberOfLines
        view.font = props.font
        view.isOfficialUser = props.isOfficialUser
        view.textColor = props.textColor
        view.name = props.name
    }
}
