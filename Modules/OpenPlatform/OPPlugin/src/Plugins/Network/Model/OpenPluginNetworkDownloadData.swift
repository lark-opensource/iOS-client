//
//  OpenPluginNetworkDownloadData.swift
//  OPPlugin
//
//  Created by MJXin on 2022/1/16.
//

import Foundation

/// 下载的 JSSDK 入参数据结构, 包含了 JSSDK 序列化后的业务入参
/// 详见 JSSDK  <-> 客户端 部分: https://bytedance.feishu.cn/wiki/wikcnkk0882N9RppUoeHigDEmTe
/// 用于端上处理逻辑(如获取 cookie 等, 最终形态是没有这个数据结构, JSSDK 直接对接 Rust. 但目前部分基建还不在 rust 实现)
struct OpenPluginNetworkDownloadParamsPayload: OpenPluginNetworkParamsPayloadProtocol, Codable {
    let url: String
    let taskID: String
    let filePath: String?
    let method: String?
    private enum CodingKeys : String, CodingKey {
        case url, taskID = "downloadTaskId", filePath, method
    }
}

/// 下载的 客户端-> Rust 通信数据结构 extra 部分
/// 详见 客户端 <->  Rust 的 request extra 数据部分: https://bytedance.feishu.cn/wiki/wikcnkk0882N9RppUoeHigDEmTe
/// 用于描述端上提供上下文数据
struct OpenPluginNetworkDownloadParamsExtra: Codable {
    let downloadFilePath: String
    let ua: String?
    let cookie: [String]?
    let referer: String?
    let timeout: UInt?
    
    init(downloadFilePath: String, cookies: [String]?, originUA: String?, referer: String?, timeout: UInt?){
        self.ua = originUA
        self.cookie = cookies
        self.referer = referer
        self.timeout = timeout
        self.downloadFilePath = downloadFilePath
    }
}

/// 下载的 Rust->客户端 -> JSSDK 进度的数据结构
/// 详见 onProgressUpdate 部分: https://bytedance.feishu.cn/wiki/wikcnkk0882N9RppUoeHigDEmTe
/// 用于描述下载进度
struct OpenPluginNetworkDownloadProgressData: Codable {
    let uploadTaskId: String
    let totalBytesSent: UInt
    let totalBytesExpectedToSend: UInt
    let progress: UInt
}

/// 下载的 Rust->客户端 -> JSSDK 返回结果数据结构
/// 详见 客户端 <->  Rust  Response payload 部分: https://bytedance.feishu.cn/wiki/wikcnkk0882N9RppUoeHigDEmTe
/// 用于描述返回结果
struct OpenPluginNetworkDownloadResultPayload: Codable {
    var tempFilePath: String?
    var statusCode: Int?
}

/// 下载的 Rust -> 客户端 返回结果数据结构
/// 详见 客户端 <->  Rust  Response extra 部分: https://bytedance.feishu.cn/wiki/wikcnkk0882N9RppUoeHigDEmTe
/// 用于 rust-sdk 传给端上供端上处理的数据
struct OpenPluginNetworkDownloadResultExtra: OpenPluginNetworkResultExtraProtocol, Codable {
    let url: String?
    let downloadFilePath: String
    let suggestedFileName: String
    let cookie: [String]?
    let statusCode: Int?

    func realSuggestedFileName() -> String {
        guard suggestedFileName.contains("/") else {
            return suggestedFileName
        }
        return suggestedFileName.replacingOccurrences(of: "/", with: "_")
    }
}
