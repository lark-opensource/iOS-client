//
//  WikiTreeOfflineChecker.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/27.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKCommon
import SKInfra
import LarkContainer

public protocol WikiTreeOfflineCheckerType {
    func checkOfflineEnable(meta: WikiTreeNodeMeta) -> Bool
}

public class WikiMainTreeOfflineChecker: WikiTreeOfflineCheckerType {

    let driveCacheService: DriveCacheServiceBase?
    let clientVarAPI: ClientVarMetaDataManagerAPI?
    let userReslover: UserResolver

    public init(userReslover: UserResolver) {
        driveCacheService = DocsContainer.shared.resolve(DriveCacheServiceBase.self)
        clientVarAPI = DocsContainer.shared.resolve(ClientVarMetaDataManagerAPI.self)
        self.userReslover = userReslover
    }

    public func checkOfflineEnable(meta: WikiTreeNodeMeta) -> Bool {
        guard meta.objType.offLineEnable else { return false }
        
        if meta.objToken.isFakeToken {
            return true
        }
        
        if meta.nodeLocation == .wiki {
            // 目录树上的wiki文档需要校验一下wikiInfo缓存
            let wikiStroge = try? userReslover.resolve(assert: WikiStorage.self)
            if wikiStroge?.getWikiInfo(by: meta.wikiToken) == nil {
                return false
            }
        }
        
        if meta.objType == .file {
            let fileExtension = SKFilePath.getFileExtension(from: meta.title)
            return driveCacheService?.canOpenOffline(token: meta.objToken,
                                                     dataVersion: nil,
                                                     fileExtension: fileExtension) ?? false
        } else {
            return clientVarAPI?.getMetaDataRecordBy(meta.objToken).hasClientVar ?? false
        }
    }
}
