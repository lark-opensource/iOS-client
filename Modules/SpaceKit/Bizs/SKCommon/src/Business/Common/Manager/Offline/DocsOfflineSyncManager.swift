//
//  DocsOfflineSyncManager.swift
//  SpaceKit
//
//  Created by Ryan on 2018/12/5.
//  swiftlint:disable line_length file_length

import UIKit
import RxSwift
import RxRelay
import SKFoundation
import SpaceInterface
import LarkAppConfig
import LarkSetting
import SKInfra
import LarkContainer

// 需要通过dependency获取到当前的browserVC，弹出容量超限弹窗
public protocol DocsOfflineSynManagerDependency {
    var curBrowserVC: UIViewController? { get }
}

final public class DocsOfflineSyncManager: NSObject {
    public static let shared = DocsOfflineSyncManager()
    public static let needSyncKey = "OfflineSyncManagerneedSyncKey"
    public static let tokenCacheKey = "FakeTokenKeyFromNative"
    private let beginSyncKey = "beginSync"
    private let uploadProgressKey = "updateProgress"
    private static let staticSyncQuue = DispatchQueue(label: "docs.bytedance.net.offlineSyncStatic.\(UUID())")
    private let offlineSyncQueue = DispatchQueue(label: "docs.bytedance.net.offlineSync.\(UUID())", target: DocsOfflineSyncManager.staticSyncQuue)
    private let batchLogQueue = DispatchQueue(label: "docs.bytedance.net.rnBatchLog.\(UUID())", target: DocsOfflineSyncManager.staticSyncQuue)

    ///这些不需要离线同步，让webview去处理
    private static var webviewHandledObjTokens = [FileListDefine.ObjToken: Int]()
    private var needSyncObjTokens = Set<FileListDefine.ObjToken>()

    /// APP启动时，90%的情况下，DocsNetStateMonitor.shared.isReachable == true，并且addObserver的时候，会马上刷新这个值
    var isReachable: Bool = true
    var canBeginSync: Bool = false
    private let uploadFileAdapter = UploadFileAdapter()
    private var currentSyncToken: FileListDefine.ObjToken? {
        didSet {
            DocsLogger.debug("current sync token is \(String(describing: currentSyncToken))", component: LogComponents.offlineSyncDoc)
        }
    }
    private weak var resolver: DocsResolver?
    lazy private var newCacheAPI = resolver?.resolve(NewCacheAPI.self)
    lazy private var clientVarMetaManager = resolver?.resolve(ClientVarMetaDataManagerAPI.self)
    private let dispostBag = DisposeBag()
    var offlineSynIdle = BehaviorRelay<Bool>(value: true)
    private var hadFailed: Bool = false // 队列同步过程中，是否有失败的
    private var listRetryCount: Int = 0 // 列表重试次数
    private var tokenRetryMap: [String: Int] = [:] // 每个token重试次数记录
    private let maxRetryPerToken: Int = 2 //每个token最大重试次数
    var uploadUUids: [String] = [] //正在上传的uuids
    private let dataCenterAPI: DataCenterAPI

    init(_ resolver: DocsResolver = DocsContainer.shared) {
        self.resolver = resolver
        dataCenterAPI = resolver.resolve(DataCenterAPI.self)!
        super.init()
        addNetworkMonitor()
        _ = NotificationCenter.default.addObserver(forName: Notification.Name.Docs.userWillLogout, object: nil, queue: nil) { [weak self] (_) in
            self?.clearNeedSyncObjTokens()
        }

        let rnUserOk = RNManager.manager.userValidInjectObsevable
        let rnSetupOk = RNManager.manager.hadSetupEnviroment
        let driveInitOk = DocsContainer.shared.resolve(DriveRustRouterBase.self)?.driveInitFinishObservable ?? BehaviorRelay<Bool>(value: false)
        let dbLoaded = dataCenterAPI.dbLoadingStateObservable

        Observable.combineLatest(rnUserOk, rnSetupOk, driveInitOk, dbLoaded)
            .distinctUntilChanged({ (l, r) -> Bool in return l == r })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isRnUserOk, isRnSetupOk, isDriveInitOk, isDbLoaded) in
                DocsLogger.info("watch condition: isRnUserOk=\(isRnUserOk), isRnSetupOk=\(isRnSetupOk), isDriveInitOk=\(isDriveInitOk), isDbLoaded=\(isDbLoaded)", component: LogComponents.offlineSyncDoc)
                if isRnUserOk && isRnSetupOk && isDriveInitOk && isDbLoaded {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { [weak self] in
                        DocsLogger.info("watch condition: done, try beginSync, force=true", component: LogComponents.offlineSyncDoc)
                        self?.currentSyncToken = nil
                        self?.canBeginSync = true
                        self?.offlineSynIdle.accept(false)
                        self?.beginSync(force: true)
                    }
                }
            }).disposed(by: self.dispostBag)
    }

    deinit {
        DocsNetStateMonitor.shared.observers.remove(self)
    }

    public var isInForground = true {
        didSet {
            guard isInForground != oldValue else {
                return
            }
            if self.isInForground {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000) {
                     if self.isInForground {
                        DocsLogger.info("isInForground, tryToBegin Syn", component: LogComponents.offlineSyncDoc)
                        self.beginSync()
                    }
                }
            }
        }
    }
}

