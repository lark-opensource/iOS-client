//
//  ClientVarSqlTableManager.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2019/12/22.

import SKFoundation
import SQLite
import RxCocoa
import RxRelay
import RxSwift
import Foundation
import SpaceInterface
import SKInfra

typealias CleanDataCallBack = (Bool, Int, Int, Int) -> Void
typealias TotalSizeCallBack = (Bool, Int, Int) -> Void
protocol NewCacheBaseProtocol {
    func userDidLogout()
    func userDidLogin()
    func cacheTrim(maxSize: Int, ageLimit: Int, isUserTrigger: Bool, complete: @escaping CleanDataCallBack)
    func getTotalSize(complete: @escaping TotalSizeCallBack)
}

final class ClientVarSqlTableManager: NewCacheBaseProtocol {

    private var delayToHandle: Int {
        var delay = SettingConfig.offlineDbConfig?.docsDelayToClean ?? 0
        if delay <= 0 {
            delay = 120
        }
        return delay
    }

    private var autoTrimSize: Int {
        var remoteConfigSize = SettingConfig.offlineDbConfig?.clientVarCacheSize ?? 0
        if remoteConfigSize <= 0 {
            remoteConfigSize = 200 * 1024 * 1024
        }
        return remoteConfigSize
    }

    private let connectLock = NSLock()
    private var fileListDbLoaded = false
    var writeQueue = DispatchQueue(label: "com.bytedance.net.newcache.write")
    private var trimQueue = DispatchQueue(label: "com.bytedance.net.newcache.trim", qos: DispatchQoS.background)
    let metaTable: FileMetaDataTable = {
        return FileMetaDataTable()
    }()
    let rawDataTable: RawDataTable = {
        return RawDataTable()
    }()
    let picInfoTable: SKPicInfoTable = {
        return SKPicInfoTable()
    }()
    let assetInfoTable: SKAssetInfoTable = {
        return SKAssetInfoTable()
    }()


    private var _writeConection: Connection?
    var writeConection: Connection? {
        connectLock.lock()
        defer {
            connectLock.unlock()
        }
        guard _writeConection == nil else {
            return _writeConection
        }
        _writeConection = createWriteConnection()
        return _writeConection
    }

    private var _readConnection: Connection?
    var readConnection: Connection? {
        //需要先创建writeConection，因为需要数据库升级
        _ = writeConection

        connectLock.lock()
        defer {
            connectLock.unlock()
        }
        guard _readConnection == nil else {
            return _readConnection
        }
        _readConnection = createReadConnection()
        return _readConnection
    }
    private let disposeBag = DisposeBag()


    init() {
        if let dbLoaded = DocsContainer.shared.resolve(DataCenterAPI.self)?.dbLoadingStateObservable {
            dbLoaded.asObservable().subscribe(onNext: { [weak self] ret in
                guard let self = self else { return }
                self.fileListDbLoaded = ret
            }).disposed(by: disposeBag)
        }
    }

    @objc
    func userDidLogin() {
        ///这里先不初始化_writeConection、_readConnection，延迟到使用再初始化
        ///
    }

    func userDidLogout() {
        connectLock.lock()
        defer {
            connectLock.unlock()
        }
        _writeConection = nil
        _readConnection = nil
        fileListDbLoaded = false
    }

    func cacheTrim(maxSize: Int, ageLimit: Int, isUserTrigger: Bool, complete: @escaping CleanDataCallBack) {
        trimQueue.async {
            if isUserTrigger {
                self.trimToSize(maxSize: 0, complete: complete)
            } else {
                self.trimToSize(maxSize: maxSize, ageLimit: ageLimit, complete: complete)
            }
        }
    }

