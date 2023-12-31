//
//  JOSNLoader.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/20.
//

import Foundation
import SwiftyJSON

protocol PathRepresentable {
    var fullPath: String { get }
}

/// 资源路径
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

class Resource {
    static func loadFile(path: PathRepresentable) throws -> Data {
        guard let path = Bundle(for: Resource.self)
            .url(forResource: path.fullPath, withExtension: nil) else {
            throw LoadJSONError.fileNotFound
        }
        let data = try Data(contentsOf: path)
        return data
    }

    static func loadJSON(path: PathRepresentable) throws -> SwiftyJSON.JSON {
        let data = try loadFile(path: path)
        let json = try SwiftyJSON.JSON(data: data)
        return json
    }

    enum JSON: ResourcePath {
        static let parent: ResourcePath.Type? = nil
        static let path: String = "JSON"

    }
}

extension Resource.JSON {
    enum UserPermission: ResourcePath {
        static let parent: ResourcePath.Type? = Resource.JSON.self
        static let path: String = "UserPermission"

        enum Document: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = UserPermission.self
            static let path: String = "Document"

            case edit
            case fullAccess = "full_access"
            case needApply = "need_apply"
            case noPermission = "no_permission"
            case owner
            case read
            case requirePassword = "require_password"
        }

        enum Folder: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = UserPermission.self
            static let path: String = "Folder"

            case edit
            case fullAccess = "full_access"
            case needApply = "need_apply"
            case noPermission = "no_permission"
            case owner
            case read
            case requirePassword = "require_password"
        }

        enum LegacyFolder: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = UserPermission.self
            static let path: String = "LegacyFolder"

            case edit
            case noPermission = "no_permission"
            case read
        }
    }
}

extension Resource.JSON {
    enum DLP: ResourcePath {
        static let parent: ResourcePath.Type? = Resource.JSON.self
        static let path: String = "DLP"

        enum Policy: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = DLP.self
            static let path: String = "Policy"

            case disable
            case enable
        }

        enum Result: String, ResourcePath, PathRepresentable {
            static let parent: ResourcePath.Type? = DLP.self
            static let path: String = "Result"

            case safe
            case detecting
            case sensitive
            case mix
        }
    }
}

enum LoadJSONError: Error {
    case fileNotFound
}


