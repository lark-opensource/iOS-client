//
//  IMMentionParameters.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/25.
//

import Foundation

struct IMMentionSearchParameters {
    struct Chatter {
        enum ChatterType {
            case normal
            case mail
        }
        var type: ChatterType = .normal
        /// 在职
        var isWork: Bool = true
        /// 已离职
        var isResigned: Bool = false
        /// 包含内部人员 (目前一定包含)
//        var includeInner: Bool = true
        /// 包含外部人员
        var includeOuter: Bool = true
        
        var showChatterMail: Bool = false
    }
    
    struct Chat {
        var isJoined: Bool = true
        var isNotJoined: Bool = true
        var isPublic: Bool = true
        var isPrivate: Bool = true
        var isOuter: Bool = true
        var isInner: Bool = true
        /// 群聊需包含的成员 IDs，只搜索包含 ID 列表的群，默认为空，不过滤
        var includeMemberIds: [String]?
    }
    
    struct Document {
        enum DocumentType: Int {
            case unknown = 0
            case doc
            case sheet
            case bitable
            case mindnote
            case file
            case slide
            case wiki
            case docx
            case folder
            case catalog
        }
        /// 文档所有者 IDs，只搜索 ID 列表内的文档
        var creatorIds: [String]?
        /// 文档类型 Types，只搜索指定的文档类型，不设置时默认搜索全部
        var types: [DocumentType]?
        /// 仅搜索文档标题
        var isOnlyTitle: Bool = true
        /// 显示所有者 (默认显示更新时间)
        var showDocumentOwner: Bool = false
    }
    
    /// 人员-过滤配置
    var chatter: Chatter? = Chatter()
    /// 群组 过滤配置
    var chat: Chat? = Chat()
    /// 文档 过滤配置
    var document: Document? = Document()
}
