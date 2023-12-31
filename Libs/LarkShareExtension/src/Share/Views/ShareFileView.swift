//
//  ShareFileView.swift
//  ShareExtension
//
//  Created by K3 on 2018/7/4.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import LarkExtensionCommon
import MobileCoreServices

final class ShareFileView: UIView, ShareTableHeaderProtocol {
    var viewHeight: CGFloat = 102
    private var item: ShareFileItem

    private var iconView: UIImageView
    private var nameLabel: UILabel

    init(item: ShareFileItem) {
        self.item = item
        self.iconView = UIImageView(image: Resources.unknownFile)
        self.nameLabel = UILabel()
        super.init(frame: .zero)

        iconView.backgroundColor = ColorPub.N50
        iconView.layer.masksToBounds = true
        iconView.layer.cornerRadius = 2
        addSubview(iconView)
        iconView.frame = CGRect(x: 15, y: 15, width: 70, height: 70)

        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.textColor = ColorPub.N900
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.text = item.name
        addSubview(nameLabel)
    }

    override var frame: CGRect {
        didSet {
            let frame = self.bounds
            // nameLabel.centerY.equalTo(iconView)
            nameLabel.frame = CGRect(x: 98, y: 15, width: frame.size.width - 98 - 16, height: 70)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
