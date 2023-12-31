//
//  ShareFolderListAPI.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/10/22.
//
// disable-lint: magic number

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SKInfra


protocol ShareFolderListAPI {
    typealias SortOption = SpaceSortHelper.SortOption
    /// 拉取共享文件夹列表，全量拉取不分页
    static func queryList(sortOption: SortOption?, lastLabel: String?, extraParams: [String: Any]?) -> Single<FileDataDiff>
    // 是否允许设置隐藏状态
    static var toggleHiddenStatusEnabled: Bool { get }
    // 数据库的key
    static var folderKey: DocFolderKey { get }
}

extension ShareFolderListAPI {
    static func queryList(sortOption: SortOption? = nil, lastLabel: String? = nil, extraParams: [String: Any]? = nil) -> Single<FileDataDiff> {
        queryList(sortOption: sortOption, lastLabel: lastLabel, extraParams: extraParams)
    }
}

/// 无单容器灰度的 API 接口，会分别拉取隐藏文件夹、非隐藏文件夹，合并后返回
enum V1ShareFolderListAPI: ShareFolderListAPI {

    static var toggleHiddenStatusEnabled: Bool { true }
    static var folderKey: DocFolderKey { DocFolderKey.shareFolder }

    static func queryList(sortOption: SortOption?,
                          lastLabel: String?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var params: [String: Any] = [
            "manager_first": true // 意义不明的参数，历史逻辑一直在传 true，这里保留，写死取值，等一位有缘人了解意义后更新下注释
        ]

        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }

        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }
        // 分别请求非隐藏、隐藏的文件夹，合并后返回列表汇总数据
        var nonHiddenFolderParams = params
        nonHiddenFolderParams["hidden"] = 0
        var hiddenFolderParams = params
        hiddenFolderParams["hidden"] = 1
        let nonHiddenRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.newShareFolder, params: nonHiddenFolderParams).set(method: .GET).rxStart()
        let hiddenRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.newShareFolder, params: hiddenFolderParams).set(method: .GET).rxStart()
        return Single.zip(nonHiddenRequest, hiddenRequest)
            .observeOn(SerialDispatchQueueScheduler(qos: .default)) // 可能包含数据解析逻辑，放在后台线程解析
            .map { nonHiddenJSON, hiddenJSON in
                guard let nonHiddenJSON = nonHiddenJSON,
                      let hiddenJSON = hiddenJSON else {
                          throw NSError(domain: "request.share-folder.space", code: -1, userInfo: ["des": "empty share folder data in fetch response"])
                      }
                let nonHiddenData = DataBuilder.getShareFoldersData(data: nonHiddenJSON)
                let hiddenData = DataBuilder.getShareFoldersData(data: hiddenJSON)
                return DataBuilder.mergeShareFolderData(nonHiddenData, hiddenData)
            }
            .observeOn(MainScheduler.instance)
    }
}

// 单容器灰度后，共享文件夹列表入口仅有与我共享 banner，列表拉取逻辑不同，只有非owner的非隐藏共享文件夹
public enum V2ShareFolderListAPI: ShareFolderListAPI {

    static var toggleHiddenStatusEnabled: Bool { false }
    static var folderKey: DocFolderKey { DocFolderKey.shareFolder }

    static func queryList(sortOption: SortOption?,
                          lastLabel: String?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var params: [String: Any] = [
            "be_shared": true,
            "manager_first": true // 意义不明的参数，历史逻辑一直在传 true，这里保留，写死取值，等一位有缘人了解意义后更新下注释
        ]

        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }

        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.newShareFolder, params: params)
            .set(method: .GET)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .default)) // 可能包含数据解析逻辑，放在后台线程解析
            .map { data in
                guard let json = data else {
                          throw NSError(domain: "request.share-folder.space", code: -1, userInfo: ["des": "empty share folder data in fetch response"])
                      }
                return DataBuilder.getShareFoldersData(data: json)
            }
            .observeOn(MainScheduler.instance)
    }

    public static func checkHasHistoryFolder() -> Single<Bool> {
        queryList().map { dataDiff in
            return !dataDiff.shareFoldersObjs.isEmpty
        }
    }
}

public enum V3ShareFolderListAPI: ShareFolderListAPI {
    static var toggleHiddenStatusEnabled: Bool { true }
    static var folderKey: DocFolderKey { DocFolderKey.shareFolderV2 }
    
    static func queryList(sortOption: SortOption?,
                          lastLabel: String?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var params: [String: Any] = ["length": 50, "hidden": false]
        
        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }
        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }
        if let lastLabel = lastLabel {
            params["last_label"] = lastLabel
        }
        
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.newShareFolderV2, params: params).set(method: .GET)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .default)) // 可能包含数据解析逻辑，放在后台线程解析
            .map { data in
                guard let json = data else {
                    throw NSError(domain: "request.share-folder-V2.space", code: -1, userInfo: ["des": "empty share folder data in fetch response"])
                }
                let dataDiff = DataBuilder.getShareFoldersData(data: json)
                return DataBuilder.addHiddenStatusMark(false, to: dataDiff)
            }
            .observeOn(MainScheduler.instance)
    }
}

public enum HiddenFolderListAPI: ShareFolderListAPI {
    static var toggleHiddenStatusEnabled: Bool { true }
    static var folderKey: DocFolderKey { DocFolderKey.hiddenFolder }
    
    static func queryList(sortOption: SortOption?,
                          lastLabel: String?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var params: [String: Any] = ["length": 50, "hidden": true]
        
        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }
        
        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }
        
        if let lastLabel = lastLabel {
            params["last_label"] = lastLabel
        }
        
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.newShareFolderV2, params: params).set(method: .GET)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { data in
                guard let json = data else {
                    throw NSError(domain: "request.share-folder-v2-hidden.space", code: -1, userInfo: ["des": "empty share folder data in fetch response"])
                }
                let dataDiff = DataBuilder.getShareFoldersData(data: json)
                return DataBuilder.addHiddenStatusMark(true, to: dataDiff)
            }
            .observeOn(MainScheduler.instance)
    }
    
    public static func checkHasHiddenFolder() -> Single<Bool> {
        queryList().map { data in
            return !data.shareFoldersObjs.isEmpty
        }
    }
}
