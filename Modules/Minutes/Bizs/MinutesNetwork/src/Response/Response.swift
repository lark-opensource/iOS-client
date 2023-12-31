//
//  Response.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/11.
//

import Foundation

public protocol MinutesResponseType {
    static func build(from: Data) -> Result<Self, Error>
}

extension MinutesResponseType where Self: Codable {
    public static func build(from: Data) -> Result<Self, Error> {
        do {
            let data = try JSONDecoder().decode(Self.self, from: from)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
}

extension String: MinutesResponseType {
    public static func build(from: Data) -> Result<String, Error> {
        if let value = String(data: from, encoding: .utf8) {
            return .success(value)
        } else {
            return .failure(NSError())
        }
    }
}

///
public struct Response<T: Codable>: Codable, MinutesResponseType {

    public let code: Int
    public let data: T
}

public struct BasicResponse: Codable, MinutesResponseType {

    public let code: Int
}

public struct ErrorResponse: Codable, MinutesResponseType {

    public let code: Int
    public let msg: String?
    public let newMsg: MinutesCommonErrorMsg?
}

public struct EmptyResponse: MinutesResponseType {
    public static func build(from: Data) -> Result<EmptyResponse, Error> {
        return .success(EmptyResponse())
    }
}

public struct UploadResponse: Codable, MinutesResponseType {

    public let code: Int
    public let msg: String?
}

public enum ResponseError: Int, Error, Equatable {
    case requestError = 400 // 请求参数或者数据有错
    case authFailed = 401 // 用户未登录
    case noPermission = 403 // 用户无相关操作权限
    case pathNotFound = 404 // 路径错误
    case uploadCompleted = 406 // 上传已经结束
    case inRecording = 409 // 正在录音
    case resourceDeleted = 410 // 相关资源已被删除
    case serverError = 500 // 服务器错误
    case uploadTimeout = 4061 // 上传超时
    case invalidJSONObject = 4070 // 无效JSON格式
    case invalidData = 4071 // 无效DATA数据
    case invalidURL = 4072 // 无效URL
    case noInternet = -1 // 无网络
}

public enum UploadResponseError: Error {
    case error(with: Error, data: Any?, statusCode: Int, logId: String)
}

// https://bytedance.feishu.cn/docx/J6KzdnOhCoV3rwxxQmxcO2Obn3E
public enum UploadBizCode: Int, Error, Equatable {
    case success = 0                        // 上传成功
    case notRecordMinutes = 1000130040      // 妙记不是录音
    case uploadCompleted = 1000130041        // 妙记已经上传完成
    case keyDeleted = 11010      // 租户密钥已经删除
    case durationTimeout = 1000130043      // 录音超过4小时不允许上传
    case getKeyFailed = 1000130044   // 获取密钥失败
    case encryptFailed = 1000130045       // 加密失败
    case uploadTosFailed = 1000130046   // 上传 tos 失败
    case abaseFailed = 1000130047       // 设置 abase 失败
    case deviceGrabbed = 1000130048     // 设备被抢占
    case transcodeFailed = 1000130049  // 转码失败
    case unknown = -1  // 未知业务码
}

extension ResponseError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .requestError: return "\(rawValue) 请求参数或者数据有错"
        case .authFailed: return "\(rawValue) 用户未登录"
        case .noPermission: return "\(rawValue) 用户无相关操作权限"
        case .pathNotFound: return "\(rawValue) 路径错误"
        case .uploadCompleted: return "\(rawValue) 上传已经结束"
        case .inRecording: return "\(rawValue) 正在录音"
        case .resourceDeleted: return "\(rawValue) 相关资源已被删除"
        case .serverError: return "\(rawValue) 服务器错误"
        case .uploadTimeout: return "\(rawValue) 上传超时"
        case .invalidJSONObject: return "\(rawValue) 无效JSON格式"
        case .invalidData: return "\(rawValue) 无效DATA数据"
        case .invalidURL: return "\(rawValue) 无效URL"
        case .noInternet: return "\(rawValue) 无网络"
        }
    }
}

extension UploadBizCode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success: return "\(rawValue) upload success"
        case .notRecordMinutes: return "\(rawValue) not record minutes"
        case .uploadCompleted: return "\(rawValue) upload already completed"
        case .keyDeleted: return "\(rawValue) key deleted"
        case .durationTimeout: return "\(rawValue) duration timeout"
        case .getKeyFailed: return "\(rawValue) get key failed"
        case .encryptFailed: return "\(rawValue) encrypt failed"
        case .uploadTosFailed: return "\(rawValue) upload tos failed"
        case .abaseFailed: return "\(rawValue) abase failed"
        case .deviceGrabbed: return "\(rawValue) device grab"
        case .transcodeFailed: return "\(rawValue) transcode failed"
        case .unknown: return "\(rawValue) unknown biz code"
        }
    }
}
