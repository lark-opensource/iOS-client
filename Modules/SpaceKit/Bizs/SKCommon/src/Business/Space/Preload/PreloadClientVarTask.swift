//
//  ClientVarPreloader.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/7.
//
// 预加载clientVar， sheet，评论，投票

import Foundation
import SKFoundation
import SwiftyJSON
import SpaceInterface
import SKInfra

protocol RNPreloadClientVarDelegate: AnyObject {
    func sendRNPreloadClientVarsIfNeed(_ task: PreloadClientVarTask, shouldContinue: Bool)
}

let mayContainEmbeddedDataTypes: [DocsType] = [.doc /*, .docX */] // docX 直接把clientVar和sublock在RN内部实现了

struct PreloadClientVarTask: PreloadTask {
    weak var rnPreloader: RNPreloadClientVarDelegate?
    private let clientVarPreloaderType: ClientVarPreloader.Type
    private var preloadQueue: DispatchQueue
    private var completeBlock: ((Result<Any, Preload.Err>) -> Void)?
    private let maxTryCount: Int
    private var currentTryCount: Strong<Int> = .init(0)
    let key: PreloadKey
    let canUseCarrierNet: Bool // 是否可以使用蜂窝网络来预加载
    private var enqueueTime: TimeInterval
    var finishTask: ((_ succ: Bool, _ code: Int?, _ shouldContinue: Bool) -> Void)? // continue是否继续后续流程
    var willStartTask: (() -> Void)?
    var stateChangeTask: ((_ downloadStatus: DownloadStatus) -> Void)?
    
    var requestReferences = RequestReferences()
    
    // 预加载优先级
    private var loadPriority: PreloadPriority
    
    // 预加载ClintVar统计上报
    private var preloadRecord: PreloadDataRecord
    
    // 用于请求引用，注：如果会多次更新的请求不能使用这个来进行引用
    class RequestReferences {
        var docVersionRequest: DocsRequest<JSON>?
    }
    
    private let clientvarHasLoad = Strong<Bool>(false)
    init(key: PreloadKey, preloadQueue: DispatchQueue, canUseCarrier: Bool, enqueueTime: TimeInterval, waitScheduleTime: TimeInterval, clientVarPreloaderType: ClientVarPreloader.Type, maxRetryCount: Int = 0) {
        self.preloadQueue = DispatchQueue(label: "docPreloadClientVar-\(UUID())", target: preloadQueue)
        self.clientVarPreloaderType = clientVarPreloaderType
        self.key = key
        self.loadPriority = key.loadPriority
        self.canUseCarrierNet = canUseCarrier
        self.enqueueTime = enqueueTime
        self.maxTryCount = maxRetryCount + 1
        self.preloadRecord = PreloadDataRecord(fileID: key.encryptedObjToken, preloadFrom: key.fromSource, waitScheduleTime: waitScheduleTime)
    }
    func currentPriority() -> PreloadPriority {
        return loadPriority
    }
    
    func getEnqueueTime() -> TimeInterval {
        return enqueueTime
    }
    
    mutating func updatePriority(_ newPriority: PreloadPriority) {
        loadPriority = newPriority
    }
    
    mutating func updateEnqueueTime(_ newEnqueueTime: TimeInterval) {
        enqueueTime = newEnqueueTime
    }
    
    mutating func cancel() {
        preloadRecord.endRecord(cancel: true)
        completeBlock?(.failure(.cancel))
        completeBlock = nil
        self.clientvarHasLoad.value = false
        self.currentTryCount.value = 0
    }
    private func expectOnQueue() {
        #if DEBUG
        //dispatchPrecondition(condition: .onQueue(preloadQueue))
        #endif
    }

    mutating func start(complete: @escaping (Result<Any, Preload.Err>) -> Void) {
        self.completeBlock = complete
        self.willStartTask?()
        self.loadClientVars()
    }

    private func loadClientVars() {
        preloadQueue.async {
            self.innerLoadClientVars()
        }
    }

    private var rnLoadClientVarsTypes: [DocsType] {
        var supportTyps: [DocsType] = [.sheet, .bitable, .docX]
        return supportTyps
    }

