//
//  PersonalFileListAPI.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/11/5.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SpaceInterface
import SKInfra

protocol PersonalFileListAPI {
    typealias SortOption = SpaceSortHelper.SortOption
    typealias FilterOption = SpaceFilterHelper.FilterOption
    // 是否是 Space 2.0 单容器版本，目前用户区分 more 面板内的列表上下文判断
    static var isV2: Bool { get }
    // 虚拟表 ID
    static var folderKey: DocFolderKey { get }
    // 是否允许过滤
    static var filterEnabled: Bool { get }
    // 是否允许分页
    static var pagingEnabled: Bool { get }

    static func queryList(count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff>
}

extension PersonalFileListAPI {
    static func queryList(count: Int,
                          lastLabel: String? = nil,
                          sortOption: SortOption? = nil,
                          filterOption: FilterOption? = nil,
                          extraParams: [String: Any]? = nil) -> Single<FileDataDiff> {
        queryList(count: count, lastLabel: lastLabel, sortOption: sortOption, filterOption: filterOption, extraParams: extraParams)
    }
}

enum V1PersonalFileListAPI: PersonalFileListAPI {

    static var isV2: Bool { false }
    // 虚拟表 ID
    static var folderKey: DocFolderKey { .personal }
    // 是否允许过滤
    static var filterEnabled: Bool { true }
    // 是否允许分页
    static var pagingEnabled: Bool { true }

    static func queryList(count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var params: [String: Any] = [
            "need_total": 1,
            "need_path": 1,
            "length": count
        ]

        var path = OpenAPI.APIPath.getPersonFileListInHome

        if let lastLabel = lastLabel {
            params["last_label"] = lastLabel
        }
        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }

        if let filterOption = filterOption {
            params = params.merging(filterOption.filterParams, uniquingKeysWith: { $1 })
            if let filterQuery = filterOption.filterQuery {
                path += "?\(filterQuery)"
            }
        }

        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }

        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .GET)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .default)) // 可能包含数据解析逻辑，放在后台线程解析
            .map { data in
                guard let json = data else {
                    throw NSError(domain: "request.recent.space", code: -1, userInfo: ["des": "recent files empty in fetch response"])
                }
                let result = DataBuilder.getPersonalFileData(from: json)
                return result
            }
            .observeOn(MainScheduler.instance)
    }
}

enum V2PersonalFileListAPI: PersonalFileListAPI {
    static var isV2: Bool { true }
    // 虚拟表 ID
    static var folderKey: DocFolderKey { .personal }
    // 是否允许过滤
    static var filterEnabled: Bool { false }
    // 是否允许分页
    static var pagingEnabled: Bool { false }

    static func queryList(count: Int, // v2 接口不支持分页，此参数会被忽略
                          lastLabel: String?, // v2 接口不支持分页，此参数会被忽略
                          sortOption: SortOption?,
                          filterOption: FilterOption?, // v2 接口的 filterOption 参数会被忽略
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {

        var params: [String: Any] = [
            "need_total": 1
        ]

        var path = OpenAPI.APIPath.mySpaceListV3
        let supportShortcutObjTypes: [DocsType] = [.folder, .doc, .sheet, .bitable, .mindnote, .file, .slides, .docX]
        let query = supportShortcutObjTypes.map { type in
            "shortcut_filter=\(type.rawValue)"
        }.joined(separator: "&")
        path += "?\(query)"

        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }

        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }

        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .GET)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .default)) // 可能包含数据解析逻辑，放在后台线程解析
            .map { data in
                guard let json = data else {
                    throw NSError(domain: "request.recent.space", code: -1, userInfo: ["des": "recent files empty in fetch response"])
                }
                let result = DataBuilder.getPersonalFileData(from: json)
                return result
            }
            .observeOn(MainScheduler.instance)
    }
}

// Space 2.0 + 新首页，云盘页的个人文件夹列表
enum V2PersonalFolderListAPI: PersonalFileListAPI {
    static var isV2: Bool { true }
    // 虚拟表 ID
    static var folderKey: DocFolderKey { .personalFolderV2 }

    static var filterEnabled: Bool { false }

    static var pagingEnabled: Bool { true }

    static func queryList(count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        let path = OpenAPI.APIPath.mySpaceFolder
        let defaultLength: Int = 50
        var params: [String: Any] = [
            "length": min(count, defaultLength)
        ]
        if let lastLabel {
            params["last_label"] = lastLabel
        }

        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }

        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }

        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .GET)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .default)) // 可能包含数据解析逻辑，放在后台线程解析
            .map { data in
                guard let json = data else {
                    throw NSError(domain: "request.recent.space", code: -1, userInfo: ["des": "recent files empty in fetch response"])
                }
                let result = DataBuilder.getPersonalFileData(from: json)
                return result
            }
            .observeOn(MainScheduler.instance)
    }
}

// 未整理列表
enum V3PersonalFileListAPI: PersonalFileListAPI {
    static var isV2: Bool { true }
    // 虚拟表 ID
    static var folderKey: DocFolderKey { .personalFileV3 }

    static var filterEnabled: Bool { false }

    static var pagingEnabled: Bool { true }

    static func queryList(count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var path = OpenAPI.APIPath.mySpaceFileV3
        var params: [String: Any] = [
            "length": count,
            "scene": "unsorted"     // 帮助后端区分该接口是用于“未整理”列表
        ]
        if let lastLabel {
            params["last_label"] = lastLabel
        }

        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }

        if let filterOption = filterOption {
            params = params.merging(filterOption.filterParams, uniquingKeysWith: { $1 })
            if let filterQuery = filterOption.filterQuery {
                path += "?\(filterQuery)"
            }
        }

        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }

        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .GET)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .default)) // 可能包含数据解析逻辑，放在后台线程解析
            .map { data in
                guard let json = data else {
                    throw NSError(domain: "request.recent.space", code: -1, userInfo: ["des": "recent files empty in fetch response"])
                }
                let result = DataBuilder.getPersonalFileData(from: json)
                return result
            }
            .observeOn(MainScheduler.instance)
    }
}
