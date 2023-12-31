//
//  OPURLSessionTask.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/12.
//

import UIKit
import LarkOPInterface

typealias onOPURLTaskProgress = (_ data: Data, _ recevied: Float, _ total: Float) -> Void
typealias onOPURLTaskComplete = (_ data: Data?, _ error: OPError?) -> Void
typealias onOPURLTaskMetricsCollected = (_ metriccs: URLSessionTaskMetrics) -> Void

/// 网络请求delegate事件处理器
public final class OPURLSessionTaskEventHandler: NSObject {

    /// 进度回调事件
    var onProgress: onOPURLTaskProgress?

    /// 请求完成事件
    var onComplete: onOPURLTaskComplete?

    /// 性能数据收集完成事件
    var onMetricsCollected: onOPURLTaskMetricsCollected?

    init(onProgress: onOPURLTaskProgress? = nil,
         onComplete: onOPURLTaskComplete? = nil,
         onMetricsCollected: onOPURLTaskMetricsCollected? = nil) {
        self.onProgress = onProgress
        self.onComplete = onComplete
        self.onMetricsCollected = onMetricsCollected
    }

}

public enum OPURLRequestMethod: Int {
    case get
    case head
    case post
    case put
    case patch
    case delete
    case trace
    case connect
}

extension OPURLRequestMethod {

    /// 对应的HTTPMethod
    var httpMethod: String {
        switch self {
        case .get:
            return "GET"
        case .head:
            return "HEAD"
        case .post:
            return "POST"
        case .put:
            return "PUT"
        case .patch:
            return "PATCH"
        case .delete:
            return "DELETE"
        case .trace:
            return "TRACE"
        case .connect:
            return"CONNECT"
        }
    }

    /// 参数应该最终转化的类型
    enum ParamType {
        case body
        case query
    }

    /// 参照almofire：get, delete, head传入的参数应该转换为query，其他的转换为httpBody
    var paramType: ParamType {
        switch self {
        case .get, .delete, .head:
            return .query
        default:
            return .body
        }
    }
}

public final class OPURLSessionTaskConfigration: NSObject {

    /// 请求任务唯一标识，用来做合并等操作, 合并配置会以之前的配置为准
    let identifier: String

    /// 请求的ULR
    let url: URL

    /// 请求的method
    let method: OPURLRequestMethod

    /// 请求的header
    let headers: NSDictionary

    /// 如果是get请求，会组装到url的query里，如果是post，会塞到httpbody
    let params: NSDictionary

    /// 优先级：会根据该值的大小在队列中进行排布, 取值可参照URLSessionTask.proority
    let priority: Float

    /// 是否与session内其他相同id的任务进行merge，merge会直接使用队列中的第一个任务
    let shouldMergeWithSameId: Bool

    var eventHandler: OPURLSessionTaskEventHandler?

    public init(identifier: String,
         url: URL,
         method: OPURLRequestMethod,
         headers: NSDictionary,
         params: NSDictionary,
         priority: Float = URLSessionTask.defaultPriority,
         shouldMergeWithSameId: Bool = true,
         eventHandler: OPURLSessionTaskEventHandler? = nil) {
        self.identifier = identifier
        self.url = url
        self.eventHandler = eventHandler
        self.priority = priority
        self.shouldMergeWithSameId = shouldMergeWithSameId
        self.params = params
        self.headers = headers
        self.method = method
    }
}

/// 开放平台网络请求配置：目前支持超时时间配置，最大并发请求数配置
class OPURLSessionConfiguration: NSObject {

    /// 网络请求超时时间：默认为60s
    let timeoutInterval: TimeInterval

    /// 请求最大并发数，默认值为CPU活跃核心数*2
    let maxConcurrentOperationCount: Int

    init(timeoutInterval: TimeInterval = 60,
         maxConcurrentOperationCount: Int = max(ProcessInfo.processInfo.activeProcessorCount * 2, 1)) {
        self.timeoutInterval = timeoutInterval
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
    }

    static let `default`: OPURLSessionConfiguration = OPURLSessionConfiguration()

}