extension DocsOfflineSyncManager {
    private func beginSync(force: Bool = false) {
        offlineSyncQueue.async {
            guard self.canBeginSync == true else {
                DocsLogger.info("beginSync, canBeginSync = false, force=\(force)", component: LogComponents.offlineSyncDoc)
                return
            }

            var isCurrentTokenWating = false
            if let currentSyncToken = self.currentSyncToken,
               let file = self.dataCenterAPI.getAllSpaceEntries()[currentSyncToken],
               file.syncStatus.upSyncStatus == .waiting {
                isCurrentTokenWating = true
                DocsLogger.info("beginSync, currentSyncToken is wating, token=\(currentSyncToken.encryptToken))", component: LogComponents.offlineSyncDoc)
            }

            if self.currentSyncToken == nil || isCurrentTokenWating || force {
                 self.gatherNeedSyncObjtokens {
                    guard self.isReachable else {
                        DocsLogger.info("beginSync err, force=\(force), isReachable=\(self.isReachable)", component: LogComponents.offlineSyncDoc)
                        self.offlineSynIdle.accept(true)
                        return
                    }
                     self.syncNextIfNeed()
                 }
            } else {
                DocsLogger.info("beginSync err, force=\(force), currentToken=\(String(describing: self.currentSyncToken?.encryptToken))", component: LogComponents.offlineSyncDoc)
            }
        }
    }

    func setData(params: [String: Any]) {
        offlineSyncQueue.async {
            guard let data = params["data"] as? [String: Any],
                let objToken = data["objToken"] as? String,
                let payloadData = data["data"] as? NSCoding,
                let needSync = data["needSync"] as? Bool,
                let key = data["key"] as? String else {
                    spaceAssertionFailure()
                    return
            }
            DocsLogger.info("setData: \(key.encryptToken)", component: LogComponents.offlineSyncDoc)

            if let type = data["type"] as? String,
                type == "image_base64" {
                if let base64 = data["data"] as? String,
                    let originImage = UIImage.docs.image(base64: base64, scale: 1),
                    let image = originImage.sk.rotate(radians: 0),
                    let data = image.data(quality: 1, limitSize: 2 * 1024 * 1024) {
                    // 处理图片上传
                    self.newCacheAPI?.set(object: data as NSCoding, for: objToken, subkey: key, cacheFrom: nil)
                }
            } else {
                let record = H5DataRecord(objToken: objToken, key: key, needSync: needSync, payload: payloadData as NSCoding, type: nil, cacheFrom: key.isClientVarKey ? .cacheFromPreload : .cacheFromUnKnown)
                self.newCacheAPI?.setH5Record(record, needLog: true, completion: nil)
            }

            if let callback = params[RNManager.callbackID] as? String {
                let res: [String: Any] = ["code": 0, "data": "", "message": ""]
                RNManager.manager.sendSyncData(data: res, responseId: callback)
            }
        }
    }

    func getData(params: [String: Any]) {
        guard let data = params["data"] as? [String: Any],
            let objToken = data["objToken"] as? String,
            let key = data["key"] as? String,
            let callback = params[RNManager.callbackID] as? String else {
                DocsLogger.info("rn get data, format wrong, return ", component: LogComponents.offlineSyncDoc)
                return
        }

        offlineSyncQueue.async {
            let returnData: Any = {
                let recordKey = H5DataRecordKey(objToken: objToken, key: key)
                return self.newCacheAPI?.getH5RecordBy(recordKey)?.payload ?? ""
            }()

            let dict = ["code": 0, "message": "", "data": returnData]
            DocsLogger.info("rn get data, send sync data back, encryptedToken: \(objToken.encryptToken), data count is \(dict.toJSONString()?.count ?? 0)", component: LogComponents.offlineSyncDoc)
            RNManager.manager.sendSyncData(data: dict, responseId: callback)
        }
    }
    /// 前端告知fakeToken，告知前端filePath之类的信息
    ///
    /// - Parameter params: fakeToken 和 callBack
    public func getOfflineCreateDoc(params: [String: Any], callBack: (([String: Any]) -> Void)? = nil) {
        guard let data = params["data"] as? [String: Any],
            let fakeToken = data["fakeToken"] as? String,
            let callback = params[RNManager.callbackID] as? String else {
                DocsLogger.info("get offline create doc info ,params not valid", component: LogComponents.offlineSyncDoc)
                spaceAssertionFailure()
                return
        }
        offlineSyncQueue.async {
            var dict: [String: Any] = ["fakeToken": fakeToken, "obj_token": fakeToken]
            var parentToken: String?

            if let nodeToken = self.dataCenterAPI.convertToNodeToken(for: fakeToken),
               let folderToken = self.dataCenterAPI.folderToken(containing: nodeToken) {
                dict["filepath"] = folderToken
                parentToken = folderToken
            }
            if let fileEntry = self.dataCenterAPI.spaceEntry(objToken: fakeToken) {
                var docsType = fileEntry.docsType
                if let wikiEntry = fileEntry as? WikiEntry, let wikiInfo = wikiEntry.wikiInfo {
                    docsType = wikiInfo.docsType
                    dict["is_wiki"] = true
                }
                dict["type"] = docsType.rawValue
                if docsType == .sheet {
                    dict["name"] = fileEntry.realName
                }
            } else {
                spaceAssertionFailure()
            }

            DocsLogger.info("getOfflineCreateDoc \(fakeToken.encryptToken)", component: LogComponents.offlineSyncDoc)
            DocsLogger.debug("sendSyncData \(dict)", component: LogComponents.offlineSyncDoc)

            ///默认ownerType
            var ownerType: Int = defaultOwnerType
            ///截取fakeToken中ownerType
            let array = fakeToken.components(separatedBy: "ownerType")
            if let last = array.last, let type = Int(last) {
                ownerType = type
            }

            ///https://bytedance.feishu.cn/docx/doxcnm3uM050IYGRrvZYZlEdofb
            if let parentToken = parentToken {
                self.getEntryInfo(objToken: parentToken, type: .folder) { type, error in
                    if let type = type {
                        DocsLogger.info("getEntryInfo success")
                        ownerType = type
                    } else {
                        DocsLogger.error("getEntryInfo fail \(String(describing: error))")
                    }
                    dict["owner_type"] = ownerType
                    RNManager.manager.sendSyncData(data: dict, responseId: callback)
                    callBack?(dict)
                }
            } else {
                ownerType = SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType
                dict["owner_type"] = ownerType
                RNManager.manager.sendSyncData(data: dict, responseId: callback)
                callBack?(dict)
            }
        }
    }

