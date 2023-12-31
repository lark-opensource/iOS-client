//
//  RequestConfig.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/1/24.
//

import Foundation
import LarkContainer

/// 发起请求时的配置项
public struct RequestConfig {
    let userResolver: UserResolver
    var customTimeOut: Double?
    var method = DocsHTTPMethod.POST
    var url: String!
    var encodeType: ParamEncodingType = .urlEncodeDefault
    var params: Params = [:]
    public var headers = [String: String]()
    var qos: NetConfigQos = .default
    var forceComplexConnect: Bool = false
    var trafficType: NetConfigTrafficType = .default
    var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    private(set) var requestId: String = {
        return RequestConfig.generateRequestID()
    }()
    
    //本地生成requestId
    public static func generateRequestID() -> String {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let netConfig = userResolver.docs.netConfig
        var reqId = String.randomStr(len: 12) + "-" + (netConfig?.userID ?? "")
        if SKFoundationConfig.shared.isStagingEnv, let featureId = SKFoundationConfig.shared.docsFeatureID, !featureId.isEmpty {
            reqId += ("#" + featureId)
        }
        return reqId
    }
    
    //本地生成logid
    public static func generateTTLogid() -> String {
        //logid规则不能随便改，要不会导致观测平台查询失败：https://bytedance.feishu.cn/wiki/wikcnF5gKiIW655Tdqux88NMloh
        //021573726681239ffffffffffffffffffffffffffffffffabcdef
        //版本号[2位]     时间戳（精确到毫秒）[13位]     IPv6[32位] +                        random[6位]
        //02                    1573726681239      ffffffffffffffffffffffffffffffff    abcdef

        let nowDate = Date()
        let timeInterval = Int64(nowDate.timeIntervalSince1970 * 1000)
        // 获取IPv6暂时用32个f代替
        let logId = "02" + "\(timeInterval)" + String(repeating: "f", count: 32) + String.randomStr(len: 5)
        return logId
    }
    

    var urlRequest: URLRequest?
}

extension RequestConfig {

    /// 如果设置了urlrequest，返回加入了requestid/xrequestid的urlrequest。否则返回nil
    mutating func requestIdAddedRequest() -> URLRequest? {
        guard var alteredRequest = urlRequest else { return nil }
        let featureId: String? = {
            guard SKFoundationConfig.shared.isStagingEnv else { return nil }
            return SKFoundationConfig.shared.docsFeatureID
        }()
        let reqID: String = {
            guard let reqId = alteredRequest.allHTTPHeaderFields?[DocsCustomHeader.requestID.rawValue] else {
                return requestId
            }
            if let fid = featureId, !reqId.hasSuffix(fid) {
                requestId = reqId + "#" + fid
            } else {
                requestId = reqId
            }
            return requestId
        }()
        alteredRequest.setValue(reqID, forHTTPHeaderField: DocsCustomHeader.requestID.rawValue)
        alteredRequest.setValue(reqID, forHTTPHeaderField: DocsCustomHeader.xttTraceID.rawValue)
        if featureId != nil {
            alteredRequest.setValue(reqID, forHTTPHeaderField: DocsCustomHeader.xRequestID.rawValue)
        }
        
        if alteredRequest.allHTTPHeaderFields?.keys.compactMap({ return $0.lowercased() }).contains(DocsCustomHeader.xttLogId.rawValue) == false {
            //本地生成logid
            alteredRequest.setValue(RequestConfig.generateTTLogid(), forHTTPHeaderField: DocsCustomHeader.xttLogId.rawValue)
        }
        return alteredRequest
    }

    ///  如果自己的header里没有相应字段，加入额外的header里的字段。urlrequest必须是nil
    ///
    /// - Parameter additional: 额外的header
    /// - Returns: 处理后的header
    public func headersWith(_ additional: [String: String]) -> [String: String] {
        guard urlRequest == nil else { spaceAssertionFailure();  return [:] }
        var finalHeaders = ["User-Agent": UserAgent.defaultNativeApiUA]
        // 单个请求的自定义header
        finalHeaders.merge(other: headers)
        finalHeaders.merge(additional) { (current, _) -> String in current }
        let reqID = requestId
        if finalHeaders.keys.compactMap({ return $0.lowercased() }).contains(DocsCustomHeader.requestID.rawValue) == false {
            finalHeaders[DocsCustomHeader.requestID.rawValue] = reqID
            finalHeaders[DocsCustomHeader.xttTraceID.rawValue] = reqID
        } else {
            spaceAssertionFailure()
        }
        if finalHeaders.keys.compactMap({ return $0.lowercased() }).contains(DocsCustomHeader.xttLogId.rawValue) == false {
            //本地生成logid
            finalHeaders[DocsCustomHeader.xttLogId.rawValue] = RequestConfig.generateTTLogid()
        }
        if SKFoundationConfig.shared.isStagingEnv, let featureId = SKFoundationConfig.shared.docsFeatureID, !featureId.isEmpty {
            finalHeaders[DocsCustomHeader.xRequestID.rawValue] = reqID
        }
        return finalHeaders
    }
}
