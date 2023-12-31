//
//  RoundAvatarView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/16.
//

import Foundation
import LarkUIKit
import LarkBizAvatar
import ByteWebImage

final class RoundAvatarView: UIView {
    var blueCircleWidth: CGFloat = 2
    private let avatarInfo: MailSearchFilterView.AvatarInfo?
    private let avatarImageView = BizAvatar()

    init(avatarInfo: MailSearchFilterView.AvatarInfo, avatarWidth: CGFloat = 16, showBgColor: Bool = true, blueCircleWidth: CGFloat = 2) {
        self.avatarInfo = avatarInfo
        self.blueCircleWidth = blueCircleWidth
        super.init(frame: .zero)
        avatarImageView.setAvatarByIdentifier(avatarInfo.avatarID, avatarKey: avatarInfo.avatarKey, avatarViewParams: .init(sizeType: .size(avatarWidth)))
        setup(avatarWidth: avatarWidth, showBgColor: showBgColor)
    }

    init(avatarImage: UIImage, avatarWidth: CGFloat = 16, showBgColor: Bool = true, blueCircleWidth: CGFloat = 2) {
        self.avatarInfo = nil
        self.blueCircleWidth = blueCircleWidth
        super.init(frame: .zero)
        avatarImageView.image = avatarImage
        setup(avatarWidth: avatarWidth, showBgColor: showBgColor)
    }

    init(avatarImageURL: String, avatarWidth: CGFloat = 16, showBgColor: Bool = true, blueCircleWidth: CGFloat = 2, placeholderImage: UIImage? = nil) {
        self.avatarInfo = nil
        self.blueCircleWidth = blueCircleWidth
        super.init(frame: .zero)
        avatarImageView.avatar.bt.setImage(URL(string: avatarImageURL), placeholder: placeholderImage)
        setup(avatarWidth: avatarWidth, showBgColor: showBgColor)
    }

    func setup(avatarWidth: CGFloat, showBgColor: Bool = true) {
        let totalWidth = avatarWidth + 2 * blueCircleWidth
        let blueBgView = UIView()
        if showBgColor {
            blueBgView.backgroundColor = UIColor.ud.primaryContentDefault
            blueBgView.clipsToBounds = true
            blueBgView.layer.cornerRadius = totalWidth / 2
        }

        addSubview(blueBgView)
        addSubview(avatarImageView)

        blueBgView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: totalWidth, height: totalWidth))
            make.center.equalToSuperview()
            make.edges.equalToSuperview()
        }
        avatarImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: avatarWidth, height: avatarWidth))
            make.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
