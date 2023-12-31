//
//  DocsPreloaderPerformanceDefine.swift
//  SKCommon
//
//  Created by Guoxinyi on 2022/7/13.
//

import Foundation
import SKUIKit
import SKFoundation
import SpaceInterface

/// 上报到后台时的字段
enum PreloadReportKey: String {
    case fileId         =  "file_id"
    case resultKey      =  "result_key"
    case resultCode     =  "result_code"
    case costTime       =  "cost_time"
    case taskCostTime   =  "total_cost_time"
    case loaderType     =  "loader_type"
    case fileType       =  "file_type"
    case loadSource     =  "load_from"
    case netType        =  "net_type"
    case loadDataType   =  "load_type"
    case loadLength     =  "length"
    case retry          =  "retry"
    case cancel         =  "cancel"
    case cache          =  "cache"
    case subFileType    =  "sub_file_type"  //如果是wiki，增加subtype
    case waitStartTime  =  "wait_start_time"
    case priority       =  "priority"       // 预加载优先级
    case taskScheduleTime = "wait_schedule_time" // 等待预加载框架触发的耗时
}

// 据加载的数据类型
enum PreloadDataType: String {
    case unknow
    case clientVars
    case SSR
    case pictures
    case vote
    case comment
    case permission
}

// 预加载器类型
enum LoaderType: String {
    case Native
    case RN
}

enum PreloadErrorCode: Int {
    case RNTimeOut = 99999                  // RN超时
    case unknowError = 99998                // 未知错误
    case PermissionDefault = 99997          // 权限拉取失败默认错误码
    case GetSSRDataError = 99996            // 后端没有返回code字段
    case SSRDataFormatError = 99995         // SSRdata字段是空, 5.32版本之前
    case SSRDataFormatJsonError = 99994     // 转json失败
    case SSRDataFormatDataEmpty = 99993     // data是空，没有code
    case ClientVarsNoPermission = 4030004   // clientvar没有权限
    case SSRNotFound = 40404                // 没有SSR
    case SSRNoPermission = 40403            // SSR没有权限
    case DocsDeleted = 50003                // docx文档被删除
}

public final class PreloadDataRecord {
    private var fileId: String                      // 加密后的fileid
    private let preloadFromSource: String           // from
    private var timeStamp: Double                   // record开始时间
    private var taskTimeStamp: Double               // 添加到队列的开始时间
    private var waitTimeStamp: Double               // 队列中排队耗时
    private var allParames: [String: Any] = [:]     // 上报参数
    
    init(fileID: String, preloadFrom: PreloadFromSource?, waitScheduleTime: TimeInterval) {
        fileId = fileID
        timeStamp = 0
        preloadFromSource = preloadFrom?.rawValue ?? ""
        taskTimeStamp = Date().timeIntervalSince1970
        waitTimeStamp = Date().timeIntervalSince1970
        allParames.updateValue(waitScheduleTime > 0 ? waitScheduleTime * 1000 : 0, forKey: PreloadReportKey.taskScheduleTime.rawValue)
        allParames.updateValue(fileID, forKey: PreloadReportKey.fileId.rawValue)
    }
    
    // 开始统计
    public func startRecod() {
        timeStamp = Date().timeIntervalSince1970
        allParames.updateValue(waitTimeStamp > 0 ? (Date().timeIntervalSince1970 - waitTimeStamp) * 1000 : 0, forKey: PreloadReportKey.waitStartTime.rawValue)
    }
    // 结束统计
    public func endRecord(cancel: Bool = false, cache: Bool = false) {
        if timeStamp <= 0, cache == false {
            return
        }
        allParames.updateValue(cancel ? 1 : 0, forKey: PreloadReportKey.cancel.rawValue)
        allParames.updateValue(cache ? 1 : 0, forKey: PreloadReportKey.cache.rawValue)
        allParames.updateValue(timeStamp > 0 ? (Date().timeIntervalSince1970 - timeStamp) * 1000 : 0, forKey: PreloadReportKey.costTime.rawValue)
        allParames.updateValue(taskTimeStamp > 0 ? (Date().timeIntervalSince1970 - taskTimeStamp) * 1000 : 0, forKey: PreloadReportKey.taskCostTime.rawValue)
        #if DEBUG
        DocsLogger.info("PreloadEnd: \(allParames)")
        #else
            DocsTracker.newLog(enumEvent: .docsPreloadDataPerformance, parameters: allParames)
        #endif
        allParames.removeAll()
        timeStamp = 0
        taskTimeStamp = 0
    }
    
    // 更新初始化信息
    func updateInitInfo(loaderType: LoaderType,
                               fileType: DocsType,
                               subFileType: DocsType?,
                               loadType: PreloadDataType,
                               retry: Int,
                                priority: Int? = nil) {
        allParames.updateValue(loaderType.rawValue, forKey: PreloadReportKey.loaderType.rawValue)
        allParames.updateValue(fileType.name, forKey: PreloadReportKey.fileType.rawValue)
        allParames.updateValue(loadType.rawValue, forKey: PreloadReportKey.loadDataType.rawValue)
        allParames.updateValue(retry, forKey: PreloadReportKey.retry.rawValue)
        allParames.updateValue(preloadFromSource, forKey: PreloadReportKey.loadSource.rawValue)
        if let subFileType = subFileType {
            allParames.updateValue(subFileType.name, forKey: PreloadReportKey.subFileType.rawValue)
        }
        if let priority = priority{
            allParames.updateValue(priority, forKey: PreloadReportKey.priority.rawValue)
        }
    }
    
    // 更新错误码
    public func updateResultCode(code: Int) {
        if code == 0 {
            allParames.updateValue(0, forKey: PreloadReportKey.resultKey.rawValue)
            allParames.updateValue(code, forKey: PreloadReportKey.resultCode.rawValue)
        } else {
            allParames.updateValue(1, forKey: PreloadReportKey.resultKey.rawValue)
            allParames.updateValue(code, forKey: PreloadReportKey.resultCode.rawValue)
        }
    }
    // 更新加载数据大小
    public func updateLoadLength(loadLength: UInt64) {
        allParames.updateValue(loadLength, forKey: PreloadReportKey.loadLength.rawValue)
    }
}
