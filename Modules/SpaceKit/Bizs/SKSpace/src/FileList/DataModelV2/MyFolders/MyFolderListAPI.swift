//
//  MyFolderListAPI.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/10/21.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SKInfra

struct MyFolderListResult {
    let dataDiff: FileDataDiff
    // 我的空间根目录 token，仅 1.0 相关接口会使用
    let rootToken: String?
}

protocol MyFolderListAPIType {
    typealias SortOption = SpaceSortHelper.SortOption

    typealias ListResult = MyFolderListResult

    static func queryList(count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          extraParams: [String: Any]?) -> Single<ListResult>

    static func listModifier(sortOption: SortOption) -> SpaceListModifier
}

extension MyFolderListAPIType {
    static func queryList(count: Int) -> Single<ListResult> {
        queryList(count: count, lastLabel: nil, sortOption: nil, extraParams: nil)
    }
}

enum MyFolderListAPI: MyFolderListAPIType {
    typealias SortOption = SpaceSortHelper.SortOption

    /// 拉取我的文件夹列表
    /// - Parameters:
    ///   - count: 分页数量
    ///   - lastLabel: 分页标签
    ///   - sortOption: 排序选项
    ///   - extraParams: 额外参数，慎用，目前仅有缩略图尺寸需要使用此参数
    /// - Returns: 我的文件夹的 json 解析目前写在 ReAction 内，暂时兼容原有逻辑，不在 API 层解析，例外会尝试解析我的空间根目录 token
    static func queryList(count: Int,
                          lastLabel: String? = nil,
                          sortOption: SortOption? = nil,
                          extraParams: [String: Any]? = nil) -> Single<ListResult> {
        var params: [String: Any] = [
            "type": 0, // 表明过滤文件夹？
            "token": "", // 表明我的空间根目录
            "need_path": 1, // 表明需要返回我的空间根目录自身，核心在于获取我的空间根目录 token
            "need_total": 1,
            "length": count,
            "show_no_perm": 1 // 需要显示无权限文件，但我的文件夹列表理论上不存在无权限文件，暂时保留
        ]

        if let lastLabel = lastLabel {
            params["last_label"] = lastLabel
        }
        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }

        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }

        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.folderDetail, params: params)
            .set(method: .GET)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .default)) // 可能包含数据解析逻辑，放在后台线程解析
            .map { data in
                guard let json = data else {
                    throw NSError(domain: "request.my-folder.space", code: -1, userInfo: ["des": "empty my folder data in fetch response"])
                }
                let rootToken = json["data"]["path"].arrayValue.first?.string
                let dataDiff = DataBuilder.getFolderData(from: json, parent: rootToken ?? "")
                return ListResult(dataDiff: dataDiff, rootToken: rootToken)
            }
            .observeOn(MainScheduler.instance)
    }

    static func listModifier(sortOption: SortOption) -> SpaceListModifier {
        SpaceListSortModifier(sortOption: sortOption)
    }
}