    private func getEntryInfo(objToken: String, type: DocsType?, callBack: @escaping (Int?, Error?) -> Void) {
        guard let type = type else {
            callBack(nil, nil)
            return
        }
        let getEntryInfoRequest = DocsRequestCenter.getEntryInfoFor(objToken: objToken, objType: type) { ownerType, error in
            callBack(ownerType, error)
        }
        getEntryInfoRequest.makeSelfReferenced()
    }

    /// 这个不用了
    func modifyOfflineDocInfo(params: [String: Any]) {}

    //离线文档创建完成, 替换本地数据中的临时token等数据
    public func syncDocInfo(params: [String: Any], successCallBack: (() -> Void)? = nil) {
        guard let data = params["data"] as? [String: Any],
            let fakeObjToken = data["fakeToken"] as? String,
            let objToken = data["objToken"] as? String,
            let nodeToken = data["token"] as? String,
            let callback = params[RNManager.callbackID] as? String else {
                spaceAssertionFailure()
                DocsLogger.info("rn syncDocInfo, param not right", component: LogComponents.offlineSyncDoc)
                return
        }
        let wikiInfo = praseWikiInfo(data)
        // wiki文档需要将真实token传递给文档容器进行替换
        NotificationCenter.default.post(name: Notification.Name.Docs.didSyncFakeObjToken(fakeObjToken), object: wikiInfo, userInfo: ["objToken": objToken])
        DocsLogger.info("syncDocInfo \(fakeObjToken) to objToken \(objToken.encryptToken)", component: LogComponents.offlineSyncDoc)
        DocsOfflineSyncManager.staticSyncQuue.async {
            self.replaceFakeTokenInOpenRecords(fakeToken: fakeObjToken, token: objToken)
        }

        offlineSyncQueue.async {
            // 避免下次再去同步这个fake
            self.dataCenterAPI.updateNeedSyncState(objToken: fakeObjToken, type: .doc, needSync: false, completion: nil)
            DocsLogger.info("offline_sync: 同步中token发生更新 fake:\(fakeObjToken)  new:\(objToken.encryptToken)", component: LogComponents.offlineSyncDoc)
            // cache
            self.newCacheAPI?.changeTokenFrom(fakeObjToken, to: wikiInfo?.objToken ?? objToken)
            //保存realToken -> fakeToken的映射
            if let payload = fakeObjToken as? NSCoding {
                DocsLogger.error("save fakeToken cache", component: LogComponents.offlineSyncDoc)
                let h5Record = H5DataRecord(objToken: objToken, key: Self.tokenCacheKey, needSync: false, payload: payload, type: nil)
                self.newCacheAPI?.setH5Record(h5Record, needLog: true) { result in
                    switch result {
                    //映射在DB中存储失败时，再尝试存一次cache
                    case .failure:
                        CacheService.configCache.set(object: payload, forKey: objToken + Self.tokenCacheKey)
                        DocsLogger.error("save faketoken in db fail, try to save in cache", component: LogComponents.offlineSyncDoc)
                    default:
                        break
                    }
                }
            }
            if let fakeEntry = self.dataCenterAPI.spaceEntry(objToken: fakeObjToken) {
                fakeEntry.updateOpenTime(Date().timeIntervalSince1970)
                if let wikiInfo {
                    // 有WikiInfo信息需要手动构建extra 更新wikiInfo
                    let extra: [String: Any] = ["wiki_subtype": wikiInfo.docsType.rawValue,
                                                "wiki_sub_token": wikiInfo.objToken,
                                                "wiki_space_id": wikiInfo.spaceId]
                    fakeEntry.updateExtraValue(extra)
                    NotificationCenter.default.post(name: Notification.Name.Docs.updateFakeWikiInfo, object: wikiInfo, userInfo: ["title": fakeEntry.name,
                                                                                                                                  "fakeToken": fakeObjToken])
                }
                self.dataCenterAPI.update(fakeEntry: fakeEntry, serverObjToken: objToken, serverNodeToken: nodeToken)
            }
            successCallBack?()
            RNManager.manager.sendSyncData(data: ["code": 0, "message": "", "data": ""], responseId: callback)
        }
    }
    
