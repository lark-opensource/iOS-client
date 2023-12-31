//
//  WikiTreeNodeMeta.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/13.
//
// disable-lint: magic number

import Foundation
import SKCommon
import SKFoundation
import SKResource
import SpaceInterface
import SKInfra
import LarkIcon

// 标识树上一个节点的基础信息
public struct WikiTreeNodeMeta: Equatable {

    public typealias MetaStorage = [String: WikiTreeNodeMeta]

    public enum NodeType: Equatable {
        case normal
        case shortcut(location: ShortcutLocation)
        case mainRoot
        case starRoot
        case sharedRoot
        /// 新首页置顶知识库根节点
        case multiTreeRoot
        /// 新首页置顶文档列表根节点
        case clipDocumentListRoot
        /// 新首页共享列表根节点
        case homeSharedRoot

        var rawValue: Int {
            switch self {
            case .normal:
                return 0
            case .shortcut:
                return 1
            case .mainRoot:
                return 2
            case .starRoot:
                return 998
            case .sharedRoot:
                return 1000
            case .multiTreeRoot:
                return 1011
            case .clipDocumentListRoot:
                return 1012
            case .homeSharedRoot:
                return 1013
            }
        }

        public var isRootType: Bool {
            switch self {
            case .mainRoot, .starRoot, .sharedRoot, .multiTreeRoot, .clipDocumentListRoot, .homeSharedRoot:
                return true
            default:
                return false
            }
        }
        
        public var isMainRootType: Bool {
            switch self {
            case .mainRoot, .multiTreeRoot, .clipDocumentListRoot, .homeSharedRoot:
                return true
            default:
                return false
            }
        }
    }

    public enum ShortcutLocation: Equatable {
        case inWiki(wikiToken: String, spaceID: String)
        case external
    }

    // wiki token
    public let wikiToken: String
    // 所属 space ID, 由于存在跨库移动的场景，设为变量
    public var spaceID: String

    public let objToken: String

    public let objType: DocsType
    
    // 标题
    public var title: String
    // 是否有子节点，仅为后端数据，并非 UI 最终状态
    public var hasChild: Bool
    // 秘钥删除状态
    public let secretKeyDeleted: Bool
    // 在 space 中的收藏状态
    public var isExplorerStar: Bool
    
    public let nodeType: NodeType
    // shortcut本体是否被删除标志位 0：未删除 1:被删除
    public var originDeletedFlag: Int
    // Wiki是否被添加到快速访问
    public var isExplorerPin: Bool
    // 默认node节点类型都是wiki下节点， space下文档类型需要手动设置
    public var nodeLocation: NodeLocation = .wiki
    // 自定义icon信息
    public var iconInfo: String?
    // wiki知识库节点icon类型, 非知识库节点默认为nil
    public var wikiSpaceIconType: LarkIcon.IconType? = nil
    // wiki节点的detail信息
    public var detailInfo: WikiTreeNodeDetailInfo?
    // 文档链接
    public var url: String?
    
    public init(wikiToken: String,
                spaceID: String,
                objToken: String,
                objType: DocsType,
                title: String,
                hasChild: Bool,
                secretKeyDeleted: Bool,
                isExplorerStar: Bool,
                nodeType: WikiTreeNodeMeta.NodeType,
                originDeletedFlag: Int,
                isExplorerPin: Bool,
                iconInfo: String,
                url: String?) {
        self.wikiToken = wikiToken
        self.spaceID = spaceID
        self.objToken = objToken
        self.objType = objType
        self.title = title
        self.hasChild = hasChild
        self.secretKeyDeleted = secretKeyDeleted
        self.isExplorerStar = isExplorerStar
        self.nodeType = nodeType
        self.originDeletedFlag = originDeletedFlag
        self.isExplorerPin = isExplorerPin
        self.iconInfo = iconInfo
        self.url = url
    }
}

extension WikiTreeNodeMeta {

    public var isShortcut: Bool {
        guard case .shortcut = nodeType else {
            return false
        }
        return true
    }

