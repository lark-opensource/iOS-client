//
//  OpenPluginNetworkRequestAbortData.swift
//  OPPlugin
//
//  Created by MJXin on 2021/12/15.
//

import Foundation
struct OpenPluginNetworkRequestAbortParamsPayload: Codable {
    let taskID: String
    private enum CodingKeys : String, CodingKey {
        case taskID = "requestTaskId"
    }
}
