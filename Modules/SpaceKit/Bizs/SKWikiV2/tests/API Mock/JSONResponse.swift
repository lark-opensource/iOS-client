//
//  JSONResponse.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/6/28.
//

import Foundation
import SwiftyJSON

protocol PathRepresentable {
    var fullPath: String { get }
}

/// 缓存所属业务模块
protocol ResourcePath {
    /// 上级文件夹
    static var parent: ResourcePath.Type? { get }
    /// 当前文件路径
    static var path: String { get }
}

extension ResourcePath {
    /// 拼接上所有parent模块后的完整路径
    static var fullPath: String {
        var paths = [path]
        var currentParent = parent
        while let nextParent = currentParent {
            paths.append(nextParent.path)
            currentParent = nextParent.parent
        }
        return paths.reversed().joined(separator: "/")
    }
}

extension PathRepresentable where Self: ResourcePath, Self: RawRepresentable, Self.RawValue == String {
    var fullPath: String {
        return "\(Self.fullPath)/\(rawValue).json"
    }
}

enum JSONPath: String, ResourcePath, PathRepresentable {
    static let parent: ResourcePath.Type? = nil
    static let path: String = "JSON"

    case copyToWiki = "copy-to-wiki"
    // code: 0 成功
    case plainSuccess = "plain-success"
    // code: 4 无权限
    case noPermission = "no-permission"
    // 获取 space members
    case getSpaceMembers = "get-wiki-members"
    // 获取 space 空间信息
    case getSpaceDetail = "get-space-detail"
    // 获取 space 空间信息
    case needApproval = "need-approval"
}

enum TreeJSON: String, ResourcePath, PathRepresentable {
    static let parent: ResourcePath.Type? = JSONPath.self
    static let path: String = "Tree"

    static let mockSpaceID = "6974724413786685468"

    case originData = "origin-data"
    case getFavoriteInfo = "get-favorite-info"
    case freeTreeData = "free-tree-data"
    case emptyTreeData = "empty-tree-data"
}

extension TreeJSON {
    enum AddNode: ResourcePath {

        static let parent: ResourcePath.Type? = TreeJSON.self
        static let path: String = "AddNode"

        enum WithCache: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = AddNode.self
            static let path: String = "WithCache"
            case expect
        }

        enum WithoutCache: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = AddNode.self
            static let path: String = "WithoutCache"
            case expect
            case getChildren = "get-children"
        }
    }
}

extension TreeJSON {
    enum DeleteNode: ResourcePath {
        static let parent: ResourcePath.Type? = TreeJSON.self
        static let path: String = "DeleteNode"

        enum LeafNode: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = DeleteNode.self
            static let path: String = "LeafNode"
            case expect
        }

        enum WithSubNode: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = DeleteNode.self
            static let path: String = "WithSubNode"
            case expect
        }

        enum LastChildNode: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = DeleteNode.self
            static let path: String = "LastChildNode"
            case input
            case expect
        }
    }
}

extension TreeJSON {
    enum MoveNode: ResourcePath {
        static let parent: ResourcePath.Type? = TreeJSON.self
        static let path: String = "MoveNode"

        enum WithBothNode: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = MoveNode.self
            static let path: String = "WithBothNode"
            case expect
        }
        enum WithSourceNode: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = MoveNode.self
            static let path: String = "WithSourceNode"
            case expect
        }
        enum WithTargetNode: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = MoveNode.self
            static let path: String = "WithTargetNode"
            case expect
        }
        enum MoveSelectedNode: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = MoveNode.self
            static let path: String = "MoveSelectedNode"
            case withoutTargetNode = "without-target-node"
        }
    }
}

enum LoadJSONError: Error {
    case fileNotFound
}

class WikiTestUtil {
    
    static func loadFile(path: PathRepresentable) throws -> Data {
        guard let path = Bundle(for: WikiTestUtil.self)
            .url(forResource: path.fullPath, withExtension: nil) else {
            throw LoadJSONError.fileNotFound
        }
        let data = try Data(contentsOf: path)
        return data
    }
    
    static func loadJSON(path: PathRepresentable) throws -> JSON {
        let data = try loadFile(path: path)
        let json = try JSON(data: data)
        return json
    }
}
