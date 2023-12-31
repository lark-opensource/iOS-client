//
//  ShareUserCardAlertConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/24.
//

import LarkUIKit
import LarkSDKInterface
import LarkMessengerInterface
import EENavigator
import LarkBizAvatar

final class ShareUserCardAlertConfig: ForwardAlertConfig {
    private let avatarSize: CGFloat = 64

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareUserCardAlertContent != nil {
            return true
        }
        return false
    }

    override func getContentView() -> UIView? {
        guard let userCardContent = content as? ShareUserCardAlertContent else {
            return nil
        }

        let container = BaseForwardConfirmFooter()
        let avatarView = BizAvatar()
        container.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(avatarSize)
            make.top.left.bottom.equalToSuperview().inset(10)
        }
        avatarView.setAvatarByIdentifier(userCardContent.shareChatter.id,
                                         avatarKey: userCardContent.shareChatter.avatarKey,
                                         avatarViewParams: .init(sizeType: .size(avatarSize)))

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 4
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.text = BundleI18n.LarkForward.Lark_Legacy_PreviewUserCard(userCardContent.shareChatter.localizedName)
        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avatarView.snp.top).offset(4)
            make.left.equalTo(avatarView.snp.right).offset(10)
            make.right.equalToSuperview().inset(10)
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
        }
        return container
    }
}