    public var originWikiToken: String? {
        guard case let .shortcut(location) = nodeType,
              case let .inWiki(wikiToken, _) = location else {
            return nil
        }
        return wikiToken
    }

    public var originSpaceID: String? {
        guard case let .shortcut(location) = nodeType,
              case let .inWiki(_, spaceID) = location else {
            return nil
        }
        return spaceID
    }

    public var originIsExternal: Bool {
        return nodeType == .shortcut(location: .external)
    }

    // UI 展示用
    public var displayTitle: String {
        if secretKeyDeleted {
            return objType == .wikiCatalog ?
            BundleI18n.SKResource.CreationDoc_Folder_KeyInvalid :
            BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidTitle
        }
        if title.isEmpty {
            return objType.untitledString
        }
        return title
    }
    
    public var originDeleted: Bool {
        return originDeletedFlag != 0
    }

    public var wikiMeta: WikiMeta {
        WikiMeta(wikiToken: wikiToken, spaceID: spaceID)
    }
    
    public var isOwner: Bool {
        guard let detailInfo, let userId = User.current.info?.userID else {
            return false
        }
        return detailInfo.ownerId == userId
    }
}

// root 节点特化
extension WikiTreeNodeMeta {
    public static func createMainRoot(rootToken: String, spaceID: String) -> WikiTreeNodeMeta {
        WikiTreeNodeMeta(wikiToken: rootToken,
                         spaceID: spaceID,
                         objToken: "",
                         objType: .unknownDefaultType,
                         title: BundleI18n.SKResource.LarkCCM_CM_MyLib_TableOfContent_Title,
                         hasChild: true,
                         secretKeyDeleted: false,
                         isExplorerStar: false,
                         nodeType: .mainRoot,
                         originDeletedFlag: 0,
                         isExplorerPin: false,
                         iconInfo: "", 
                         url: nil)
    }

    public static let sharedRootToken = "MOCK_WIKI_SHARED_ROOT"
    public static func createSharedRoot(spaceID: String) -> WikiTreeNodeMeta {
        WikiTreeNodeMeta(wikiToken: sharedRootToken,
                         spaceID: spaceID,
                         objToken: "",
                         objType: .unknownDefaultType,
                         title: BundleI18n.SKResource.LarkCCM_Common_Space_SharedWithMe,
                         hasChild: true,
                         secretKeyDeleted: false,
                         isExplorerStar: false,
                         nodeType: .sharedRoot,
                         originDeletedFlag: 0,
                         isExplorerPin: false,
                         iconInfo: "", 
                         url: nil)
    }

    public static let favoriteRootToken = "MOCK_WIKI_FAVORITE_ROOT"
    public static func createFavoriteRoot(spaceID: String) -> WikiTreeNodeMeta {
        WikiTreeNodeMeta(wikiToken: favoriteRootToken,
                         spaceID: spaceID,
                         objToken: "",
                         objType: .unknownDefaultType,
                         title: BundleI18n.SKResource.CreationMobile_Wiki_Clipped_Tab,
                         hasChild: true,
                         secretKeyDeleted: false,
                         isExplorerStar: false,
                         nodeType: .starRoot,
                         originDeletedFlag: 0,
                         isExplorerPin: false,
                         iconInfo: "", 
                         url: nil)
    }
    
    public static let mutilTreeRootToken = "MOCK_MUTIL_TREE_ROOT"
    public static let mutilTreeSpaceID = "MOCK_MUTIL_TREE_SPACE_ID"
    public static func createMutilTreeRoot()  -> WikiTreeNodeMeta {
        WikiTreeNodeMeta(wikiToken: mutilTreeRootToken,
                         spaceID: mutilTreeSpaceID,
                         objToken: "",
                         objType: .unknownDefaultType,
                         title: BundleI18n.SKResource.Doc_Facade_Wiki,
                         hasChild: true,
                         secretKeyDeleted: false,
                         isExplorerStar: false,
                         nodeType: .multiTreeRoot,
                         originDeletedFlag: 0,
                         isExplorerPin: false,
                         iconInfo: "", 
                         url: nil)
    }
    
