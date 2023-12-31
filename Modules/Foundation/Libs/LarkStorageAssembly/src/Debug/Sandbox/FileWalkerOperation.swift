//
//  FileWalkerOperation.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/14.
//

#if !LARK_NO_DEBUG
import Foundation

class FileWalkerOperation: Operation {
    let path: String
    let action: (ContainerFilesItem) -> Void
    let filter: (String) -> Bool
    let onComplete: () -> Void

    init(
        path: String,
        filter: @escaping (String) -> Bool,
        action: @escaping (ContainerFilesItem) -> Void,
        onComplete: @escaping () -> Void = {}
    ) {
        self.path = path
        self.filter = filter
        self.action = action
        self.onComplete = onComplete
    }

    override func main() {
        recursiveSearch(parent: path)
        let onComplete = self.onComplete
        OperationQueue.main.addOperation {
            onComplete()
        }
    }

    func recursiveSearch(parent: String) {
        guard !isCancelled else { return }
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: parent) else {
            return
        }

        for name in names {
            guard !isCancelled else {
                return
            }

            let path = NSString(string: parent).appendingPathComponent(name)
            let isDirectory = Self.isDirectory(path: path)

            if self.filter(path) {
                let action = self.action
                OperationQueue.main.addOperation {
                    action(ContainerFilesItem(path: path, name: name, isDirectory: isDirectory))
                }
            }

            if Self.isDirectory(path: path) {
                recursiveSearch(parent: path)
            }
        }
    }

    private static func isDirectory(path: String) -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            return isDir.boolValue
        }
        return false
    }
}
#endif
