//
//  KeyCommand+Util.swift
//  LarkKeyCommandKit
//
//  Created by 李晨 on 2020/2/5.
//

import UIKit
import Foundation

/// https://stackoverflow.com/questions/41731442/stop-uikeycommand-repeated-actions
/// 避免快捷键长按，无限响应
extension UIKeyCommand {
    var nonRepeating: UIKeyCommand {
        let repeatableConstant = "repeatable"
        if self.responds(to: Selector(repeatableConstant)) {
            self.setValue(false, forKey: repeatableConstant)
        }
        return self
    }
}