    public static let clipDocumentRootToken = "MOCK_CLIP_DOCUMENT_ROOT"
    public static let clipDocumentSpaceID = "MOCK_CLIP_DOCUMENT_SPACE_ID"
    public static func createDocumentRoot() -> WikiTreeNodeMeta {
        WikiTreeNodeMeta(wikiToken: clipDocumentRootToken,
                         spaceID: clipDocumentSpaceID,
                         objToken: "",
                         objType: .unknownDefaultType,
                         title: BundleI18n.SKResource.Doc_List_Space,
                         hasChild: true,
                         secretKeyDeleted: false,
                         isExplorerStar: false,
                         nodeType: .clipDocumentListRoot,
                         originDeletedFlag: 0,
                         isExplorerPin: false,
                         iconInfo: "", 
                         url: nil)
    }
    
    public static let homeSharedRootToken = "MOCK_HOME_SHARED_ROOT"
    public static let homeSharedSpaceID = "MOCK_HOME_SHARED_SPACE_ID"
    public static func createHomeSharedRoot() -> WikiTreeNodeMeta {
        WikiTreeNodeMeta(wikiToken: homeSharedRootToken,
                         spaceID: homeSharedSpaceID,
                         objToken: "",
                         objType: .unknownDefaultType,
                         title: BundleI18n.SKResource.LarkCCM_NewCM_Shared_Menu,
                         hasChild: true,
                         secretKeyDeleted: false,
                         isExplorerStar: false,
                         nodeType: .homeSharedRoot,
                         originDeletedFlag: 0,
                         isExplorerPin: false,
                         iconInfo: "", 
                         url: nil)
    }
}

// 从后端数据解析
extension WikiTreeNodeMeta: Decodable {

    private enum CodingKeys: String, CodingKey {
        case wikiToken = "wiki_token"
        case spaceID = "space_id"

        case objToken = "obj_token"
        case objType = "obj_type"

        case title
        case hasChild = "has_child"
        case secretKeyDeleted = "secret_key_delete"
        case isExplorerStar = "is_explorer_star"
        case isExplorerPin = "is_explorer_pin"
        // shortcut 相关
        case nodeType = "wiki_node_type"
        case originWikiToken = "origin_wiki_token"
        case originSpaceID = "origin_space_id"
        case originIsExternal = "origin_is_external"
        case entityDeleteFlag = "entity_delete_flag"
        case iconInfo = "icon_info"
        // detail 相关
        case detailInfo = "detail_info"
        case url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wikiToken = try container.decode(String.self, forKey: .wikiToken)
        spaceID = try container.decode(String.self, forKey: .spaceID)

        objToken = try container.decode(String.self, forKey: .objToken)
        let objTypeValue = try container.decode(Int.self, forKey: .objType)
        objType = DocsType(rawValue: objTypeValue)

