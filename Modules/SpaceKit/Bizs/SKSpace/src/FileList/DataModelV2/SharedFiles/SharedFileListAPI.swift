//
//  SharedFileListAPI.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/11/4.
//
// disable-lint: magic number

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SKInfra

protocol SharedFileListAPI {
    typealias SortOption = SpaceSortHelper.SortOption
    typealias FilterOption = SpaceFilterHelper.FilterOption

    static var deleteEnabled: Bool { get }
    
    static var folderKey: DocFolderKey { get }

    static func queryList(count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff>
}

extension SharedFileListAPI {
    static func queryList(count: Int,
                          lastLabel: String? = nil,
                          sortOption: SortOption? = nil,
                          filterOption: FilterOption? = nil,
                          extraParams: [String: Any]? = nil) -> Single<FileDataDiff> {
        queryList(count: count, lastLabel: lastLabel, sortOption: sortOption, filterOption: filterOption, extraParams: extraParams)
    }
}

enum V1SharedFileListAPI: SharedFileListAPI {

    static var deleteEnabled: Bool { true }
    
    static var folderKey: DocFolderKey { .share }

    static func queryList(count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var params: [String: Any] = [
            "need_total": 1,
            "length": count
        ]

        var path = OpenAPI.APIPath.shareFiles

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
                let result = DataBuilder.getShareFileData(from: json)
                return result
            }
            .observeOn(MainScheduler.instance)
    }
}

enum V2SharedFileListAPI: SharedFileListAPI {

    static var deleteEnabled: Bool { false }
    
    static var folderKey: DocFolderKey { .share }

    static func queryList(count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        let isDefaultFilter: Bool
        if let filterOption = filterOption {
            isDefaultFilter = filterOption == .all
        } else {
            isDefaultFilter = true
        }
        if lastLabel == nil, isDefaultFilter {
            return queryFirstPageFullList(sortOption: sortOption, extraParams: extraParams)
        }

        var params: [String: Any] = [
            "need_total": 1,
            "length": count
        ]

        var path = OpenAPI.APIPath.shareFilesV2

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
        } else {
            // 仅在没有过滤参数的情况下，才需要在 lastLabel 不为 nil 时加这个参数
            params["forbidden_obj_type"] = 0
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
                let result = DataBuilder.getShareFileData(from: json)
                return result
            }
            .observeOn(MainScheduler.instance)
    }

    // 下拉刷新且没有过滤选项时，同时拉取文件夹和文件列表，合并返回
    private static func queryFirstPageFullList(sortOption: SortOption?, extraParams: [String: Any]?) -> Single<FileDataDiff> {
        let folderRequest = queryList(folderOnly: true, sortOption: sortOption, extraParams: extraParams)
        let filesRequest = queryList(folderOnly: false, sortOption: sortOption, extraParams: extraParams)

        return Single.zip(folderRequest, filesRequest)
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { folderJSON, filesJSON in
                guard let folderJSON = folderJSON,
                let filesJSON = filesJSON else {
                    throw NSError(domain: "request.shared-files.space", code: -1, userInfo: ["des": "share files empty in fetch response"])
                }
                let folderData = DataBuilder.getShareFileData(from: folderJSON)
                let filesData = DataBuilder.getShareFileData(from: filesJSON)
                return DataBuilder.mergeV2ShareFileData(folderData: folderData, filesData: filesData)
            }
            .observeOn(MainScheduler.instance)
    }

    // 通过 v2 接口拉取与我共享列表
    private static func queryList(folderOnly: Bool, sortOption: SortOption?, extraParams: [String: Any]?) -> Single<JSON?> {
        var params: [String: Any] = [
            "need_total": 1
        ]
        if folderOnly {
            params["obj_type"] = 0
            params["length"] = 800
        } else {
            params["forbidden_obj_type"] = 0
            params["length"] = 100
        }

        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }

        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }

        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.shareFilesV2, params: params)
            .set(method: .GET)
        return request.rxStart()
    }
}

enum V3SharedFileListAPI: SharedFileListAPI {
    static var deleteEnabled: Bool { false }
    
    static var folderKey: DocFolderKey { .share }
    
    static func queryList(count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var params: [String: Any] = [
            "need_total": 1,
            "forbidden_obj_type": 0,
            "length": count
        ]
        
        var path = OpenAPI.APIPath.shareFilesV2
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
                    throw NSError(domain: "request.shareFile-V2.space", code: -1, userInfo: ["des": "recent files empty in fetch response"])
                }
                let result = DataBuilder.getShareFileData(from: json)
                return result
            }
            .observeOn(MainScheduler.instance)
    }
}

enum V4ShareFileListAPI: SharedFileListAPI {
    static var deleteEnabled: Bool { false }
    
    static var folderKey: DocFolderKey { .spaceTabShared }
    
    static func queryList(count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        let sortOption = SortOption(type: .sharedTime, descending: true, allowAscending: false)
        return V3SharedFileListAPI.queryList(count: count, lastLabel: nil, sortOption: sortOption, filterOption: nil, extraParams: extraParams)
    }
}
