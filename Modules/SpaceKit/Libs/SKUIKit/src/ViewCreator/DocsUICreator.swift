//
//  DocsUICreator.swift
//  AlamofirePr
//
//  Created by litao_dev on 2019/7/2.
//  Copyright © 2019 panyult. All rights reserved.

import UIKit
import SKFoundation
import EENavigator

extension UIView: DocsExtensionCompatible {}

// MARK: - UIImage Creator
extension DocsExtension where BaseType == UIImage {
    public class func create(by color: UIColor, size: CGSize? = nil) -> UIImage? {

        var rect: CGRect
        if let sizeLo = size {
            rect = CGRect(x: 0, y: 0, width: sizeLo.width, height: sizeLo.height)
        } else {
            let width = Navigator.shared.mainSceneWindow?.bounds.width ?? 375
            rect = CGRect(x: 0, y: 0, width: width, height: width / 2.0)
        }

        UIGraphicsBeginImageContext(rect.size)

        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return image
    }
}

extension DocsExtension where BaseType == UIFont {
    public class func createDefaultFont(size: CGFloat) -> UIFont? {
        return UIFont.systemFont(ofSize: size)
    }
}
