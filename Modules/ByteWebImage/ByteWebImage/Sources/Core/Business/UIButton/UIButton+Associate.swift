//
//  UIButton+Associate.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/8.
//

import Foundation

private enum AssociativeKey {

    static var enableDownsample = "AssociativeKey.EnableDownsample"

    static var imageSetter = "AssociativeKey.ImageSetter"
}

extension ImageWrapper where Base: UIButton {

    /// 启用降采样功能
    public var enableDownsample: Bool {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.enableDownsample) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.enableDownsample, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 图像请求
    internal var imageSetter: ButtonImageSetter? {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.imageSetter) as? ButtonImageSetter
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.imageSetter, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
