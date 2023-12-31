//
//  NetStatisticsReporter.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/1/24.
//

import Foundation
import Alamofire
import TTNetworkManager
// MARK: - 统计相关
public protocol StatisticsServcie {
    //shouldAddPrefix: 是否需要添加Docs_前缀
    static func log(event: String, parameters: [AnyHashable: Any]?, category: String?, shouldAddPrefix: Bool)
    static func newLog(event: String, parameters: [AnyHashable: Any]?, category: String?)
}

/// 网络相关的统计上报
struct NetStatisticsReporter {
    private var timeInfo = DocsNetTimeInfo()
    var additionalStatisticInfos = [String: Any]()
    let statisticServiceType: StatisticsServcie.Type

    private let useRust: Bool
    let identifier: String
    init(identifier: String, useRust: Bool, statisticServiceType: StatisticsServcie.Type = DocsTracker.self) {
        self.identifier = identifier
        self.useRust = useRust
        self.statisticServiceType = statisticServiceType
    }

    func append(_ metrics: URLSessionTaskMetrics?) {
        if let metrics = metrics {
            self.timeInfo.timelines.append(metrics)
        }
    }
    func doStatisticsFor(request: DocsInternalBaseRequest?, response: DataResponse<Any>) {
        // 最后一次成功的还没统计
        if let unWrappedRequest = request, timeInfo.timelines.count <= unWrappedRequest.retryCount {
            timeInfo.timelines.append(response.timeline)
            doStatisticsFor(request: request, timeLine: request?.netMetrics, error: response.error,
                            response: response.response, data: response.data,
                            metrics: response.metrics, requestEnd: false)
        }
        doStatisticsFor(request: request, timeLine: timeInfo, error: response.error,
                        response: response.response, data: response.data, metrics: response.metrics)
    }

    func doStatisticsFor(request: DocsInternalBaseRequest?, response: DataResponse<Data>) {
        //最后一次成功的还没统计
        if let unWrappedRequest = request, timeInfo.timelines.count <= unWrappedRequest.retryCount {
            timeInfo.timelines.append(response.timeline)
            doStatisticsFor(request: request, timeLine: request?.netMetrics, error: response.error,
                            response: response.response, data: response.data, metrics: response.metrics, requestEnd: false)
        }
        doStatisticsFor(request: request, timeLine: timeInfo, error: response.error,
                        response: response.response, data: response.data, metrics: response.metrics)
    }

