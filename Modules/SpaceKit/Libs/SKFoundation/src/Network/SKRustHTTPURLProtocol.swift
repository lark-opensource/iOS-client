//
//  SKRustHTTPURLProtocol.swift
//  SKFoundation
//
//  Created by chenhuaguan on 2020/7/15.
//

import LarkRustHTTP
import RustPB

open class SKRustHTTPURLProtocol: RustHttpURLProtocol {
    public override func willStartRequestServer(request: FetchRequest?) {
        super.willStartRequestServer(request: request)
        guard let req = request else { return }

        let requestId = req.headers.first { (header) -> Bool in
            return header.name.lowercased() == "request-id"
        }?.value
        
        let logId = req.headers.first { (header) -> Bool in
            return header.name.lowercased() == DocsCustomHeader.xttLogId.rawValue
        }?.value

        guard let reqId = requestId else {
            return
        }

        DocsLogger.info("sknetinfo: docs_request_id=\(reqId), \(DocsCustomHeader.xttLogId.rawValue)=\(String(describing: logId)), task_id= \(req.requestID)", component: LogComponents.net)
    }
}
