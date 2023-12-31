//
//  WikiTreeNodeConverter.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/14.
//

import Foundation
import SKFoundation
import SKResource
import SKCommon
import UniverseDesignColor

public struct WikiTreeConverterConfig {
    // 是否需要过滤，true 表示保留，false 表示需要过滤
    var filter: ((WikiTreeNodeMeta) -> Bool)?
    // 是否 enable
    var enableChecker: ((WikiTreeNodeMeta) -> Bool)?
    // 点展开按钮时的操作
    var clickStateHandler: ((WikiTreeNodeMeta, TreeNode) -> ((IndexPath) -> Void)?)?
    // 点内容区域时的操作
    var clickContentHandler: ((WikiTreeNodeMeta, TreeNode) -> ((IndexPath) -> Void)?)?
    // cell 右侧 accessoryItem 的配置
    var accessoryItemProvider: ((WikiTreeNodeMeta, TreeNode) -> TreeNodeAccessoryItem?)?
    
    public init(filter: ((WikiTreeNodeMeta) -> Bool)? = nil,
                  enableChecker: ((WikiTreeNodeMeta) -> Bool)? = nil,
                  clickStateHandler: ((WikiTreeNodeMeta, TreeNode) -> ((IndexPath) -> Void)?)? = nil,
                  clickContentHandler: ((WikiTreeNodeMeta, TreeNode) -> ((IndexPath) -> Void)?)? = nil,
                  accessoryItemProvider: ((WikiTreeNodeMeta, TreeNode) -> TreeNodeAccessoryItem?)? = nil) {
        self.filter = filter
        self.enableChecker = enableChecker
        self.clickStateHandler = clickStateHandler
        self.clickContentHandler = clickContentHandler
        self.accessoryItemProvider = accessoryItemProvider
    }
}

public protocol WikiTreeConverterClickHandler: AnyObject {
    func configDidClickNode(meta: WikiTreeNodeMeta, node: TreeNode) -> ((IndexPath) -> Void)?
    func configDidToggleNode(meta: WikiTreeNodeMeta, node: TreeNode) -> ((IndexPath) -> Void)?
    func configAccessoryItem(meta: WikiTreeNodeMeta, node: TreeNode) -> TreeNodeAccessoryItem?
}

public enum WikiTreeConvertError: Error {
    case rootNotFound(section: TreeNodeRootSection)
}

public protocol WikiTreeConverterType {
    typealias Config = WikiTreeConverterConfig
    typealias ConvertError = WikiTreeConvertError
    func convert(rootList: [(TreeNodeRootSection, String)]) -> [NodeSection]
}

public protocol WikiTreeConverterProviderType: AnyObject {
    func converter(treeState: WikiTreeState, config: WikiTreeConverterType.Config) -> WikiTreeConverterType
}

public struct WikiTreeNodeConverter {
    let treeState: WikiTreeState
    let config: Config
    
    public init(treeState: WikiTreeState, config: WikiTreeNodeConverter.Config) {
        self.treeState = treeState
        self.config = config
    }
}

extension WikiTreeNodeConverter: WikiTreeConverterType {

    init(relation: WikiTreeRelation,
                     viewState: WikiTreeViewState,
                     metaStorage: WikiTreeNodeMeta.MetaStorage,
                     config: Config) {
        treeState = WikiTreeState(viewState: viewState,
                                  metaStorage: metaStorage,
                                  relation: relation)
        self.config = config
    }

    var relation: WikiTreeRelation {
        treeState.relation
    }
    var viewState: WikiTreeViewState {
        treeState.viewState
    }
    var metaStorage: WikiTreeNodeMeta.MetaStorage {
        treeState.metaStorage
    }

    public func convert(rootList: [(TreeNodeRootSection, String)]) -> [NodeSection] {
        rootList.compactMap { (section, rootToken) -> NodeSection? in
            do {
                return try convert(section: section, rootToken: rootToken)
            } catch {
                DocsLogger.error("convert section \(section) failed", error: error)
                return nil
            }
        }
    }

    func convert(section: TreeNodeRootSection, rootToken: String) throws -> NodeSection {
        guard let rootMeta = metaStorage[rootToken] else {
            throw ConvertError.rootNotFound(section: section)
        }
        let rootNode = convertRootNode(section: section, meta: rootMeta)
        let children: [TreeNode]
        if rootNode.isOpened {
            children = convertChildNodes(section: section,
                                         parentToken: rootToken,
                                         level: 0,
                                         path: [],
                                         shortcutPath: "")
        } else {
            children = []
        }
        // 置顶树无内容，固定隐藏
        if section == .favoriteRoot, relation.nodeChildrenMap[rootToken]?.isEmpty == true {
            throw ConvertError.rootNotFound(section: section)
        }
        let section = NodeSection(identifier: rootToken,
                                  title: rootNode.title,
                                  headerNode: rootNode,
                                  items: children)
        return section
    }

