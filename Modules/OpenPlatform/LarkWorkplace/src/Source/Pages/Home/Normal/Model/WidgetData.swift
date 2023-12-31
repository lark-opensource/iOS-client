//
//  WidgetData.swift
//  LarkWorkplace
//
//  Created by 李论 on 2020/5/14.
//

import Foundation
import SwiftyJSON

protocol WidgetBizDataReqContextProtocol: Codable {
    /// 请求时的语言环境
    var locale: String { get }
    /// 请求的用户身份
    var userID: String { get }
    /// 请求的WidgetID
    var widgetID: String { get }
    /// 请求的Widget当时的版本
    var widgetVersion: String { get }
    /// 请求附带的上下文信息
    var extraInfo: [String: String] { get set }
}

/// 对应当时请求的回包
protocol WidgetBizDataRespProtocol: Codable {
    /// 请求的WidgetID
    var widgetID: String { get }
    /// 请求的Widget当时的版本
    var widgetVersion: String { get }
    /// json串内容
    var content: String { get }
    /// Widget Data 更新的时间戳, 单位ms
    var timestamp: Int64 { get }
}

/// 单个Widget缓存的数据item
protocol WidgetBizCacheDataProtocol: Codable {
    /// 当时请求的上下文
    var reqContext: WidgetBizDataReqContextProtocol? { get set }
    /// 对应的回包信息
    var widgetBizDataResp: WidgetBizDataRespProtocol? { get set }
}

/// 整体缓存的数据结构
protocol WidgetBizCacheMapDataProtocol: Codable {
    /// Lark版本,可能存在版本之前的数据迁移，备用
    var hostVersion: String { get set }
    /// 请求的用户身份
    var userID: String { get }
    /// key 是WidgetID，value是缓存的WidgetCacheData
    var widgetBizDataMap: [String: WidgetBizCacheDataProtocol] { get set }
}

/// 本地缓存模块
protocol WidgetDataCacheProtocol {
    /// init的时候，根据当前用户的身份加载Cache
    func loadCache()
    /// 写缓存到磁盘中
    func saveCacheToDisk()
    /// 整个Widget Map缓存
    var widgetMap: WidgetBizCacheMapDataProtocol { get }
    /// 更新缓存，如果为空，表示删除缓存；首先更新内存缓存，再更新磁盘缓存
    func updateCache(widgetID: String, data: WidgetBizCacheDataProtocol?)
    /// 获取缓存
    func getWidgetData(widgetID: String) -> WidgetBizCacheDataProtocol?
}

/// 外部整体入口
protocol WidgetDataProtocol {
    /// 更新策略
    var updateLogic: GadgetDataUpdateLogicProtocol { get }
    /// 缓存对象
    var gadgetCache: WidgetDataCacheProtocol { get }
    /// 同步查询GadgetData
    func getWidgetData(widgetID: String) -> WidgetBizCacheDataProtocol?
    /// 异步请求GadgetData
    func batchRequestWidgetData(
        reqList: [WidgetBizDataReqContextProtocol],
        callback: @escaping ([WidgetBizCacheDataProtocol], Error?) -> Void
    )
}

/// Gadget更新策略，可能会增加更新频控
protocol GadgetDataUpdateLogicProtocol {
    /// 本次是否要更新
    func shouldUpdateWidgetData(widgetID: String) -> Bool
    /// 记录Widget更新业务数据
    func recordUpdateWidgetData(reqList: [WidgetBizDataReqContextProtocol])
}

final class WidgetBizDataReqContext: WidgetBizDataReqContextProtocol, Codable {

    /// 请求时的语言环境
    var locale: String = "en"
    /// 请求的用户身份
    var userID: String = ""
    /// 请求的WidgetID
    var widgetID: String = ""
    /// 请求的Widget当时的版本
    var widgetVersion: String = ""
    /// 请求附带的上下文信息
    var extraInfo: [String: String] = [:]

    enum CodingKeys: String, CodingKey {
        case locale
        case userID
        case widgetID
        case widgetVersion
        case extraInfo
    }

