//
//  ClientVarMetaDataManager.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/30.
//

import Foundation
import SKInfra

public protocol ClientVarMetaDataManagerAPI {
    func getMetaDataRecordBy(_ objToken: FileListDefine.ObjToken) -> ClientVarMetaData
    func getAllNeedSyncTokens() -> Set<String>
}

final class ClientVarMetaDataManager: ClientVarMetaDataManagerAPI {
    let newCacheAPI: NewCacheAPI

    init(_ resolver: DocsResolver = DocsContainer.shared) {
        newCacheAPI = resolver.resolve(NewCacheAPI.self)!
    }

    func getMetaDataRecordBy(_ objToken: FileListDefine.ObjToken) -> ClientVarMetaData {
        return newCacheAPI.getMetaDataRecordBy(objToken)
    }
    
    func getAllNeedSyncTokens() -> Set<String> {
        return newCacheAPI.getAllNeedSyncTokens()
    }
}
