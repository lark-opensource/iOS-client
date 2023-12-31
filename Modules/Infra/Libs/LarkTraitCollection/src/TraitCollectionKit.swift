//
//  TraitCollectionKit.swift
//  LarkTraitCollection
//
//  Created by 李晨 on 2020/5/25.
//

import UIKit
import Foundation

/// 定制 traitCollection 工具类
public final class TraitCollectionKit {

    /// 通过 size 获取定制 traitCollection
    public static func customTraitCollection(
        _ traitCollection: UITraitCollection,
        _ size: CGSize
    ) -> UITraitCollection {
        if !RootTraitCollection.shared.useCustomSizeClass {
            return traitCollection
        }

        return CustomSizeClass.customHorizontalSizeClass(
            traitCollection: traitCollection,
            size: size
        )
    }
}
