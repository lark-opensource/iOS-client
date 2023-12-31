//
//  UniversalCardImageUtils.swift
//  UniversalCardBase
//
//  Created by zhujingcheng on 11/8/23.
//

import Foundation
import RustPB

public final class UniversalCardImageUtils {
    public static func isLongImage(imageProperty: RustPB.Basic_V1_RichTextElement.ImageProperty?, disableLongImageTag: Bool = false, heightWidthRatioLimit: CGFloat) -> Bool {
        guard let imageProperty = imageProperty,
              !disableLongImageTag,
              imageProperty.originWidth > 0 && imageProperty.originHeight > 0 else {
            return false
        }
        // disableLongImageTag已迁址Lynx处理, 76-80行代码预期可以删除以改动最小原则暂时保留
        let curImageAspectRatio = CGFloat(imageProperty.originHeight) / CGFloat(imageProperty.originWidth)
        guard curImageAspectRatio > heightWidthRatioLimit else {
            return false
        }
        // 图片实际宽度小于60，不显示长图标签,详见https://bytedance.feishu.cn/wiki/wikcnQsu3G1mXZFPADOiIjjBHhf
        if imageProperty.hasCustomWidth && imageProperty.customWidth < 60 && imageProperty.customWidth > 0 {
            return false
        }
        return true
    }
    
    public static func cropImage(image: UIImage?, imageCropHeight: CGFloat) -> UIImage? {
        guard let image = image, imageCropHeight > 0 else {
            return nil
        }
        let toRect = CGRect(x: 0, y: 0, width: image.size.width, height: imageCropHeight)
        let rect = toRect.applying(CGAffineTransform(scaleX: image.scale, y: image.scale))
        if let croppedCgImage = image.cgImage?.cropping(to: rect)?.copy() {
            return UIImage(cgImage: croppedCgImage)
        } else if let ciImage = image.ciImage {
            let croppedCiImage = ciImage.cropped(to: rect)
            return UIImage(ciImage: croppedCiImage)
        }
        return nil
    }
}
