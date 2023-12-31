//
//  WorkspacePickerNetworkAPI.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/9/27.
//

import Foundation
import SKFoundation
import SwiftyJSON
import RxSwift
import SKResource
import SKInfra
import SpaceInterface

private extension WorkspacePickerAction {
    var actionValue: String {
        switch self {
        case .createWiki:
            return "create"
        case .createWikiShortcut:
            return "wiki_create_shortcut"
        case .createSpaceShortcut:
            return "space_create_shortcut"
        case .moveWiki:
            return "wiki_move"
        case .moveSpace:
            return "space_move"
        case .copyWiki:
            return "wiki_copy"
        case .copySpace:
            return "space_copy"
        }
    }
}

enum WorkspacePickerRecentFilter {
    case all
    case spaceOnly
    case wikiOnly

    fileprivate var filterValue: String? {
        switch self {
        case .all:
            return nil
        case .spaceOnly:
            return "space"
        case .wikiOnly:
            return "wiki"
        }
    }
}

protocol WorkspacePickerNetworkAPI {
    typealias RecentFilter = WorkspacePickerRecentFilter
    static func loadRecentEntries(action: WorkspacePickerAction, filter: RecentFilter) -> Single<[WorkspacePickerRecentEntry]>
}

enum WorkspacePickerStandardNetworkAPI: WorkspacePickerNetworkAPI {
    static func loadRecentEntries(action: WorkspacePickerAction, filter: RecentFilter) -> Single<[WorkspacePickerRecentEntry]> {
        var params: [String: Any] = [
            "action": action.actionValue
        ]
        if let filterValue = filter.filterValue {
            params["filter"] = filterValue
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getWorkspaceRecentOperation,
                                        params: params)
            .set(method: .GET)
        return request.rxStart().map { json in
            guard let data = json?["data"] else {
                throw DocsNetworkError.invalidData
            }
            return parseRecentList(data: data)
        }
    }

    static func parseRecentList(data: JSON) -> [WorkspacePickerRecentEntry] {
        let nodes = parseNodeList(data: data)
        if nodes.isEmpty {
            return []
        }
        let wikiNodes = parseWikiData(data: data)
        let spaceNodes = parseSpaceData(data: data)
        return nodes.compactMap { node in
            switch node.containerType {
            case .space:
                guard let spaceEntry = spaceNodes[node.containerToken] else { return nil }
                return .folder(entry: spaceEntry)
            case .wiki:
                guard let wikiEntry = wikiNodes[node.containerToken] else { return nil }
                return .wiki(entry: wikiEntry)
            case .phoenix:
                return nil
            }
        }
    }

    static func parseNodeList(data: JSON) -> [WorkspaceCrossNetworkAPI.ContainerInfo] {
        guard let nodes = data["nodes"].array else {
            return []
        }
        let result = nodes.compactMap { node -> WorkspaceCrossNetworkAPI.ContainerInfo? in
            guard let token = node["token"].string,
                  let bizTypeValue = node["biz_type"].int,
                  let bizType = WorkspaceCrossNetworkAPI.ContainerType(rawValue: bizTypeValue) else {
                return nil
            }
            // 暂时不允许 phoenix 出现在最近操作列表里
            if bizType == .phoenix { return nil }
            return WorkspaceCrossNetworkAPI.ContainerInfo(containerToken: token, containerType: bizType)
        }
        return result
    }

    static func parseWikiData(data: JSON) -> [String: WorkspacePickerWikiEntry] {
        guard let nodes = data["wiki"]["nodes"].dictionary else {
            return [:]
        }
        let decoder = JSONDecoder()
        var result: [String: WorkspacePickerWikiEntry] = [:]
        nodes.forEach { wikiToken, json in
            do {
                let data = try json.rawData()
                let entry = try decoder.decode(WorkspacePickerWikiEntry.self, from: data)
                result[wikiToken] = entry
            } catch {
                DocsLogger.error("parse recent wiki data failed", error: error)
            }
        }
        return result
    }

