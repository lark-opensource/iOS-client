//
//  FileListDataModelDefines.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/5/28.
//
//列表里的数据结构类型

import Foundation

public enum FileListDefine {

    /// 出现在目录结构树里的唯一标识
    public typealias NodeToken = String

    /// 打开文档/文件夹时，url的一部分，也是唯一标识
    public typealias ObjToken = String
    public typealias UserID = String
    public typealias Key = String
    public typealias ObjInfo  = [FileListDefine.Key: Any]
    public typealias Node  = [FileListDefine.Key: Any]
//    public typealias Nodes = [FileListDefine.NodeToken: [FileListDefine.Key: Any]]
    

    public typealias User  = [FileListDefine.Key: Any]
    public typealias Users = [FileListDefine.UserID: User]
}

public struct TokenStruct: Hashable {
    public let token: String  //nodeToken和objToken都有可能
    public let nodeType: Int
    public var isShortCut: Bool { nodeType == 1 }

    public init(token: String, nodeType: Int) {
        self.token = token
        self.nodeType = nodeType
    }
    public init(token: String) {
        self.token = token
        self.nodeType = 0
    }

    //nodeToken是唯一的，所以这里可以不判断nodeType
    public func contain(nodeToken: String) -> Bool {
        return token == nodeToken
    }
    //在确定不可能为shortCut的情况下，可以使用这个方法
    public func contain(objToken: String) -> Bool {
        return token == objToken
    }
}

extension Array where Element == TokenStruct {
    public func contain(nodeToken: String) -> Bool {
        return first(where: { $0.contain(nodeToken: nodeToken) }) != nil
    }
    //在确定不可能为shortCut的情况下，可以使用这个方法
    public func contain(objToken: String) -> Bool {
        return first(where: { $0.contain(objToken: objToken) }) != nil
    }
}

extension FileListDefine.ObjToken {
    public var isFakeToken: Bool {
        return hasPrefix("fake_")
    }
}

/// 后台定义的字段
public enum FileListServerKeys: String {
    case type
    case token
    case objToken = "obj_token"
    case name
    case editTime = "edit_time"
    case editUid = "edit_uid"
    case extra
    case subtype
    case ownerId = "owner_id"
    case shareId = "sharer_id"
    case isPined = "is_pined"
    case isShareRoot = "is_share_root"
    case spaceId = "space_id"
    case isTop = "is_top"
    case isHiddenStatus = "is_hidden_status"
    case shareVersion = "share_version"
    case ownerType = "owner_type"
    case thumbnailExtra = "thumbnail_extra"
    // 下面三个icon开头的是自定义icon相关字段名称
    case iconKey = "icon_key"
    case iconType = "icon_type"
    case iconFSUnit = "icon_fsunit"
    case nodeType = "node_type"
    case isShareFolder = "is_share_folder"
    // 密级标签名字
    case secureLabelName = "security_name"
    // 密级级别
    case secureLabelLevel = "security_level"
    // 密级id
    case secureLabelId = "security_label_id"
    // 密级详情错误码
    case secureLabelCode = "get_sec_label_code"
    // 是否可以设置密级
    case canSetSecLabel = "can_set_sec_label"
    // 秘钥是否被删除
    case secretKeyDelete = "secret_key_delete"
    // 表明 shortcut 内容指向的业务，对 wiki 是 2
    case objBizType = "obj_biz_type"
    // 表明 shortcut 内容指向业务的 node token，对 wiki 是 wiki token
    case bizNodeToken = "obj_node_token"
    // 表用 shortcut 的本体是否被删除, 1表示删除，0表示未删除
    case deleteFlag = "delete_flag"
    // 自定义icon组件显示字段
    case iconInfo = "icon_info"
    // 添加到收藏的时间
    case favoriteTime = "star_time"
}

/// 本地自定义的字段
public enum FileListNativeKeys: String {
    case realToken = "real_token"
}

public extension Dictionary where Key == String {
    subscript(key: FileListServerKeys) -> Value? {
        get {
            return self[key.rawValue]
        }
        set(newValue) {
            self[key.rawValue] = newValue
        }
    }
}