    private func innerLoadClientVars() {
        DocsLogger.info("clientVar start!", component: LogComponents.preload)
        self.currentTryCount.value += 1
        expectOnQueue()
        if key.objToken.isEmpty {
            didFinish(succ: true, shouldContinue: false)
            return
        }
        if key.needPreload() {
            _innerLoadClientVars()
        } else if key.isTimeOut {
            requestReferences.docVersionRequest = key.fetchDocsVersion(preloadKey: key, completion: { (token, version, error) in
                preloadQueue.async {
                    defer {
                        requestReferences.docVersionRequest = nil
                    }
                    if error != nil {
                        DocsLogger.error("fetch DocVersion error: \(String(describing: error?.localizedDescription))")
                    }
                    //请求clientVar的版本号失败也需要更新
                    if  let token = token,
                        key.objToken == token,
                        let newVersion = version,
                        let oldVersion = key.clientVarVersion,
                        oldVersion >= newVersion {
                        //当前版本号不低于clientVar最新的版本号不需要执行预加载，仅重置clientVar的更新时间
                        key.setClietVarUpdateTime()
                        didFinish(succ: true, shouldContinue: false)
                        return
                    }
                    _innerLoadClientVars()
                }
            })
        } else {
            didFinish(succ: true, shouldContinue: false)
            return
        }
    }
    
    private func _innerLoadClientVars() {
        stateChangeTask?(.downloading)
        WatermarkManager.shared.requestWatermarkInfo(key.toWatermarkKey)

        if key.type == .wiki {
            guard let wikiInfo = key.wikiInfo, wikiInfo.docsType.isOpenByWebview else {
                return
            }
            // 先缓存wiki_info
            DocsLogger.debug("wiki 预加载： wiki_info: \(wikiInfo)")
            self.key.newCacheAPI.set(object: wikiInfo.dictValue as NSCoding,
                                     for: wikiInfo.wikiToken,
                                     subkey: DocsType.wiki.wikiInfoKey, cacheFrom: nil)

            // 各个业务的clientVars单独缓存
            DocsLogger.debug("wiki 预加载： biz clientvars: \(wikiInfo.docsType)")
            _loadClientVars(byRN: rnLoadClientVarsTypes.contains(wikiInfo.docsType))
        } else {
            _loadClientVars(byRN: rnLoadClientVarsTypes.contains(key.type))
        }
    }

