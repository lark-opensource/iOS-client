//
//  AvatarImageView.swift
//  LarkAvatar
//
//  Created by 袁平 on 2020/4/26.
//

import Foundation
import UIKit
import LarkUIKit
// import Kingfisher
import ByteWebImage

open class AvatarImageView: LastingColorView {

    lazy private(set) var imageView: UIImageView = {
        var imageView = UIImageView(image: nil)
        imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        self.backgroundColor = UIColor.ud.N300
        self.lastingColor = UIColor.ud.N50
        self.addSubview(self.imageView)
        self.clipsToBounds = true
        self.imageView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalTo(self)
        }
    }

    public func setContentMode(contentMode: UIView.ContentMode) {
        self.imageView.contentMode = contentMode
    }

    public func set(entityId: String = "",
                  avatarKey: String = "",
                  placeholder: UIImage? = nil,
                  image: UIImage? = nil,
                  completion: ImageRequestCompletion? = nil) {
        guard !avatarKey.isEmpty else {
            self.imageView.image = image
            return
        }
        // TODO: 部分接口返回中rust没有处理好avatarKey,此处做容错，待rust修正后去除
        var fixedKey = avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
        fixedKey = fixedKey.replacingOccurrences(of: "mosaic-legacy/", with: "")
        self.imageView.bt.setLarkImage(with: .avatar(key: fixedKey,
                                                     entityID: entityId),
                                       placeholder: placeholder,
                                       trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .avatar)
                                       },
                                       completion: completion)
    }
}
