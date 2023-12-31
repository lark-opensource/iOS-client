//
//  ClippingDocReport.swift
//  SKCommon
//
//  Created by huayufan on 2022/7/7.
//  


import SKFoundation
import SKResource

class ClippingDocReport {

    enum Stage {
        ///  解压js
        case extract
        ///  字符串替换
        case replace
        /// 写入文件
        case writeFile(fileSize: Int)
        /// 读取文件转二进制
        case readFile(fileSize: Int)
        /// 接口耗时
        case fetch(url: String, fileSize: Int?)
        
        var params: [String: Any] {
            switch self {
            case .extract:
                return ["stage": "extract"]
            case .replace:
                return ["stage": "replace"]
            case let .writeFile(fileSize):
                return ["stage": "writeFile", "file_size": fileSize]
            case let .readFile(fileSize):
                return ["stage": "readFile", "file_size": fileSize]
            case let .fetch(url, fileSize):
                var pa: [String: Any] = ["stage": "fetch", "url": url]
                if let size = fileSize {
                    pa["file_size"] = size
                }
                return pa
            }
        }
    }
    
    enum FailReason: String {
        case extractFail = "unzip_fail"
        case injectTimeout = "inject_js_timeout"
        case injectFail = "inject_js_fail"
        case unknow
    }
    
    private let articleUrl: String
    
    init(articleUrl: String) {
        self.articleUrl = articleUrl
    }
    
    /// 仅上报native代码功能错误，其他非功能错误由前端上报
    func fail(reason: FailReason) {
        let params: [String: Any] = ["click": "fail",
                                     "target": "ccm_clip_prompt_view",
                                     "click_source": "im_card",
                                     "website": articleUrl,
                                     "login_state": "true",
                                     "version": ClippingDocResource().version,
                                     "is_latest_flag": "true",
                                     "is_real_fail_flag": "true",
                                     "fail_reason": reason.rawValue]
        DocsLogger.debug("[tea] fail params:\(params)", component: LogComponents.clippingDoc)
        DocsTracker.newLog(event: DocsTracker.EventType.clipResultClick.rawValue, parameters: params)
    }
    
    func record(stage: Stage, cost: Double) {
        var params: [String: Any] = ["cost": cost,
                                     "version": ClippingDocResource().version]
        params.merge(stage.params) { (_, new) in new }
        DocsLogger.debug("[tea] stage params:\(params)", component: LogComponents.clippingDoc)
        DocsTracker.newLog(event: DocsTracker.EventType.clipStagDuration.rawValue, parameters: params)
    }
    
}
