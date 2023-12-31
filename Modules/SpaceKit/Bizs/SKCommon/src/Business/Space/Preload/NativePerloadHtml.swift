//
//  NativePerloadHtml.swift
//  SKCommon
//
//  Created by lizechuang on 2021/10/18.
//  docx预加载html，直接通过结构请求获取HTML缓存，与doc1.0区分
//  https://bytedance.feishu.cn/docx/doxcnjtSetRMGbttFh3uZbDLN1d#doxcnio0aWse8q0y8Ker4QdiGPg

import Foundation
import SKFoundation
import SpaceInterface
import SKInfra
import SKUIKit

public struct NativePerloadHtmlTask: PreloadTask {
    private var completeBlock: ((Result<Any, Preload.Err>) -> Void)?
    public static weak var delegate: BrowserJSEngine?
    private var preloadQueue: DispatchQueue
    var key: PreloadKey
    let canUseCarrierNet: Bool
    public var finishTask: ((_ err: Int) -> Void)?
    var willStartTask: (() -> Void)?
    // 预加载优先级
    private var loadPriority: PreloadPriority
    private var enqueueTime: TimeInterval
    private let htmlHasLoad = Strong<Bool>(false)
    private let isCancel = Strong<Bool>(false)
    private let newCacheAPI: NewCacheAPI
    private var preloadRecord: PreloadDataRecord // 预加载上报
    private var loadErrCode: Strong<Int> = .init(0)
    private var loadData: Strong<H5DataRecord?> = .init(nil)
    private var forceRequest: Bool = false
    init(key: PreloadKey, preloadQueue: DispatchQueue, canUseCarrier: Bool, enqueueTime: TimeInterval, waitScheduleTime: TimeInterval, resolver: DocsResolver = DocsContainer.shared) {
        self.key = key
        self.preloadQueue = DispatchQueue(label: "nativePreloadHtml-\(UUID())", target: preloadQueue)
        self.canUseCarrierNet = canUseCarrier
        self.enqueueTime = enqueueTime
        self.preloadRecord = PreloadDataRecord(fileID: key.encryptedObjToken, preloadFrom: key.fromSource, waitScheduleTime: waitScheduleTime)
        self.loadPriority = key.loadPriority
        newCacheAPI = resolver.resolve(NewCacheAPI.self)!
    }
    
    public init(key: PreloadKey, taskQueue: DispatchQueue, resolver: DocsResolver = DocsContainer.shared) {
        self.key = key
        self.canUseCarrierNet = true
        self.enqueueTime = 0
        self.preloadQueue = taskQueue
        self.preloadRecord = PreloadDataRecord(fileID: key.encryptedObjToken, preloadFrom: key.fromSource, waitScheduleTime: 0)
        self.loadPriority = key.loadPriority
        newCacheAPI = resolver.resolve(NewCacheAPI.self)!
    }
    
