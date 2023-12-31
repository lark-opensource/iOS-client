//
//  UIViewExtensions.swift
//  ByteViewUI
//
//  Created by kiri on 2023/5/19.
//

import Foundation
import ByteViewCommon

extension VCExtension where BaseType: UIView {
    public func setSquircleMask(cornerRadius: CGFloat, rect: CGRect) {
        UIDependencyManager.dependency?.setSquircleMask(for: base, cornerRadius: cornerRadius, rect: rect)
    }

    public var displayScale: CGFloat {
        base.traitCollection.displayScale > 0 ? base.traitCollection.displayScale : 1.0
    }
}

extension VCExtension where BaseType: UIImageView {
    /// 普通图片，支持 Rust image key (不带协议头默认为此) & http(s):// & file:// & data(base64) url
    @discardableResult
    public func setImage(url: String, accessToken: String, placeholder: UIImage? = nil,
                         completion: ((Result<UIImage?, Error>) -> Void)? = nil) -> ImageRequest? {
        UIDependencyManager.dependency?.setImage(for: base, resource: .url(url, accessToken: accessToken), placeholder: placeholder, completion: completion)
    }

    /// reaction
    @discardableResult
    public func setReaction(_ key: String, placeholder: UIImage? = nil,
                            completion: ((Result<UIImage?, Error>) -> Void)? = nil) -> ImageRequest? {
        UIDependencyManager.dependency?.setImage(for: base, resource: .reaction(key), placeholder: placeholder, completion: completion)
    }

    /// 表情分栏icon
    @discardableResult
    public func setEmojiSectionIcon(_ key: String, placeholder: UIImage? = nil,
                                    completion: ((Result<UIImage?, Error>) -> Void)? = nil) -> ImageRequest? {
        UIDependencyManager.dependency?.setImage(for: base, resource: .emojiSectionIcon(key), placeholder: placeholder, completion: completion)
    }
}

public extension VCExtension where BaseType: UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        base.setBackgroundImage(UIImage.vc.fromColor(color), for: state)
    }
}
