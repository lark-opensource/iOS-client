//
//  QuickAccessListAPI.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/8/16.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SKInfra
import SpaceInterface

protocol QuickAccessListAPI {
    /// 拉取快速访问列表
    /// - Parameters:
    ///   - extraParams: 额外参数，慎用，目前仅有缩略图尺寸需要使用此参数
    static func queryList(extraParams: [String: Any]?) -> Single<FileDataDiff>
    
    // 数据库列表key
    static var folderKey: DocFolderKey { get }
}

extension QuickAccessListAPI {
    static func queryList(extraParams: [String: Any]? = nil) -> Single<FileDataDiff> {
        queryList(extraParams: extraParams)
    }
}

enum V1QuickAccessListAPI: QuickAccessListAPI {
    static var folderKey: DocFolderKey {
        .pins
    }
    
    static func queryList(extraParams: [String: Any]?) -> Single<FileDataDiff> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getPins, params: extraParams)
            .set(method: .GET)
        return request.rxStart().observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map({ json in
                guard let json = json else {
                    throw NSError(domain: "request.space.quickaccess", code: -1, userInfo: ["des": "quickaccess files empty in fetch response"])
                }
                let result = DataBuilder.getPinsFileData(from: json)
                return result
            })
            .observeOn(MainScheduler.instance)
    }
}

enum V2QuickAccessListAPI: QuickAccessListAPI {
    static var folderKey: DocFolderKey {
        .pins
    }
    
    static func queryList(extraParams: [String: Any]?) -> Single<FileDataDiff> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getPinsV2, params: extraParams)
            .set(method: .GET)
        return request.rxStart().observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map({ json in
                guard let json = json else {
                    throw NSError(domain: "request.space.quickaccess", code: -1, userInfo: ["des": "quickaccess files empty in fetch response"])
                }
                let result = DataBuilder.getPinsFileData(from: json)
                return result
            })
            .observeOn(MainScheduler.instance)
    }
}

// 快速访问文件夹列表
enum QuickAccessFolderListAPI: QuickAccessListAPI {
    static var folderKey: DocFolderKey {
        .pinFolderList
    }
    
    static func queryList(extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var params: [String: Any] = ["obj_type": DocsType.folder.rawValue]
        params.merge(other: extraParams)
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getPinsV2, params: params)
            .set(method: .GET)
        return request.rxStart().observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map({ json in
                guard let json = json else {
                    throw NSError(domain: "request.space.quickaccess.folder", code: -1, userInfo: ["des": "quickaccess folders empty in fetch response"])
                }
                let result = DataBuilder.getPinsFileData(from: json)
                return result
            })
            .observeOn(MainScheduler.instance)
    }
}