    mutating func cancel() {
        preloadRecord.endRecord(cancel: true)
        completeBlock?(.failure(.cancel))
        completeBlock = nil
        self.htmlHasLoad.value = false
        self.isCancel.value = true
    }
    private func expectOnQueue() {
        #if DEBUG
        //dispatchPrecondition(condition: .onQueue(preloadQueue))
        #endif
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
    
    //强制请求最新的ssr，忽略缓存
    mutating public func startForceRequest(complete: @escaping (Result<Any, Preload.Err>) -> Void) {
        self.forceRequest = true
        self.start(complete: complete)
    }

    mutating public func start(complete: @escaping (Result<Any, Preload.Err>) -> Void) {
        self.completeBlock = complete
        self.willStartTask?()
        self.loadHtml()
    }

    /// preloadHtml 结束
    public func didFinish() {
        preloadQueue.asyncAfter(deadline: DispatchTime.now() + 0.01, execute: {
            self.innerFinish()
        })
    }

    private func innerFinish() {
        expectOnQueue()
        guard !self.htmlHasLoad.value else {
            return
        }
        self.htmlHasLoad.value = true
        preloadRecord.updateResultCode(code: 0)
        preloadRecord.endRecord()
        self.finishTask?(self.loadErrCode.value)
        self.completeBlock?(.success(self.loadData.value ?? ()))
    }

    private func loadHtml() {
        let renderKey = DocsType.htmlCacheKey
        let realKey = key.wikiRealPreloadKey ?? key
        let token =  realKey.objToken
        guard let prefix = User.current.info?.cacheKeyPrefix else {
            return
        }
        /// 强制刷新，则不读缓存是否存在
        ///先判断cache是否已经存在了，如果存在则不去拉取 直接finish
        if !forceRequest,
            let cachedHtml = newCacheAPI.object(forKey: token, subKey: prefix + renderKey),
            cachedHtml != nil {
            //记录下data，可以回调使用
            self.loadData.value = cachedHtml as? H5DataRecord
            DocsLogger.info("native preload html ,has cache，can load next", component: LogComponents.preload)
            didFinish()
        } else {
            preloadQueue.async {
                self.innerLoadHtml()
            }
        }
    }

    private func innerLoadHtml() {
        if key.wikiRealPreloadKey != nil {
            DocsLogger.info("wiki-SSR start!", component: LogComponents.preload)
        } else {
            DocsLogger.info("SSR start!", component: LogComponents.preload)
        }
        expectOnQueue()
        guard !key.objToken.isEmpty else {
            didFinish()
            return
        }
        let realKey = key.wikiRealPreloadKey ?? key
        ///获取 ssr html数据
        var parameters = [String: Any]()
        parameters["version"] = SpaceKit.version
        let userDomain = DomainConfig.userDomain
        var path = OpenAPI.APIPath.getDocxSSRContent + realKey.objToken
        //判断是否是ipad，是则拼接?isipad=true
        if UserScopeNoChangeFG.HZK.enableIpadSSR && SKDisplay.pad {
            path += "?isipad=true"
        }
        let urlStr = OpenAPI.docs.currentNetScheme + "://" + userDomain + path
        let getHtmlRequest = DocsRequest<Any>(url: urlStr, params: parameters)
        DocsLogger.info("native preload html start: \(realKey.objToken.encryptToShort)", component: LogComponents.preload)
        constructPreloadRecordAndStart(loaderType: .Native, fileType: self.key.type, subFileType: self.key.wikiRealPreloadKey?.type)
        getHtmlRequest.set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .set(needVerifyData: false)
            .start(rawResult: { (data, _, error) in
                preloadQueue.async {
                    defer {
                        if self.htmlHasLoad.value == false, self.isCancel.value == false {
                            self.didFinish()
                        }
                    }
                    guard error == nil, let data = data else {
                        DocsLogger.error("native preload html error \(error.debugDescription)", component: LogComponents.preload)
                        let nsErr = error as? NSError ?? NSError(domain: "Native Preload Html", code: PreloadErrorCode.unknowError.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unknow Error"])
                        self.loadErrCode.value = nsErr.code
                        self.preloadRecord.updateResultCode(code: nsErr.code)
                        self.preloadRecord.endRecord()
                        return
                    }
                    if let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        if  dict["data"] != nil {
                            let resultCode = dict["code"] as? Int ?? PreloadErrorCode.GetSSRDataError.rawValue
                            if resultCode == 0, let prefix = User.current.info?.cacheKeyPrefix {
                                let renderKey = DocsType.htmlCacheKey
                                let token = key.objToken
                                let record = H5DataRecord(objToken: token, key: prefix + renderKey, needSync: false, payload: dict as NSCoding, type: nil, cacheFrom: .cacheFromPreload)
                                self.loadData.value = record
                                newCacheAPI.setH5Record(record)
                            } else {
                                DocsLogger.error("get native preload error code:\(resultCode), message:\(String(describing: dict["message"]))", component: LogComponents.preload)
                                self.loadErrCode.value = resultCode
                                self.preloadRecord.updateResultCode(code: resultCode)
                                self.preloadRecord.endRecord()
                            }
                        } else {
                            DocsLogger.error("get native preload data is empty, message:\(String(describing: dict["message"]))", component: LogComponents.preload)
                            let resultCode = dict["code"] as? Int ?? PreloadErrorCode.SSRDataFormatDataEmpty.rawValue
                            self.loadErrCode.value = resultCode
                            self.preloadRecord.updateResultCode(code: resultCode)
                            self.preloadRecord.endRecord()
                        }
                    } else {
                        DocsLogger.error("get native preload html fail", component: LogComponents.preload)
                        self.loadErrCode.value = PreloadErrorCode.SSRDataFormatJsonError.rawValue
                        self.preloadRecord.updateResultCode(code: PreloadErrorCode.SSRDataFormatJsonError.rawValue)
                        self.preloadRecord.endRecord()
                    }
                }
            })
        getHtmlRequest.makeSelfReferenced()
    }
    
    private func constructPreloadRecordAndStart(loaderType: LoaderType, fileType: DocsType, subFileType: DocsType?) {
        preloadRecord.updateInitInfo(loaderType: loaderType, fileType: fileType, subFileType: subFileType, loadType: .SSR, retry: 0, priority: self.loadPriority.rawValue)
        preloadRecord.startRecod()
    }
}

extension NativePerloadHtmlTask: Hashable {
    public static func == (lhs: NativePerloadHtmlTask, rhs: NativePerloadHtmlTask) -> Bool {
        return lhs.key == rhs.key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

extension PreloadKey {
    func makeNativeHtmlTask(canUseCarrierNetwork: Bool, enqueueTime: TimeInterval, waitScheduleTime: TimeInterval, preloadQueue: DispatchQueue) -> NativePerloadHtmlTask {
        return NativePerloadHtmlTask(key: self, preloadQueue: preloadQueue, canUseCarrier: canUseCarrierNetwork, enqueueTime: enqueueTime, waitScheduleTime: waitScheduleTime)
    }
}
