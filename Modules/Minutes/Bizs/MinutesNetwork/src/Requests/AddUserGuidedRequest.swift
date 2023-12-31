//
//  AddUserGuidedRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2022/1/4.
//

import Foundation

struct AddUserGuidedRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/user/guide/add"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let guideType: String
    var catchError: Bool
    
    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["guide_type"] = guideType
        return params
    }
}
