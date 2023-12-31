//
//  WPCacheKey.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/3/7.
//

import Foundation
import LarkStorage

/// 工作台缓存 key 定义
///
/// 规范:
/// 1. 接入 LarkStorage 后工作台所有的缓存相关的 key 收敛到此处。
/// 2. key 已经经过 LarkStorage space 和 domain 隔离，不需要再自己加前缀了，一般直接带有业务语义即可。
/// 3. 建议 key 的命名方式：小写字母 + 下划线 + 数字，数字不能在首位。
/// 4. 每个 key 必须明确通过注释说明其含义，并明确说明其 value 所对应的数据类型。
///
/// 维度:
/// 1. 缓存 key 需要区分维度，目前默认含有 user 维度，在此基础上定义 key。
/// 2. 常用维度: WPCacheKey namespace 下面认为是 user 维度，门户无关的缓存 key 定义在此。比如：门户列表 last_portal_list
/// 3. 常用维度: WPCacheKey.Portal namespace 下面认为是某个门户维度，门户相关的缓存 key 定义在此。比如：门户 schema
/// 4. 不常用维度: WPCacheKey.Global namespace 下面认为是应用全局维度，存储一些与业务无关的数据。
///
/// Domain:
/// LarkStorage 定义了 Domain 的概念，其中工作台场景默认的 Domain 已经预注册，即: Domain.biz.workplace
/// 业务开发时必须使用此 Domain，如果要基于工作台 Domain 划分更细维度，则应在其上注册子 Domain。
/// 比如：门户维度可以根据门户 id 注册，即：Domain.biz.workplace.child(template.id)
///
/// WPCacheKey 默认认为是 user 维度数据。
enum WPCacheKey {
    /// 上次使用门户 id, value: String
    static let lastPortalId = "last_portal_id"
    /// 上次使用的门户 类型, value: String（WPPortalTemplate.tplType)
    static let lastPortalType = "last_port_type"
    /// 上次使用的门户列表, value: WPPortalTemplate
    static let lastPortalList = "last_portal_list"
    /// 原生工作台门户组件
    static var nativePortalModule: String { "\(WorkplaceTool.curLanguage())_native_portal_module" }
    /// 导航栏应用商店配置
    static var workplaceSettings: String { "\(WorkplaceTool.curLanguage())_workplace_settings" }
    /// 常用应用列表
    static var favoriteApps: String { "\(WorkplaceTool.curLanguage())_favorite_apps" }
    /// “添加常用”页面应用列表
    static var categoryPage: String { "\(WorkplaceTool.curLanguage())_category_page" }
    /// Widget 数据
    static let widgetModel: String = "widget_model"
    
    /// 上次组件预加载时间戳
    static let lastPreloadWidgetTimestamp: String = "last_preload_widget_timestamp"

    /// 运营弹窗是否被确认过
    static func operationDialogMgrAck(notificationId: String) -> String {
        return "operation_dialog_mgr_ack_\(notificationId)"
    }

    /// Block 高度
    static func blockHeightLynx(blockId: String) -> String {
        return "block_height_lynx_\(blockId)"
    }

    /// Block 预览设置页，用户自定义配置
    static func blockPreviewSettings(blockTypeId: String) -> String {
        return "block_preview_settings_\(blockTypeId)"
    }

    /// App 全局维度数据
    enum Global {

    }

    /// 门户维度数据
    enum Portal {
        /// 门户 schema 数据，value: SchemaModel
        static let schema = "schema"
        /// 门户组件数据，value: [ComponentModule]
        static let components = "components" 
    }
}
