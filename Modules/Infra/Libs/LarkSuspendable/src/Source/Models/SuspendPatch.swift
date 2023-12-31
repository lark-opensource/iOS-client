//
//  SuspendPatch.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/22.
//

import UIKit
import LarkTab

/// 可暂存 ViewController 的信息，用于持久化和恢复页面
public struct SuspendPatch: Codable {

    /// 用于页面去重的唯一标识
    var id: String
    /// 用于区分来源的唯一标识
    var source: String
    /// 页面图标
    var icon: ImageWrapper?
    /// 页面图标链接
    var iconURL: String?
    /// 页面图标 key（ByteWebImage 需要）
    var iconKey: String?
    /// chatID 或者 chatterID（ByteWebImage 需要）
    var iconEntityID: String?
    /// 悬浮窗显示的名称
    var title: String
    /// Navigator 系统中的页面 baseURL
    var url: String
    /// 用于恢复该页面所必要的参数
    var params: [String: AnyCodable]
    /// 是否支持重复打开相同的页面
    var forcePush: Bool?
    /// 分组名
    var group: SuspendGroup
    /// 埋点类型名称
    var analytics: String
}

// MARK: Unwraping

extension SuspendPatch {

    /// 解包后的页面图标
    var displayIcon: UIImage {
        return icon?.image ??
            BundleResources.LarkSuspendable.icon_multitask_outlined.ud.withTintColor(UIColor.ud.iconN3)
    }

    /// 解包后的路由参数
    var untreatedParams: [String: Any] {
        var restoreParams: [String: Any] = [String: Any]()
        for (key, value) in params {
            restoreParams[key] = value.value
        }
        return restoreParams
    }
}
