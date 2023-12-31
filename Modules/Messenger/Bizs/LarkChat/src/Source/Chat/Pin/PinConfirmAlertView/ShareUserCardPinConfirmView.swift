//
//  ShareUserCardPinConfirmView.swift
//  LarkChat
//
//  Created by 赵家琛 on 2020/4/23.
//

import Foundation
import UIKit
import LarkBizAvatar
import LarkModel
import LarkMessageCore

final class ShareUserCardPinConfirmView: PinConfirmContainerView {
    private let contentView: PinShareUserCardContentView = PinShareUserCardContentView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.contentView)
        contentView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(BubbleLayout.commonInset)
            make.top.equalToSuperview().inset(16)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.top)
            make.height.equalTo(PinShareUserCardContentView.contentHeight)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let shareUserCardVM = contentVM as? ShareUserCardPinConfirmViewModel else {
            return
        }
        contentView.content = shareUserCardVM.content
    }
}

final class ShareUserCardPinConfirmViewModel: PinAlertViewModel {
    var content: ShareUserCardContent!

    init?(shareUserCardMessage: Message, getSenderName: @escaping (Chatter) -> String) {
        super.init(message: shareUserCardMessage, getSenderName: getSenderName)
        guard let content = shareUserCardMessage.content as? ShareUserCardContent else {
            return nil
        }
        self.content = content
    }
}

final class PinShareUserCardContentView: UIView {
    static let contentHeight: CGFloat = 68
    private let avatarSize: CGFloat = 34

    private lazy var avatarView: BizAvatar = {
        let avatarView = BizAvatar()
        return avatarView
    }()

    private lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.N300
        return lineView
    }()

    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.numberOfLines = 1
        nameLabel.textAlignment = .left
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.text = ""
        return nameLabel
    }()

    private lazy var descLabel: UILabel = {
        let descLabel = UILabel()
        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.textColor = UIColor.ud.N600
        descLabel.numberOfLines = 1
        descLabel.textAlignment = .left
        descLabel.text = BundleI18n.LarkChat.Lark_Legacy_SendUserCard
        return descLabel
    }()

    var content: ShareUserCardContent? {
        didSet {
            self.nameLabel.text = content?.chatter?.localizedName ?? ""
            self.avatarView.setAvatarByIdentifier(content?.chatter?.id ?? "",
                                                  avatarKey: content?.chatter?.avatarKey ?? "",
                                                  avatarViewParams: .init(sizeType: .size(avatarSize)))
        }
    }

    init() {
        super.init(frame: .zero)

        self.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(8)
            make.centerY.equalTo(avatarView)
            make.right.equalToSuperview()
        }

        self.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(avatarView.snp.bottom).offset(8)
        }

        self.addSubview(descLabel)
        descLabel.snp.makeConstraints { (make) in
            make.left.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