    private func praseWikiInfo(_ dic: [String: Any]) -> WikiInfo? {
        if let wikiInfoData = dic["wikiInfo"] as? [String: Any],
           let wikiToken = wikiInfoData["wiki_token"] as? String,
           let spaceId = wikiInfoData["space_id"] as? String,
           let objToken = wikiInfoData["obj_token"] as? String,
           let objType = wikiInfoData["obj_type"] as? Int,
           let url = wikiInfoData["url"] as? String,
           let sortID = wikiInfoData["sort_id"] as? Double,
           let title = wikiInfoData["title"] as? String {
            // 构建wikiInfo信息
            var wikiInfo = WikiInfo(wikiToken: wikiToken, objToken: objToken, docsType: DocsType(rawValue: objType), spaceId: spaceId, shareUrl: url)
            wikiInfo.sortId = sortID
            // 更新wikiDB
            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
            guard let wikiSrtorageAPI = try? userResolver.resolve(assert: WikiStorageBase.self)  else {
                DocsLogger.error("can not get wikiSrtorageAPI")
                return nil
            }
            let wikiNode = WikiNode(wikiToken: wikiToken, spaceId: spaceId, objToken: objToken, objType: DocsType(rawValue: objType), title: title)
            wikiSrtorageAPI.insertFakeNodeForLibrary(wikiNode: wikiNode)
            return wikiInfo
        }
        return nil
    }

    //同步状态更新
    func notifySyncStatus(params: [String: Any]) {
        offlineSyncQueue.async {
            guard let data = params["data"] as? [String: Any],
                let synState = data["status"] as? Int,
                var objToken = data["objToken"] as? String else {
                DocsLogger.info("notifySyncStatus: param err", component: LogComponents.offlineSyncDoc)
                return
            }
            if let wikiToken = data["wikiToken"] as? String {
                objToken = wikiToken
            }
            var file = self.dataCenterAPI.getAllSpaceEntries()[objToken]
            if file == nil {
                file = self.dataCenterAPI.loadDBSpaceEntry(objToken: objToken)
            }
            if let fileEntry = file {
                var resultState: UpSyncStatus = .none
                var notNeedRetry = false
                switch synState {
                case 0:
                    resultState = .finish
                case 1:
                    resultState = .failed
                    self.hadFailed = true
                    let errcode = data["code"] as? Int
                    if errcode != nil, self.notRetryErrCode(errcode!) {
                        notNeedRetry = true
                    }
                    DocsLogger.info("notifySyncStatus: objToken=\(objToken.encryptToken) fail:\(String(describing: errcode))", component: LogComponents.offlineSyncDoc)
                case 2:
                    resultState = .waiting
                case 3:
                    resultState = .uploading
                default:
                    resultState = .none
                }
                DocsLogger.info("notifySyncStatus: objToken=\(objToken.encryptToken), changeSynState=\(resultState), raw=\(synState)", component: LogComponents.offlineSyncDoc)

                var tokenInfos = [FileListDefine.ObjToken: SyncStatus]()
                tokenInfos[objToken] = fileEntry.syncStatus.modifingUpSyncStatus(resultState)
                self.dataCenterAPI.updateUIModifier(tokenInfos: tokenInfos)

                if resultState == .finish {
                    self.tokenRetryMap[objToken] = 0 // 清空对应token记录
                    self.dataCenterAPI.updateNeedSyncState(objToken: objToken, type: .doc, needSync: false) {
                        DispatchQueue.main.docAsyncAfter(1, block: {
                            var delayTokenInfos = [FileListDefine.ObjToken: SyncStatus]()
                            delayTokenInfos[objToken] = fileEntry.syncStatus.modifingUpSyncStatus(.finishOver1s)
                            self.dataCenterAPI.updateUIModifier(tokenInfos: delayTokenInfos)
                        })
                    }
                }
                if resultState == .failed || resultState == .finish {
                    if resultState == .failed, notNeedRetry {
                        self.dataCenterAPI.updateNeedSyncState(objToken: objToken, type: .doc, needSync: false, completion: nil)
                        DocsLogger.info("notNeedSyncErrToken: objToken=\(objToken.encryptToken)", component: LogComponents.offlineSyncDoc)
                    }
                    self.syncNextIfNeed()
                    var params: [String: Any] = [:]
                    params["status"] = resultState == .failed ? 1 : 0
                    params["file_type"] = fileEntry.type.name
                    params["file_id"] = DocsTracker.encrypt(id: fileEntry.objToken)
                    DocsTracker.log(enumEvent: .devPerformanceSyncStatus, parameters: params)
                }
            } else {
                DocsLogger.info("notifySyncStatus: can not find fileEntry", component: LogComponents.offlineSyncDoc)
            }
        }
    }