    func getTotalSize(complete: @escaping TotalSizeCallBack) {
        trimQueue.async {
            DocsLogger.info("getTotalSize clientVar begin", component: LogComponents.newCache)
            guard let readConnection = self.readConnection else {
                complete(false, 0, 0)
                return
            }
            let (hadLoadFileListDb, manuOfflineTokens) = self.getManuOfflineTokens()
            guard hadLoadFileListDb else {
                DocsLogger.info("getTotalSize 列表数据库还没加载完, 提前返回", component: LogComponents.newCache)
                complete(false, 0, 0)
                return
            }
            let beginTime = Date.timeIntervalSinceReferenceDate

            DocsLogger.info("getTotalSize manuOfflineTokens=\(manuOfflineTokens.count)", component: LogComponents.newCache)

            var sum = self.rawDataTable.getTotalDataSize(connection: readConnection, manuOfflineTokens: manuOfflineTokens) ?? 0
            if CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.didOpenOneDocsFile) == false {
                sum = (sum < 1 * 1024 * 1024) ? 0 : sum
            }
            let endTime = Date.timeIntervalSinceReferenceDate
            let costTime = endTime - beginTime
            DocsLogger.info("getTotalSize clientVar end total=\(sum), costTime=\(costTime)", component: LogComponents.newCache)
            complete(true, Int(costTime * 1000), sum)
        }
    }

    func trimToSize(maxSize: Int, ageLimit: Int? = nil, complete: CleanDataCallBack?) {
        let maxSize = maxSize
        let limitAge = ageLimit ?? Int(INT_MAX)
        let maxTimeInterval = Date.timeIntervalSinceReferenceDate - Double(limitAge)
        let beginTime = Date.timeIntervalSinceReferenceDate
        DocsLogger.info("trimToSize begin, maxSize=\(maxSize), limitAge=\(limitAge), maxTimeInterVal=\(maxTimeInterval)", component: LogComponents.newCache)
        guard let readConnection = self.readConnection else {
            complete?(false, 0, 0, 0)
            return
        }
        let (hadLoadFileListDb, manuOfflineTokens) = getManuOfflineTokens()
        guard hadLoadFileListDb else {
            DocsLogger.info("trimToSize 列表数据库还没加载完，提前返回", component: LogComponents.newCache)
            complete?(false, 0, 0, 0)
            return
        }
        DocsLogger.info("trimToSize manuOfflineTokens=\(manuOfflineTokens.count)", component: LogComponents.newCache)

        let sum = self.rawDataTable.getTotalDataSize(connection: readConnection, manuOfflineTokens: manuOfflineTokens) ?? 0
        var currentMaxAccessTime: TimeInterval = 0
        DocsLogger.info("trimToSize totalSize=\(sum)", component: LogComponents.newCache)

        var deleteItems: Int = 0
        var totalSize = sum
        while totalSize > maxSize || currentMaxAccessTime < maxTimeInterval {
            let perCount = 16
            let items = self.rawDataTable.getItemsOrderByAscTimeInTokenGroup(maxCount: perCount, connection: readConnection, manuOfflineTokens: manuOfflineTokens)
            var deleteSomeItemSuc = false
            for item in items {
                currentMaxAccessTime = item.maxAccessTime ?? TimeInterval(0)
                if totalSize > maxSize || currentMaxAccessTime < maxTimeInterval {
                    ///deleate item
                    deleteSomeItemSuc = deleteItemByObjToken(objToken: item.objToken) || deleteSomeItemSuc
                    totalSize -= item.groupDataSize
                    deleteItems += 1
                } else {
                    DocsLogger.info("trimToSize already achieve, deleteItems=\(deleteItems)", component: LogComponents.newCache)
                    break
                }
            }
            if items.count == 0 || deleteSomeItemSuc == false {
                ///异常退出
                DocsLogger.info("trimToSize items.count=\(items.count), deleteSomeItemSuc=\(deleteSomeItemSuc), deleteItems=\(deleteItems)", component: LogComponents.newCache)
                break
            }
        }
        
        let endTime = Date.timeIntervalSinceReferenceDate
        let costTime = endTime - beginTime
        DocsLogger.info("trimToSize end from=\(sum), to=\(totalSize); currentMaxAccessTime=\(currentMaxAccessTime), costTime=\(costTime)", component: LogComponents.newCache)
        totalSize = totalSize < 0 ? 0 : totalSize
        complete?(true, Int(costTime * 1000), totalSize, sum - totalSize)
    }

    func deleteItemByObjToken(objToken: FileListDefine.ObjToken) -> Bool {
        ///删掉rawTable里对应objToken组所有项中"单独存在文件里的clientVar" (注意 !objToken.isEmpty,不然数据库都被删了)
        if objToken.isEmpty == false {
            let cacheDir = SKFilePath.clientVarCacheDir.appendingRelativePath(objToken)
            if cacheDir.exists {
                do {
                    try cacheDir.removeItem()
                } catch {
                    DocsLogger.error("[SKFilePath] trimToSize deleteItemByObjToken", component: LogComponents.newCache)
                    spaceAssertionFailure("[SKFilePath] trimToSize deleteItemByObjToken error")
                }
            }
        }

        var hadDeleteItem = false
        ///删掉数据库里对应的项
        self.writeQueue.sync {
            guard let writeConnection = self.writeConection else {
                hadDeleteItem = false
                return
            }
            ///删掉rawTable里对应objToken组的所有项
            let deleteRaw = self.rawDataTable.deleteItemsByObjToken(objToken, connection: writeConnection)
            ///删掉metaTable里对应objToken项
            let deleteMeta = self.metaTable.deleteItemsByObjToken(objToken, connection: writeConnection)
            ///删掉picInfoTable里对应objToken项
            _ = self.picInfoTable.deleteItemsByObjToken(objToken, connection: writeConnection)
            hadDeleteItem = deleteRaw || deleteMeta
        }
        return hadDeleteItem
    }

    private func getManuOfflineTokens() -> (Bool, [FileListDefine.ObjToken]) {
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            return (false, [])
        }
        var manuOfflineTokens = [FileListDefine.ObjToken]()
        let dbHadLoad = dataCenterAPI.hadLoadDBForCurrentUser
        manuOfflineTokens = dataCenterAPI.manualOfflineTokens.compactMap({ $0.token })
        return (dbHadLoad, manuOfflineTokens)
    }

    //找出未同步的图片
