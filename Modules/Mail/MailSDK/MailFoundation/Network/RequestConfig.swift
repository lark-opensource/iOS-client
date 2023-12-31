//
//  RequestConfig.swift
//  DocsSDK
//
//  Created by huahuahu on 2019/1/24.
//

import Foundation

/// 发起请求时的配置项
struct RequestConfig {
    var customTimeOut: Double?
    var method = MailHTTPMethod.POST
    var url: String!
    var encodeType: ParamEncodingType = .urlEncodeDefault
    var params: Params = [:]
    var headers = [String: String]()
    var qos: MailNetConfig.Qos = .default
    var trafficType: MailNetConfig.TrafficType = .default
    private(set) var requestId: String = {
        var reqId = String.random(len: 12) + "-" + (MailNetConfig.userID ?? "")
        return reqId
    }()

    var urlRequest: URLRequest?
    init() {}

    static let `default`: RequestConfig = {
        var config = RequestConfig()
        config.method = .POST
        config.encodeType = .urlEncodeDefault
        return config
    }()
}

extension RequestConfig {
    /// 如果设置了urlrequest，返回加入了requestid/xrequestid的urlrequest。否则返回nil
    mutating func requestIdAddedRequest() -> URLRequest? {
        guard var alteredRequest = urlRequest else { return nil }
        let featureId: String? = {
            return nil
        }()
        let reqID: String = {
            guard let reqId = alteredRequest.allHTTPHeaderFields?[MailCustomRequestHeader.requestID.rawValue] else {
                return requestId
            }
            if let fid = featureId, !reqId.hasSuffix(fid) {
                requestId = reqId + "#" + fid
            } else {
                requestId = reqId
            }
            return requestId
        }()
        alteredRequest.setValue(reqID, forHTTPHeaderField: MailCustomRequestHeader.requestID.rawValue)
        if featureId != nil {
            alteredRequest.setValue(reqID, forHTTPHeaderField: MailCustomRequestHeader.xRequestID.rawValue)
        }
        return alteredRequest
    }

    ///  如果自己的header里没有相应字段，加入额外的header里的字段。urlrequest必须是nil
    ///
    /// - Parameter additional: 额外的header
    /// - Returns: 处理后的header
    func heandersWith(_ additional: [String: String]) -> [String: String] {
        guard urlRequest == nil else { return [:] }
        var finalHeaders = ["User-Agent": UserAgent.defaultNativeApiUA]
        // 单个请求的自定义header
        finalHeaders.merge(other: headers)
        finalHeaders.merge(additional) { (current, _) -> String in current }
        let reqID = requestId
        if finalHeaders.keys.compactMap({ return $0.lowercased() }).contains(MailCustomRequestHeader.requestID.rawValue) == false {
            finalHeaders[MailCustomRequestHeader.requestID.rawValue] = reqID
        }
        return finalHeaders
    }
}