    func convertRootNode(section: TreeNodeRootSection, meta: WikiTreeNodeMeta) -> TreeNode {
        // 选中态判断
        let isSelected = viewState.selectedWikiToken == meta.wikiToken
        let nodeUID = WikiTreeNodeUID(wikiToken: meta.wikiToken, section: section, shortcutPath: "")
        let isOpened = viewState.expandedUIDs.contains(nodeUID)
        // rootNode 的 title 这里单独处理，避免切换语言后 DB 里的脏数据
        let title: String
        switch section {
        case .favoriteRoot:
            title = BundleI18n.SKResource.CreationMobile_Wiki_Clipped_Tab
        case .mainRoot:
            title = BundleI18n.SKResource.LarkCCM_CM_MyLib_TableOfContent_Title
        case .sharedRoot:
            title = BundleI18n.SKResource.LarkCCM_Common_Space_SharedWithMe
        case .mutilTreeRoot:
            title = BundleI18n.SKResource.Doc_Facade_Wiki
        case .documentRoot:
            title = BundleI18n.SKResource.Doc_List_Space
        case .homeSharedRoot:
            title = BundleI18n.SKResource.LarkCCM_NewCM_Shared_Menu
        }
        
        // 展开态判断
        var node = TreeNode(id: meta.wikiToken,
                            section: section,
                            title: title,
                            typeIcon: nil, // 根节点没有 icon
                            isSelected: isSelected,
                            isOpened: isOpened,
                            isEnabled: true,
                            level: 0,
                            diffId: nodeUID,
                            type: .normal,
                            isLeaf: false,
                            isShortcut: false,
                            objToken: meta.objToken,
                            iconInfo: meta.iconInfo ?? "")
        let enable = config.enableChecker?(meta) ?? true
        node.clickStateAction = config.clickStateHandler?(meta, node) ?? { _ in }
        node.clickContentAction = config.clickContentHandler?(meta, node) ?? { _ in }
        node.accessoryItem = enable ? config.accessoryItemProvider?(meta, node) : nil
        return node
    }

    /// 深度优先递归解析子节点
    /// - Parameters:
    ///   - section: 所在 section
    ///   - parentToken: 父节点的 token
    ///   - level: 父节点的 level
    ///   - path: 父节点的 path，不包含父节点的 originToken
    ///   - shortcutPath: 父节点的 shortcutPath，不包含父节点的 shortcutToken
    ///   - checkCanExpand: 是否要前置父节点的 canExpand，如果前置判断过了，可以省略一次判断
    /// - Returns: 返回子树转换的一维数组
    func convertChildNodes(section: TreeNodeRootSection,
                           parentToken: String,
                           level: Int,
                           path: Set<String>,
                           shortcutPath: String) -> [TreeNode] {
        guard let parentMeta = metaStorage[parentToken] else {
            spaceAssertionFailure("get parent meta failed, should be check in canExpand")
            return []
        }
        let contentWikiToken = parentMeta.originWikiToken ?? parentMeta.wikiToken
        guard let children = relation.nodeChildrenMap[contentWikiToken] else {
            // 展开节点时，节点的 children 还未请求到
            DocsLogger.info("expanding node without known children info")
            return []
        }
        let nextLevel = level + 1
        var nextPath = path
        var nextShortcutPath = shortcutPath
        if let originWikiToken = parentMeta.originWikiToken {
            // 展开的是 shortcut 需要将 originWikiToken 加到 path 里
            nextPath.insert(originWikiToken)
            // 展开的是 shortcut，需要将 token 加到 shortcutPath 里
            nextShortcutPath += "-\(parentToken)"
        } else {
            // 展开的是普通节点，需要将 token 加到 path 里
            nextPath.insert(parentToken)
        }
        // 前置检查通过后，逐个 flatMap 子节点
        let subNodes = children.flatMap { child -> [TreeNode] in
            // 先将子节点自身构建好，再拼接孙子节点后返回
            guard let childMeta = metaStorage[child.wikiToken] else {
                DocsLogger.error("child meta not found when expand parent",
                                 extraInfo: ["parent": DocsTracker.encrypt(id: parentToken),
                                             "child": DocsTracker.encrypt(id: child.wikiToken)])
                return []
            }
            guard config.filter?(childMeta) ?? true else {
                // 被外部过滤，终止展开
                return []
            }
            var childShortcutPath = nextShortcutPath
            if section == .favoriteRoot || section == .documentRoot, nextLevel == 1 {
                // 针对收藏树，需要从一级节点开时给 UID 额外注入一级节点的 wikiToken，避免冲突
                // 作用等同于旧方案的 level 含义
                childShortcutPath += "-\(child.wikiToken)"
            }
            let childNode = convertChildNode(section: section,
                                             meta: childMeta,
                                             level: nextLevel,
                                             path: nextPath,
                                             shortcutPath: childShortcutPath)
            var result = [childNode]
            if !childNode.isLeaf, childNode.isOpened {
                result.append(contentsOf: convertChildNodes(section: section,
                                                            parentToken: child.wikiToken,
                                                            level: nextLevel,
                                                            path: nextPath,
                                                            shortcutPath: childShortcutPath))
            }
            return result
        }

        if subNodes.isEmpty {
            // 展开后没有可见的子节点，返回一个空白占位节点
            // 包括所有子节点都无权限、picker tree 中子节点全部被过滤场景
            let emptyNode = Self.makeEmptyNode(section: section,
                                               level: nextLevel,
                                               parentToken: parentToken,
                                               shortcutPath: nextShortcutPath)
            return [emptyNode]
        } else {
            return subNodes
        }
    }

