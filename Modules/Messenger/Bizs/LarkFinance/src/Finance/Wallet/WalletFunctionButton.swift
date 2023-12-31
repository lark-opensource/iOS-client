//
//  WalletFunctionButton.swift
//  LarkFinance
//
//  Created by CharlieSu on 2018/10/29.
//

import Foundation
import UIKit

final class WalletFunctionButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.numberOfLines = 0
        titleLabel?.textAlignment = .center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let imageView = self.imageView, let titleLabel = self.titleLabel else {
            return
        }
        imageView.sizeToFit()
        titleLabel.sizeToFit()

        imageView.frame.top = 0
        imageView.frame.centerX = bounds.width / 2

        titleLabel.frame.top = imageView.frame.bottom
        titleLabel.preferredMaxLayoutWidth = bounds.width
        titleLabel.frame.size = titleLabel.sizeThatFits(CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude))
        titleLabel.frame.centerX = bounds.width / 2
    }

    override var intrinsicContentSize: CGSize {
        guard let imageView = self.imageView, let titleLabel = self.titleLabel else {
            return super.intrinsicContentSize
        }

        imageView.sizeToFit()
        titleLabel.sizeToFit()

        return CGSize(width: max(imageView.frame.width, titleLabel.frame.width),
                      height: imageView.frame.height + titleLabel.frame.height)
    }
}
