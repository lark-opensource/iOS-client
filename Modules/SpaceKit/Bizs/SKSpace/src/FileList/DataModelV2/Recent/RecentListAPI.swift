//
//  RecentListAPI.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/7/1.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SpaceInterface
import SKInfra

protocol RecentListAPI {
    typealias SortOption = SpaceSortHelper.SortOption
    typealias FilterOption = SpaceFilterHelper.FilterOption
    static func queryList(count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff>

    static func listModifier(sortOption: SortOption, filterOption: FilterOption) -> SpaceListModifier

    // 通用的从最近列表移除功能
    static func removeFromRecentList(objToken: FileListDefine.ObjToken,
                                     docType: DocsType) -> Completable
}


extension RecentListAPI {

    static func queryList(count: Int,
                          lastLabel: String? = nil,
                          sortOption: SortOption? = nil,
                          filterOption: FilterOption? = nil,
                          extraParams: [String: Any]? = nil) -> Single<FileDataDiff> {
        queryList(count: count, lastLabel: lastLabel, sortOption: sortOption, filterOption: filterOption, extraParams: extraParams)
    }

    static func removeFromRecentList(objToken: FileListDefine.ObjToken,
                                     docType: DocsType) -> Completable {
        var params: [String: Any] = [String: Any]()
        params["obj_token"] = objToken
        params["obj_type"] = docType.rawValue
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.deleteRecentFileByObjTokenV2,
                                        params:["entities": [params]])
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart().asCompletable()
    }
}

enum StandardRecentListAPI: RecentListAPI {
    
    /// 拉取最近列表  
    /// - Parameters:
    ///   - count: 拉取的数量
    ///   - lastLabel: 分页 label
    ///   - sortOption: 排序规则
    ///   - filterOption: 删选规则
    ///   - extraParams: 额外参数，慎用，目前仅有缩略图尺寸需要使用此参数
    static func queryList(count: Int,
                          lastLabel: String? = nil,
                          sortOption: SortOption? = nil,
                          filterOption: FilterOption? = nil,
                          extraParams: [String: Any]? = nil) -> Single<FileDataDiff> {
        var params: [String: Any] = [
            "need_total": 1,
            "length": count
        ]

        // https://bytedance.feishu.cn/wiki/BVV3wUnwziWSoGkwT5ec5VXVn7c
        if UserScopeNoChangeFG.ZYP.recentListNewFilterEnable {
            params["type_opt"] = 1
        }

        var path = OpenAPI.APIPath.recentUpdate

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
                let result = DataBuilder.getRecentFileData(from: json)
                return result
            }
            .observeOn(MainScheduler.instance)
    }

    static func listModifier(sortOption: SortOption, filterOption: FilterOption) -> SpaceListModifier {
        let modifier: SpaceListComplexModifier = [
            SpaceListFilterModifier(filterOption: filterOption),
            SpaceRecentListModifier(sortOption: sortOption),
            SpaceListSortModifier(sortOption: sortOption)
        ]
        return modifier
    }
}

enum LeanModeRecentListAPI: RecentListAPI {

    /// 精简模式下拉取最近列表
    /// - Parameters:
    ///   - count: 拉取的数量
    ///   - lastLabel: 分页 label
    ///   - sortOption: 排序规则
    ///   - filterOption: 删选规则
    ///   - extraParams: 额外参数，慎用，目前仅有缩略图尺寸需要使用此参数
    static func queryList(count: Int,
                          lastLabel: String? = nil,
                          sortOption: SortOption? = nil,
                          filterOption: FilterOption? = nil,
                          extraParams: [String: Any]? = nil) -> Single<FileDataDiff> {
        // 精简模式下不需要 need_total
        var params: [String: Any] = [
            "length": count
        ]

        if UserScopeNoChangeFG.ZYP.recentListNewFilterEnable {
            params["type_opt"] = 1
        }

        var path = OpenAPI.APIPath.recentUpdate

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

        // 注意精简模式的 API 不同
        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .GET)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .default)) // 可能包含数据解析逻辑，放在后台线程解析
            .map { data in
                guard let json = data else {
                    throw NSError(domain: "request.recent.space", code: -1, userInfo: ["des": "recent files empty in lean mode fetch response"])
                }
                let result = DataBuilder.getRecentFileData(from: json)
                return result
            }
            .observeOn(MainScheduler.instance)
    }

    static func listModifier(sortOption: SortOption, filterOption: FilterOption) -> SpaceListModifier {
        let modifier: SpaceListComplexModifier = [
            SpaceListFilterModifier(filterOption: filterOption),
            SpaceLeanModeModifier(),
            SpaceRecentListModifier(sortOption: sortOption),
            SpaceListSortModifier(sortOption: sortOption)
        ]
        return modifier
    }
}
