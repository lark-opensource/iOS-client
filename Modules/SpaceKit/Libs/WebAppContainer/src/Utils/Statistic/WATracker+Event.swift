//
//  WATracker+Event.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/30.
//

import Foundation

//埋点文档： https://bytedance.larkoffice.com/wiki/DuTqwZGm9iSLVLkCUmAcYkJTnDg
extension WATracker {
    // 事件名称
    public enum EvetentType: String {
        case openFinish = "webapp_open_finish_dev"
        case extractPackage = "webapp_extract_pkg_dev"
        case commonError = "webapp_common_error_dev"
    }
    
    // 上报key
    public enum ReportKey: String {
        case app_id
        case app_name
        case result
        case code
        case res_version
        case from
        case url_type
        case cost
        case preload_type
        case load_type
        case route_stage_cost
        case unzip_stage_start
        case unzip_stage_cost
        case preload_stage_start
        case preload_stage_cost
        case render_stage_start
        case render_stage_cost
        case duration_ms
        case is_success
        case error_type
        case errorMsg
        case costTime
    }
    
    // 后续的一些二级参数key可自行扩展
}

enum WATrackerCommonErrorType: Int {
    case requestInPreload = 1
}
