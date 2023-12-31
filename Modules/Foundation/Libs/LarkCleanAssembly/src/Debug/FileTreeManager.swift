//
//  FileTreeManager.swift
//  LarkCleanAssembly
//
//  Created by 李昊哲 on 2023/7/3.
//  

#if !LARK_NO_DEBUG

import Foundation
import LarkStorage

class FileTreeManager {
    let queue: DispatchQueue
    let group = DispatchGroup()

    let treeRoot: FileTree

    init?(root path: AbsPath, queue: DispatchQueue? = nil) {
        let attributes = path.attributes
        guard let type = attributes[.type] as? FileAttributeType, type == .typeDirectory,
              let size = attributes[.size] as? Int64
        else { return nil }

        self.queue = queue ?? DispatchQueue(label: "com.lark.clean.FileTreeManager", attributes: .concurrent)
        self.treeRoot = FileTree(path: path, size: size, isDirectory: true)
    }

    func build() throws {
        try self.buildTree(for: treeRoot)
        self.group.wait()
    }

    func clear() {
        // 防止 build 未完成时，外部调用 clear 导致树结构不一致
        self.group.wait()
        self.treeRoot.clearChildren()
    }

    private func buildTree(for node: FileTree) throws {
        for childName in try node.path.contentsOfDirectory_() {
            let childPath = node.path + childName
            let attributes = childPath.attributes
            guard let type = attributes[.type] as? FileAttributeType,
                  let size = attributes[.size] as? Int64
            else { return }

            let isDirectory = type == .typeDirectory
            let child = node.add(name: childName, size: size, isDirectory: isDirectory, path: childPath)

            if isDirectory {
                self.queue.async(group: self.group) {
                    try? self.buildTree(for: child)
                }
            }
        }
    }

//    func find(path: AbsPath) -> FileTree? {
//        let node = self.treeRoot
//        let pathStr = path.absoluteString
//        let nodePathStr = node.path.absoluteString
//        guard pathStr.hasPrefix(nodePathStr) else {
//            return nil
//        }
//        let remainPathStr = pathStr.dropFirst(nodePathStr.count)
//        var components = (remainPathStr as NSString).pathComponents
//        if components.first == "/" {
//            components.removeFirst()
//        }
//        if components.isEmpty {
//            return node
//        }
//        return self.find(node: node, components: components[...])
//    }
//
//    private func find(node: FileTree, components: ArraySlice<String>) -> FileTree? {
//        guard let name = components.first,
//              let child = node.children[name]
//        else { return nil }
//
//        var newComponents = components.dropFirst()
//        if newComponents.first == "/" {
//            newComponents.removeFirst()
//        }
//        if newComponents.isEmpty {
//            return child
//        }
//        return self.find(node: child, components: newComponents)
//    }
}

#endif
