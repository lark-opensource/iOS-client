//
//  LarkCleanDebugModel.swift
//  LarkCleanAssembly
//
//  Created by 李昊哲 on 2023/7/3.
//  

#if !LARK_NO_DEBUG

import Foundation
import RxDataSources
import EEAtomic
import LarkClean
import LarkStorage

struct PathDebugSection {
    var title: String
    var items: [PathDebugAdapter]

    static func from(_ items: [String: [PathDebugItem]], queue: DispatchQueue) -> [Self] {
        items.map {
            PathDebugSection(
                title: $0,
                items: $1.map { item in PathDebugAdapter(from: item, queue: queue) }
            )
        }
    }

    init(title: String, items: [PathDebugAdapter]) {
        self.title = title
        self.items = items
    }
}

extension PathDebugSection: SectionModelType {
    init(original: PathDebugSection, items: [PathDebugAdapter]) {
        self = original
        self.items = items
    }
}

enum PathDebugState {
    case idle
    case scan
    case ready
    case notExists
    case error(String)
}

final class PathDebugAdapter {
    let manager: FileTreeManager?

    // 当前的状态
    @AtomicObject
    var state = PathDebugState.idle

    var isDirectory: Bool { inner.path.isDirectory }
    var title: String {
        inner.path.relativePath(to: AbsPath.home) ?? "Unknown"
    }
    var fileCount: Int {
        if !isDirectory {
            return 1
        }
        return manager?.treeRoot.count ?? 0
    }
    var bytesCount: Int64 {
        if !isDirectory {
            return Int64(inner.path.fileSize ?? 0)
        }
        return manager?.treeRoot.totalSize ?? 0
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var description: String? {
        switch state {
        case .idle: return nil
        case .scan: return "正在扫描..."
        case .ready:
            var strList: [String] = []
            if let updateAt = inner.path.attributes[.modificationDate] as? Date {
                strList.append("最后更新: \(Self.dateFormatter.string(from: updateAt))")
            }
            if !isDirectory {
                let bytesText = ByteCountFormatter().string(fromByteCount: bytesCount)
                strList.append("文件大小: \(bytesText)")
            } else {
                strList.append("文件数: \(fileCount)")
                let bytesText = ByteCountFormatter().string(fromByteCount: bytesCount)
                strList.append("总大小: \(bytesText)")
            }
            return strList.joined(separator: " ")
        case .notExists: return "路径不存在"
        case .error(let text): return "扫描出错: \(text)"
        }
    }

    var exists: Bool { inner.path.exists }

    let inner: PathDebugItem

    init(from item: PathDebugItem, queue: DispatchQueue) {
        self.inner = item

        if item.path.isDirectory {
            self.manager = FileTreeManager(root: item.path, queue: queue)
        } else {
            self.manager = nil
        }
    }

    func clean(completion: @escaping (Bool) -> Void) {
        inner.clean(completion: completion)
    }
}

#endif
