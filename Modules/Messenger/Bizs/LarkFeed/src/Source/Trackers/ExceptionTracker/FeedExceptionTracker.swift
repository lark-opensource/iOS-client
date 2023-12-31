//
//  FeedExceptionTracker.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/1.
//

import LKCommonsTracker
import Homeric

// Feed 异常基础信息字段
struct FeedBaseErrorInfo {
    let objcId: String           // 用于error查询用的id，如feedid, 默认为空
    let errorMsg: String        // 用于error分析的数据, 默认为空
    let type: FeedExceptionType // 异常的类型
    let error: Error?
    init(type: FeedExceptionType,
         objcId: String = "",
         errorMsg: String = "",
         error: Error? = nil) {
        self.type = type
        self.objcId = objcId
        self.errorMsg = errorMsg
        self.error = error
    }
}

// Feed 主模块划分
enum FeedModuleType: String {
    case dataStream
    case feedcard
    case feedlist
    case filter
    case label
    case main
    case myai
    case navi
    case setting
    case shortcut
    case tabbar
    // 符合一级module,但error日志暂不包含
    // case bottomBar
    // case dataqueue
    // case guide
    // case header
}

enum FeedExceptionType: CustomStringConvertible {
    case info(track: Bool = false)      // 默认不上报到TEA
    case error(track: Bool = true)      // 默认上报到TEA
    case warning(track: Bool = false)   // 默认不上报到TEA

    var description: String {
        switch self {
        case .info(_):
            return "info"
        case .error(_):
            return "error"
        case .warning(_):
            return "warning"
        }
    }
}

struct FeedExceptionTracker {
    static func post(moduleName: String,
                     subModuleName: String,
                     nodeName: String,
                     info: FeedBaseErrorInfo) {
        var params: [AnyHashable: Any] = [:]
        params["module_type"] = moduleName
        params["sub_module_type"] = subModuleName
        params["node_name"] = nodeName
        params["exception_type"] = info.type.description
        params["biz_id"] = info.objcId
        params["error_msg"] = info.errorMsg

        let canUploadEvent: Bool //是否上报埋点
        let printLog = "feedlog/\(moduleName)/\(subModuleName)/\(nodeName). \(info.errorMsg)" //日志信息

        switch info.type {
        case .info(let track):
            canUploadEvent = track
            FeedContext.log.info(printLog)
        case .error(let track):
            canUploadEvent = track
            FeedContext.log.error(printLog, error: info.error)
        case .warning(let track):
            canUploadEvent = track
            FeedContext.log.warn(printLog)
        }

        // 埋点上报
        if canUploadEvent {
            Tracker.post(TeaEvent(Homeric.FEED_BIZ_LOGIC_ERROR, params: params))
        }
    }
}
