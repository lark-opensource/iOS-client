//
//  WorkplaceTrackEventKey.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/10.
//

import Foundation

/// 如果有多处埋点使用相同的 key，则应当收敛到此枚举处。
///
/// 注意: 因为所有的埋点都可能使用这个枚举，要特别注意命名和冲突，防止误用。
///
/// 最佳实践：
/// * 我们认为 key 需要做到尽可能的复用，除非有特殊情况，否则枚举命名应当和原始字段严格一致，不要使用别名。
/// * 此处的 key 不一定含有特定场景的业务语义，可能在多个场景服用，如 type。
/// * 对于特定场景业务语义的，可以单独在 WorkplaceTrackable+Biz 封装语义化用法 + WorkplaceTrackEventValue 中定义明确的 value 类型。
/// * 一般情况下对于在多处使用且 Value 为枚举类型的，建议在 WorkplaceTrackeEventValue 定义，Value 为值类型的，可直接通过 `setValue(_:for:)` 设置。
/// * 推荐尽可能将埋点相关 KV 定义为强类型字段。
enum WorkplaceTrackEventKey: String {
    /// target 目标页面，可使用 setTargetView 设置。
    case target
    /// 点击对象，可使用 setClickValue 设置。
    case click
    /// 渲染事件
    case view

    /// 指代某种类型，可使用 setExposeUIType / setFavoriteDragType 等设置。
    case type
    /// 组件类型，可使用 setSubType 设置。
    case sub_type
    ///
    case my_common_type
    /// 移除类型，可使用 setFavoriteRemoveType 设置。
    case remove_type

    /// 组件 menu 类型，可使用 setMenuType 设置。
    case menu_type
    /// 宿主类型，可使用 setHost 设置。
    case host
    /// 设置常用组件状态，可使用 setFavoriteStatus 设置。
    case status
    /// 设置门户类型，可使用 setUpdateType 设置
    case update_type

    case version
    case if_my_common
    case duration
    case is_success
    case app_area

    /// 各种 id
    case template_id
    case chat_id
    case item_id
    case app_id
    case block_id
    case block_type_id
    case appids
    case application_id
    case operation_id
    
    /// 菜单页展示时是否有「添加到应用」这个按钮的存在
    case has_add_to_navigation

    /// 这个 appid 看起来只有个别地方使用，怀疑是历史笔误，建议优先使用 app_id
    case appid
    /// 应用所属模块
    /// "application_list：应用列表
    /// my_common：我的常用（含最近使用）
    /// all_applications：全部应用
    /// customized_group：自定义分组"
    case module
    case app_name
}
