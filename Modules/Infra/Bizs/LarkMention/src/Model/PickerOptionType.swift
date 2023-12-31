//
//  PickerOptionType.swift
//  LarkMention
//
//  Created by Yuri on 2022/5/31.
//

import UIKit
import Foundation
import RustPB
import LarkSDKInterface

// 搜索结果分为人员，群组，文档
public enum PickerOptionItemTyle {
    case unknown
    case chatter
    case chat
    case document
    case wiki
}

public enum PickerOptionTagType: Int {
    /// 互通
    case connect
    /// 外部
    case external
    /// 值班号
    case oncall
    /// 部门
    case team
    /// 公开群
    case `public`
    /// 全员
    case allStaff
    /// 官方
    case officialOncall
}

public struct MentionMetaDocType {
    public var image: UIImage
    public var docType: Basic_V1_Doc.TypeEnum
    public var url: String

    public init(image: UIImage, docType: Basic_V1_Doc.TypeEnum, url: String) {
        self.image = image
        self.docType = docType
        self.url = url
    }
}

public enum MentionMeta {
    // 先搬运v1的接口定义，保持兼容，v2适配相同的protocol
    //case chatter(SearchMetaChatterType)
    //case chat(SearchMetaChatType)
    case doc(MentionMetaDocType)
    case wiki(MentionMetaDocType)

}

public protocol PickerOptionType  {
    /// 主要搜索类型
    var type: PickerOptionItemTyle { get set }
    
    /// 各类型特有参数
    var meta: MentionMeta? { get set}
    
    /// 是否开启多选
    var isEnableMultipleSelect: Bool { get set }
    /// 多选下是否选中
    var isMultipleSelected: Bool { get set }
    /// 头像id
    var avatarID: String? { get set }
    /// 头像key
    var avatarKey: String? { get set }
    /// 名称
    var name: NSAttributedString? { get set }
    /// 次要信息：例如邮箱等
    var subTitle: NSAttributedString? { get set }
    /// 次要信息2：组织架构、更新时间等
    var desc: NSAttributedString? { get set }
    /// Tag，会转成TagType类型，具体参考LarkTag https://codebase.byted.org/repo/ee/ios-infra/-/blob/Libs/UI/LarkTag/src/TagType.swift#L15
    var tags: [PickerOptionTagType]? { get set }
}

public struct PickerOption: PickerOptionType {
    public var type: PickerOptionItemTyle = .chat
    public var meta: MentionMeta?
    
    public var isEnableMultipleSelect: Bool = false
    public var isMultipleSelected: Bool = false
    public var avatarID: String?
    public var avatarKey: String?
    public var name: NSAttributedString?
    public var subTitle: NSAttributedString?
    public var desc: NSAttributedString?
    public var tags: [PickerOptionTagType]?
}
