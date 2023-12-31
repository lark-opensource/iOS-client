//
//  UITableViewCell+Lark.swift
//  Lark
//
//  Created by 齐鸿烨 on 2017/3/9.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkCompatible

public extension LarkUIKitExtension where BaseType: UITableViewCell {
    static var reuseIdentifier: String {
        return String(describing: BaseType.self)
    }
}
