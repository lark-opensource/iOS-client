//
//  UIBarButtonItemFactory.swift
//  ByteView
//
//  Created by chentao on 2019/11/15.
//

import Foundation

public final class UIBarButtonItemFactory {

    public static func create(normalImage: UIImage?, highlightImage: UIImage? = nil,
                              target: Any?, action: Selector) -> UIBarButtonItem {
        let button = UIButton()
        button.setImage(normalImage, for: .normal)
        button.setImage(highlightImage, for: .highlighted)
        button.addTarget(target, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }

    public static func create(customView: UIView, size: CGSize? = nil) -> UIBarButtonItem {
        if let size = size {
            let frame = CGRect(origin: .zero, size: size)
            let wrapperView = UIView(frame: frame)
            wrapperView.addSubview(customView)
            customView.frame = wrapperView.bounds
            customView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return UIBarButtonItem(customView: wrapperView)
        } else {
            return UIBarButtonItem(customView: customView)
        }
    }
}