    func logger(params: [String: Any]) {
        guard let data = params["data"] as? [String: Any], let logMsg = data["logMessage"] as? String else { return }
        offlineSyncQueue.async {
            DocsLogger.info(logMsg)
        }
    }
    
    private func batchLogger(params: [String: Any]) {
        guard let data = params["data"] as? [String: Any], let logList = data["logMessages"] as? [[String: Any]] else {
            DocsLogger.info("batch-log data format error")
            return
        }
        
        for logJson in logList {
            autoreleasepool {
                if let ts = logJson["timeStamp"] as? TimeInterval { // 必须有时间戳,单位秒,保留3位小数(ms)
                    let msg = (logJson["msg"] as? String) ?? "" // 日志内容
                    self.batchLogQueue.async {
                        DocsLogger.log(level: .info, message: msg, time: ts, useCustomTimeStamp: true)
                    }
                }
            }
        }
        DocsLogger.info("batch-log write done, count: \(logList.count)")
    }

    public func addWebviewHandledObjToken(_ objToken: FileListDefine.ObjToken) {
        DocsOfflineSyncManager.staticSyncQuue.async {
            self.increaseOpenFileTokenCount(token: objToken)
            self.tokenRetryMap.removeValue(forKey: objToken)
            DocsLogger.info("addWebviewHandledObjToken \(objToken.encryptToken)", component: LogComponents.offlineSyncDoc)
        }
    }

    public func removeWebviewHandledObjToken(_ objToken: FileListDefine.ObjToken) {
        self.offlineSynIdle.accept(false)
        DocsOfflineSyncManager.staticSyncQuue.async {
            self.decreaseOpenFileTokenCount(token: objToken)
            DocsLogger.info("removeWebviewHandledObjToken \(objToken.encryptToken)", component: LogComponents.offlineSyncDoc)
            if self.clientVarMetaManager?.getMetaDataRecordBy(objToken).needSync == true {
                DocsLogger.info("需要同步: \(objToken.encryptToken)", component: LogComponents.offlineSyncDoc)
            } else {
                if self.needSyncObjTokens.count == 0 {
                    self.offlineSynIdle.accept(true)
                }
                /// 如果正在展示失败，且又不需同步，改回普通状态
                let file = self.dataCenterAPI.getAllSpaceEntries()[objToken]
                if let fileEntry = file, (fileEntry.syncStatus.upSyncStatus == .failed || fileEntry.syncStatus.upSyncStatus == .waiting) {
                    DocsLogger.info("removeWebviewHandledObjToken \(objToken.encryptToken), modify to normal becase of notNeed Sync", component: LogComponents.offlineSyncDoc)
                    var tokeToModify = [FileListDefine.ObjToken: SyncStatus]()
                    tokeToModify[objToken] = fileEntry.syncStatus.modifingUpSyncStatus(.none)
                    self.dataCenterAPI.updateUIModifier(tokenInfos: tokeToModify)
                }

            }
        }
    }
    
    private func notRetryErrCode(_ code: Int) -> Bool {
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_mobile_offlinesyn_config"))
            guard let errlist = settings["notNeedRetryCode"] as? [Int] else {
                return false
            }
            for ecode in errlist where ecode == code {
                return true
            }
        } catch {
            DocsLogger.error("systemVersions is not string array")
            return false
        }
        return false
    }
}

private extension DocsOfflineSyncManager {
    private func addNetworkMonitor() {
        DocsNetStateMonitor.shared.addObserver(self) {[weak self] (_, isReachable) in
            guard let self = self else { return }
            if self.isReachable == false && isReachable == true {
                DocsLogger.info("addNetworkMonitor = isReachable, try gather to syn", component: LogComponents.offlineSyncDoc)
                self.beginSync()
            }
            self.isReachable = isReachable
        }
    }

    private func clearNeedSyncObjTokens() {
        self.offlineSyncQueue.async {
            self.needSyncObjTokens.removeAll()
            self.currentSyncToken = nil
            DocsLogger.info("clearNeedSyncObjTokens", component: LogComponents.offlineSyncDoc)
        }
    }

    private func gatherNeedSyncObjtokens(_ complete: @escaping () -> Void) {
        self.offlineSynIdle.accept(false)
        dataCenterAPI.forceUpdateState { [weak self] in
            guard let self = self else { return }
            self.offlineSyncQueue.async {
                self.needSyncObjTokens = self.clientVarMetaManager?.getAllNeedSyncTokens() ?? []
                
                var needUIModifyItems = [FileListDefine.ObjToken: SyncStatus]()
                let needSyncObjTokensButNotOpen = self.needSyncObjTokens.subtracting(self.openFileTokenSet())
                needSyncObjTokensButNotOpen.forEach { (objToken) in
                    let file = self.dataCenterAPI.getAllSpaceEntries()[objToken]
                    if file?.syncStatus.upSyncStatus != .uploading, let newSyncStatus = file?.syncStatus.modifingUpSyncStatus(.waiting) {
                        needUIModifyItems[objToken] = newSyncStatus
                    }
                    DocsLogger.info("offline_sync: 准备同步离线新建的文档")
                }
                if !needUIModifyItems.isEmpty {
                    self.dataCenterAPI.updateUIModifier(tokenInfos: needUIModifyItems)
                }

                DocsLogger.info("get \(self.needSyncObjTokens.count) needSyncObjTokens, needModifySyncUI=\(needUIModifyItems.count), webviewHandledCount=\(DocsOfflineSyncManager.webviewHandledObjTokens.count)", component: LogComponents.offlineSyncDoc)
                complete()
            }
        }
    }

