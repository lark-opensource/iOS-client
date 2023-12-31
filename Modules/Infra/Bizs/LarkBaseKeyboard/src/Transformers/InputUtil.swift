//
//  InputUtil.swift
//  Pods
//
//  Created by lichen on 2018/8/2.
//

import UIKit
import Foundation
import LarkUIKit
import EditTextView

public final class InputUtil {

    /// 创建 RichRext element 随机 id
    ///
    /// - Returns: int32 id
    public static func randomId() -> Int32 {
        return Int32(arc4random() % 100_000_000)
    }

    /// https://www.jianshu.com/p/89ed22f50a9c
    public static func textAttachmentForImage(_ image: UIImage, font: UIFont) -> NSTextAttachment {
        let height = font.lineHeight
        let width = image.size.width / (image.size.height / height)
        let bounds = CGRect(x: 0, y: font.descender, width: width, height: height)
        let textAttachment = NSTextAttachment()
        textAttachment.image = image
        textAttachment.bounds = bounds
        return textAttachment
    }
}
