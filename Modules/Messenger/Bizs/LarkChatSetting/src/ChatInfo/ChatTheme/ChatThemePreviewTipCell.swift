//
//  ChatThemePreviewTipCell.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2022/12/27.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkMessageCore

protocol ChatThemePreviewItem {
    var config: ChatThemePreviewConfig { get set }

    var cellIdentifier: String { get set }
}

class ChatThemePreviewBaseCell: UITableViewCell {
    var item: ChatThemePreviewItem? {
        didSet {
            setCellInfo()
        }
    }
    func setCellInfo() {
        assertionFailure("must be override")
    }
}

struct ChatThemePreviewTipItem: ChatThemePreviewItem {
    var title: String
    var config: ChatThemePreviewConfig
    var componentTheme: ChatComponentTheme
    var cellIdentifier = ChatThemePreviewTipCell.lu.reuseIdentifier
}

final class ChatThemePreviewTipCell: ChatThemePreviewBaseCell {
    private let content = UIView()
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.addSubview(content)
        content.layer.cornerRadius = 6
        content.clipsToBounds = true
        content.snp.makeConstraints { make in
            make.top.equalTo(32)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-12)
        }
        content.addSubview(titleLabel)
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? ChatThemePreviewTipItem else { return }

        titleLabel.text = item.title
        let contentColor = item.componentTheme.systemMessageBlurColor
        content.backgroundColor = ChatThemePreviewColorManger.getColor(color: contentColor, config: item.config)
        titleLabel.textColor = ChatThemePreviewColorManger.getColor(color: UIColor.ud.textCaption, config: item.config)
    }
}
