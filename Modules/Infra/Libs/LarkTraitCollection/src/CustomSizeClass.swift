//
//  CustomSizeClass.swift
//  LarkTraitCollection
//
//  Created by 李晨 on 2020/5/25.
//

import UIKit
import Foundation

final class CustomSizeClass {
    class func customHorizontalSizeClass(view: UIView) -> UITraitCollection {
        return CustomSizeClass.customHorizontalSizeClass(
            traitCollection: view.traitCollection,
            size: view.bounds.size
        )
    }

    class func customHorizontalSizeClass(traitCollection: UITraitCollection, size: CGSize) -> UITraitCollection {

        if UIDevice.current.userInterfaceIdiom != .pad {
            return traitCollection
        }

        if traitCollection.horizontalSizeClass == .compact {
            return traitCollection
        }

        var horizontalSizeClass: UIUserInterfaceSizeClass = .compact
        /// 目前按照产品给出的规则，678 是 12.9 寸半屏宽度，大于这个宽度的 view 才算是 regular sizeClass
        /// TODO: 这里在之后版本可以优化算法
        if size.width > 678 {
            horizontalSizeClass = .regular
        }
        let customTrait = UITraitCollection(
            horizontalSizeClass: horizontalSizeClass
        )
        return UITraitCollection(traitsFrom: [traitCollection, customTrait])
    }
}
