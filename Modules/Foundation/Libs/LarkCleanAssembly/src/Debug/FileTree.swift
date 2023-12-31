//
//  FileTree.swift
//  LarkCleanAssembly
//
//  Created by 李昊哲 on 2023/7/3.
//  

#if !LARK_NO_DEBUG

import Foundation
import EEAtomic
import LarkStorage

// 表示虚拟的文件树结构，和文件系统解耦，仅维护树结构的一致性
final class FileTree {
    let lock = UnfairLock()
    weak var parent: FileTree?

    var children = [String: FileTree]()

    let name: String
    let path: AbsPath
    let isDirectory: Bool

    /// 表示节点本身的大小，不包含子文件
    var size: Int64

    /// 表示子文件的数量和，不包含自身
    var count: Int = 0

    /// 表示子文件的总大小，不包含自身
    var totalSize: Int64 = 0

    init(path: AbsPath, size: Int64, isDirectory: Bool, name: String? = nil, parent: FileTree? = nil) {
        self.path = path
        self.size = size
        self.parent = parent
        self.isDirectory = isDirectory

        self.name = name ?? path.lastPathComponent
    }

    @discardableResult
    func add(name: String, size: Int64, isDirectory: Bool, path: AbsPath? = nil) -> FileTree {
        let path = path ?? (self.path + name)
        let child = FileTree(
            path: path,
            size: size,
            isDirectory: isDirectory,
            name: name,
            parent: self
        )

        self.lock.lock()
        self.children[name] = child
        self.lock.unlock()

        self.updateCount(delta: 1)
        self.updateTotalSize(delta: size)

        return child
    }

    @discardableResult
    func remove(name: String) -> FileTree? {
        self.lock.lock()
        let child = self.children.removeValue(forKey: name)
        self.lock.unlock()

        if let child {
            child.lock.lock()
            child.parent = nil
            child.lock.unlock()

            self.updateCount(delta: -1)
            self.updateTotalSize(delta: -child.size)
        }

        return child
    }

    @discardableResult
    func removeFromParent() -> FileTree? {
        self.lock.lock()
        let parent = self.parent
        self.parent = nil
        self.lock.unlock()

        if let parent {
            parent.lock.lock()
            parent.children.removeValue(forKey: name)
            parent.lock.unlock()

            parent.updateCount(delta: -1)
            parent.updateTotalSize(delta: -size)
        }

        return parent
    }

    // 清空整个子树，方便后续重新扫描
    func clearChildren() {
        self.lock.lock()
        self.children.removeAll()
        self.count = 0
        self.totalSize = 0
        self.lock.unlock()
    }

    // 当实际的文件系统更新文件大小时，调用这个方法更新整个文件树
    func update(size: Int64) {
        self.lock.lock()
        let oldSize = self.size
        self.size = size
        self.lock.unlock()

        self.updateTotalSize(delta: size - oldSize)
    }

    private func updateTotalSize(delta: Int64) {
        self.lock.lock()
        self.totalSize += delta
        let parent = self.parent
        self.lock.unlock()

        parent?.updateTotalSize(delta: delta)
    }

    private func updateCount(delta: Int) {
        self.lock.lock()
        self.count += delta
        let parent = self.parent
        self.lock.unlock()

        parent?.updateCount(delta: delta)
    }
}

#endif
