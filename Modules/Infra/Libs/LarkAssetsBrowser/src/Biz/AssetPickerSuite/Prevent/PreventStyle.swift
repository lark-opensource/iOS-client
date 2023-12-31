//
//  PreventStyle.swift
//  LarkAssetsBrowser
//
//  Created by xiongmin on 2021/4/29.
//

import Foundation

public enum PreventStyle {
    /// 不阻断
    case none
    /// 允许访问部分图片
    case limited
    /// 不允许访问图片
    case denied

    /// 允许部分图片访问则展示tips
    public func showTips() -> Bool {
        return self == .limited
    }
}
