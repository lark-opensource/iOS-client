//
//  UIImageView+Extension.swift
//  TangramService
//
//  Created by 袁平 on 2022/1/26.
//

import UIKit
import Foundation
import UniverseDesignColor

extension UIImageView {
    public func setImage(_ image: UIImage?,
                         tintColor: UIColor?,
                         completion: ((UIImage?) -> Void)? = nil) {
        guard let tintColor = tintColor else {
            self.image = image
            completion?(image)
            return
        }
        // AttributeString里的Attachment场景下：
        // 使用下面的方式设置Image，在Lark设置与系统设置相反（如Lark LM，系统DM或Lark DM，系统LM）时会有问题，
        // 偶现LM下取到DM图片（或DM下取到LM图片），暂时没查出为啥不生效（尝试过修改UITraitCollection.current也会有问题）
//        if #available(iOS 13.0, *) {
//            let traitCollection = UITraitCollection(userInterfaceStyle: UDThemeManager.userInterfaceStyle)
//            traitCollection.performAsCurrent {
//                let image = image.ud.withTintColor(tintColor, renderingMode: renderingMode)
//                self.image = image
//                completion?(image)
//            }
//        }

        // 通过下面方式设置染色会有问题，见：
        // https://meego.feishu.cn/larksuite/issue/detail/14060036
//        self.tintColor = tintColor
//        self.image = image?.withRenderingMode(.alwaysTemplate)

        self.tintColor = tintColor
        self.image = image?.ud.withTintColor(tintColor)
        completion?(self.image)
    }
}
