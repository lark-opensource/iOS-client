//
//  NetworkRequestJsonSerializer.swift
//  OfflineResourceManager
//
//  Created by bytedance on 2021/11/24.
//

import Foundation
import TTNetworkManager

final class NetworkRequestJsonSerializer: TTDefaultHTTPRequestSerializer {

    override func urlRequest(withURL URL: String!,
                             headerField headField: [AnyHashable: Any]!,
                             params: Any!, method: String!,
                             constructingBodyBlock bodyBlock: TTConstructingBodyBlock!,
                             commonParams commonParam: [AnyHashable: Any]!) -> TTHttpRequest! {
        let request: TTHttpRequest = super.urlRequest(withURL: URL,
                                                      headerField: headField,
                                                      params: params,
                                                      method: method,
                                                      constructingBodyBlock: bodyBlock,
                                                      commonParams: commonParam)
        if let params = params as? [AnyHashable: Any], !params.isEmpty {
            let postData: Data? = try? JSONSerialization.data(withJSONObject: params as Any,
                                                              options: JSONSerialization.WritingOptions.fragmentsAllowed)
            request.httpBody = postData
            return request
        }
        return request
    }
}
