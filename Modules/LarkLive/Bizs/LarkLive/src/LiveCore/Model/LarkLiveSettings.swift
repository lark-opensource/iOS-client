//
//  LarkLiveSettings.swift
//  ByteView
//
//  Created by 李全民 on 2021/1/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

struct LarkLiveSettings: Decodable {
    let liveHosts: [String]?
    let livePaths: [String]?
    let liveUrls: [String]?
    let liveNative: Bool?
}

struct NewLarkLiveSettings: Codable {
    let liveHosts: [String]?
    let livePaths: [String]?
    let liveUrls: [String]?
    let liveNative: Bool?
    let liveHostRules: [NewLarkLiveRule]?
}

struct NewLarkLiveRule: Codable {
    let host: String
    let paths: [String]
}

struct LiveQuicFallbackRules: Decodable {
    let ignoreErrorCode: Bool?
}

struct LiveQuicLibraAB: Decodable {
    let useLibraAB: Bool?
}

struct LiveNodeOptimizeConfig: Decodable {
    let useNodeOptimize: Bool?
}



