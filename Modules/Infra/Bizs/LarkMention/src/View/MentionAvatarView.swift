//
//  MentionAvatarView.swift
//  LarkMention
//
//  Created by Yuri on 2022/5/31.
//

import Foundation
import UIKit
import UniverseDesignIcon
#if canImport(LarkBizAvatar)
import LarkBizAvatar

final class MentionAvatarView: BizAvatar {
    func setAvatarBy(by identifier: String, avatarKey: String) {
        self.setAvatarByIdentifier(identifier, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(36)))
    }
    
    func setAvatarImage(image: UIImage) {
        self.image = image
    }
}
#else
class MentionAvatarView: UIImageView {
    func setAvatarBy(by identifier: String, avatarKey: String) {
        self.backgroundColor = .lightGray
    }
    func setAvatarImage(image: UIImage) {
        self.image = image
    }
    
}
#endif