    //swiftlint:disable function_parameter_count
    func doStatisticsFor(request: DocsInternalBaseRequest?, timeLine: DocsNetTimeLine?, error: Error?, response: HTTPURLResponse?, data: Data?, metrics: URLSessionTaskMetrics?, requestEnd: Bool = true) {
        guard let request = request else {
            spaceAssertionFailure()
            return
        }

        var reportParams: [String: Any] = [:]
        reportParams.merge(self.additionalStatisticInfos) { (_, new) in new }
        DispatchQueue.global().async {
            let code = self.getNetErrorCode(error: error, response: response)
            reportParams["code"] = code
            reportParams["cost_time"] = (timeLine?.requestDuration ?? -1 ) * 1000
            reportParams["url"] = request.urlRequest?.url?.stringForStatistics ?? ""
            reportParams["docs_net_retry_count"] = request.retryCount
            reportParams["response_length"] = data?.count ?? 0
            reportParams["server-timing"] = response?.allHeaderFields["server-timing"] ?? ""
            reportParams.merge(metrics?.metricsDict ?? [:]) { (_, new) in new }
            
            let eventType = requestEnd ? DocsTracker.InnerEventType.fetchServerResponse : DocsTracker.InnerEventType.fetchServerSubResponse
            if UserScopeNoChangeFG.HZK.enableNetworkDirectConnectRust {
                //结束请求，才可以取rustMetrics
                if requestEnd && request.rustMetricsDict.count > 0 {
                    reportParams.merge(request.rustMetricsDict ) { (_, new) in new }
                }
                reportParams[DocsTracker.Params.netChannel] = request.netChannel
            } else {
                if self.useRust{
                    reportParams.merge(request.rustMetricsDict ) { (_, new) in new }
                }
                reportParams[DocsTracker.Params.netChannel] = self.useRust ? "rustChannel" : "nativeUrlSession"
            }
            
            reportParams[DocsTracker.Params.useMultiConnection] = request.urlRequest?.enableComplexConnect
            
            //结束请求，才可以取rustMetrics
            if requestEnd && UserScopeNoChangeFG.HZK.enableNetworkOptimize {
                
                //没有网络请求结果，resourceFetchType是unknow，证明rust请求没有发出去，这里看下打印下日志
                let rustNetworkLoadCount = request.rustMetrics.filter({ $0.resourceFetchType == .networkLoad || $0.resourceFetchType == .localCache }).count
                //rustNetworkLoadCount为0，证明请求没有走到rust
                reportParams[DocsTracker.Params.hasRustMetrics] = rustNetworkLoadCount
                
            }
            let ttNetworkManager = TTNetworkManager.shareInstance()
            let effectiveConnectionType = ttNetworkManager.getEffectiveConnectionType()
            reportParams["network_quality_type"] = effectiveConnectionType.rawValue
            self.statisticServiceType.log(enumEvent: eventType, parameters: reportParams)
            reportParams["event"] = eventType.rawValue
            reportParams["identifier"] = self.identifier
            if code == 0 {
                let abnormalTimeThreshold = 5.0
                if (timeLine?.requestDuration ?? -1) > abnormalTimeThreshold || !UserScopeNoChangeFG.YY.allowAllNetLogDisable {
                    DocsLogger.info("log net event", extraInfo: reportParams, error: nil, component: LogComponents.net)
                }
            } else {
                reportParams["errorMsg"] = error?.localizedDescription.toBase64()
                DocsLogger.error("net fail", extraInfo: reportParams, error: nil, component: LogComponents.net)
            }
        }
    }
    //swiftlint:enable function_parameter_count
    func doUploadStatistisFor(request: DocsInternalBaseRequest?, response: DefaultDataResponse) {
        DispatchQueue.global().async {
            var reportParams: [String: Any] = ["code": self.getNetErrorCode(error: response.error, response: response.response),
                                               "errorMsg": getErrMessage(response.error),
                                               "url": request?.urlRequest?.url?.stringForStatistics ?? "",
                                               "docs_net_retry_count": request?.retryCount ?? 5,
                                               "docs_body_length": request?.urlRequest?.httpBody?.count ?? 0,
                                               "cost_time": response.timeline.requestDuration * 1000]

            reportParams.merge(self.additionalStatisticInfos) { (_, new) in new }
            reportParams.merge(response.metrics?.metricsDict ?? [:]) { (_, new) in new }
            if self.useRust {
                reportParams.merge(request?.rustMetricsDict ?? [:]) { (_, new) in new }
            }
            if UserScopeNoChangeFG.HZK.enableNetworkOptimize {
                //count为0，证明请求没有走到rust
                reportParams[DocsTracker.Params.hasRustMetrics] = request?.rustMetrics.filter({ $0.resourceFetchType == .networkLoad || $0.resourceFetchType == .localCache }).count ?? 0
            }
            reportParams[DocsTracker.Params.useMultiConnection] = request?.urlRequest?.enableComplexConnect
            reportParams[DocsTracker.Params.netChannel] = self.useRust ? "rustChannel" : "nativeUrlSession"
            self.statisticServiceType.log(enumEvent: DocsTracker.InnerEventType.pictureUpload, parameters: reportParams )
        }
    }

    private func getNetErrorCode(error: Error?, response: HTTPURLResponse?) -> Int {
        var code = -3
        if error != nil {
            if let urlError = error as? URLError {
                code = urlError.errorCode
            } else if let nserror = error as NSError? {
                code = nserror.code
            } else {
                code = -4
            }
        } else if let response = response {
            if (200...299).contains(response.statusCode) {
                code = 0
            } else {
                code = -response.statusCode
            }
        } else {
            code = -5
        }
        return code
    }

    private func getErrMessage(_ oriError: Error?) -> String {
        guard let error = oriError else {
            return ""
        }
        //userInfo可能会有敏感信息, 只加想知道的
        let nsErr = error as NSError
        return "\(nsErr.code):\(nsErr.domain)"
    }
}

extension URL {
    /// url 上报到后台的字符串
    public var stringForStatistics: String {
        guard var component = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return ""
        }
        component.query = nil
        let pathComponent = self.pathComponents.dropFirst().map { subPath -> String in
            guard subPath.count >= 22 else { return subPath }
            return ""
        }
        component.path = "/" + pathComponent.joined(separator: "/")
        return component.url?.absoluteString ?? ""
    }
    
    public var unlForLog: String {
        guard var component = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return ""
        }
        component.query = nil
        component.path = component.path.encryptToShort
        return component.url?.absoluteString ?? ""
    }
}
