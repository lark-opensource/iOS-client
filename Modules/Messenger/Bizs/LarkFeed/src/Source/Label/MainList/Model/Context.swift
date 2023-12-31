//
//  LabelMainListContext.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation

// TODO:
/** LabelMainListContext的设计：提供全局视角的数据，并可以被传递到任何地方
1. 提供全局视角的关键数据：vc和vm
2. 提供方便获取的方式，并可以让任何类 强持有
*/

final class LabelMainListContext {

    weak var vc: LabelMainListViewController?

    init() {}
}
