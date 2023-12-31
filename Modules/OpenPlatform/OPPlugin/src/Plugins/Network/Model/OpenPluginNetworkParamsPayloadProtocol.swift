//
//  OpenPluginNetworkParamsPayloadProtocol.swift
//  OPPlugin
//
//  Created by MJXin on 2021/12/27.
//

import Foundation

protocol OpenPluginNetworkParamsPayloadProtocol {
    var url: String { get }
    var taskID: String { get }
    var method: String? { get }
}

protocol OpenPluginNetworkResultExtraProtocol {
    var url: String? { get }
    var cookie: [String]? { get }
    var statusCode: Int? { get }
}
