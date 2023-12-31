//
//  RedPacketCommonAvatar.swift
//  LarkFinance
//
//  Created by bytedance on 2021/12/21.
//

import Foundation
import UIKit
import LarkBizAvatar
import SnapKit
import LarkUIKit
import ByteWebImage
import RustPB
import LKCommonsLogging
/// 由于发送人可能是企业，也可能是个人 所以需要不同的加载方式
enum RedPacketAvatarType {
    case user(identifier: String, avatarKey: String, avatarViewParams: AvatarViewParams)
    case company(passThrough: ImagePassThrough)
}

final class RedPacketCommonAvatar: UIView {

    private static let logger = Logger.log(RedPacketCommonAvatar.self, category: "RedPacketCommonAvatar")

    let avatarView = BizAvatar()

    lazy var iconImageView: ByteImageView = {
        let imageView = ByteImageView()
        imageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    var avatarType: RedPacketAvatarType? {
        didSet {
            updateUI()
        }
    }

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        addSubview(avatarView)
        addSubview(iconImageView)
        avatarView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        avatarView.isHidden = true
        iconImageView.isHidden = true
    }

    func updateUI() {
        guard let type = self.avatarType else {
            avatarView.isHidden = true
            iconImageView.isHidden = true
            return
        }
        /// 这里设置头像的时候，清空一下其他头像，取消不需要展示头像的加载(cell复用中出现)
        switch type {
        case .user(let identifier, let avatarKey, let avatarViewParams):
            avatarView.isHidden = false
            iconImageView.isHidden = true
            avatarView.setAvatarByIdentifier(identifier,
                                             avatarKey: avatarKey,
                                             avatarViewParams: avatarViewParams)
            iconImageView.bt.setLarkImage(with: .default(key: ""))
        case .company(let passThrough):
            avatarView.isHidden = true
            iconImageView.isHidden = false
            avatarView.setAvatarByIdentifier("", avatarKey: "")
            iconImageView.bt.setLarkImage(with: .default(key: passThrough.key ?? ""),
                                          passThrough: passThrough,
                                          completion: { result in
                switch result {
                case .failure(let error):
                    Self.logger.error("company logo loaded fail", error: error)
                default:
                    break
                }
             })
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if iconImageView.bounds.width > 0,
           iconImageView.layer.cornerRadius != iconImageView.bounds.width / 2.0 {
            iconImageView.layer.cornerRadius = iconImageView.bounds.width / 2
        }
    }
}
