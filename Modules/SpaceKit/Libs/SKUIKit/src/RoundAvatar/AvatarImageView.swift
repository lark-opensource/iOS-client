//
//  AvatarImageView.swift
//  Lark
//
//  Created by 齐鸿烨 on 2016/12/27.
//  Copyright © 2016年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import ByteWebImage
import UniverseDesignAvatar

/// 请使用SKAvatar来显示头像
open class AvatarImageView: LastingColorView {
    
    public private(set) lazy var imageView: UIImageView = {
        let configuration = UDAvatar.Configuration(placeholder: nil,
                                                   backgroundColor: nil,
                                                   style: .circle,
                                                   contentMode: .scaleAspectFit)
        let imageView = SKAvatar(configuration: configuration)
        imageView.image = nil
        return imageView
    }()

    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        backgroundColor = UIColor.ud.N300
        lastingColor = UIColor.ud.N50
        addSubview(imageView)
        clipsToBounds = true
        imageView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalTo(self)
        }
    }

    open func set(avatarKey: String = "",
                  fsUnit: String? = nil,
                  placeholder: UIImage? = nil,
                  image: UIImage? = nil,
                  completion: ByteWebImage.ImageRequestCompletion? = nil) {
        guard !avatarKey.isEmpty else {
            imageView.image = image
            return
        }
        var fixedKey = avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
        fixedKey = fixedKey.replacingOccurrences(of: "mosaic-legacy/", with: "")
        imageView.bt.setLarkImage(with: .avatar(key: fixedKey, entityID: ""),
                                  placeholder: placeholder,
                                  completion: completion)
    }
    
    open func cancelImageRequest() {
        imageView.bt.cancelImageRequest()
    }
}