    init() {
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locale = try container.decode(String.self, forKey: .locale)
        userID = try container.decode(String.self, forKey: .userID)
        widgetID = try container.decode(String.self, forKey: .widgetID)
        widgetVersion = try container.decode(String.self, forKey: .widgetVersion)
        extraInfo = try container.decode(Dictionary<String, String>.self, forKey: .extraInfo)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locale, forKey: .locale)
        try container.encode(userID, forKey: .userID)
        try container.encode(widgetID, forKey: .widgetID)
        try container.encode(widgetVersion, forKey: .widgetVersion)
        try container.encode(extraInfo, forKey: .extraInfo)
    }
}

/// 对应当时请求的回包
final class WidgetBizDataResp: WidgetBizDataRespProtocol, Codable {
    /// 响应头
//    var baseRsp: WidgetBizDataBaseResp = WidgetBizDataBaseResp()
    /// 请求的WidgetID
    var widgetID: String = "en"
    /// 请求的Widget当时的版本
    var widgetVersion: String = "en"
    /// json串内容
    var content: String = "en"
    /// Widget Data 更新的时间戳, 单位ms
    var timestamp: Int64 = 0

    enum CodingKeys: String, CodingKey {
        case baseRsp
        case widgetID
        case widgetVersion
        case content
        case timestamp
    }

    init() {
    }

    convenience init(json: JSON) {
        self.init()
        widgetID = json["CardID"].stringValue
        widgetVersion = json["Version"].stringValue
        timestamp = json["CreateTime"].int64Value
        content = json["Content"].stringValue
    }

    /// 反序列化，从二进制数据反序列化为对象
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        widgetID = try container.decode(String.self, forKey: .widgetID)
        widgetVersion = try container.decode(String.self, forKey: .widgetVersion)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Int64.self, forKey: .timestamp)
    }

    /// 序列化对象到二进制数据
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(widgetID, forKey: .widgetID)
        try container.encode(widgetVersion, forKey: .widgetVersion)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

/// 单个Widget缓存的数据item
final class WidgetBizCacheData: WidgetBizCacheDataProtocol, Codable {
    /// 当时请求的上下文
    var reqContext: WidgetBizDataReqContextProtocol?
    /// 对应的回包信息
    var widgetBizDataResp: WidgetBizDataRespProtocol?

    init(
        req: WidgetBizDataReqContextProtocol,
        rsp: WidgetBizDataRespProtocol?
    ) {
        reqContext = req
        widgetBizDataResp = rsp
    }

    enum CodingKeys: String, CodingKey {
        case reqContext
        case widgetBizDataResp
    }

    /// Codable 需要实现的 Decoder 初始化方法
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reqContext = try container.decode(WidgetBizDataReqContext.self, forKey: .reqContext)
        widgetBizDataResp = try container.decode(WidgetBizDataResp.self, forKey: .widgetBizDataResp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reqContext as? WidgetBizDataReqContext, forKey: .reqContext)
        try container.encode(widgetBizDataResp as? WidgetBizDataResp, forKey: .widgetBizDataResp)
    }
}

/// 整体缓存的数据结构
final class WidgetBizCacheMapData: WidgetBizCacheMapDataProtocol, Codable {
    /// Lark版本,可能存在版本之前的数据迁移，备用
    var hostVersion: String
    /// 请求的用户身份
    var userID: String
    /// key 是WidgetID，value是缓存的WidgetCacheData
    var widgetBizDataMap: [String: WidgetBizCacheDataProtocol] = [:]

    init(hostVersion: String, userID: String) {
        self.hostVersion = hostVersion
        self.userID = userID
    }

    enum CodingKeys: String, CodingKey {
        case hostVersion
        case userID
        case widgetBizDataMap
    }

    /// Codable 需要实现的 Decoder 初始化方法
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hostVersion = try container.decode(String.self, forKey: .hostVersion)
        userID = try container.decode(String.self, forKey: .userID)
        widgetBizDataMap = try container.decode(Dictionary<String, WidgetBizCacheData>.self, forKey: .widgetBizDataMap)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hostVersion, forKey: .hostVersion)
        try container.encode(userID, forKey: .userID)
        try container.encode(widgetBizDataMap as? [String: WidgetBizCacheData], forKey: .widgetBizDataMap)
    }
}
