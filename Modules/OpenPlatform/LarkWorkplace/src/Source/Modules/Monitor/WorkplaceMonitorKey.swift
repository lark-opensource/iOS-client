//
//  WorkplaceMonitorKey.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/8.
//

import Foundation

/// 如果有多处埋点使用相同的 key，则应当收敛到此枚举处。
///
/// 注意: 因为所有的埋点都可能使用这个枚举，要特别注意命名和冲突，防止误用。
enum WorkplaceMonitorKey: String {
    case duration
    case http_code
    case error_code
    case error_msg
    case result_type

    case net_status
    case rust_status
    case portal_type

    case wp_message

    case id
    case request_id
    case log_id
    case portal_id
    case app_id

    case current_template_id
    case new_portal_type
    case origin_portal_type
    case new_portal_id
    case origin_portal_id

    case type
    case fail_from
    case error_from
    case error_type
    case trigger_from
    case change_type
    case server_error
    case is_retry

    case use_cache
    case has_cache
    case is_cached
    case cache_type

    case render_scene
    case components
    case portals_size

    /// 建议使用 timint() 或 duration，此字段目前数据链路有依赖，留作兼容
    case renderEnd
    /// 建议使用 error_msg
    case error_message
    
    case from
}
