//
//  IMMentionAvatarView.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/21.
//

import Foundation
import UIKit
import UniverseDesignIcon
#if canImport(LarkBizAvatar)
import LarkBizAvatar

final class IMMentionAvatarView: BizAvatar {
    func setAvatarBy(by identifier: String, avatarKey: String) {
        self.setAvatarByIdentifier(identifier, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(36))) {
            if case .failure(let error) = $0 {
                IMMentionLogger.shared.error(module: .view, event: "load avatar failed", parameters: "id=\(identifier)&key=\(avatarKey)&error=\(error.localizedDescription)")
            }
        }
    }
    
    func setAvatar(image: UIImage?) {
        self.image = image
    }
    
    func setMaskView() {
        self.avatar.ud.setMaskView()
    }
}
#else
class IMMentionAvatarView: UIImageView {
    func setAvatarBy(by identifier: String, avatarKey: String) {
        self.backgroundColor = .red
    }
    func setAvatar(image: UIImage?) {
        self.image = image
        self.backgroundColor = .blue
    }
    func setMaskView() {
        self.ud.setMaskView()
    }
    
}
#endif
