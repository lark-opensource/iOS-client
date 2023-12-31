//
//  OpenPluginNetworkUploadData.swift
//  OPPlugin
//
//  Created by MJXin on 2021/12/27.
//

import Foundation

struct OpenPluginNetworkUploadParamsPayload: OpenPluginNetworkParamsPayloadProtocol, Codable {
    let url: String
    let taskID: String
    let filePath: String
    let name: String
    let method: String?
    private enum CodingKeys : String, CodingKey {
        case url, taskID = "uploadTaskId", filePath, name, method
    }
}

struct OpenPluginNetworkUploadParamsExtra: Codable {
    let realFilePath: String
    let ua: String?
    let cookie: [String]?
    let referer: String?
    let timeout: UInt?
    
    init(realFilePath: String, cookies: [String]?, originUA: String?, referer: String?, timeout: UInt?){
        self.ua = originUA
        self.cookie = cookies
        self.referer = referer
        self.timeout = timeout
        self.realFilePath = realFilePath
    }
}

struct OpenPluginNetworkUploadProgressData: Codable {
    let uploadTaskId: String
    let totalBytesSent: UInt
    let totalBytesExpectedToSend: UInt
    let progress: UInt
}


struct OpenPluginNetworkUploadResultExtra: OpenPluginNetworkResultExtraProtocol, Codable {
    let url: String?
    let cookie: [String]?
    let statusCode: Int?
}
