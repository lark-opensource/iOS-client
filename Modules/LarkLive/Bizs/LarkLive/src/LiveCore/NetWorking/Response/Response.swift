//
//  Response.swift
//  LarkLiveAPI
//
//  Created by lvdaqian on 2021/1/11.
//

import Foundation

public protocol LiveResponseType {
    static func build(from: Data) -> Result<Self, Error>
}

extension LiveResponseType where Self: Codable {
    public static func build(from: Data) -> Result<Self, Error> {
        do {
            let data = try JSONDecoder().decode(Self.self, from: from)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
}

extension String: LiveResponseType {
    public static func build(from: Data) -> Result<String, Error> {
        if let value = String(data: from, encoding: .utf8) {
            return .success(value)
        } else {
            return .failure(NSError())
        }
    }
}

///
public struct Response<T: Codable>: Codable, LiveResponseType {

    public let code: Int
    public var data: T?
}

public struct BasicResponse: Codable, LiveResponseType {

    public let code: Int
}

public struct ErrorResponse: Codable, LiveResponseType {

    public let code: Int
    public let msg: String?
}

public struct EmptyResponse: LiveResponseType {
    public static func build(from: Data) -> Result<EmptyResponse, Error> {
        return .success(EmptyResponse())
    }
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
    case liveDeleted = 6000 // 直播被删除
    case encryptKeyDeleted = 8003 // 密钥被删除
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
        case .liveDeleted: return "\(rawValue) 直播被删除"
        case .encryptKeyDeleted: return "\(rawValue) 直播密钥被删除"
        }
    }
}
