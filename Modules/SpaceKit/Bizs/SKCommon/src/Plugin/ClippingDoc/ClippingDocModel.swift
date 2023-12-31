//
//  ClippingDocModel.swift
//  SKCommon
//
//  Created by huayufan on 2022/6/30.
//  


import SKFoundation
import SKResource
import Foundation

// 展示前端toast信息
struct ClippingToastModel: Codable {
    enum Status: Int, Codable {
        case loading = 0
        case success = 1
        case fail = 2
    }
    
    enum FailReason: Int, Codable {
        case fail = 0
        case browserLimit = 1
        case tooLarge = 2
        case network = 3
        case unsupported = 4
        
        var failMsg: String? {
            
            switch self {
            case .fail:
                return BundleI18n.SKResource.LarkCCM_Clip_Failed
            case .browserLimit:
                return BundleI18n.SKResource.LarkCCM_Clip_ClipFailedBrowser
            case .tooLarge:
                return BundleI18n.SKResource.LarkCCM_Clip_Error_WebpageTooLarge
            case .network:
                return BundleI18n.SKResource.LarkCCM_Clip_Error_PoorInternetAccess
            case .unsupported:
                return BundleI18n.SKResource.LarkCCM_Clip_NotSupportClip
            }
        }
    }
    
    let status: Status
    var progress: Int?
    var failReason: FailReason?
    var showRetry: Bool?  
}

// 打印前端日志
struct ClippingLogModel: Codable {
    enum Level: Int, Codable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
    }
    let level: Level
    let msg: String
    let tag: String?
}


// 前端接口请求日志
struct ClippingFetchModel: Codable {
    
    struct File: Codable {
        let fileName: String // title的hash值
        let title: String // 发送给后端的title，前端已经encode过
        let paramName: String?
    }
    
    enum Method: String, Codable {
        case get = "GET"
        case post = "POST"
        
        var docMethod: DocsHTTPMethod {
            switch self {
            case .get:
                return .GET
            case .post:
                return .POST
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case url
        case headers
        case params
        case file
        case method
        case secretKey
        case timeout
    }
    
    let url: String
    let headers: [String: String]?
    let params: [String: Any]?
    let file: File?
    let method: Method
    let secretKey: String
    var timeout: Double
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decodeIfPresent(String.self, forKey: .url) ?? ""
        headers = try? values.decodeIfPresent([String: String].self, forKey: .headers)
        params = try? values.decodeIfPresent([String: Any].self, forKey: .params)
        file = try? values.decodeIfPresent(File.self, forKey: .file)
        method = try values.decodeIfPresent(Method.self, forKey: .method) ?? .get
        secretKey = try values.decodeIfPresent(String.self, forKey: .secretKey) ?? ""
        timeout = try values.decodeIfPresent(Double.self, forKey: .timeout) ?? 0
        timeout /= 1000.0
    }
    
    func encode(to encoder: Encoder) throws {
        spaceAssertionFailure()
    }

    var encodingType: ParamEncodingType {
        guard let type = headers?["Content-Type"] else {
            return .urlEncodeDefault
        }
        if type == "application/json" {
            return .jsonEncodeDefault
        } else {
            return .urlEncodeDefault
        }
    }
}


public struct ClipTimeMeasure {
    
    let begin = Date()
    
    init() {}
    
    func end() -> TimeInterval {
        return Date().timeIntervalSince1970 * 1000 - begin.timeIntervalSince1970 * 1000
    }
}
