//
//  BTStatisticDefine.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/8/28.
//

import Foundation

struct BTStatisticDebug {
    static let debug = false
    static let logTempPoint = false
}

struct BTStatisticConstant {
    static let fpsMaxCount = 65
    static let dropMaxCount = 30
    static let dropCallbackInterval = 3

    static let tag = "BitableStatistic"

    static let viewType = "view_type"
    static let blockType = "block_type"
    static let openType = "open_type"
    static let subViewType = "sub_view_type"
    static let traceId = "trace_id"
    static let isFormV2 = "isFormV2"
    static let parentTraceId = "parent_trace_id"
    static let time = "time"
    static let stage = "stage"
    static let result = "result"
    static let reason = "reason"
    static let isBitableReady = "is_bitable_ready"
    static let fieldUIType = "field_ui_type"
    static let costTime = "cost_time"
    static let tableType = "table_type"

    static let costTimeList = "cost_time_list"
    static let countList = "count_list"

    static let mainStageTimestampKey = "main_stage_timestamp_list"
    static let mainStageDurationKey = "main_stage_duration_list"

    static let FG = "fg"
    static let fileId = "file_id"
    static let pointName = "point_name"
    static let pointType = "point_type"
    static let recordId = "record_id"

    static let sdkCost = "SDK_COST"
    static let isFromNativePull = "is_from_native_pull"
    
    static let code = "code"
    static let msg = "msg"
    static let retryCount = "retry_count"
    static let fieldCount = "field_count"
    static let dataSize = "data_size"
    static let isFasterRender = "is_faster_render"
}

enum BTStatisticEventResult: String {
    case cancel
    case fail
    case success
}

enum BTStatisticStageType: String {
    case start
    case end
}

enum BTStatisticMainStageName: String {
    // 点击 Base 内记录卡片
    case OPEN_RECORD_START
    case OPEN_RECORD_SET_RECORD
    case OPEN_RECORD_TTV
    case OPEN_RECORD_TTV_NOTIFY_DATA_CHANGED
    case OPEN_RECORD_TTU
    case OPEN_RECORD_TTU_NOTIFY_DATA_CHANGED
    case OPEN_RECORD_FAIL
    case OPEN_RECORD_CELL_SET_DATA
    case OPEN_RECORD_CELL_DRAW
    case OPEN_RECORD_CELL_LIST
    case OPEN_RECORD_BITABLE_READY

    case BITABLE_SDK_LOAD_COST

    // 文档加载｜记录分享｜Base外记录新建
    case OPEN_FILE_START
    case OPEN_FILE_SDK_FIRST_PAINT  // 仅文档加载
    case OPEN_FILE_TTV
    case OPEN_FILE_TTU
    case OPEN_FILE_CANCEL
    case OPEN_FILE_FAIL
    case POINT_VIEW_OR_BLOCK_SWITCH
    case OPEN_FILE_CREATE_UI_START
    case OPEN_FILE_CREATE_UI_END
    case OPEN_FILE_TEMPLATE_PRELOAD_START
    case OPEN_FILE_TEMPLATE_PRELOAD_END
    case OPEN_FILE_START_RENDER
    case OPEN_FILE_END_RENDER


    case OPEN_HOME_START
    case OPEN_HOME_XYZ_START
    case OPEN_HOME_XYZ_END
    case OPEN_HOME_LOAD_DATA_END_FILE
    case OPEN_HOME_LOAD_DATA_END_DASHBOARD
    case OPEN_HOME_LOAD_DATA_END_RECOMMEND
    case OPEN_HOME_TTV_FILE
    case OPEN_HOME_TTV_DASHBOARD
    case OPEN_HOME_TTV_RECOMMEND
    case OPEN_HOME_END
    case OPEN_HOME_CANCEL
    case OPEN_HOME_FAIL

    case BASE_ADD_RECORD_META_START             // 开始请求 META。仅 Base 外新建记录提交
    case BASE_ADD_RECORD_META_SUCCESS           // 请求 META 网络成功（不包括业务 code 失败）。仅 Base 外新建记录提交
    case BASE_ADD_RECORD_META_FAIL              // 请求 META 网络失败。仅 Base 外新建记录提交
    case BASE_ADD_RECORD_GET_META               // 前端调用 META 接口的时机
    case BASE_ADD_RECORD_RETURN_META            // 前端调用 META 接口后返回数据的时机
    
