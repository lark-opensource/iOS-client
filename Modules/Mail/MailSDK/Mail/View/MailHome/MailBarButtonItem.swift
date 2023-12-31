//
//  MailBarButtonItem.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2019/10/28.
//

import UIKit

class MailBarButtonItem: UIBarButtonItem {
    convenience init?(image: UIImage?, target: Any?, action: Selector) {

        let button = UIButton(type: .custom)
        let normalImage = image?.withRenderingMode(.alwaysTemplate)
        button.setBackgroundImage(normalImage, for: .normal)

        let highlightedImage = UIImage.lu.fromColor(UIColor.ud.textTitle)
        button.setBackgroundImage(highlightedImage, for: .highlighted)
        button.setBackgroundImage(highlightedImage, for: .selected)

        button.addTarget(target, action: action, for: .touchUpInside)
        button.bounds.size = button.currentBackgroundImage?.size ?? CGSize(width: 24, height: 24)
        self.init(customView: button)

    }
}
