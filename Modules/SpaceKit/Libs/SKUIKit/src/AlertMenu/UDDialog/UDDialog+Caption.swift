//
//  UDDialog+Caption.swift
//  SKUIKit
//
//  Created by Weston Wu on 2022/5/7.
//

import Foundation
import UniverseDesignDialog
import UniverseDesignColor

extension UDDialog {
    public func setContent(text: String, caption: String) {
        let contentStyle = UDDialog.TextStyle.content()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 10

        let titleString = NSAttributedString(string: text,
                                             attributes: [
                                                .font: contentStyle.font,
                                                .foregroundColor: contentStyle.color
                                             ])

        let captionString = NSAttributedString(string: "\n" + caption,
                                            attributes: [
                                                .font: UIFont.systemFont(ofSize: 14),
                                                .foregroundColor: UDColor.textCaption
                                            ])
        let content = NSMutableAttributedString(attributedString: titleString)
        content.append(captionString)
        content.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: content.length))
        setContent(attributedText: content)
    }
}