    private func syncNextIfNeed() {
        self.offlineSyncQueue.async {
            if let randomUnSyncedObjToken = self.needSyncObjTokens.filter({ !self.openFileTokenSet().contains($0) }).randomElement() {
                // 先从内存获取fileEntry，如果不存在则从数据库获取
                var file = self.dataCenterAPI.getAllSpaceEntries()[randomUnSyncedObjToken]
                if file == nil {
                    file = self.dataCenterAPI.loadDBSpaceEntry(objToken: randomUnSyncedObjToken)
                }
                guard let fileEntry = file else {
                    self.needSyncObjTokens.remove(randomUnSyncedObjToken)
                    DocsLogger.info("can not find unSynced fileEntry, token=\(randomUnSyncedObjToken.encryptToken), continue", component: LogComponents.offlineSyncDoc)
                    self.syncNextIfNeed()
                    return
                }
                let retryCount: Int = self.tokenRetryMap[randomUnSyncedObjToken] ?? 0
                guard retryCount <= self.maxRetryPerToken else {
                    self.needSyncObjTokens.remove(randomUnSyncedObjToken)
                    DocsLogger.info("retryTimes Over, token=\(randomUnSyncedObjToken.encryptToken), continue", component: LogComponents.offlineSyncDoc)
                    self.syncNextIfNeed()
                    return
                }

                self.needSyncObjTokens.remove(randomUnSyncedObjToken)
                self.currentSyncToken = randomUnSyncedObjToken
                self.delayHandeUnSynced(randomUnSyncedObjToken)
                var body = [String: Any]()
                body["token"] = fileEntry.objToken
                body["type"] = fileEntry.type.rawValue
                if let wikiEntry = fileEntry as? WikiEntry, let wikiInfo = wikiEntry.wikiInfo {
                    body["suiteOriginalType"] = wikiInfo.docsType.rawValue
                    body["suiteOriginalToken"] = wikiInfo.objToken
                }
                let data: [String: Any] = ["operation": self.beginSyncKey, "body": body]
                DocsLogger.info("beginsync \(fileEntry.objToken.encryptToken), type=\(fileEntry.type.name), reportToken=\(DocsTracker.encrypt(id: fileEntry.objToken))", component: LogComponents.offlineSyncDoc)
                RNManager.manager.sendSyncData(data: data)
                var params: [String: Any] = [:]
                params["retry_times"] = retryCount
                params["file_type"] = fileEntry.type.name
                params["file_id"] = DocsTracker.encrypt(id: fileEntry.objToken)
                DocsTracker.log(enumEvent: .devPerformanceSyncBeginsync, parameters: params)
                self.tokenRetryMap[randomUnSyncedObjToken] = retryCount + 1

            } else {
                self.currentSyncToken = nil
                self.offlineSynIdle.accept(true)
                DocsLogger.info("syncNextIfNeed complete, needSyncObjTokens=\(self.needSyncObjTokens.count), webviewHandledObjTokens=\(DocsOfflineSyncManager.webviewHandledObjTokens.count)", component: LogComponents.offlineSyncDoc)
                if self.needSyncObjTokens.count == 0 {
                    self.retryIfNeed()
                }
            }
        }
    }

    private func retryIfNeed() {
        offlineSyncQueue.asyncAfter(deadline: .now() + 60) { [weak self] in
            guard let self = self else { return }
            if self.hadFailed, self.listRetryCount < 3 {
                DocsLogger.info("retryIfNeed, retry = true, hadFailed =\(self.hadFailed), retryCount =\(self.listRetryCount)", component: LogComponents.offlineSyncDoc)
                self.listRetryCount += 1
                self.hadFailed = false
                self.beginSync()
            } else {
                DocsLogger.info("retryIfNeed, retry = false, hadFailed =\(self.hadFailed), retryCount =\(self.listRetryCount)", component: LogComponents.offlineSyncDoc)
            }
        }
    }

