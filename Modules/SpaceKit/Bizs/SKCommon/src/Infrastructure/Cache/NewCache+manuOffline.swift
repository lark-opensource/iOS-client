//
//  NewCache+manuOffline.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/8/28.
//

import SKFoundation
import SpaceInterface
import SKInfra

public struct SKPicMapInfo: CustomStringConvertible {
    var objToken: String
    var picKey: String
    var picType: Int
    var needUpLoad: Bool
    var isDrive: Bool?
    var updateTime: Double?

    public var description: String {
        return "PicMapInfo: objToken=\(objToken.encryptToken), picKey=\(picKey.encryptToken), picType=\(picType), isDrive=\(isDrive ?? false),needUpLoad=\(needUpLoad)"
    }
}

extension NewCache: ManualOfflineFileStatusObserver {
    func didReceivedFileOfflineStatusAction(_ action: ManualOfflineAction) {
        manuOfflineQueue.async {
            switch action.event {
            case .add:
                let keys = action.files.map { $0.objToken }
                self.handleAddManuOffline(tokens: keys)
            case .remove:
                let keys = action.files.map { $0.objToken }
                let isEntityDeleted: Bool
                if let value = action.extra?[.entityDeleted] as? Bool {
                    isEntityDeleted = value
                } else {
                    isEntityDeleted = false
                }
                self.handleRemoveManuOffline(tokens: keys, isEntityDeleted: isEntityDeleted)
            default: ()
            }
        }
    }

    private func handleAddManuOffline(tokens: [String]) {
        guard tokens.count > 0 else { return }
        let encryptKeys = tokens.map { $0.encryptToken }
        let (docsPics, drivePics) = getAllPics(tokens: tokens)
        var moveCount: Int = 0
        for picItem in docsPics {
            let imageInCache: NSCoding? = CacheService.docsImageCache.object(forKey: picItem.picKey)
            if let imageInCache = imageInCache {
                moveCount += 1
                CacheService.docsImageStore.set(object: imageInCache, forKey: picItem.picKey)
                CacheService.docsImageCache.removeObject(forKey: picItem.picKey)
            }
        }
        let driveInfos = drivePics.compactMap { info -> (String, DocCommonDownloadType)? in
            guard let downloadType = DocCommonDownloadType(rawValue: info.picType) else { return nil }
            return (info.objToken, downloadType)
        }
        DocsContainer.shared.resolve(SpaceDownloadCacheProtocol.self)!.addImagesToManualCache(infos: driveInfos)
        DocsLogger.info("NewCache,didReceivedFileOfflineAction, add,keys=\(encryptKeys), docsPics=\(docsPics), drivePics=\(drivePics), docMoveCount=\(moveCount)")
    }

    private func handleRemoveManuOffline(tokens: [String], isEntityDeleted: Bool) {
        guard tokens.count > 0 else { return }
        let encryptKeys = tokens.map { $0.encryptToken }
        let (docsPics, drivePics) = getAllPics(tokens: tokens)
        var moveCount: Int = 0
        for picItem in docsPics {
            let imageInCache: NSCoding? = CacheService.docsImageStore.object(forKey: picItem.picKey)
            if let imageInCache = imageInCache {
                moveCount += 1
                CacheService.docsImageCache.set(object: imageInCache, forKey: picItem.picKey)
                CacheService.docsImageStore.removeObject(forKey: picItem.picKey)
            }
        }

        if isEntityDeleted {
            tokens.forEach {
                let objToken = $0
                self.cachedDictQueue.async { // 清理内存缓存
                    self.metaDataCache.removeValue(forKey: objToken)
                    // 因为不知道 H5DataRecordKey 的 key，只知道objToken，所以全取出来然后过滤出objToken一致的记录
                    let items = self.clientVarCache.allKeys()
                    for item in items where item.objToken == objToken {
                        self.clientVarCache.removeValue(forKey: item)
                    }
                }
                _ = self.sql?.deleteItemByObjToken(objToken: objToken) // 清理数据库缓存
                DocsLogger.info("NewCache, sql deleteItemByObjToken:\(objToken.encryptToken)")
            }
        }

        let driveInfos = drivePics.compactMap { info -> (String, DocCommonDownloadType)? in
            guard let downloadType = DocCommonDownloadType(rawValue: info.picType) else { return nil }
            return (info.objToken, downloadType)
        }
        DocsContainer.shared.resolve(SpaceDownloadCacheProtocol.self)!.removeImagesFromManualCache(infos: driveInfos)
        DocsLogger.info("NewCache,didReceivedFileOfflineAction, remove,keys=\(encryptKeys), docsPics=\(docsPics), drivePics=\(drivePics), docMoveCount=\(moveCount), isEntityDeleted:\(isEntityDeleted)")
    }

    private func getAllPics(tokens: [String]) -> ([SKPicMapInfo], [SKPicMapInfo]) {
        guard let allPicInfos = self.sql?.getAllPicInfos(tokens: tokens, ignoreNeedUpload: true)  else {
            return ([], [])
        }
        var docsPic: [SKPicMapInfo] = []
        var drivePic: [SKPicMapInfo] = []
        allPicInfos.forEach { (picInfo) in
            if picInfo.isDrive == true {
                drivePic.append(picInfo)
            } else {
                docsPic.append(picInfo)
            }
        }
        return (docsPic, drivePic)
    }
}
