//
//  HomeSpaceListRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/7/9.
//

import Foundation

struct HomeSpaceListRequest: Request {

    typealias ResponseType = Response<MinutesSpaceList>

    let endpoint: String = "/minutes/api/space/list"
    let requestID: String = UUID().uuidString
    let timestamp: String
    let spaceName: MinutesSpaceType
    let size: Int?
    let ownerType: MinutesOwnerType?
    let rank: MinutesRankType?
    let asc: Bool?

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["timestamp"] = timestamp
        params["space_name"] = spaceName.rawValue
        params["size"] = size
        params["owner_type"] = ownerType?.rawValue
        params["rank"] = rank?.rawValue
        params["asc"] = asc
        return params
    }
}
