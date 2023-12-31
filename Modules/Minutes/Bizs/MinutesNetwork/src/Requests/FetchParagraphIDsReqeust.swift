//
//  FetchParagraphIDsReqeust.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

struct FetchParagraphIDsReqeust: Request {

    typealias ResponseType = Response<List<ParagraphID>>

    let endpoint: String = "/minutes/api/subtitles/paragraph-ids"
    let requestID: String = UUID().uuidString
    let objectToken: String
    let pageNum: Int?
    let pageSize: Int?

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["page_num"] = pageNum
        params["page_size"] = pageSize
        return params
    }
}