//    func findNeedSyncPics() -> [FileListDefine.ObjToken: [String]]? {
//        DocsLogger.info("findNeedSyncPic pic begin", component: LogComponents.newCache)
//        guard let readConnection = self.readConnection else {
//            DocsLogger.info("findNeedSyncPic readConnection is nil", component: LogComponents.newCache)
//            return nil
//        }
//        let items = self.rawDataTable.getChangeSetAndNeedSyncItem(connection: readConnection)
//        DocsLogger.info("findNeedSyncPic pic syncItems=\(items.count)", component: LogComponents.newCache)
//        var picKeyDic = [FileListDefine.ObjToken: [String]]()
//        var totalCount = 0
//
//        for item in items {
//            var payload = item.payload
//            if payload == nil {
//                let filePath = H5DataRecord.payLoadFilePathIfExist(objToken: item.objToken, md5Key: item.md5Key)
                    // 需要使用SKFilePath类型操作文件，这里已注释就不改造了
//                if FileManager.default.fileExists(atPath: filePath) {
//                    let url = URL(fileURLWithPath: filePath)
//                    let fileData = try? Data(contentsOf: url)
//                    DocsLogger.info("findNeedSyncPic pic has file ")
//                    payload = fileData.map { NSKeyedUnarchiver.unarchiveObject(with: $0) } as? NSCoding
//                }
//            }
//            let picArray = self.findPicInChangeSetData(payload: payload, item: item)
//            if picArray.count > 0 {
//                totalCount += picArray.count
//                picKeyDic.updateValue(picArray, forKey: item.objToken)
//            } else {
//                DocsLogger.info("findNeedSyncPic pic 找不到图片\(DocsTracker.encrypt(id: item.objToken))", component: LogComponents.newCache)
//            }
//        }
//
//        DocsLogger.info("findNeedSyncPic pic end; foundcount=\(totalCount) ", component: LogComponents.newCache)
//
//        let userInfo: [String: Any] = ["needSynPicDic": picKeyDic, "totalCount": totalCount]
//        NotificationCenter.default.post(name: Notification.Name.Docs.findUnSyncPicsComplete, object: nil, userInfo: userInfo)
//        return picKeyDic
//    }

//    private func findPicInChangeSetData(payload: NSCoding?, item: CVSqlDefine.SqlSyncItem) -> [String] {
//        var picArray = [String]()
//        if let payload = payload as? [String: Any] {
//            let apool = payload["apool"] as? [String: Any]
//            let numToAttrib = (apool?["numToAttrib"] as? [String: Any]) ?? [:]
//            for (_, value) in numToAttrib {
//                let syncArray = value as? [String]
//                let firstStringInArray = syncArray?.first
//                let count = syncArray?.count ?? 0
//                if firstStringInArray == "gallery", count > 1 {
//                    let secondStringInArray = syncArray?[1]
//                    let data = secondStringInArray?.data(using: String.Encoding.utf8)
//                    if let data = data, let galleryDic = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
//                        let galleryInnerArray = (galleryDic["items"] as? [Any]) ?? []
//                        for picData in galleryInnerArray {
//                            let picDic = picData as? [String: Any]
//                            let type = picDic?["type"] as? String
//                            let src = picDic?["src"] as? String
//                            if let type = type, type == "image", let src = src, let picUrl = src.removingPercentEncoding {
//                                picArray.append(picUrl)
//                            }
//                        }
//                    }
//                }
//            }
//        } else {
//            DocsLogger.info("findNeedSyncPic pic 找不到payload=\(DocsTracker.encrypt(id: item.objToken))", component: LogComponents.newCache)
//        }
//        return picArray
//    }

    func getAllNeedSyncTokens() -> Set<String> {
        guard let connection = self.readConnection else {
            DocsLogger.error("ClientVarMetaInfoFromDB no readConnection", component: LogComponents.newCache)
            return []
        }
        return self.rawDataTable.getNeedSyncTokens(with: connection)
    }

    func mapTokenAndPicKey(picInfo: SKPicMapInfo) {
        self.writeQueue.async {
            guard let writeConection = self.writeConection else {
                DocsLogger.error("mapTokenAndPicKey, writeConection.isNil", component: LogComponents.newCache)
                return
            }
            self.picInfoTable.insert(picInfo, with: writeConection)
        }
    }