    private func _loadClientVars(byRN: Bool) {
        
        // 添加统计信息
        self.constructPreloadRecordAndStart(loaderType: byRN ? .RN : .Native, fileType: self.key.type, subFileType:self.key.wikiRealPreloadKey?.type)
        if byRN {
            // 走RN通道的预加载的类型，列表是 loadClientVarsByRNTypes
            rnPreloader?.sendRNPreloadClientVarsIfNeed(self, shouldContinue: true)
            preloadQueue.asyncAfter(deadline: DispatchTime.now() + 20) {
                self.didFinish(succ: false, code: PreloadErrorCode.RNTimeOut.rawValue, shouldContinue: true) // 这里是超时重试逻辑的入口，如果在这之前已经 succ 的话，走这个代码会被 clientvarHasLoad 这个 flag 拦截返回
            }
        } else {
            let key: PreloadKey = self.key.wikiRealPreloadKey ?? self.key
            // 走本地请求的预加载
            DocsLogger.info("start preload clientvar for \(key), count \(self.currentTryCount.value)", component: LogComponents.preload)
            let request = clientVarPreloaderType.requestWith(key)
            request.load(preloadKey: key, result: {  (data, _, error) in
                preloadQueue.async {
                    var succ = true
                    var resultCode: Int?
                    defer {
                        if let preloadKey = data {
                            preloadRecord.updateLoadLength(loadLength: UInt64(preloadKey.count))
                        }
                        self.didFinish(succ: succ, code: resultCode, shouldContinue: true)
                    }
                    guard error == nil, let data = data else {
                        DocsLogger.error("error \(error.debugDescription)")
                        succ = false
                        return
                    }
                    guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any],
                        let innerDict = dict["data"] as? [String: Any] else {
                            succ = false
                            return
                    }
                    if key.type != .docX {
                        resultCode = innerDict["code"] as? Int
                        guard let code = innerDict["code"] as? Int, code == 0 else {
                            DocsLogger.warning("preload response code not 0")
                            succ = false
                            return
                        }
                    } else {
                        resultCode = dict["code"] as? Int
                        guard let code = resultCode, code == 0 else {
                            DocsLogger.warning("preload response code not 0")
                            succ = false
                            return
                        }
                    }

                    self.key.savePreloadedData(dict)
                    succ = true
                    DispatchQueue.global().async {
                        var preloadKey = self.key
                        preloadKey.responseLength = data.count
                        self.addStatisticsForPreloadOK(preloadKey)
                    }
                }
            })
            request.referenceSelf()
        }
    }

    // 这个方法有两个入口会调用
    // 一个是 RN 通过 loadComplete 接口传过来完成（见 DocRNPreloader.didReceivedRNData）
    // 另一个是重复加载已经完成的 clientVars 时的提前返回（见 DocRNPreloader.sendRNPreloadIfNeed）
    func didFinishClientVarPreload(_ preloadKey: PreloadKey, success: Bool, code: Int?, canRetry: Bool = true) {
        guard preloadKey == key else {
            return
        }
        didFinish(succ: success, code: code, canRetry: canRetry, shouldContinue: true)
    }

    /// clientVar 结束了，开始做其他事情，比如预加载 block 的信息（嵌入sheet、嵌入bitable、投票等）
    private func didFinish(succ: Bool, code: Int? = nil, canRetry: Bool = true, shouldContinue: Bool) {
        preloadQueue.async {
            self.innerFinish(succ: succ, code: code, canRetry: canRetry, shouldContinue: shouldContinue)
        }
    }

    private func innerFinish(succ: Bool, code: Int? = nil, canRetry: Bool, shouldContinue: Bool) {
        expectOnQueue()
        guard !self.clientvarHasLoad.value else {
            return
        }
        if !succ,
           canRetry,
            self.currentTryCount.value < maxTryCount,
            code != DocsNetworkError.Code.coldDocument.rawValue,
            code != DocsNetworkError.Code.forbidden.rawValue,
            code != DocsNetworkError.Code.resourceDeleted.rawValue,
            code != DocsNetworkError.Code.docsForbidden.rawValue,
            code != PreloadErrorCode.ClientVarsNoPermission.rawValue {
            preloadRecord.updateResultCode(code: code ?? PreloadErrorCode.unknowError.rawValue)
            preloadRecord.endRecord()
            loadClientVars() // 失败重试
            DocsLogger.info("start preload clientvar for \(key) failed retry :\(self.currentTryCount.value)", component: LogComponents.preload)
            return
        }
        preloadRecord.updateResultCode(code: code ?? 0)
        preloadRecord.endRecord()
        self.clientvarHasLoad.value = true
//        DocsLogger.debug("\(self.key) clientvar ok", component: LogComponents.preload)
        if mayContainEmbeddedDataTypes.contains(key.type), code != DocsNetworkError.Code.coldDocument.rawValue {
            self.rnPreloader?.sendRNPreloadClientVarsIfNeed(self, shouldContinue: shouldContinue)
        }

        self.finishTask?(succ, code, shouldContinue)
        self.completeBlock?(.success(()))
    }

    private func addStatisticsForPreloadOK(_ preloadKey: PreloadKey) {
        spaceAssert(!Thread.isMainThread)
        var params: [String: Any] = [DocsTracker.Params.fileType: preloadKey.type.name]
        params[DocsTracker.Params.fileId] = preloadKey.encryptedObjToken
        params[DocsTracker.Params.docNetStatus] = DocsNetStateMonitor.shared.accessType.intForStatistics
        params[DocsTracker.Params.responseLentgh] = preloadKey.responseLength
        DocsTracker.log(enumEvent: .preloadClientVar, parameters: params)
    }
    
    private func constructPreloadRecordAndStart(loaderType: LoaderType, fileType: DocsType, subFileType: DocsType?) {
        preloadRecord.updateInitInfo(loaderType: loaderType, fileType: fileType, subFileType: subFileType, loadType: .clientVars, retry: self.currentTryCount.value - 1, priority: self.loadPriority.rawValue)
        preloadRecord.startRecod()
    }
}

extension PreloadClientVarTask: Hashable {
    static func == (lhs: PreloadClientVarTask, rhs: PreloadClientVarTask) -> Bool {
        return lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

extension PreloadKey {
    func makeClientVarTask(canUseCarrierNetwork: Bool, preloadQueue: DispatchQueue, clientVarPreloaderType: ClientVarPreloader.Type, maxRetryCount: Int, enqueueTime: TimeInterval, waitScheduleTime: TimeInterval) -> PreloadClientVarTask {
        return PreloadClientVarTask(key: self, preloadQueue: preloadQueue, canUseCarrier: canUseCarrierNetwork, enqueueTime: enqueueTime, waitScheduleTime: waitScheduleTime, clientVarPreloaderType: clientVarPreloaderType, maxRetryCount: maxRetryCount)
    }
}
