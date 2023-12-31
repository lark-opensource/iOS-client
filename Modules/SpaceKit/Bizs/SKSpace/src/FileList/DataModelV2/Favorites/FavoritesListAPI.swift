//
//  FavoritesListAPI.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/8/20.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SKInfra

protocol FavoritesListAPI {
    typealias FilterOption = SpaceFilterHelper.FilterOption

    /// 拉取收藏列表
    /// - Parameters:
    ///   - count: 分页数量
    ///   - lastLabel: 分页标签
    ///   - filterOption: 过滤选项
    ///   - extraParams: 额外参数，慎用，目前仅有缩略图尺寸需要使用此参数
    static func queryList(count: Int,
                          lastLabel: String?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff>
}

extension FavoritesListAPI {
    static func queryList(count: Int,
                          lastLabel: String? = nil,
                          filterOption: FilterOption? = nil,
                          extraParams: [String: Any]? = nil) -> Single<FileDataDiff> {
        queryList(count: count, lastLabel: lastLabel, filterOption: filterOption, extraParams: extraParams)
    }
}

enum V1FavoritesListAPI: FavoritesListAPI {
    static func queryList(count: Int,
                          lastLabel: String?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {

        var params: [String: Any] = [
            "need_total": 1,
            "length": count
        ]

        var path = OpenAPI.APIPath.getFavorites

        if let lastLabel = lastLabel {
            params["last_label"] = lastLabel
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
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map({ json in
                guard let json = json else {
                    throw NSError(domain: "request.space.favorites", code: -1, userInfo: ["des": "quickaccess files empty in fetch response"])
                }
                let result = DataBuilder.getFavoritesFileData(from: json)
                return result
            })
            .observeOn(MainScheduler.instance)
    }
}

enum V2FavoritesListAPI: FavoritesListAPI {
    static func queryList(count: Int,
                          lastLabel: String?,
                          filterOption: FilterOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var params: [String: Any] = [
            "need_total": 1,
            "length": count
        ]

        var path = OpenAPI.APIPath.getFavoritesV2

        // https://bytedance.feishu.cn/wiki/BVV3wUnwziWSoGkwT5ec5VXVn7c
        if UserScopeNoChangeFG.ZYP.recentListNewFilterEnable {
            params["type_opt"] = 1
        }
        
        if let lastLabel = lastLabel {
            params["last_label"] = lastLabel
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
        return request.rxStart().observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map({ json in
                guard let json = json else {
                    throw NSError(domain: "request.space.favorites", code: -1, userInfo: ["des": "quickaccess files empty in fetch response"])
                }
                let result = DataBuilder.getFavoritesFileData(from: json)
                return result
            })
            .observeOn(MainScheduler.instance)
    }
}
