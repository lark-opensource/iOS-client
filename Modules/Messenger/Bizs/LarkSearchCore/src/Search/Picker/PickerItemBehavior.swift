//
//  PickerItemBehavior.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/11/22.
//

import Foundation
import LarkModel

/// Picker Item行为控制
public protocol PickerItemBehavior {
    /// item是否被置灰
    /// SearchOption: 返回的item类型
    /// return: true表示置灰
    var itemDisableBehavior: ((SearchOption) -> Bool)? { get set }

    /// 置灰的item被选中时, 弹出对应的Toast提示
    /// SearchOption: 返回的item类型
    /// return: 弹出的Toast文案, 为空时不弹出Toast
    var itemDisableSelectedToastBehavior: ((SearchOption) -> String?)? { get set }
}
