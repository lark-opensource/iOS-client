//
//  UIImageView+Associate.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/24.
//

import Foundation

private enum AssociativeKey {

    static var enableDownsample = "AssociativeKey.EnableDownsample"

    static var imageRequest = "AssociativeKey.ImageRequest"
}

extension ImageWrapper where Base: UIImageView {

//    /// 启用降采样功能
//    public var enableDownsample: Bool {
//        get {
//            objc_getAssociatedObject(base, &AssociativeKey.enableDownsample) as? Bool ?? false
//        }
//        set {
//            objc_setAssociatedObject(base, &AssociativeKey.enableDownsample, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }

    /// 图像请求
    internal var imageRequest: ImageRequest? {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.imageRequest) as? ImageRequest
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.imageRequest, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
