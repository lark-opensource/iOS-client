//
//  MailLabelModel+Tree.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/12/15.
//

import Foundation

class FolderTree {
    var rootNode: FolderTreeNode<MailFilterLabelCellModel>
        = FolderTreeNode(nil, MailFilterLabelCellModel(labelId: Mail_FolderId_Root, badge: 0))

    fileprivate var nodeMap: [String: FolderTreeNode<MailFilterLabelCellModel>] = [:]

    static func getSortedListWithNodePath(_ root: FolderTreeNode<MailFilterLabelCellModel>?) -> [MailFilterLabelCellModel] {
        var result = [MailFilterLabelCellModel]()
        guard let root = root else {
            return []
        }
        if root.parent != nil {
            result.append(root.value)
        }
        for child in root.children {
            result.append(contentsOf: getSortedListWithNodePath(child))
        }
        return result
    }

    static func build(_ data: [MailFilterLabelCellModel]) -> FolderTree {
        let instance = FolderTree()
        instance.setupTree(data)
        return instance
    }

    func findMaxDepth(_ folderID: String) -> Int {
        guard let node = rootNode.search(folderID) else {
            return 0
        }
        if node.children.count > 0 {
            var depthes = [Int]()
            for child in node.children {
                depthes.append(findMaxDepth(child.value.labelId))
            }
            return (depthes.sorted(by: { $0 > $1 }).first ?? 0) + 1
        } else {
            return 1
        }
    }

    func getDepth(_ folderID: String) -> Int {
        guard let node = rootNode.search(folderID) else {
            return 0
        }
        var depth = 0
        var tempNode: FolderTreeNode? = node
        while let node = tempNode, node.value.labelId != rootNode.value.labelId {
            tempNode = node.parent
            depth += 1
        }
        return depth
    }

    func findChilds(_ folderID: String) -> [MailFilterLabelCellModel] {
        var result: [MailFilterLabelCellModel] = []
        guard let node = rootNode.search(folderID) else {
            return []
        }
        result.append(node.value)
        for child in node.children {
            result.append(contentsOf: findChilds(child.value.labelId))
        }
        return result
    }

    func findChildsInSameParent(_ folderID: String) -> [MailFilterLabelCellModel] {
        guard let node = rootNode.search(folderID) else {
            return []
        }
        return node.children.map({ $0.value })
    }

    private func setupTree(_ data: [MailFilterLabelCellModel]) {
        var nodeMap = [String: FolderTreeNode<MailFilterLabelCellModel>]()
        for tag in data {
            nodeMap.updateValue(FolderTreeNode(nil, tag), forKey: tag.labelId)
        }
        for node in nodeMap.values.sorted(by: { $0.value < $1.value }) {
            if node.value.parentID.isEmpty || node.value.parentID.isRoot() {
                // 父级列表
                // print("根目录列表: \(node.value.text) parentID: \(node.value.parentID)")
                rootNode.add(child: node)
            } else {
                // 子级列表
                if let parentNode = nodeMap[node.value.parentID] {
                    // print("子级列表: \(parentNode.value.text) parentID: \(parentNode.value.parentID)")
                    parentNode.add(child: node)
                } else {
                    // print("待排 tag: \(node.value.text) parentID: \(node.value.parentID)")
                    rootNode.add(child: node)
                }
            }
        }
        self.nodeMap = nodeMap
    }
}

extension Array where Element == MailFilterLabelCellModel {

    /// 已经排序好的列表，系统label 在最前面
    func genSortedSystemFirst() -> [MailFilterLabelCellModel] {
        var (system, other) = genSortedSystemAndOther()
        system.append(contentsOf: other)
        return system
    }

