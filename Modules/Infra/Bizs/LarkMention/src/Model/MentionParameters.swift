//
//  MentionParameters.swift
//  LarkMention
//
//  Created by Yuri on 2022/6/14.
//

import UIKit
import Foundation

public struct MentionSearchParameters {
    public struct Chatter {
        public enum ChatterType {
            case normal
            case mail
        }
        public var type: ChatterType = .normal
        /// 在职
        public var isWork: Bool = true
        /// 已离职
        public var isResigned: Bool = false
        /// 包含内部人员 (目前一定包含)
//        var includeInner: Bool = true
        /// 包含外部人员
        public var includeOuter: Bool = true
        
        public var showChatterMail: Bool = false
    }
    
    public struct Chat {
        public var isJoined: Bool = true
        public var isNotJoined: Bool = true
        public var isPublic: Bool = true
        public var isPrivate: Bool = true
        public var isOuter: Bool = true
        public var isInner: Bool = true
        /// 群聊需包含的成员 IDs，只搜索包含 ID 列表的群，默认为空，不过滤
        public var includeMemberIds: [String]?
    }
    
    public struct Document {
        public enum DocumentType: Int {
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
        public var creatorIds: [String]?
        /// 文档类型 Types，只搜索指定的文档类型，不设置时默认搜索全部
        public var types: [DocumentType]?
        /// 仅搜索文档标题
        public var isOnlyTitle: Bool = true
        /// 显示所有者 (默认显示更新时间)
        public var showDocumentOwner: Bool = false
    }
    
    /// 人员-过滤配置
    public var chatter: Chatter? = Chatter()
    /// 群组 过滤配置
    public var chat: Chat? = Chat()
    /// 文档 过滤配置
    public var document: Document? = Document()

    public init() { }
}

public struct MentionUIParameters {
    /// 面板显示的标题信息
    public var title: String?
    /// 面板显示的无数据文案
    public var noResultText: String?
    /// 是否可以多选
    public var needMultiSelect: Bool = false
    /// 是否包含全局选择器
    public var hasGlobalCheckBox: Bool = false
    /// 全局选择器默认状态
    public var globalCheckBoxSelected: Bool = false
    /// mention最大展示高度，超过限定高度时，展示为限定高度
    public var maxHeight: CGFloat?
    /// 键盘高度
    public var keyboardHeight: CGFloat?

    public init(title: String? = nil,
                noResultText: String? = nil,
                needMultiSelect: Bool = false,
                hasGlobalCheckBox: Bool = false,
                globalCheckBoxSelected: Bool = false,
                maxHeight: CGFloat? = nil,
                keyboardHeight: CGFloat? = nil
    ) {
        self.title = title
        self.noResultText = noResultText
        self.needMultiSelect = needMultiSelect
        self.hasGlobalCheckBox = hasGlobalCheckBox
        self.globalCheckBoxSelected = globalCheckBoxSelected
        self.maxHeight = maxHeight
        self.keyboardHeight = keyboardHeight
    }
}
