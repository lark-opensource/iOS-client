//
//  ShareTextView.swift
//  ShareExtension
//
//  Created by K3 on 2018/7/3.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import LarkExtensionCommon
import MobileCoreServices

private let inset: CGFloat = 16
private let defaultHeight: CGFloat = 122

final class ShareTextView: UIView, UITextViewDelegate, ShareTableHeaderProtocol {
    let viewHeight: CGFloat = defaultHeight
    fileprivate var item: ShareTextItem

    fileprivate let textLabel: UILabel

    init(item: ShareTextItem) {
        self.item = item
        textLabel = UILabel()

        super.init(frame: .zero)

        textLabel.font = UIFont.systemFont(ofSize: 16)
        textLabel.textColor = ColorPub.N900
        textLabel.numberOfLines = 0
        addSubview(textLabel)
        loadText()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var frame: CGRect {
        didSet {
            let frame = self.bounds
            textLabel.frame = CGRect(
                x: inset,
                y: inset,
                width: frame.size.width - inset * 2,
                height: viewHeight - inset * 2
            )
        }
    }
}

extension ShareTextView {
    fileprivate func loadText() {
        self.textLabel.text = item.text
    }
}
