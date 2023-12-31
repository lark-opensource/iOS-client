//
//  WikiFeatureGate.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/10/8.
//  

import UIKit
import SwiftyJSON
import SKFoundation

public struct WikiFeatureGate {
    /// 最近列表预加载数量
    public static var preloadCount: Int {
        return 10
    }

    /// 是否仅在wifi环境下进行预加载
    public static var preloadWifiOnly: Bool {
        return false
    }

    /// 最近列表滚动时预加载数量
    public static var listScrollPreloadCount: Int {
        return 10
    }

    public static var preloadDelay: Int? {
        if ListConfig.needDelayLoadDB {
            return nil // 延迟到wiki首页展示的时候再加载数据库
        }
        return 30
    }
}
