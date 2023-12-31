//
//  OpenRedPacketAvatarView.swift
//  Pods
//
//  Created by ChalrieSu on 2018/10/22.
//

import Foundation
import UIKit
import LarkCore
import LarkUIKit
import LarkBizAvatar

final class OpenRedPacketAvatarView: UIView {
    let avatarView = RedPacketCommonAvatar()

    init(backgroundImage: UIImage? = nil) {
        super.init(frame: .zero)
        clipsToBounds = true
        addSubview(avatarView)
        avatarView.clipsToBounds = true
        avatarView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(avatarInset)
        }
        if let backgroundImage = backgroundImage {
            let imageView = UIImageView()
            imageView.image = backgroundImage
            addSubview(imageView)
            imageView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    var avatarInset: CGFloat = 0 {
        didSet {
            avatarView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(avatarInset)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        avatarView.layer.masksToBounds = true
    }
}
