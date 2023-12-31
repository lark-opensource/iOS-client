//
//  Utils.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/22.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import LarkFoundation
import LarkUIKit
import LarkCore

final class LarkChatUtils {
    /// 一行最多显示字符数
    static let maxCharCountAtOneLine: Int = 40
    /// pin 确认弹窗内容最大宽度
    static let pinAlertConfirmMaxWidth: CGFloat = (268.0 / 375.0) * min(UIScreen.main.bounds.width, 375)

    static var imageMaxSize: CGSize {
        let screen = UIScreen.main.bounds
        return CGSize(width: screen.width * 0.6, height: screen.width * 0.6)
    }
    static var imageMinSize: CGSize {
        return CGSize(width: 50, height: 50)
    }
    // UI展示的最小百分比
    // UI展示的最大百分比
}
