//
//  TokenModel.swift
//  EEAtomic
//
//  Created by huanzhengjie on 2022/8/2.
//

import UIKit

@objc
public enum TokenType: Int, Codable {
    case none = 0
    case audioRecord = 1    // 麦克风录音
    case camera = 2         // 录像、拍照等
    case location = 3       // 地理位置
    case phone = 4          // 电话
    case contacts = 5        // 联系人
    case pasteboard = 6     // 粘贴板
    case mediaRecord = 7    // Android独有
    case deviceInfo = 8     // IDFA、IDFV、ssid等设备信息
    case permission = 9     // Android独有
    case album = 10         // 相册
    case calendar = 11      // 日历，iOS独有
    case faceID = 12        // 指纹、人脸识别
}

extension TokenType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .audioRecord:
            return "audioRecord"
        case .camera:
            return "camera"
        case .location:
            return "location"
        case .phone:
            return "phone"
        case .contacts:
            return "contacts"
        case .pasteboard:
            return "pasteboard"
        case .mediaRecord:
            return "mediaRecord"
        case .deviceInfo:
            return "deviceInfo"
        case .permission:
            return "permission"
        case .album:
            return "album"
        case .calendar:
            return "calendar"
        case .faceID:
            return "faceID"
        default:
            return "none"
        }
    }

    public static func stringToType(_ str: String) -> TokenType {
        switch str {
        case "audioRecord":
            return .audioRecord
        case "camera":
            return .camera
        case "location":
            return .location
        case "phone":
            return .phone
        case "contacts":
            return .contacts
        case "pasteboard":
            return .pasteboard
        case "mediaRecord":
            return .mediaRecord
        case "deviceInfo":
            return .deviceInfo
        case "permission":
            return .permission
        case "album":
            return .album
        case "calendar":
            return .calendar
        case "faceID":
            return .faceID
        default:
            return .none
        }
    }
}

enum TokenStatus: Int, Codable {
    case DISABLE = -1
    case ENABLE = 0
}

/// Token
@objc
public final class Token: NSObject {
    /// 合规平台申请的token标识，App内需保持唯一
    public let identifier: String
    /// 类型，标识场景
    public internal(set) var type: TokenType
    /// 扩展字段
    public let extraInfo: [String: Any]?

    /// 初始化
    /// - Parameters:
    ///   - identifier: Token Identifier
    @objc
    @available(*, deprecated,
                message: "We will deprecate this method, please use the init(_ identifier: String)")
    public convenience init(withIdentifier identifier: String) {
        self.init(identifier, type: .none, extraInfo: nil)
    }

    /// 初始化
    /// - Parameters:
    ///   - identifier: Token Identifier
    @objc
    public init(_ identifier: String) {
        self.identifier = identifier
        self.type = .none
        self.extraInfo = nil
    }

    /// 初始化
    /// - Parameters:
    ///   - identifier: Token Identifier
    ///   - type: Token Type
    ///   - extraInfo: 额外参数
    @available(*, deprecated,
                message: "We will deprecate this method, please use the init(_ identifier: String)")
    public init(_ identifier: String,
                type: TokenType = .none,
                extraInfo: [String: Any]? = nil) {
        self.identifier = identifier
        self.type = type
        self.extraInfo = extraInfo
    }
}

/// token的配置信息
struct TokenConfig: Codable {
    let identifier: String
    let atomicInfoList: [String]
    let status: TokenStatus

    enum CodingKeys: String, CodingKey {
        case identifier
        case atomicInfoList = "psda_atomicinfo"
        case status
    }

    public init(identifier: String, atomicInfoList: [String], status: TokenStatus) {
        self.identifier = identifier
        self.atomicInfoList = atomicInfoList
        self.status = status
    }
}

extension TokenConfig {
    static func createConfig(with data: [String: Any]) -> TokenConfig? {
        do {
            let dictData = try JSONSerialization.data(withJSONObject: data)
            return try JSONDecoder().decode(TokenConfig.self, from: dictData)
        } catch {
            let category = ParseResult(scene: .parse, errorMsg: error.localizedDescription).buildWithData(data)
            LSC.monitor?.sendInfo(service: kMonitorErrorKey, category: category, metric: nil)
            LSC.logger?.error("parse single token failure: \(error.localizedDescription)")
        }
        return nil
    }

    static func createConfigs(with data: Data) -> [TokenConfig]? {
        var jsonObj: Any?
        do {
            jsonObj = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        } catch {
            let category = ParseResult(scene: .parse, errorMsg: error.localizedDescription).buildWithData(data)
            LSC.monitor?.sendInfo(service: kMonitorErrorKey, category: category, metric: nil)
            LSC.logger?.error("parse network request failure: \(error.localizedDescription)")
        }

        guard let jsonDict = jsonObj as? NSDictionary,
              let dataDict = jsonDict["data"] as? NSDictionary,
              let dictArray = dataDict["token_config"] as? NSArray else {
            LSC.logger?.info("network request token config is nil")
            return nil
        }

        var tokenConfigList = [TokenConfig]()
        for dict in dictArray {
            guard let dict = dict as? [String: Any] else {
                continue
            }
            guard let tokenConfig = createConfig(with: dict) else {
                continue
            }
            tokenConfigList.append(tokenConfig)
        }
        return tokenConfigList
    }
}
