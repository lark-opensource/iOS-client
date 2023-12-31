//
//  MomentsInteractionBar.swift
//  Moment
//
//  Created by ByteDance on 2022/7/6.
//

import Foundation
import AsyncComponent
import UIKit
import AvatarComponent
import LarkBizAvatar
import ByteWebImage

final class MomentsInteractiveBar: UIView {
    struct MomentsInteractionInfo {
        var iconKey: String
        var title: String
    }
    private var iconSize = CGSize(width: 16, height: 16)

    private lazy var iconImage = UIImageView()
    /// label行高的style
    private lazy var labelAttribute: [NSAttributedString.Key: Any] = {
        /// 通过富文本来设置行高
        let paraph = NSMutableParagraphStyle()
        paraph.lineHeightMultiple = 1.25
        let attribute = [NSAttributedString.Key.paragraphStyle: paraph,
                         NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium)]
        return attribute
    }()
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ud.textCaption
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0
        return label
    }()

    init(frame: CGRect, momentsInteractionInfo: MomentsInteractionInfo) {
        super.init(frame: frame)
        label.attributedText = NSAttributedString(string: momentsInteractionInfo.title, attributes: labelAttribute)
        setupView()
    }

    private func setupView() {
        addSubview(iconImage)
        addSubview(label)
        iconImage.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            /// icon居中于label的第一行，向下偏移5
            make.top.equalTo(5)
            make.size.equalTo(iconSize)
        }
        label.snp.makeConstraints { (make) in
            /// icon与label之间的间距为8
            make.left.equalTo(iconImage.snp.right).offset(8)
            make.top.right.bottom.equalToSuperview()
        }
    }

    func update(title: String, iconKey: String) {
        iconImage.bt.setLarkImage(with: .avatar(key: iconKey, entityID: MomentsGlobalConfigs.entityEmpty))
        label.attributedText = NSAttributedString(string: title, attributes: labelAttribute)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
