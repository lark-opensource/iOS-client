//
//  ChatTabAddURLSearchCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/4/6.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import LKCommonsLogging
import TangramService

final class ChatTabAddURLSearchCell: UITableViewCell {
    private lazy var plusIcon: UIImageView = {
        let plusIcon = UIImageView()
        plusIcon.image = UDIcon.getIconByKey(.addMiddleOutlined, size: CGSize(width: 20, height: 20))
        return plusIcon
    }()

    private lazy var urlLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(plusIcon)
        contentView.addSubview(urlLabel)
        plusIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        urlLabel.snp.makeConstraints { make in
            make.left.equalTo(plusIcon.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(20)
        }
    }

    func set(_ text: String) {
        urlLabel.text = BundleI18n.LarkChat.Lark_IM_Tabs_AddLink_Button_Mobile(text)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ChatTabAddURLPreviewCell: UITableViewCell {
    static let logger = Logger.log(ChatTabAddURLPreviewCell.self, category: "Module.IM.ChatTab")
    private lazy var urlPreviewIcon: UIImageView = {
        let urlPreviewIcon = UIImageView()
        return urlPreviewIcon
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(urlPreviewIcon)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)
        urlPreviewIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(urlPreviewIcon.snp.right).offset(12)
            make.top.equalToSuperview().inset(12)
            make.right.equalToSuperview().inset(20)
        }
        subTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(urlPreviewIcon.snp.right).offset(12)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.right.equalToSuperview().inset(20)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.urlPreviewIcon.bt.setLarkImage(with: .default(key: ""))
    }

    func set(_ urlPreviewInfo: URLPreviewInfo, link: String) {
        titleLabel.text = urlPreviewInfo.title
        subTitleLabel.text = link
        let defaultIcon = UDIcon.getIconByKey(.fileRoundLinkColorful, size: CGSize(width: 40, height: 40))
        if let udIconKey = urlPreviewInfo.udIcon, !udIconKey.isEmpty {
            urlPreviewIcon.image = URLPreviewUDIcon.getIconByKey(udIconKey, iconColor: UIColor.ud.textLinkNormal, size: CGSize(width: 40, height: 40)) ?? defaultIcon
            return
        }
        let iconKey = urlPreviewInfo.iconKey ?? urlPreviewInfo.iconUrl
        if let iconKey = iconKey, !iconKey.isEmpty {
            urlPreviewIcon.bt.setLarkImage(with: .default(key: iconKey),
                                           placeholder: defaultIcon) { [weak urlPreviewIcon] res in
                switch res {
                case .success(let imageResult):
                    if let image = imageResult.image {
                        urlPreviewIcon?.setImage(image, tintColor: UIColor.ud.textLinkNormal)
                    }
                case .failure(let error):
                    Self.logger.error("set image fail", error: error)
                }
            }
            return
        }
        urlPreviewIcon.image = defaultIcon
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
