//
//  Camera.swift
//  LarkCore
//
//  Created by 王元洵 on 2021/6/16.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkFeatureGating
import UIKit
import LarkUIKit
import LarkContainer

/// 拍照页面相关埋点
public extension PublicTracker {
    struct Camera {}
}

/// 拍照相关页面的展示
public extension PublicTracker.Camera {
    /// 开始拍照
    static func view() {
        // 新版本相机在组件内部埋点
        let userResolver = Container.shared.getCurrentUserResolver()
        if !userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.mobile.ve_camera")) {
            Tracker.post(TeaEvent(Homeric.PUBLIC_PHOTOGRAPH_VIEW, userID: userResolver.userID))
        }
    }
}

/// 拍照相关页面的动作事件
public extension PublicTracker.Camera {
    struct Click {
        /// 拍照页面点击事件
        public static func takePhoto() {
            let params: [AnyHashable: Any] = ["click": "photograph", "target": "none"]
            Tracker.post(TeaEvent(Homeric.PUBLIC_PHOTOGRAPH_CLICK, params: params))
        }
    }
}
