//
//  HTTPHeaderInfoUtils.swift
//  LarkWebViewContainer
//
//  Created by ByteDance on 2023/2/22.
//

import Foundation
import LKCommonsLogging
import LarkSetting

final public class HTTPHeaderInfoUtils {
    private static let logger = Logger.lkwlog(HTTPHeaderInfoUtils.self, category: "HTTPHeaderInfoUtils")
    private static var webHTTPHeaderLogEnable: Bool = !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.httpheaderlog.disable.ios"))// user:global
    
    public static func requestCacheInfo(_ request: URLRequest, traceId: String? = nil) {
        guard webHTTPHeaderLogEnable else {
            Self.logger.info("can not print http header info, fg not enable")
            return
        }
        var cacheInfo: String = "[RequestHeaders]"
        if let url = request.url {
            cacheInfo.append(" url:\(url.safeURLString)")
        }
        if let ifModifiedSince = value(request: request, forHTTPHeaderField: "If-Modified-Since") {
            cacheInfo.append(" If-Modified-Since:\(ifModifiedSince)")
        }
        if let ifUnmodifiedSince = value(request: request, forHTTPHeaderField: "If-Unmodified-Since") {
            cacheInfo.append(" If-Unmodified-Since:\(ifUnmodifiedSince)")
        }
        if let ifNoneMatch = value(request: request, forHTTPHeaderField: "If-None-Match") {
            cacheInfo.append(" If-None-Match:\(ifNoneMatch)")
        }
        if let ifMatch = value(request: request, forHTTPHeaderField: "If-Match") {
            cacheInfo.append(" If-Match:\(ifMatch)")
        }
        Self.logger.lkwlog(level: .info, cacheInfo, traceId: traceId)
    }
    
    public static func responseCacheInfo(_ response: URLResponse, traceId: String? = nil) {
        guard webHTTPHeaderLogEnable else {
            Self.logger.info("can not print http header info, fg not enable")
            return
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            Self.logger.info("response is not HTTPURLResponse")
            return
        }
        var cacheInfo: String = "[ResponseHeaders]"
        if let url = response.url {
            cacheInfo.append(" url:\(url.safeURLString)")
        }
        cacheInfo.append(" statusCode:\(response.statusCode)")
        if let textEncodingName = response.textEncodingName {
            cacheInfo.append(" textEncodingName:\(textEncodingName)")
        }
        if let eTag = value(response: httpResponse, forHTTPHeaderField: "Etag") {
            cacheInfo.append(" Etag:\(eTag)")
        }
        if let contentType = value(response: httpResponse, forHTTPHeaderField: "Content-Type") {
            cacheInfo.append(" Content-Type:\(contentType)")
        }
        if let contentDisposition = value(response: httpResponse, forHTTPHeaderField: "Content-Disposition") {
            cacheInfo.append(" Content-Disposition:\(contentDisposition)")
        }
        if let cacheControl = value(response: httpResponse, forHTTPHeaderField: "Cache-Control") {
            cacheInfo.append(" Cache-Control:\(cacheControl)")
        }
        if let expires = value(response: httpResponse, forHTTPHeaderField: "Expires") {
            cacheInfo.append(" Expires:\(expires)")
        }
        if let lastModified = value(response: httpResponse, forHTTPHeaderField: "Last-Modified") {
            cacheInfo.append(" Last-Modified:\(lastModified)")
        }
        if let xLogId = value(response: httpResponse, forHTTPHeaderField: "x-tt-logid") {
            cacheInfo.append(" x-tt-logid:\(xLogId)")
        }
        if let xTraceTag = value(response: httpResponse, forHTTPHeaderField: "x-tt-trace-tag") {
            cacheInfo.append(" x-tt-trace-tag:\(xTraceTag)")
        }
        if let xRequestId = value(response: httpResponse, forHTTPHeaderField: "x-request-id") {
            cacheInfo.append(" x-request-id:\(xRequestId)")
        }
        if let lobLogId = value(response: httpResponse, forHTTPHeaderField: "lob-logid") {
            cacheInfo.append(" lob-logid:\(lobLogId)")
        }
        if let contentLength = value(response: httpResponse, forHTTPHeaderField: "Content-Length") {
            cacheInfo.append(" Content-Length:\(contentLength)")
        }
        if let hsts = value(response: httpResponse, forHTTPHeaderField: "Strict-Transport-Security") {
            cacheInfo.append(" Strict-Transport-Security:\(hsts)")
        }
        Self.logger.lkwlog(level: .info, cacheInfo, traceId: traceId)
    }
    
    public static func value(request: URLRequest, forHTTPHeaderField field: String) -> String? {
        return request.value(forHTTPHeaderField: field)
    }
    
    public static func value(response: HTTPURLResponse, forHTTPHeaderField field: String) -> String? {
        if #available(iOS 13.0, *) {
            return response.value(forHTTPHeaderField: field)
        } else {
            return response.allHeaderFields.first { (key: AnyHashable, value: Any) in
                if let key = key as? String, key == field {
                    return true
                } else {
                    return false
                }
            }?.value as? String
        }
    }
}
