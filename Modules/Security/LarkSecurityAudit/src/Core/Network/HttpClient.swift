//
//  HttpClient.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/24.
//

import Foundation
import LarkRustHTTP

enum SecurityAuditError: Error {
    case unknown
    case mergeDataFail
    case badHTTPStatusCode(code: Int, body: String, length: Int)
    case badBizCode(code: Int)
    case badServerData
    case serializeDataFail
}

final class HTTPClient {

    static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Const.requestTimeout
        configuration.protocolClasses = [RustHttpURLProtocol.self]
        return URLSession(configuration: configuration)
    }()

    func request(url: URL, body: Data, complete: @escaping (Result<Data, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = Const.requestTimeout
        request.httpBody = body
        let reqId = UUID().uuidString
        request.allHTTPHeaderFields = [
            Const.xRequestId: "\(reqId)\(SecurityAuditManager.shared.sidecar)",
            Const.contentType: Const.applicationPB,
            Const.suiteSessionKey: SecurityAuditManager.shared.conf.session
        ]
        let dataTask = Self.session.dataTask(with: request, completionHandler: { (data, resp, error) in
            if let data = data, let resp = resp as? HTTPURLResponse {
                if resp.statusCode == Const.httpStatusOK {
                    complete(.success(data))
                } else {
                    let err = SecurityAuditError.badHTTPStatusCode(
                        code: resp.statusCode,
                        body: String(data: data, encoding: .utf8) ?? Const.empty,
                        length: data.count
                    )
                    complete(.failure(err))
                }
            } else if let error = error {
                complete(.failure(error))
            } else {
                complete(.failure(SecurityAuditError.unknown))
            }
        })
        dataTask.resume()
    }

}