    func convertChildNode(section: TreeNodeRootSection,
                          meta: WikiTreeNodeMeta,
                          level: Int,
                          path: Set<String>,
                          shortcutPath: String) -> TreeNode {
        let isSelected = viewState.selectedWikiToken == meta.wikiToken
        let nodeUID = WikiTreeNodeUID(wikiToken: meta.wikiToken,
                                      section: section,
                                      shortcutPath: shortcutPath)
        let isOpened = viewState.expandedUIDs.contains(nodeUID)
        let isLeaf = !canExpand(section: section, token: meta.wikiToken, path: path)
        var node = TreeNode(id: meta.wikiToken,
                            section: section,
                            title: meta.displayTitle,
                            typeIcon: meta.objType,
                            isSelected: isSelected,
                            isOpened: isOpened,
                            isEnabled: config.enableChecker?(meta) ?? true,
                            level: level,
                            diffId: nodeUID,
                            type: meta.nodeType == .mainRoot ? .wikiSpace(spaceId: meta.spaceID, iconType: meta.wikiSpaceIconType) : .normal,
                            isLeaf: isLeaf,
                            isShortcut: meta.isShortcut,
                            objToken: meta.objToken,
                            iconInfo: meta.iconInfo ?? "")
        node.clickStateAction = config.clickStateHandler?(meta, node) ?? { _ in }
        node.clickContentAction = config.clickContentHandler?(meta, node) ?? { _ in }
        node.accessoryItem = config.accessoryItemProvider?(meta, node)
        return node
    }

    // 递归终止条件判断
    func canExpand(section: TreeNodeRootSection,
                   token: String,
                   path: Set<String>) -> Bool {
        guard let meta = metaStorage[token] else {
            // 取不到欲展开的节点信息，终止展开
            DocsLogger.info("meta not found, expand end")
            return false
        }
        if !meta.hasChild {
            guard meta.isShortcut, let originWikiToken = meta.originWikiToken else {
                // 非 shortcut，直接看 hasChild
                return false
            }
            guard let originMeta = metaStorage[originWikiToken], originMeta.hasChild else {
                // shortcut 拿不到本体，以自身的 hasChild 为准
                return false
            }
            // 能拿到 shortcut 本体，且本体 hasChild 为 true，允许展开
        }
        let originWikiToken = meta.originWikiToken ?? meta.wikiToken
        // shortcut 需要找本体的 children
        if path.contains(originWikiToken) {
            // 防止套娃，禁止重复展开
            return false
        }
        return true
    }
}

extension WikiTreeNodeConverter {

    static func makeEmptyNode(section: TreeNodeRootSection,
                              level: Int,
                              parentToken: String,
                              shortcutPath: String) -> TreeNode {
        let title: String
        if section == .favoriteRoot, level == 1 {
            title = BundleI18n.SKResource.CreationMobile_Wiki_NoPage_Placeholder
            DocsLogger.warning("expand star root without sub nodes")
        } else {
            DocsLogger.warning("expand node without sub nodes is forbidden")
            title = BundleI18n.SKResource.CreationMobile_Wiki_NoSubpages_Placeholder
        }
        let token = "empty-\(parentToken)"
        let emptyNode = TreeNode(id: token,
                                 section: section,
                                 title: title,
                                 typeIcon: nil,
                                 isSelected: false,
                                 isOpened: false,
                                 isEnabled: true,
                                 level: level,
                                 diffId: WikiTreeNodeUID(wikiToken: token,
                                                         section: section,
                                                         shortcutPath: shortcutPath),
                                 type: .empty,
                                 isLeaf: true,
                                 isShortcut: false,
                                 objToken: "",
                                 iconInfo: "")
        return emptyNode
    }
}
