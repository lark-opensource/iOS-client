//
//  SpaceThumbnailStatistic.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/19.
//  

import SKFoundation
import SpaceInterface

public enum SpaceThumbnailStatistic {
    
    public enum Source: String {
        case spaceList = "space_list"  // docs tab中的所有列表页
        case spaceListIcon = "space_list_icon"
        case chat // 会话
        case template // 新建文件--自定义模板的图片
        case announcement // lark会话中的群公告
        case vcfollow // 视频会议
        case unknown = ""
        case wikiSpace
    }

    struct Result {
        let source: Source
        let isSucceed: Bool
        let fileType: DocsType
        let url: String
        // 缓存请求成功时，非 304 传 true
        var isUpdate: Bool
        var errorMsg: String?
        var code: Int?
    }

    static func report(result: Result) {
        let encryptURL = DocsTracker.encrypt(id: result.url)
        let statusCode: String
        if let code = result.code {
            statusCode = String(code)
        } else {
            statusCode = ""
        }
        let params: [String: String] = [
            "source": result.source.rawValue,
            "status_name": result.isSucceed ? "1" : "0",
            "file_type": result.fileType.name,
            "url": encryptURL,
            "is_update": result.isUpdate ? "1" : "0",
            "is_new": "1",
            "errorMsg": result.errorMsg ?? "",
            "network_status": DocsNetStateMonitor.shared.isReachable ? "1": "0",
            "response_status_code": statusCode
        ]
        DocsTracker.log(enumEvent: .thumbnailRequestResult, parameters: params)
    }

    struct Info {
        let isEncrypt: Bool
        let fileType: DocsType
        let source: Source
        let costTime: Int
        let fileSize: Int
    }

    static func report(info: Info) {
        let params: [String: Any] = [
            "is_encrypt": info.isEncrypt ? "1" : "0",
            "file_type": info.fileType.name,
            "source": info.source.rawValue,
            "time_cost_ms": info.costTime,
            "file_size": info.fileSize
        ]
        DocsTracker.log(enumEvent: .thumbnailInfo, parameters: params)
    }
}