        title = try container.decode(String.self, forKey: .title)
        hasChild = try container.decode(Bool.self, forKey: .hasChild)
        secretKeyDeleted = try container.decodeIfPresent(Bool.self, forKey: .secretKeyDeleted) ?? false
        isExplorerStar = try container.decodeIfPresent(Bool.self, forKey: .isExplorerStar) ?? false
        originDeletedFlag = try container.decodeIfPresent(Int.self, forKey: .entityDeleteFlag) ?? 0
        isExplorerPin = try container.decodeIfPresent(Bool.self, forKey: .isExplorerPin) ?? false
        iconInfo = try container.decodeIfPresent(String.self, forKey: .iconInfo) ?? ""
        url = try container.decodeIfPresent(String.self, forKey: .url)
        detailInfo = try container.decodeIfPresent(WikiTreeNodeDetailInfo.self, forKey: .detailInfo)
        let nodeTypeRawValue = try container.decode(Int.self, forKey: .nodeType)
        // 取值参考 NodeType.rawValue
        switch nodeTypeRawValue {
        case 0:
            nodeType = .normal
        case 1:
            let originIsExternal = try container.decodeIfPresent(Bool.self, forKey: .originIsExternal) ?? false
            if originIsExternal {
                nodeType = .shortcut(location: .external)
            } else {
                let originWikiToken = try container.decode(String.self, forKey: .originWikiToken)
                let originSpaceID = try container.decode(String.self, forKey: .originSpaceID)
                nodeType = .shortcut(location: .inWiki(wikiToken: originWikiToken, spaceID: originSpaceID))
            }
        case 2:
            nodeType = .mainRoot
        case 998:
            nodeType = .starRoot
        case 1000:
            nodeType = .sharedRoot
        default:
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.nodeType, in: container, debugDescription: "unknown wiki node type \(nodeTypeRawValue) found")
        }
    }
    
    public func transform() -> DocsInfo {
        let docsInfo = DocsInfo(type: objType, objToken: self.objToken)
        docsInfo.nodeType = isShortcut ? 1 : nil
        docsInfo.title = title
        docsInfo.wikiInfo = WikiInfo(wikiToken: wikiToken,
                                     objToken: objToken,
                                     docsType: objType,
                                     spaceId: spaceID)
        return docsInfo
    }
}

// 兼容置顶-云文档树的两种不同的数据类型，将spaceEntry转化为wikiTreeNode数据结构
extension WikiTreeNodeMeta {
    public enum NodeLocation: Equatable {
        case wiki
        case space(file: SpaceEntry)
        
        public static func == (lhs: WikiTreeNodeMeta.NodeLocation, rhs: WikiTreeNodeMeta.NodeLocation) -> Bool {
            switch lhs {
            case .wiki:
                if case .wiki = rhs {
                    return true
                } else {
                    return false
                }
            case .space(let lhsFile):
                if case let .space(rhsFile) = rhs {
                    return lhsFile.objToken == rhsFile.objToken
                } else {
                    return false
                }
            }
        }
    }
    
    public mutating func setNodeLocation(location: NodeLocation) {
        self.nodeLocation = location
    }
    
    public func transformFileEntry() -> SpaceEntry {
        let entry = WikiEntry(type: .wiki, nodeToken: wikiToken, objToken: wikiToken)
        let wikiInfo = WikiInfo(wikiToken: wikiToken, objToken: objToken, docsType: objType, spaceId: spaceID)
        entry.updateName(title)
        entry.update(wikiInfo: wikiInfo)
        entry.updatePinedStatus(isExplorerPin)
        entry.updateStaredStatus(isExplorerStar)
        entry.updateShareURL(DocsUrlUtil.url(type: .wiki, token: wikiToken).absoluteString)
        entry.updateOwnerType(
            SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType
        )
        entry.updateOwnerID(detailInfo?.ownerId)
        entry.updateCreateTime(detailInfo?.createTime)
        entry.updateEditTime(detailInfo?.editTime)
        entry.updateThumbnailExtra(detailInfo?.thumbnail?.spaceThumbnailExtra)
        return entry
    }
}

// 简便的构建方式
extension WikiTreeNodeMeta {
    public init(wikiToken: String, spaceId: String, objToken: String, docsType: DocsType, title: String) {
        self.init(wikiToken: wikiToken,
                  spaceID: spaceId,
                  objToken: objToken,
                  objType: docsType,
                  title: title,
                  hasChild: false,
                  secretKeyDeleted: false,
                  isExplorerStar: false,
                  nodeType: .normal,
                  originDeletedFlag: 0,
                  isExplorerPin: false,
                  iconInfo: "", 
                  url: nil)
    }
    
    // 转化为其他业务方使用的简便wiki节点结构
    public func transformWikiNode() -> WikiNode {
        WikiNode(wikiToken: wikiToken, spaceId: spaceID, objToken: objToken, objType: objType, title: title)
    }
}
