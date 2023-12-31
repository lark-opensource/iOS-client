//
//  VideoImageView.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/30.
//

import UIKit
import Foundation
import LarkUIKit

public final class VideoImageView: BaseImageView {
    override public var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        self.contentMode = .scaleAspectFill
        // 如果图片大小为0的情况下，会返回占位大小100*100，这里再次修正下
        if size.width < videoMinSize.width, size.height < videoMinSize.height {
            return videoMinSize
        }
        return size
    }

    public override static func calculateSizeAndContentMode(originSize: CGSize, maxSize: CGSize, minSize: CGSize) -> (CGSize, UIView.ContentMode) {
        let (size, _) = super.calculateSizeAndContentMode(originSize: originSize, maxSize: maxSize, minSize: minSize)
        if size.width < videoMinSize.width, size.height < videoMinSize.height {
            return (videoMinSize, .scaleAspectFill)
        }
        return (size, .scaleAspectFill)
    }
}
