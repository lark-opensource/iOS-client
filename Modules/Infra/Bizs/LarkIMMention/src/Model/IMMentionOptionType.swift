//
//  IMMentionOptionType.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/20.
//

import UIKit
import Foundation
import RustPB

// 搜索结果分为人员，群组，文档
public enum IMPickerOptionType {
    case unknown
    case chatter
    case chat
    case document
    case wiki
}

public enum ChatType {
    case normal
    case huge
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
    /// 请假
    case onLeave
    /// 机器人
    case robot
    /// 未注册
    case unregistered
}


public struct IMMentionMetaDocType {
    var image: UIImage
    public var url: String
    public var type: RustPB.Basic_V1_Doc.TypeEnum
}

public enum IMMentionMeta {
    //case chatter(SearchMetaChatterType)
    //case chat(SearchMetaChatType)
    case doc(IMMentionMetaDocType)
    case wiki(IMMentionMetaDocType)
}

public protocol IMMentionOptionType  {
    ///  唯一id
    var id: String? { get }
    /// 是否开启多选
//    var isEnableMultipleSelect: Bool { get set }
    /// 多选下是否选中
    var isMultipleSelected: Bool { get set }
    /// 是否在当前群内
    var isInChat: Bool { get set }
    /// 主要搜索类型
    var type: IMPickerOptionType { get set }
    /// 头像id
    var avatarID: String? { get set }
    /// 头像key
    var avatarKey: String? { get set }
    /// 名称
    var name: NSAttributedString? { get set }
    /// 实际名称
    var actualName: String? { get set }
    /// 次要信息：例如邮箱等
    var subTitle: NSAttributedString? { get set }
    /// 次要信息2：组织架构、更新时间等
    var desc: NSAttributedString? { get set }
    /// Tag，会转成TagType类型，具体参考LarkTag
    var tags: [PickerOptionTagType]? { get set }
    /// 各类型特有参数
    var meta: IMMentionMeta? { get }
    /// 埋点信息
    var trackerInfo: TrackerInfo { get set }
    /// 状态
    var focusStatus: [RustPB.Basic_V1_Chatter.ChatterCustomStatus]? { get set }
    /// 自定义标签
    var tagData: Basic_V1_TagData? { get set }
}

// TODO 改造
public struct IMPickerOption: IMMentionOptionType {
    static let allId = "all"
    
    public var focusStatus: [RustPB.Basic_V1_Chatter.ChatterCustomStatus]?
    
    public var actualName: String?
    public var isInChat = false
    public var id: String?
    public var isEnableMultipleSelect = false
    public var isMultipleSelected = false
    public var type: IMPickerOptionType = .chat
    public var meta: IMMentionMeta?
    public var avatarID: String?
    public var avatarKey: String?
    public var name: NSAttributedString?
    public var subTitle: NSAttributedString?
    public var desc: NSAttributedString?
    public var tags: [PickerOptionTagType]?
    public var tagData: Basic_V1_TagData?
    public var trackerInfo = TrackerInfo(pageType: .unknown, chooseType: .unknown)
    
    public init(id: String = "") {
        self.id = id
    }
}

