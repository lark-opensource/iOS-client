//
//  OpenPluginNetworkUploadAbortData.swift
//  OPPlugin
//
//  Created by MJXin on 2021/12/27.
//

import Foundation
struct OpenPluginNetworkUploadAbortParamsPayload: Codable {
    let taskID: String
    private enum CodingKeys : String, CodingKey {
        case taskID = "uploadTaskId"
    }
}