    static func parseSpaceData(data: JSON) -> [String: WorkspacePickerSpaceEntry] {
        guard let nodes = data["space"]["nodes"].dictionary else {
            return [:]
        }
        var result: [String: WorkspacePickerSpaceEntry] = [:]
        nodes.forEach { folderToken, json in
            guard let name = json["name"].string,
                  let ownerType = json["owner_type"].int,
                  let shareVersion = json["share_version"].int else {
                return
            }
            let isShareFolder = json["extra"]["is_share_folder"].bool
            let isExternal = json["extra"]["is_external"].boolValue
            let folderType = FolderType(ownerType: ownerType, shareVersion: shareVersion, isShared: isShareFolder)
            let entry = WorkspacePickerSpaceEntry(folderToken: folderToken,
                                                  folderType: folderType,
                                                  name: name,
                                                  isExternal: isExternal,
                                                  extra: json["extra"].dictionaryObject,
                                                  subTitle: nil)
            result[folderToken] = entry
        }
        guard let paths = data["space"]["paths"].array else {
            // 解析 path 失败，不处理 parentName
            return result
        }
        paths.forEach { json in
            guard let path = json.arrayObject as? [String],
                  path.count >= 2 else {
                // path 内容数量太少，说明父节点是根节点或无权限，按 PRD 不需要展示 parentName，可以跳过
                return
            }
            guard let rootToken = path.first,
                  let childToken = path.last else {
                spaceAssertionFailure("first and last value should not be nil")
                return
            }
            guard var childEntry = result[childToken],
                  let parentEntry = result[rootToken] else { return }
            childEntry.subTitle = parentEntry.name
            result[childToken] = childEntry
        }
        return result
    }
}

// 操作 1.0 节点，需要用 LegacyNetworkAPI
enum WorkspacePickerLegacyNetworkAPI: WorkspacePickerNetworkAPI {
    static func loadRecentEntries(action: WorkspacePickerAction, filter: RecentFilter) -> Single<[WorkspacePickerRecentEntry]> {
        loadRecentEntries(usingV2API: SettingConfig.singleContainerEnable)
    }

    static func loadRecentEntries(usingV2API: Bool) -> Single<[WorkspacePickerRecentEntry]> {
        let path: String
        if usingV2API {
            path = OpenAPI.APIPath.recentlyUsedFoldersV2
        } else {
            path = OpenAPI.APIPath.recentlyUsedFolders
        }
        let request = DocsRequest<JSON>(path: path, params: nil)
            .set(method: .GET)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .utility))
            .map { json in
                guard let data = json?["data"] else {
                    throw DocsNetworkError.invalidData
                }
                return parseRecentFolders(data: data)
            }
    }

    static func parseRecentFolders(data: JSON) -> [WorkspacePickerRecentEntry] {
        guard let nodes = data["entities"]["nodes"].dictionary else {
            return []
        }
        var metas: [String: WorkspacePickerSpaceEntry] = [:]
        nodes.forEach { folderToken, json in
            guard let name = json["name"].string,
                  let ownerType = json["owner_type"].int,
                  let shareVersion = json["share_version"].int else {
                return
            }
            let isShareFolder = json["extra"]["is_share_folder"].bool
            let isExternal = json["extra"]["is_external"].boolValue
            let folderType = FolderType(ownerType: ownerType, shareVersion: shareVersion, isShared: isShareFolder)
            var entry = WorkspacePickerSpaceEntry(folderToken: folderToken,
                                                  folderType: folderType,
                                                  name: name,
                                                  isExternal: isExternal,
                                                  extra: json["extra"].dictionaryObject,
                                                  subTitle: nil)
            if let editTime = json["edit_time"].double {
                entry.subTitle = BundleI18n.SKResource.Doc_List_LastUpdateTime(editTime.fileSubTitleDateFormatter)
            }
            metas[folderToken] = entry
        }
        guard let paths = data["path"].array else {
            // 解析 path 失败，不处理 parentName
            return []
        }
        var result: [WorkspacePickerRecentEntry] = []
        paths.forEach { json in
            guard let path = json.arrayObject as? [String],
                  let folderToken = path.last,
                  var folderEntry = metas[folderToken] else {
                return
            }
            result.append(.folder(entry: folderEntry))
        }
        return result
    }
}
