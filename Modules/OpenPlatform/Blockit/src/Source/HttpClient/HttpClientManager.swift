//
//  HttpClientManager.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/10/10.
//

import Foundation
import LKCommonsLogging
import LarkRustHTTP
import ECOInfra
import LarkLocalizations

final class HttpClientManager {
    static let logId: String = "x-tt-logid"

    private let config: BlockitConfig

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [ECOMonitorRustHttpURLProtocol.self]
        let urlSession = URLSession(configuration: config)
        return urlSession
    }()

    init(config: BlockitConfig) {
        self.config = config
    }

    // MARK: - 发送POST请求
    func post(
        path: String,
        params: [String: Any],
        headers: [String: String] = [:],
        success: @escaping ([String: Any]) -> Void,
        failure: @escaping (Error) -> Void
    ) {

        let urlString = config.urlPrefix + path
        guard let url = HttpSerializer.encode(urlString) else {
            Blockit.log.error("url: \(urlString) error: \(encodingError)")
            failure(encodingError)
            return
        }

        var request = URLRequest(url: url, cachePolicy: config.cachePolicy)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": config.contentType,
            "Cookie": "session=\(config.token)",
            "Accept-Language": LanguageManager.currentLanguage.localeIdentifier
        ]
        if !headers.isEmpty {
            if let defaultHeaders = request.allHTTPHeaderFields {
                var updatedHeaders = defaultHeaders
                headers.forEach { (key, value) in
                    updatedHeaders[key] = value
                }
                request.allHTTPHeaderFields = updatedHeaders
            } else {
                request.allHTTPHeaderFields = headers
            }
        }

        guard let data = HttpSerializer.toData(params) else {
            Blockit.log.error("url: \(urlString) error: \(serializationError)")
            failure(serializationError)
            return
        }
        request.httpBody = data
        send(request, success: success, failure: failure)
    }

    func send(
        _ request: URLRequest,
        success: @escaping ([String: Any]) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let startTime = CFAbsoluteTimeGetCurrent()
            let dataTask = self.session.dataTask(with: request) { (data, response, error) in
                let endTime = CFAbsoluteTimeGetCurrent()
                let cost = "\(Int((endTime - startTime) * 1000))ms"
                let info = self.getInfo(response, cost: cost)
                if let error = error {
                    /// 返回 error 时，response 为空，取不到 logId，因此 error.userInfo 不带上 logId 信息
                    Blockit.log.error("info: \(info) error: \(error)")
                    failure(error)
                    return
                }

                guard let _ = response as? HTTPURLResponse else {
                    /// URLResponse 没有 allHeaderFields 属性，不能取 logId，因此 error.userInfo 不带上 logId 信息
                    let error = NSError(domain: "cannot get HTTPURLResponse", code: -1, userInfo: nil)
                    Blockit.log.error("url: \(request.url?.safeURLString), cost:\(cost), error: \(error)")
                    failure(error)
                    return
                }

                let logId = response?.allHeaderFields[Self.logId] as? String
                guard let data = data else {
                    let error = NSError(domain: "data = null", code: -1, userInfo: [Self.logId : logId ?? ""])
                    Blockit.log.error("info: \(info) error: \(error)")
                    failure(error)
                    return
                }

                if var json = HttpSerializer.toObject(data) as? [String: Any] {
                    if let ttLogId = logId {
                        json[Self.logId] = ttLogId
                    }
                    success(json)
                    Blockit.log.info("success: info: \(info)")
                } else {
                    let error = NSError(domain: "serialization failure", code: -1, userInfo: [Self.logId : logId ?? ""])
                    Blockit.log.error("info: \(info) error: \(error)")
                    failure(error)
                }
            }
            dataTask.resume()
        }
    }

    private func getInfo(_ response: URLResponse?, cost: String) -> String {
        guard let response = response as? HTTPURLResponse else {
            return "cannot get HTTPURLResponse"
        }
        let header = response.allHeaderFields
        let resId = "X-Request-Id"
        let loblogId = "lob-logid"
        let ttlogId = "x-tt-logid"
        let date = "Date"
        var info = "date: \(header[date]), url: \(response.url?.safeURLString), statusCode: \(response.statusCode),"
        info.append("resId: \(header[resId]), loblogId: \(header[loblogId]), ttlogId:\(header[ttlogId]), cost: \(cost)")
        return info
    }

    private var serializationError: Error = {
        return NSError(domain: "serialization failure", code: -1, userInfo: nil)
    }()

    private var encodingError: Error = {
        return NSError(domain: "url encoding failure", code: -1, userInfo: nil)
    }()
}
