//
//  HttpStubHelper.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by 曾浩泓 on 2022/6/2.
//  


import Foundation
import OHHTTPStubs

class HttpStubHelper {
    static func stubSuccess(apiPath: String, jsonFileName: String) {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(apiPath)
            return contain
        }, response: { _ in
            let jsonFile = jsonFileName + ".json"
            return HTTPStubsResponse(
                fileAtPath: OHPathForFile(jsonFile, self)!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
    }
}
