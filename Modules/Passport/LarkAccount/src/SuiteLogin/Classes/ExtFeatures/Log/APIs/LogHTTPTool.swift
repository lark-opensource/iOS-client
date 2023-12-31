//
//  LogHTTPTool.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/8/13.
//

import Foundation

class LogSessionManager: BaseSessionManager {

    var forceDisableRustProxy: Bool {
        return PassportSwitch.shared.forceDisableLogRustHTTP
    }

    override var sessionType: SessionType {
        if forceDisableRustProxy {
            return .native
        }
        return super.sessionType
    }
}

class LogHTTPTool {
    private var logDomain: String? { PassportConf.shared.serverInfoProvider.getDomain(.ttGraylog).value }

    required init() {
        UploadLogManager.logger.info("upload log with new domain: \(String(describing: logDomain))", method: .local)
    }

    private lazy var sessionManager: SessionManager = {
        return LogSessionManager()
    }()

    func request(body: UploadLogRequestBody, success: @escaping (() -> Void), failure: @escaping ((_ error: Error) -> Void), isRetry: Bool = false) {
        guard let urlString = self.url else {
            let msg = "not config log url"
            assertionFailure(msg)
            UploadLogManager.logger.error(msg)
            return
        }
        guard let url = URL(string: urlString) else {
            let msg = "invalid url: \(urlString)"
            assertionFailure(msg)
            UploadLogManager.logger.error(msg)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.httpBody = try? JSONSerialization.data(withJSONObject: body.dict(), options: [])
        let reqId = UUID().uuidString
        request.allHTTPHeaderFields = [
            "X-Request-ID": reqId,
            "Content-Type": "application/json"
        ]
        let sessionType = sessionManager.sessionType
        let session = self.sessionManager.session
        let retryTag = isRetry ? "retry " : ""
        UploadLogManager.logger.info("start upload log \(retryTag)req_id: \(reqId) mode: \(sessionType)")
        DispatchQueue.global().async {
            let dataTask = session.dataTask(with: request) { (data, _, error) in
                if let data = data {
                    UploadLogManager.logger.info("finish upload log \(retryTag)success req_id: \(reqId) mode: \(sessionType)")
                    success()
                    #if DEBUG
                    if let result = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? NSDictionary {
                        print("UploadLog result: \(result)")
                    } else {
                        print("UploadLog json serial error")
                    }
                    #endif
                } else if let error = error {
                    UploadLogManager.logger.info("finish upload log \(retryTag)fail req_id: \(reqId) error: \(error) mode: \(sessionType)")
                    failure(error)
                    #if DEBUG
                    print("UploadLog error: \(error)")
                    #endif
                }
            }
            dataTask.resume()
        }
    }

    private var url: String? {
        if let domain = logDomain {
            return "https://\(domain)/collect/log/v1/"
        } else {
            return nil
        }
    }
}
