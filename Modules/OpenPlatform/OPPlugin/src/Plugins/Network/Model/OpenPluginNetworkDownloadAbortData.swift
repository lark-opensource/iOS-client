//
//  OpenPluginNetworkDownloadAbortData.swift
//  OPPlugin
//
//  Created by MJXin on 2022/1/17.
//

import Foundation
struct OpenPluginNetworkDownloadAbortParamsPayload: Codable {
    let taskID: String
    private enum CodingKeys : String, CodingKey {
        case taskID = "downloadTaskId"
    }
}
