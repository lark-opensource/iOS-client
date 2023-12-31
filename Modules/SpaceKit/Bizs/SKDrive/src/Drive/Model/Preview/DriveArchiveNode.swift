//
//  DriveArchiveNode.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/5.
//  

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import protocol SKUIKit.SKBreadcrumbItem
import LibArchiveKit
import LarkDocsIcon

class DriveArchiveNode: NSObject {

    enum FileType: Int {
        case folder = 0
        case regularFile = 1
    }

    private(set) weak var parentNode: DriveArchiveNode?

    let name: String
    let fileType: FileType

    // 压缩文件在压缩包内的路径，用于判断节点是否相等（==）
    let path: String

    fileprivate init(name: String, fileType: FileType, parentNode: DriveArchiveNode?) {
        self.name = name
        self.fileType = fileType
        self.parentNode = parentNode
        guard let parentNode = parentNode else {
            path = "/"
            return
        }
        switch fileType {
        case .folder:
            path = "\(parentNode.path)\(name)/"
        case .regularFile:
            path = "\(parentNode.path)\(name)"
        }

    }

    class func parse(data: JSON, parentNode: DriveArchiveNode?) -> DriveArchiveNode? {
        guard let name = data["name"].string,
        let rawFileType = data["file_type"].int,
        let fileType = FileType(rawValue: rawFileType) else {
            DocsLogger.error("Drive.Preview.Archive --- Failed to parse data to DriveArchiveNode", extraInfo: ["data": data])
            return nil
        }

        switch fileType {
        case .folder:
            let childNodeData = data["children"].array
            return DriveArchiveFolderNode(name: name, parentNode: parentNode, childNodeData: childNodeData)
        case .regularFile:
            guard let fileSize = data["size"].uInt64 else {
                    DocsLogger.error("Failed to get detail data for DriveArchiveFileNode", extraInfo: ["data": data])
                    return nil
            }
            return DriveArchiveFileNode(name: name, parentNode: parentNode, fileSize: fileSize)
        }
    }

}

class DriveArchiveFileNode: DriveArchiveNode {
    let fileSize: UInt64
    let driveFileType: DriveFileType

    var fileExtension: String? {
        return SKFilePath.getFileExtension(from: name)
    }

    init(name: String, parentNode: DriveArchiveNode?, fileSize: UInt64) {
        self.fileSize = fileSize
        let fileExtension = SKFilePath.getFileExtension(from: name)
        driveFileType = DriveFileType(fileExtension: fileExtension)
        super.init(name: name, fileType: .regularFile, parentNode: parentNode)
    }
}

class DriveArchiveFolderNode: DriveArchiveNode {
    var childNodes: [DriveArchiveNode] = []
    init(name: String, parentNode: DriveArchiveNode?, childNodeData: [JSON]?) {
        super.init(name: name, fileType: .folder, parentNode: parentNode)
        guard let childNodeData = childNodeData else { return }
        childNodes = childNodeData.compactMap {
            DriveArchiveNode.parse(data: $0, parentNode: self)
        }
    }

    init(name: String, parentNode: DriveArchiveNode?, childNodes: [DriveArchiveNode]) {
        self.childNodes = childNodes
        super.init(name: name, fileType: .folder, parentNode: parentNode)
    }
}

extension DriveArchiveNode: SKBreadcrumbItem {
    var itemID: String { path }
    var displayName: String { name }
}

extension DriveArchiveNode {
    static func == (lhs: DriveArchiveNode, rhs: DriveArchiveNode) -> Bool {
        if lhs.name == rhs.name, lhs.path == rhs.path {
            return true
        } else {
            return false
        }
    }
    
    // 继承于 NSObject 的类，在 Array.contains 方法里以 isEqual 作判断
    override func isEqual(_ object: Any?) -> Bool {
        guard let node = object as? DriveArchiveNode else { return false }
        return node.name == self.name && node.path == self.path
    }
}

extension LibArchiveEntry.EntryType {
    var archiveNodeType: DriveArchiveNode.FileType {
        switch self {
        case .directory: return .folder
        case .file: return .regularFile
        }
    }
}
