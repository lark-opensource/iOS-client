//
//  UDToast+DefaultLoadingText.swift
//  LarkCore
//
//  Created by 孔凯凯 on 2021/6/1.
//

import UIKit
import Foundation
import UniverseDesignToast

extension UDToast {
    /// 为了兼容旧的RoundedHUD接口实现批量替换
    /// - Parameters:
    ///   - view: 用来显示Toast的View
    ///   - disableUserInteraction: 是否拦截用户其他操作，RoundedHUD默认为 true，所以这里也默认为 true
    /// - Returns: Toast
    @discardableResult
    public class func showLoading(
        on view: UIView,
        disableUserInteraction: Bool? = true
    ) -> UDToast {
        Self.showLoading(
            with: BundleI18n.LarkCore.Lark_Legacy_BaseUiLoading,
            on: view,
            disableUserInteraction: disableUserInteraction
        )
    }
}
