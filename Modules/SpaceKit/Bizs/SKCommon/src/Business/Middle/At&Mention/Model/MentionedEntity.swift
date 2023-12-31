//
//  MentionedEntity.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/5/10.
//  


import Foundation
import SwiftyJSON
import SpaceInterface

public final class MentionedEntity {
    
    public final class UserModel {
        /// 用户id
        public var id = ""
        /// 中文名字
        public var cn_name = ""
        /// 英文名字
        public var en_name = ""
        /// 别名结构化字段
        public var aliasInfo: UserAliasInfo?
    }
    
    public final class DocModel {
        /// 标题
        public var title: String?
        /// DocsType
        public var doc_type: DocsType = .unknownDefaultType
        /// 本地加的字段
        public var token = ""
    }
    
    var users = [String: UserModel]() // key: userId
    
    var metas = [String: DocModel]() // key: token
    
    private init() {}
}

extension MentionedEntity {
    
    static var empty: MentionedEntity {
        MentionedEntity.init()
    }
    
    static func parseDictionary(_ dict: [String: Any]) -> MentionedEntity {
        let result = MentionedEntity()
        let entities = (dict["entities"] as? [String: Any]) ?? [:] // entities 中的实体
        let json = JSON(entities)
        
        let usersDict = json["users"].dictionaryValue
        result.users = [:]
        for (key, value) in usersDict {
            let model = UserModel()
            model.id = value["id"].stringValue
            model.cn_name = value["cn_name"].stringValue
            model.en_name = value["en_name"].stringValue
            model.aliasInfo = UserAliasInfo(json: value["display_name"])
            result.users.updateValue(model, forKey: key)
        }
        
        let docsDict = json["obj_meta"].dictionaryValue
        result.metas = [:]
        for (key, value) in docsDict {
            let model = DocModel()
            model.token = key
            model.title = value["title"].string
            model.doc_type = DocsType(rawValue: value["doc_type"].intValue)
            result.metas.updateValue(model, forKey: key)
        }
        
        return result
    }
}

public struct FeedMessagesWithMetaInfo {
    /// feed消息列表
    public let messages: [FeedMessageModel]
    /// feed消息中的用户\文档信息
    public let entity: MentionedEntity
    /// 文档是否开启消息通知(免打扰关闭)
    public let isRemind: Bool?
}
