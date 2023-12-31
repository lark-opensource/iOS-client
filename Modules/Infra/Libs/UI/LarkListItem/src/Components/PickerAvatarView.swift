//
//  PickerAvatarView.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/11/11.
//

import Foundation
import UIKit
import UniverseDesignIcon
#if canImport(LarkBizAvatar)
import LarkBizAvatar
import AvatarComponent
import ByteWebImage
import AppReciableSDK

final public class PickerAvatarView: UIView {
    private var imageView: LarkMedalAvatar
    public var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    override init(frame: CGRect) {
        imageView = LarkMedalAvatar(frame: frame)
        super.init(frame: frame)
        addSubview(imageView)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }

    var style: PickerAvatarViewStyle = .circle {
        didSet {
            var config = AvatarComponentUIConfig()
            config.style = style == .circle ? .circle : .square
            imageView.setAvatarUIConfig(config)
        }
    }

    public func setAvatarByIdentifier(_ identifier: String, avatarKey: String, markScene: Bool? = nil, avatarSize: CGFloat) {
        if let markScene = markScene, markScene {
            imageView.setAvatarByIdentifier(identifier, avatarKey: avatarKey, scene: .Search, avatarViewParams: .init(sizeType: .size(avatarSize)))
        } else {
            imageView.setAvatarByIdentifier(identifier, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        }
    }

    public func setAvatarByImageURL(_ imageURL: URL?) {
        if let imageURL {
            imageView.avatar.bt.setImage(imageURL)
        } else {
            imageView.image = nil
        }
    }
}
#else
public class PickerAvatarView: UIImageView {
    public func setAvatarByIdentifier(_ identifier: String, avatarKey: String, markScene: Bool? = nil, avatarSize: CGFloat) {
        self.backgroundColor = .lightGray
    }
    var style: PickerAvatarViewStyle = .circle

    public func setAvatarByImageURL(_ imageURL: URL?) {
        self.backgroundColor = .lightGray
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = bounds.width / 2
    }
}
#endif

enum PickerAvatarViewStyle {
    case circle
    case square
}
