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
}
