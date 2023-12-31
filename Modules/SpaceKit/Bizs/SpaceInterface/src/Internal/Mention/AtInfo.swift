//
//  AtInfo.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/28.
//  


import Foundation
import RxSwift
import RxCocoa

public protocol MentionIconInfo {
    var typeValue: Int { get }
    var typeIsCurSupported: Bool { get }
    var key: String { get }
    var fsunit: String { get }
    var image: BehaviorRelay<UIImage?> { get }
}

@objc
public enum AtType: Int, CaseIterable {
    case user = 0
    case doc = 1
    case folder = 2
    case sheet = 3
    case chat = 5
    case group = 6
    case bitable = 8
    case mindnote = 11
    case file = 12
    case slides = 30
    case wiki = 16
    case docx = 22
    case whiteboard = 38
    case unknown = 999
    case sheetAttachment = 999901 // 移动端交互和 file 一样，但是 PC 端完全不一样，所以新开了一个 case
    
}

public typealias PermissionQuerryBlock = (AtInfo) -> Bool?


//@objcMembers
public final class AtInfo: NSObject, NSSecureCoding {

    public let type: AtType
    public var subType: AtType? // type为wiki类型时对应的真实类型
    public var href: String
    public let token: String
    public let at: String
    public var enName: String?
    public var name: String?
    public var recommendReason: RecommendReason?
    public var keyword: String?
    public var iconInfo: MentionIconInfo?
    public var isExternal: Bool = false
    public var id: String?
    
    public var avatarUrl: String?
    public var department: String?
    public var iconInfoMeta: String?
    public var unionId: String?
    public var cnName: String?
    public var hasPermission: Bool = true
    public let uuid = UUID().uuidString
    public let disposeBag = DisposeBag()
    
    /// 小程序每个用户有单独一套id规则, 该字段用于判断是否在mention时是否需要高亮
    public var userId: String?
    
    public var inherentType: AtType {
        if self.type == .wiki, let subType = self.subType {
            return subType
        }
        return self.type
    }
    
    //处理改名问题
    public static var prevSelfAtString: String?

    public static var supportsSecureCoding: Bool { return true }
    
 

    public init(type: AtType, href: String, token: String, at: String, icon: MentionIconInfo? = nil, iconInfoMeta: String? = nil) {
        self.type = type
        self.href = href
        self.token = token
        self.at = at
        self.iconInfo = icon
        self.iconInfoMeta = iconInfoMeta
        super.init()
    }

    override public var debugDescription: String {
        let mirror = Mirror(reflecting: self)
        var str = ""
        mirror.children.forEach({ (child) in
            str.append("\(child.label ?? ""): \(String(describing: child.value))\n")
        })
        return str
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(href, forKey: "href")
        coder.encode(token, forKey: "token")
        coder.encode(at, forKey: "at")
        coder.encode(enName, forKey: "enName")
        coder.encode(name, forKey: "name")
        coder.encode(keyword, forKey: "keyword")
        
        coder.encode(cnName, forKey: "cnName")
        coder.encode(avatarUrl, forKey: "avatarUrl")
        coder.encode(department, forKey: "department")
        coder.encode(unionId, forKey: "unionId")
        coder.encode(iconInfoMeta, forKey: "iconInfoMeta")
    }

    required public init?(coder: NSCoder) {
        type = AtType(rawValue: coder.decodeInteger(forKey: "type")) ?? .doc
        href = coder.decodeObject(forKey: "href") as? String ?? ""
        token = coder.decodeObject(forKey: "token") as? String ?? ""
        at = coder.decodeObject(forKey: "at") as? String ?? ""
        enName = coder.decodeObject(forKey: "enName") as? String
        name = coder.decodeObject(forKey: "name") as? String
        keyword = coder.decodeObject(forKey: "keyword") as? String
        
        avatarUrl = coder.decodeObject(forKey: "avatarUrl") as? String
        department = coder.decodeObject(forKey: "department") as? String
        unionId = coder.decodeObject(forKey: "unionId") as? String
        cnName = coder.decodeObject(forKey: "cnName") as? String
        iconInfoMeta = coder.decodeObject(forKey: "iconInfoMeta") as? String
        super.init()
    }
}

extension AtInfo {
    public enum RecommendReason: Int {
        case recentViewUser = 1
        case recentMentionUser = 2
        case larkSearchUser = 3
        
        var strForStatistics: String {
            switch self {
            case .recentViewUser:
                return "recent_view_user"
            case .recentMentionUser:
                return "recent_mention_user"
            case .larkSearchUser:
                return "lark_search_user"
            }
        }
    }
}
