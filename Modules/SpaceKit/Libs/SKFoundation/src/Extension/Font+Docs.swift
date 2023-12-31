//
//  Font+Docs.swift
//  DocsCommon
//
//  Created by weidong fu on 25/11/2017.
//

import Foundation
extension UIFont: DocsExtensionCompatible {}

public extension DocsExtension where BaseType: UIFont {
    class func pfsc(_ fontSize: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.regular)
    }
}
