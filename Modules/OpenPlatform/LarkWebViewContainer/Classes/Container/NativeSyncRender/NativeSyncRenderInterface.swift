//
//  NativeSyncRenderInterface.swift
//  LarkWebViewContainer
//
//  Created by wangjin on 2022/11/1.
//

import Foundation
import UIKit

/// 新同层渲染方案的渲染接口
@objc public protocol LarkWebNativeSyncRenderInterface {
    /// insert native view
    func insertComponentSync(view: UIView, atIndex index: String, existContainer: UIScrollView?, completion: ((Bool) -> Void)?)

    /// remove native view for index
    func removeComponentSync(index: String) -> Bool
}
