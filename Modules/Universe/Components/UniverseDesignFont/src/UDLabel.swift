//
//  UDLabel.swift
//  UniverseDesignFont
//
//  Created by 白镜吾 on 2023/4/24.
//

import UIKit

public class UDLabel: UILabel {

    public var contentInset: UIEdgeInsets = .zero

    override init(frame: CGRect) {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInset))
    }

    public override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + contentInset.left + contentInset.right,
                      height: size.height + contentInset.top + contentInset.bottom)
    }

    public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        guard text != nil else {
            return super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        }
        let insetRect = bounds.inset(by: contentInset)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedinsets = UIEdgeInsets(top: -contentInset.top,
                                          left: -contentInset.left,
                                          bottom: -contentInset.bottom,
                                          right: -contentInset.right)
        return textRect.inset(by: invertedinsets)
    }
}