    private func delayHandeUnSynced(_ objToken: FileListDefine.ObjToken) {
        offlineSyncQueue.asyncAfter(deadline: .now() + 600) { [weak self] in
            guard let self = self else { return }
            guard self.currentSyncToken != nil else {
                DocsLogger.info("delayHandeUnSynced, currentSyncToken = nil, lastToken=\(objToken.encryptToken)", component: LogComponents.offlineSyncDoc)
                return
            }
            if self.currentSyncToken == objToken {
                DocsLogger.info("delayHandeUnSynced \(objToken.encryptToken) overtime , call next", component: LogComponents.offlineSyncDoc)
                self.hadFailed = true
                self.syncNextIfNeed()
                var tokenInfos = [FileListDefine.ObjToken: SyncStatus]()
                if let fileEntry = self.dataCenterAPI.getAllSpaceEntries()[objToken] {
                    var params: [String: Any] = [:]
                    params["status"] = 2
                    params["file_type"] = fileEntry.type.name
                    params["file_id"] = DocsTracker.encrypt(id: fileEntry.objToken)
                    DocsTracker.log(enumEvent: .devPerformanceSyncStatus, parameters: params)

                    let newSyncStatus = fileEntry.syncStatus.modifingUpSyncStatus(.failed)
                    tokenInfos[objToken] = newSyncStatus
                    self.dataCenterAPI.updateUIModifier(tokenInfos: tokenInfos)
                }
            } else {
                DocsLogger.info("delayHandeUnSynced, different token, do nothing, lastToken=\(objToken.encryptToken)", component: LogComponents.offlineSyncDoc)
            }
        }
    }
}

//图片上传相关
extension DocsOfflineSyncManager {
    func uploadFile(params: [String: Any]) {
        guard
            let data = params["data"] as? [String: Any],
            let callback = params[RNManager.callbackID] as? String,
            let uuids = data["uuids"] as? [String]
            else {
                return
        }

        let showQuota = data["showFullQuata"] as? Bool ?? true // 默认nattive处理超限弹框
        uploadUUids += uuids
        DocsLogger.info("offlineSync upload, start, uuid=\(uuids.first?.encryptToken ?? "") count=\(uuids.count)", component: LogComponents.uploadFile)
        offlineSyncQueue.async {
            for uuid in uuids {
                self.uploadFileAdapter.uploadFile(for: data) { (progressParam) in
                    let data: [String: Any] = ["operation": self.uploadProgressKey, "body": progressParam]
                    DocsLogger.error("offlineSync upload, progress=\(progressParam)", component: LogComponents.uploadFile)
                    RNManager.manager.sendSyncData(data: data)
                } completion: {[weak self] (result) in
                    guard let self = self else { return }
                    switch result {
                    case .success(let (_, data)):
                        DocsLogger.info("offlineSync upload, success, uuid=\(uuid.encryptToken)", component: LogComponents.uploadFile)
                        RNManager.manager.sendSyncData(data: data, responseId: callback)
                    case .failure(let error):
                        var errCode: Int = -1
                        if let uploadErr = error as? UploadError {
                            switch uploadErr {
                            case .driveError(let code):
                                errCode = code
                            default: break
                            }
                        } else {
                            let nsError = error as NSError
                            if nsError.code != 0 {
                                errCode = nsError.code
                            }
                        }
                        let mountInfo = self.mountInfo(from: data)
                        let showQuota = self.showQuotaAlertIfNeed(code: errCode,
                                                                  mountNodeToken: mountInfo.mountNodeToken,
                                                                  mountPoint: mountInfo.mountPoint,
                                                                  docType: mountInfo.docsType,
                                                                  showQuota: showQuota)
                        let result: [String: Any] = [
                            "code": errCode,
                            "message": "\(error)",
                            "uuid": uuid,
                            "showQuotaAlert": showQuota
                        ]
                        DocsLogger.error("offlineSync upload, error=\(errCode), uuid=\(uuid.encryptToken)", error: error, component: LogComponents.uploadFile)
                        RNManager.manager.sendSyncData(data: result, responseId: callback)
                    }
                }
            }
        }
    }
    