    func genSortedSystemAndOther() -> ([MailFilterLabelCellModel], [MailFilterLabelCellModel]) {
        let tree = FolderTree.build(self)
        var system = [MailFilterLabelCellModel]()
        var other = [MailFilterLabelCellModel]()

        var systemNodes: [FolderTreeNode<MailFilterLabelCellModel>] = []
        var otherNodes: [FolderTreeNode<MailFilterLabelCellModel>] = []
        _ = tree.rootNode.children.map { node in
            if (node.value.isSystem) {
                systemNodes.append(node)
            } else {
                otherNodes.append(node)
            }
            return node
        }

        for child in systemNodes {
            system.append(contentsOf: FolderTree.getSortedListWithNodePath(child))
        }

        for child in otherNodes {
            other.append(contentsOf: FolderTree.getSortedListWithNodePath(child))
        }
        return (system, other)
    }

    /// 如果【草稿箱，已发送】内没有子文件夹就直接不显示。
    func genSortedSystemAndOtherForMoveTo() -> ([MailFilterLabelCellModel], [MailFilterLabelCellModel]) {
        let tree = FolderTree.build(self)
        var system = [MailFilterLabelCellModel]()
        var other = [MailFilterLabelCellModel]()
        let targetLabel = Set<String>.init(systemRootEnableMoveTo)

        var systemNodes: [FolderTreeNode<MailFilterLabelCellModel>] = []
        var otherNodes: [FolderTreeNode<MailFilterLabelCellModel>] = []
        var systemFakeRoot: [FolderTreeNode<MailFilterLabelCellModel>] = [] // system不支持，但是子文件夹支持的，sb需求逻辑
        _ = tree.rootNode.children.map { node in
            if (node.value.isSystem) {
                if !targetLabel.contains(node.value.labelId) {
                    for n in node.children { // 子文件夹要放到other内
                        systemFakeRoot.append(n)
                    }
                } else {
                    systemNodes.append(node)
                }
            } else {
                otherNodes.append(node)
            }
            return node
        }
        for child in systemNodes {
            system.append(contentsOf: FolderTree.getSortedListWithNodePath(child))
        }

        for child in systemFakeRoot { // 先处理特殊的
            other.append(contentsOf: FolderTree.getSortedListWithNodePath(child))
        }

        for child in otherNodes {
            other.append(contentsOf: FolderTree.getSortedListWithNodePath(child))
        }
        return (system, other)
    }
}


extension MailFilterLabelCellModel: Comparable {
    static func < (lhs: MailFilterLabelCellModel, rhs: MailFilterLabelCellModel) -> Bool {
        if lhs.userOrderedIndex != rhs.userOrderedIndex {
            return lhs.userOrderedIndex < rhs.userOrderedIndex
        } else {
            return lhs.text < rhs.text
        }
    }
}

class FolderTreeNode<T: Comparable> {
    var value: T
    var children = [FolderTreeNode]()
    weak var parent: FolderTreeNode?

    init(_ parent: FolderTreeNode?, _ value: T) {
        self.parent = parent
        self.value = value
    }

    func add(child node: FolderTreeNode, parent: FolderTreeNode) {
        var index = 0
        for child in children {
            if let child = child.value as? MailFilterLabelCellModel,
               let nodeValue = node.value as? MailFilterLabelCellModel,
               nodeValue.userOrderedIndex < child.userOrderedIndex {
                break
            }
            index += 1
        }
        children.insert(node, at: index)
        node.parent = parent
    }

    func add(child node: FolderTreeNode) {
        add(child: node, parent: self)
    }

    func search(_ valueID: String) -> FolderTreeNode? {
        if valueID == (self.value as? MailFilterLabelCellModel)?.labelId {
            return self
        }
        for child in children {
            if let result = child.search(valueID) {
                return result
            }
        }
        return nil
    }
}

extension FolderTreeNode: CustomStringConvertible {
    var description: String {
        var text = "\(value)"

        if !children.isEmpty {
            text += "{ " + children.map({ $0.description }).joined(separator: ", ") + " }"
        }
        return text
    }
}

// MARK: 业务工具方法
extension FolderTree {
    func checkRootParentIsSystem(labelId: String) -> Bool {
        guard let node = nodeMap[labelId] else {
            return false
        }

        var parent = node.parent
        while let par_parent = parent?.parent, par_parent.value.labelId.isRoot() {
            parent = par_parent
        }
        return parent?.value.isSystem ?? false
    }
}
