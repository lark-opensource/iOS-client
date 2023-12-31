//
//  ApiRustHTTPProtocol.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/8/15.
//
import LarkRustHTTP
import RustPB
import LKCommonsLogging

typealias FetchRequest = RustPB.Tool_V1_FetchRequest

class ApiRustHTTPURLProtocol: RustHttpURLProtocol {

    private static let logger = Logger.plog(ApiRustHTTPURLProtocol.self, category: "SuiteLogin.ApiRustHTTP")

    override func willStartRequestServer(request: FetchRequest?) {
        super.willStartRequestServer(request: request)
        guard let req = request else { return }

        let requestId = req.headers.first { (header) -> Bool in
            return header.name.lowercased() == "x-request-id"
        }?.value

        guard let reqId = requestId else {
            return
        }

        ApiRustHTTPURLProtocol.logger.info("use rust proxy req_id: \(reqId) task_id: \(req.requestID)")
    }
}
