//
//  SubordinateRecentListAPI.swift
//  SKSpace
//
//  Created by peilongfei on 2023/9/13.
//  


import RxSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SpaceInterface
import SKInfra

enum SubordinateRecentListAPI {

    typealias SortOption = SpaceSortHelper.SortOption
    typealias FilterOption = SpaceFilterHelper.FilterOption


    /// 拉取最近列表
    /// - Parameters:
    ///   - count: 拉取的数量
    ///   - lastLabel: 分页 label
    ///   - sortOption: 排序规则
    ///   - filterOption: 删选规则
    ///   - extraParams: 额外参数，慎用，目前仅有缩略图尺寸需要使用此参数
    static func queryList(subordinateID: String,
                          count: Int,
                          lastLabel: String? = nil,
                          sortOption: SortOption? = nil,
                          filterOption: FilterOption? = nil,
                          extraParams: [String: Any]? = nil) -> Single<(FileDataDiff, UserInfo)> {
        var params: [String: Any] = [
            "owner_id": subordinateID,
            "need_total": 1,
            "length": count
        ]

        // https://bytedance.feishu.cn/wiki/BVV3wUnwziWSoGkwT5ec5VXVn7c
        if UserScopeNoChangeFG.ZYP.recentListNewFilterEnable {
            params["type_opt"] = 1
        }

        var path = OpenAPI.APIPath.subordinateRecentList

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
                    throw NSError(domain: "request.subordinate-recent.space", code: -1, userInfo: ["des": "subordinate-recent files empty in fetch response"])
                }
                let result = DataBuilder.getSubordinateRecentData(from: json, subordinateID: subordinateID)
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
