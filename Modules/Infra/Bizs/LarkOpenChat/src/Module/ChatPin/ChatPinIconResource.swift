//
//  ChatPinIconResource.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import RustPB
import RxSwift
import RxCocoa
import ByteWebImage

// 图片资源
public enum ChatPinIconResource {
    case image(Observable<UIImage>)
    case resource(resource: LarkImageResource, config: ImageConfig?)

    public struct ImageConfig {
        public let tintColor: UIColor?
        public let placeholder: UIImage?
        public let imageSetPassThrough: RustPB.Basic_V1_ImageSetPassThrough?
        public init(tintColor: UIColor?, placeholder: UIImage?, imageSetPassThrough: RustPB.Basic_V1_ImageSetPassThrough? = nil) {
            self.tintColor = tintColor
            self.placeholder = placeholder
            self.imageSetPassThrough = imageSetPassThrough
        }
    }
}

public struct ChatPinIconConfig {
    public let iconResource: ChatPinIconResource
    public let size: CGSize
    public let cornerRadius: CGFloat
    public init(iconResource: ChatPinIconResource, size: CGSize = CGSize(width: 20, height: 20), cornerRadius: CGFloat = 0) {
        self.iconResource = iconResource
        self.size = size
        self.cornerRadius = cornerRadius
    }
}