//    func getAllPicInfos(token: String, ignoreNeedUpload: Bool) -> [SKPicMapInfo]? {
//        guard let readConnection = self.readConnection else {
//            DocsLogger.error("getAllPicInfos, readConnection.isNil", component: LogComponents.newCache)
//            return nil
//        }
//        let picInfos = self.picInfoTable.getPicInfoData(tokens: [token], ignoreNeedUpload: ignoreNeedUpload, with: readConnection)
//        return picInfos
//    }

    func getAllPicInfos(tokens: [String], ignoreNeedUpload: Bool) -> [SKPicMapInfo]? {
        guard let readConnection = self.readConnection else {
            DocsLogger.error("getAllPicInfos, readConnection.isNil", component: LogComponents.newCache)
            return nil
        }
        let picInfos = self.picInfoTable.getPicInfoData(tokens: tokens, ignoreNeedUpload: ignoreNeedUpload, with: readConnection)
        return picInfos
    }

//    func deletePicInfoBy(token: String) {
//        self.writeQueue.async {
//            guard let writeConection = self.writeConection else {
//                DocsLogger.error("deletePicInfoBy, writeConection.isNil", component: LogComponents.newCache)
//                return
//            }
//            _ = self.picInfoTable.deleteItemsByObjToken(token, connection: writeConection)
//        }
//    }

    func updateAsset(_ asset: SKAssetInfo) {
        self.writeQueue.async {
            guard let writeConection = self.writeConection else {
                DocsLogger.error("updateAsset, writeConection.isNil", component: LogComponents.newCache)
                return
            }
            self.assetInfoTable.insert(asset, with: writeConection)
        }
    }
    func updateFileToken(uuid: String, fileToken: String, objToken: String?) {
        self.writeQueue.async {
            guard let writeConection = self.writeConection else {
                DocsLogger.error("updateFileToken, writeConection.isNil", component: LogComponents.newCache)
                return
            }
            self.assetInfoTable.updateFileToken(uuid: uuid, fileToken: fileToken, objToken: objToken, with: writeConection)
        }
    }

    func getAssetWith(uuids: [String], objToken: String?) -> [SKAssetInfo] {
        guard let readConnection = self.readConnection else {
            DocsLogger.error("getAssetWith, readConnection.isNil", component: LogComponents.newCache)
            return []
        }
        let assetInfos = self.assetInfoTable.getAssetInfoData(uuids: uuids, objToken: objToken, with: readConnection)
        return assetInfos ?? []
    }

    func getAssetWith(fileTokens: [String]) -> [SKAssetInfo] {
        guard let readConnection = self.readConnection else {
            DocsLogger.error("getAssetWith, readConnection.isNil", component: LogComponents.newCache)
            return []
        }
        let assetInfos = self.assetInfoTable.getAssetInfoData(fileTokens: fileTokens, with: readConnection)
        return assetInfos ?? []
    }
}


///删除对应token下的文档数据和图片
extension ClientVarSqlTableManager {
    func deleteFilesInSimpleMode(_ files: [SimpleModeWillDeleteFile], completion: (() -> Void)?) {
        DocsLogger.info("ClientVarSqlTableManager start to clear data in simple mode", component: LogComponents.simpleMode)

        self.trimQueue.async {
            guard let newCache = DocsContainer.shared.resolve(NewCacheAPI.self) else {
                DocsLogger.info("deleteDataByObjToken newCache nil", component: LogComponents.newCache)
                completion?()
                return
            }
            DocsLogger.info("deleteDataByObjToken count=\(files.count)", component: LogComponents.newCache)

            for file in files {
                let preloadKey = PreloadKey(objToken: file.objToken, type: file.type)
                _ = preloadKey.pictureUrls.map {
                    if let urlStr = $0.url,
                        let url = URL(string: urlStr) {
                        newCache.removePic(forKey: url.path, token: file.objToken)
                    }
                }
                _ = self.deleteItemByObjToken(objToken: preloadKey.objToken)
            }
            DocsLogger.info("deleteDataByObjToken done", component: LogComponents.newCache)
            completion?()
        }
    }

}