    // rn调用上传附件，根据回调错误码判断是否弹窗
    private func showQuotaAlertIfNeed(code: Int, mountNodeToken: String?, mountPoint: String?, docType: DocsType?, showQuota: Bool) -> Bool {
        guard showQuota else {
            DocsLogger.info("fronend will deal with the quota error")
            return false
        }
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        guard let fromVC = try? userResolver.resolve(assert: DocsOfflineSynManagerDependency.self).curBrowserVC else {
            DocsLogger.info("can not get current browser")
            return false
        }
        if code == DocsNetworkError.Code.rustUserUploadLimited.rawValue {
            guard QuotaAlertPresentor.shared.enableUserQuota else {
                DocsLogger.info("over sea user not show quota alert")
                return false
            }
            DocsLogger.info("rn upload file upload limited show user quotaAlert")
            var bizParams: SpaceBizParameter?
            if let token = mountNodeToken, let type = docType, let moudle = type.module {
                 bizParams = SpaceBizParameter(module: moudle, fileID: token, fileType: type)
            }
            
            QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: mountNodeToken,
                                                          mountPoint: mountPoint,
                                                          from: fromVC,
                                                          bizParams: bizParams)
            return true
        } else if code == DocsNetworkError.Code.uploadLimited.rawValue {
            guard QuotaAlertPresentor.shared.enableTenantQuota else {
                DocsLogger.info("over sea user not show quota alert")
                return false
            }
            DocsLogger.info("rn upload file upload limited show quotaAlert")
            QuotaAlertPresentor.shared.showQuotaAlert(type: .upload, from: fromVC)
            return true
        } else {
            DocsLogger.info("rn upload file upload other error: \(code)")
            return false
        }
    }
    
    private func mountInfo(from parmas: [String: Any]) -> (mountNodeToken: String?, mountPoint: String?, docsType: DocsType?) {
        guard let uploadParams = parmas["uploadParams"] as? [String: Any],
              let objType = uploadParams["obj_type"] as? Int,
              let mountNodeToken = uploadParams["mount_node_token"] as? String,
              let mountPoint = uploadParams["mount_point"] as? String else {
            return (nil, nil, nil)
        }
        let docsType = DocsType(rawValue: objType)
        return (mountNodeToken, mountPoint, docsType)
    }
    
    // rn调用biz.util.showFullQuoteDialog命令弹窗
    private func showQuotaAlert(params: [String: Any]) {
        guard let data = params["data"] as? [String: Any],
              let type = data["type"] as? Int,
              let quotaType = QuotaAlertType(rawValue: type) else {
            DocsLogger.info("quota type not support: \(params)")
            return
        }
        DispatchQueue.main.async {
            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
            guard let fromVC = try? userResolver.resolve(assert: DocsOfflineSynManagerDependency.self).curBrowserVC else {
                DocsLogger.info("can not get current browser")
                return
            }
            DocsLogger.info("rn call show full quotedialog")
            if quotaType == .userQuotaLimited { // 用户容量弹出
                let mountPoint = params["mount_point"] as? String
                let moutToken = params["mount_token"] as? String
                QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: moutToken, mountPoint: mountPoint, from: fromVC)
            } else { // 租户容量弹出
                QuotaAlertPresentor.shared.showQuotaAlert(type: quotaType, from: fromVC)
            }
        }
    }
}

extension DocsOfflineSyncManager: RNMessageDelegate {
    public func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        if eventName != .logger {
//            DocsLogger.info("didReceivedRNData \(eventName), data is \(data)", component: LogComponents.offlineSyncDoc)
        }

        switch eventName {
        case .rnGetData:
            getData(params: data)
        case .rnSetData:
            setData(params: data)
        case .offlineCreateDocs:
            getOfflineCreateDoc(params: data)
        case .modifyOfflineDocInfo:
            modifyOfflineDocInfo(params: data)
        case .syncDocInfo:
            syncDocInfo(params: data)
        case .notifySyncStatus:
            notifySyncStatus(params: data)
        case .logger:
            logger(params: data)
        case .batchLogger:
            batchLogger(params: data)
        case .uploadImage, .uploadFile:
            uploadFile(params: data)
        case .showQuotaDialog:
            showQuotaAlert(params: data)
        case .getAppSetting:
            handleGetAppSetting(params: data)
        default:
            DocsLogger.info("none of my business")
        }
    }
}

extension DocsOfflineSyncManager {
    func replaceFakeTokenInOpenRecords(fakeToken: String, token: String) {
        if let count = DocsOfflineSyncManager.webviewHandledObjTokens[fakeToken] {
            DocsOfflineSyncManager.webviewHandledObjTokens.removeValue(forKey: fakeToken)
            DocsOfflineSyncManager.webviewHandledObjTokens[token] = count
        }
    }

    func increaseOpenFileTokenCount(token: String) {
        var count: Int = DocsOfflineSyncManager.webviewHandledObjTokens[token] ?? 0
        count += 1
        DocsOfflineSyncManager.webviewHandledObjTokens[token] = count
    }

    func decreaseOpenFileTokenCount(token: String) {
        var count: Int = DocsOfflineSyncManager.webviewHandledObjTokens[token] ?? 0
        count -= 1
        if count <= 0 {
            DocsOfflineSyncManager.webviewHandledObjTokens.removeValue(forKey: token)
        } else {
            DocsOfflineSyncManager.webviewHandledObjTokens[token] = count
        }
    }

    func openFileTokenSet() -> Set<FileListDefine.ObjToken> {
        let allOpenKeys = DocsOfflineSyncManager.webviewHandledObjTokens.keys
        let set = Set(allOpenKeys)
        return set
    }
}

extension DocsOfflineSyncManager {
    /// RN获取native的配置，目前返回RN的日志采样率
    private func handleGetAppSetting(params: [String: Any]) {
        guard let callback = params[RNManager.callbackID] as? String else {
            DocsLogger.info("rn get AppSetting, format wrong", component: LogComponents.offlineSyncDoc)
            return
        }

        offlineSyncQueue.async {
            let rawDict = (try? SettingManager.shared.setting(with: .make(userKeyLiteral: "ccm_powerlog_config"))) ?? [:]
            let rnConfig = rawDict["rn_config"] as? [String: Any] ?? [:]
            let logSampleRate = rnConfig["log_sample_rate"] as? Double ?? 1.0
            let data = ["log_sample_rate": logSampleRate]
            DocsLogger.info("rn get AppSetting, data:\(data)", component: LogComponents.offlineSyncDoc)
            RNManager.manager.sendSyncData(data: data, responseId: callback)
        }
    }
}
