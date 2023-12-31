//
//  UtilLongPicService+analytics.swift
//  SKBrowser
//
//  Created by chensi(陈思) on 2022/2/9.
//  


import Foundation
import SKFoundation

extension UtilLongPicService {
    
    struct AnalyticsReporter {
        
        enum StatusCode: Int {
            case success = 0
            case failure = 1
        }
        
        /// 导出结果
        var status: StatusCode?
        
        /// 图片文件大小，单位KB
        var fileSize = 0
        
        /// js准备时间（毫秒）
        var jsDuration = 0
        
        /// native消耗时间（毫秒）
        var nativeDuration = 0
        
        /// 总消耗时间（毫秒）
        var totalDuration = 0
        
        /// 文件的后缀名
        var fileType = ""
        
        /// 文件ID，取值为加密后的文件token
        var fileId = ""
        
        /// 图片宽度
        var width = CGFloat(0)
        
        /// 图片高度，总体的
        var height = CGFloat(0)
        
        /// 图片张数，四舍五入
        var pageCount = 0
        
        private var processStart = CFTimeInterval(0) // 开始处理时间戳
    }
}

extension UtilLongPicService.AnalyticsReporter {
    
    mutating func reset() {
        status = nil
        fileSize = 0
        jsDuration = 0
        nativeDuration = 0
        totalDuration = 0
        fileType = ""
        fileId = ""
        width = 0
        height = 0
        pageCount = 0
        processStart = CACurrentMediaTime()
    }
    
    /// 标记web端处理完毕
    mutating func markJSProcessDone() {
        let duration = Int(round((CACurrentMediaTime() - processStart) * 1_000))
        jsDuration = max(0, duration)
    }
    
    /// 标记native端处理完毕
    mutating func markNativeProcessDone() {
        let end = CACurrentMediaTime()
        let duration = Int(round((end - processStart) * 1_000))
        totalDuration = max(0, duration)
        nativeDuration = max(0, totalDuration - jsDuration)
    }
    
    func report() {
        let parameters = toParams()
        DocsTracker.log(enumEvent: .generateLongImageInfo, parameters: parameters)
    }
    
    private func toParams() -> [String: Any] {
        let params: [String: Any] = ["status_code": "\((status ?? .failure).rawValue)",
                                     "file_size": Int(round(Double(fileSize) / 1024)), // 上报单位MB
                                     "js_cost_ms": jsDuration,
                                     "native_cost_ms": nativeDuration,
                                     "time_cost_ms": totalDuration,
                                     "file_type": fileType,
                                     "file_id": fileId,
                                     "width": "\(Int(round(width)))",
                                     "height": "\(Int(round(height)))",
                                     "page_count": "\(pageCount)"]
        return params
    }
}