    case BASE_ADD_RECORD_SUBMIT_START           // 开始提交。仅 Base 外新建记录提交
    case BASE_ADD_RECORD_SUBMIT_SUCCESS         // 提交成功。仅 Base 外新建记录提交
    case BASE_ADD_RECORD_SUBMIT_FAIL            // 提交失败/网络超时。仅 Base 外新建记录提交
    case BASE_ADD_RECORD_APPLY_END              // Apply 结束。仅 Base 外新建记录提交
    
    case NATIVE_RENDER_CARD_VIEW
    case NATIVE_RENDER_CARD_FIELD
}

enum BTStatisticEventName: String {
    // 业务埋点

    case base_mobile_performance_open_file
    case base_mobile_performance_open_record
    case base_mobile_performance_record_cell

    case base_mobile_performance_enter_homepage
    case base_mobile_performance_submit

    case base_mobile_performance_native_grid_card    
    case base_mobile_performance_native_grid_card_set_data
    case base_mobile_performance_native_grid_card_layout
    case base_mobile_performance_native_grid_card_draw
    
    case base_mobile_performance_native_grid_card_field
    case base_mobile_performance_native_grid_card_field_set_data
    case base_mobile_performance_native_grid_card_field_layout
    case base_mobile_performance_native_grid_card_field_draw

    // FPS
    case base_mobile_performance_drop_frame_info
    case base_mobile_performance_fps_info

    // 异常埋点
    case base_mobile_performance_warning_point
}

enum BTStatisticOpenFileType: String {
    case main
    case share_record
    case base_add
}

enum BTStatisticFPSEventKey: String {
    case scene
    case drop_frame
    case drop_durations
    case fps
    case duration
    case hitch_duration
    case drop_state_ratio
    case drop_dur_ratio
    case fps_average
}

enum BTStatisticFPSScene: String {
    case native_cell_list_scroll
    case native_open_record_1_min
    case native_stage_cell_list_scroll
    case faster
    case native_home_personal
    case native_home_recommend
    case native_grid_card_scroll
}

// 对应 slardar 性能监控 https://bytedance.feishu.cn/wiki/wikcnGMOaqNlcd0muczF4VWFrog
enum BTFPSDropState: String, CaseIterable {
    case none
    case little
    case normal
    case middle
    case serious
    case bad

    private static let littleFloor = 1
    private static let littleCeil = 3
    private static let normalFloor = 4
    private static let normalCeil = 8
    private static let middleFloor = 9
    private static let middleCeil = 24
    private static let seriousFloor = 25
    private static let seriousCeil = 42

    static func state(dropFrame: Int) -> BTFPSDropState {
        if dropFrame > seriousCeil {
            return .bad
        }
        if dropFrame >= seriousFloor, dropFrame <= seriousCeil {
            return .serious
        }
        if dropFrame >= middleFloor, dropFrame <= middleCeil {
            return .middle
        }
        if dropFrame >= normalFloor, dropFrame <= normalCeil {
            return .normal
        }
        if dropFrame >= littleFloor, dropFrame <= littleCeil {
            return .little
        }
        return .none
    }
}

enum BTStatisticSettingKey: String {
    case disable_native_fetch_sdk_cost
}

enum BTStatisticErrorType: String {
    case token_not_match
}

enum BTStatisticOpenHomeLoadType: String {
    case file
    case dashboard
    case recommend

    var loadStage: String {
        switch self {
        case .file:
            return BTStatisticMainStageName.OPEN_HOME_LOAD_DATA_END_FILE.rawValue
        case .dashboard:
            return BTStatisticMainStageName.OPEN_HOME_LOAD_DATA_END_DASHBOARD.rawValue
        case .recommend:
            return BTStatisticMainStageName.OPEN_HOME_LOAD_DATA_END_RECOMMEND.rawValue
        }
    }

    var ttvStage: String {
        switch self {
        case .file:
            return BTStatisticMainStageName.OPEN_HOME_TTV_FILE.rawValue
        case .dashboard:
            return BTStatisticMainStageName.OPEN_HOME_TTV_DASHBOARD.rawValue
        case .recommend:
            return BTStatisticMainStageName.OPEN_HOME_TTV_RECOMMEND.rawValue
        }
    }
}

enum BTStatisticOpenHomeCancelType: String {
    case switch_tab
    case user_back
    case user_scroll
    case user_refresh
    case new_file
    case file_list_full_screen
    case dashboard_full_screen
    case dashboard_edit
}

enum BTStatisticOpenHomeFailType: String {
    case load_file_list
    case load_dashboard
    case load_recommend
}
