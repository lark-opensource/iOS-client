//
//  UDIcon+Deprecated.swift
//  UniverseDesignIcon
//
//  Created by Weston Wu on 2021/6/17.
//

/*
import Foundation
import UIKit

extension UIImage {

    /// 重设图片大小
    @available(*, deprecated, renamed: "ud.resized(to:)")
    public func repaint(reSize: CGSize) -> UIImage {
        if self.size == reSize { return self }
        //UIGraphicsBeginImageContext(reSize);
        UIGraphicsBeginImageContextWithOptions(reSize,
                                               false,
                                               UIScreen.main.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: reSize.width, height: reSize.height))
        let reSizeImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return reSizeImage
    }

    /// 等比率缩放
    @available(*, deprecated, renamed: "ud.scaled(by:)")
    public func scaleImage(scaleSize: CGFloat) -> UIImage {
        let reSize = CGSize(width: self.size.width * scaleSize,
                            height: self.size.height * scaleSize)
        return repaint(reSize: reSize)
    }
}

public extension UDIcon {
    
    @available(*, deprecated, renamed: "closeOutlined")
    class var noticeClose: UIImage {
        return closeOutlined
    }

    @available(*, deprecated, renamed: "infoColorful")
    class var noticeInfo: UIImage {
        return infoColorful
    }

    @available(*, deprecated, renamed: "rightOutlined")
    class var noticeAccessory: UIImage {
        return rightOutlined
    }

    @available(*, deprecated, renamed: "succeedColorful")
    class var noticeSuccess: UIImage {
        return succeedColorful
    }

    @available(*, deprecated, renamed: "warningColorful")
    class var noticeWarning: UIImage {
        return warningColorful
    }

    @available(*, deprecated, renamed: "errorColorful")
    class var noticeError: UIImage {
        return errorColorful
    }
}

public extension UDIconType {

    @available(*, deprecated, renamed: "closeOutlined")
    static var noticeClose: Self { .closeOutlined }

    @available(*, deprecated, renamed: "infoColorful")
    static var noticeInfo: Self { .infoColorful }

    @available(*, deprecated, renamed: "rightOutlined")
    static var noticeAccessory: Self { .rightOutlined }

    @available(*, deprecated, renamed: "succeedColorful")
    static var noticeSuccess: Self { .succeedColorful }

    @available(*, deprecated, renamed: "warningColorful")
    static var noticeWarning: Self { .warningColorful }

    @available(*, deprecated, renamed: "errorColorful")
    static var noticeError: Self { .errorColorful }
}
 */
