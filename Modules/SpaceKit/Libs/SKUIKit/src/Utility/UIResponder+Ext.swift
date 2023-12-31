//
//  File.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/11/6.
//

import Foundation
import UIKit

private weak var docsFirstResponderObj: AnyObject?

extension UIResponder {

    public static func docsFirstResponder() -> AnyObject? {
        docsFirstResponderObj = nil
        // 通过将target设置为nil，让系统自动遍历响应链
        // 从而响应链当前第一响应者响应我们自定义的方法
        UIApplication.shared.sendAction(#selector(docsFindFirstResponder(_:)), to: nil, from: nil, for: nil)
        return docsFirstResponderObj
    }

    @objc
    func docsFindFirstResponder(_ sender: AnyObject) {
        // 第一响应者会响应这个方法，并且将静态变量currentFirstResponder设置为自己
        docsFirstResponderObj = self
    }
}
