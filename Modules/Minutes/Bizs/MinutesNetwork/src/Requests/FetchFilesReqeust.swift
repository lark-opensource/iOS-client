//
//  FetchFilesReqeust.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

struct FetchFilesReqeust: Request {

    typealias ResponseType = Response<List<FileInfo>>

    let endpoint: String = "/minutes/api/files"
    let requestID: String = UUID().uuidString
    let objectToken: String
    let offset: Int?
    let size: Int?
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["offset"] = offset
        params["size"] = size
        return params
    }
}
