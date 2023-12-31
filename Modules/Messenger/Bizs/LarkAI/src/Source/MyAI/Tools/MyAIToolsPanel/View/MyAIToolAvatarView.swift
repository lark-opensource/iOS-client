//
//  MyAIToolAvatarView.swift
//  LarkAI
//
//  Created by ByteDance on 2023/6/8.
//
import UIKit
import Foundation
import LarkBizAvatar
import ByteWebImage

final class MyAIToolAvatarView: BizAvatar {
    func setAvatarBy(by identifier: String, avatarKey: String) {
        let completion: (UIImage?, ImageRequestResult) -> Void = { [weak self] placeholder, result in
            guard let self = self else { return }
            switch result {
            case .success(let imageResult):
                guard let image = imageResult.image else { return }
                self.image = image
                self.avatar.backgroundColor = UIColor.clear
            case .failure(let error):
                if placeholder != nil { return }
                self.image = placeholder
                MyAIToolsViewController.logger.error("load avatar failed id=\(identifier)&key=\(avatarKey)&error=\(error.localizedDescription)")
            }
        }
        let placeholder: UIImage? = Resources.imageDownloadFailed
        self.setAvatarByIdentifier(identifier, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(36))) { imageResult in
            completion(placeholder, imageResult)
        }
    }

    func setAvatar(image: UIImage?) {
        self.image = image
    }

    func setMaskView() {
        self.avatar.ud.setMaskView()
    }
}
