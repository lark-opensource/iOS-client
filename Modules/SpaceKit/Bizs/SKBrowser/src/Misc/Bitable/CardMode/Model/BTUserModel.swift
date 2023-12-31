//
//  BTUserModel.swift
//  DocsSDK
//
//  Created by linxin on 2020/3/17.
//  

import Foundation
import UIKit
import HandyJSON
import SKCommon
import SKFoundation

// 抽象出Chatter协议
public protocol BTChatterProtocol {
    var chatterId: String { get set }
    var name: String { get set }
    var enName: String { get set }
    var avatarUrl: String { get set }
    var avatarKey : String? { get set }
    var chatterType: BTChatterType { get }
    // 转换到BTCapsuleModel
    func asCapsuleModel(isSelected: Bool) -> BTCapsuleModel
    // 转换成JSON Dictionary，对于实例可能会需要自定义转换规则
    func toDictionary() -> [String: Any]?
}

@frozen
public enum BTChatterType: Int {
    case group
    case user
    public var logDesc: String {
        switch self {
        case .group:
            return "group"
        case .user:
            return "user"
        }
    }
}


/// 用户数据，对应前端的 `IUser`
public struct BTUserModel: BTChatterProtocol, HandyJSON, Equatable {
    
    public var chatterId: String = ""
    public var chatterType: BTChatterType { return .user }
    public var notify: Bool = false
    public var name: String = ""
    public var enName: String = ""
    public var avatarUrl: String = ""
    
    public var avatarKey: String?

    public init() {
    }
    
    public init(chatterId: String = "", notify: Bool = false, name: String = "", enName: String = "", avatarUrl: String = "") {
        self.chatterId = chatterId
        self.notify = notify
        self.name = name
        self.enName = enName
        self.avatarUrl = avatarUrl
    }
    
    public mutating func mapping(mapper: HelpingMapper) {
        mapper <<< self.chatterId <-- "userId"
    }
    
    public func asCapsuleModel(isSelected: Bool) -> BTCapsuleModel {
        let text = DocsSDK.currentLanguage == .en_US ? enName : name
        return BTCapsuleModel(id: self.chatterId,
                              text: text,
                              color: BTColorModel(),
                              isSelected: isSelected,
                              font: .systemFont(ofSize: 14, weight: .regular),
                              token: "",
                              avatarUrl: self.avatarUrl,
                              userID: self.chatterId,
                              name: self.name,
                              enName: self.enName,
                              chatterType: self.chatterType)
    }
    
    public func toDictionary() -> [String : Any]? {
        return self.toJSON()
    }
}

// 群组实例Model
public struct BTGroupModel: HandyJSON, BTChatterProtocol, Equatable {
    
    public var chatterId: String = ""
    public var name: String = ""
    public var avatarUrl: String = ""
    public var chatterType: BTChatterType { return .group }
    public var linkToken: String = ""
    public var enName: String = ""
    
    public var avatarKey: String?
    
    public init() {
    }
    
    public init(chatterId: String = "",
                name: String = "",
                avatarUrl: String = "",
                linkToken: String = "",
                avatarKey: String? = nil) {
        self.chatterId = chatterId
        self.name = name
        self.avatarUrl = avatarUrl
        self.linkToken = linkToken
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            self.avatarKey = avatarKey
        }
    }
    
    public mutating func mapping(mapper: HelpingMapper) {
        mapper <<< self.chatterId <-- "id"
    }
    
    public func toDictionary() -> [String: Any]? {
        return self.toJSON()
    }
    
    public func asCapsuleModel(isSelected: Bool) -> BTCapsuleModel {
        var model = BTCapsuleModel(id: self.chatterId,
                              text: self.name,
                              color: BTColorModel(),
                              isSelected: isSelected,
                              font: .systemFont(ofSize: 14, weight: .regular),
                              token: self.linkToken,
                              avatarUrl: self.avatarUrl,
                              userID: self.chatterId,
                              name: self.name,
                              enName: self.name,
                              chatterType: self.chatterType)
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            model.avatarKey = avatarKey
        }
        return model
    }
}
