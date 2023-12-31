//
//  InsetsSpacingLabel.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/9/23.
//

import Foundation
import UIKit

final class InsetsSpacingLabel: UILabel {
    var insets: UIEdgeInsets
    init(frame: CGRect, insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(text: String, lineSpacing: CGFloat) {
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes(labelAttributes(lineSpacing: lineSpacing), range: NSRange(location: 0, length: text.utf16.count))
        self.attributedText = attributedString
        sizeToFit()
    }

    func setText(attributedString: NSAttributedString) {
        self.attributedText = attributedString
        sizeToFit()
    }

    func labelAttributes(lineSpacing: CGFloat) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineBreakMode = lineBreakMode
        paragraphStyle.alignment = textAlignment
        return [.paragraphStyle: paragraphStyle,
                .font: font ?? UIFont.systemFont(ofSize: 16),
                .foregroundColor: textColor ?? UIColor.ud.N600]
    }

    // MARK: - Override
    override func layoutSubviews() {
        preferredMaxLayoutWidth = frame.width - (insets.left + insets.right)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let superSizeThatFits = super.sizeThatFits(size)
        if (text != nil && !text!.isEmpty) || (attributedText?.string != nil && !attributedText!.string.isEmpty) {
            return CGSize(width: superSizeThatFits.width + insets.left + insets.right,
                          height: superSizeThatFits.height + insets.top + insets.bottom)
        }
        return superSizeThatFits
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        if (text != nil && !text!.isEmpty) || (attributedText?.string != nil && !attributedText!.string.isEmpty) {
            size.width += (insets.left + insets.right)
            size.height += (insets.top + insets.bottom)
        }
        return size
    }
}
