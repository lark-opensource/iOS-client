//
//  OpenPluginNetworkRequestParams.swift
//  OPPlugin
//
//  Created by MJXin on 2021/12/15.
//

import Foundation

struct OpenPluginNetworkRequestParamsPayload: OpenPluginNetworkParamsPayloadProtocol, Codable {
    let url: String
    let method: String?
    let taskID: String
    let usePrefetchCache: Bool?
    let responseType: String?
    private enum CodingKeys : String, CodingKey {
        case url, method, usePrefetchCache, responseType, taskID = "requestTaskId"
    }
}

struct OpenPluginNetworkRequestParamsExtra: Codable {
    let ua: String?
    let cookie: [String]?
    let referer: String?
    let timeout: UInt?
    
    init(cookies: [String]?, originUA: String?, referer: String?, timeout: UInt?){
        self.ua = originUA
        self.cookie = cookies
        self.referer = referer
        self.timeout = timeout
    }
}


struct OpenPluginNetworkRequestResultExtra: OpenPluginNetworkResultExtraProtocol, Codable {
    let url: String?
    let cookie: [String]?
    let statusCode: Int?
    let podfile: OpenPluginNetworkPodfile?
}

struct OpenPluginNetworkPodfile: Codable {
    let requestConcurrentCount: Int?
    let enqueueQueueLength: Int64?
    let requestEnqueueMS: Int64?
    let requestQueuingElapsedMS: Int64?
    let requestCostMS: Int64?
    let requestEndMS: Int64?
    let requestTotalMS: Int64?

    private enum CodingKeys : String, CodingKey {
        case requestConcurrentCount = "request_concurrent_count"
        case enqueueQueueLength = "enqueue_queue_length"
        case requestEnqueueMS = "request_enqueue_ms"
        case requestQueuingElapsedMS = "request_queuing_elapsed_ms"
        case requestCostMS = "request_cost_ms"
        case requestEndMS = "request_end_ms"
        case requestTotalMS = "request_total_ms"
    }
}
