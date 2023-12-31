//
//  TreeNode.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/18.
//

import Foundation
import SpaceInterface
import RxDataSources
import LarkIcon

public enum TreeNodeType: Equatable {
    case empty       // ref to TreeTableViewEmptyCell
    case normal      // ref to TreeTableViewCell
    case wikiSpace(spaceId: String, iconType: IconType?)
    
    public var isWikiSpace: Bool {
        switch self {
        case .empty, .normal:
            return false
        case .wikiSpace:
            return true
        }
    }
}

public enum TreeNodeRootSection: String, Equatable {
    case mainRoot   // 空间目录根节点
    case favoriteRoot  // 收藏/置顶根节点
    case sharedRoot // 与我分享根节点
    case mutilTreeRoot // 置顶知识库根节点
    case documentRoot   // 置顶云文档根节点
    case homeSharedRoot // space新首页共享部分根节点
}

public struct TreeNodeAccessoryItem {

    public let identifier: String
    public let image: () -> UIImage
    public let handler: (UIView) -> Void

    public init(identifier: String, image: @autoclosure @escaping () -> UIImage, handler: @escaping (UIView) -> Void) {
        self.identifier = identifier
        self.image = image
        self.handler = handler
    }
}

public struct TreeNode {
    
    public let id: String
    public let section: TreeNodeRootSection
    public let title: String
    public let typeIcon: DocsType?
    public var isSelected: Bool
    public var isOpened: Bool
    public var isEnabled: Bool
    public let level: Int
    public let diffId: WikiTreeNodeUID
    public let type: TreeNodeType
    public let isLeaf: Bool
    public let isShortcut: Bool
    public let objToken: String
    // 避免 loading 时相关请求报错后 loading 不消失问题
    // 仅在 cell 被点击展开时置为 true
    public var isLoading = false

    public var accessoryItem: TreeNodeAccessoryItem?
    
    // 自定义icon信息
    public let iconInfo: String?

    public var clickStateAction: (IndexPath) -> Void = { _ in }
    public var clickContentAction: (IndexPath) -> Void = { _ in }


    public static let `default` = TreeNode(id: "",
                                           section: .mainRoot,
                                           title: "",
                                           typeIcon: nil,
                                           isSelected: false,
                                           isOpened: false,
                                           isEnabled: false,
                                           level: 0,
                                           diffId: .empty,
                                           type: .normal,
                                           isLeaf: false,
                                           isShortcut: false,
                                           objToken: "",
                                           iconInfo: "")
    
    public init(id: String,
                section: TreeNodeRootSection,
                title: String,
                typeIcon: DocsType?,
                isSelected: Bool,
                isOpened: Bool,
                isEnabled: Bool,
                level: Int,
                diffId: WikiTreeNodeUID,
                type: TreeNodeType,
                isLeaf: Bool,
                isShortcut: Bool,
                objToken: String,
                iconInfo: String,
                isLoading: Bool = false,
                accessoryItem: TreeNodeAccessoryItem? = nil,
                clickStateAction: @escaping (IndexPath) -> Void = { _ in },
                clickContentAction: @escaping (IndexPath) -> Void = { _ in }) {
        self.id = id
        self.section = section
        self.title = title
        self.typeIcon = typeIcon
        self.isSelected = isSelected
        self.isOpened = isOpened
        self.isEnabled = isEnabled
        self.level = level
        self.diffId = diffId
        self.type = type
        self.isLeaf = isLeaf
        self.isShortcut = isShortcut
        self.objToken = objToken
        self.iconInfo = iconInfo
        self.isLoading = isLoading
        self.accessoryItem = accessoryItem
        self.clickStateAction = clickStateAction
        self.clickContentAction = clickContentAction
    }
}

extension TreeNode: Equatable, IdentifiableType {
    public static func == (lhs: TreeNode, rhs: TreeNode) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.isSelected == rhs.isSelected &&
        lhs.isOpened == rhs.isOpened &&
        lhs.isEnabled == rhs.isEnabled &&
        lhs.level == rhs.level &&
        lhs.isLeaf == rhs.isLeaf &&
        lhs.isShortcut == rhs.isShortcut &&
        lhs.isLoading == rhs.isLoading &&
        lhs.iconInfo == rhs.iconInfo &&
        lhs.accessoryItem?.identifier == rhs.accessoryItem?.identifier
    }

    public typealias Identity = String
    public var identity: String { diffId.uniqueID }
}

public struct NodeSection: AnimatableSectionModelType {
    public typealias Item = TreeNode
    public var identity: String { identifier }

    public let identifier: String
    public let title: String?
    public var headerNode: TreeNode?
    public var items: [Item]

    public init(identifier: String,
                title: String?,
                headerNode: TreeNode?,
                items: [TreeNode]) {
        self.identifier = identifier
        self.title = title
        self.headerNode = headerNode
        self.items = items
    }

    public init(original: NodeSection,
                items: [TreeNode]) {
        self = original
        self.items = items
    }

    public mutating func updateItems(_ items: [TreeNode]) {
        self.items = items
    }

    public static let `default` = NodeSection(identifier: "", title: nil, headerNode: nil, items: [])
}
