//
//  PreloadHtml.swift
//  SpaceKit
//
//  Created by LiXiaolin on 2019/8/9.
//  预加载html，将clientVar传给web,由web端直出html

import Foundation
import SwiftyJSON
import SKFoundation
import SpaceInterface
import SKInfra

public struct PreloadHtmlTask: PreloadTask {
    private var completeBlock: ((Result<Any, Preload.Err>) -> Void)?
    public static weak var delegate: BrowserJSEngine?
    private var preloadQueue: DispatchQueue
    var key: PreloadKey
    let canUseCarrierNet: Bool
    private var enqueueTime: TimeInterval
    var finishTask: (() -> Void)?
    // 预加载优先级
    private var loadPriority: PreloadPriority
    private let htmlHasLoad = Strong<Bool>(false)
    private let isCancel = Strong<Bool>(false)
    private let newCacheAPI: NewCacheAPI
    public init(key: PreloadKey, preloadQueue: DispatchQueue, canUseCarrier: Bool, enqueueTime: TimeInterval, resolver: DocsResolver = DocsContainer.shared) {
        self.key = key
        self.preloadQueue = DispatchQueue(label: "docPreloadHtml-\(UUID())", target: preloadQueue)
        self.canUseCarrierNet = canUseCarrier
        self.enqueueTime = enqueueTime
        self.loadPriority = key.loadPriority
        newCacheAPI = resolver.resolve(NewCacheAPI.self)!
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

    mutating func start(complete: @escaping (Result<Any, Preload.Err>) -> Void) {
        self.completeBlock = complete
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
//        DocsLogger.debug("\(self.key) preLoadHtml ok", component: LogComponents.preload)

        self.finishTask?()
        self.completeBlock?(.success(()))
    }

    private func loadHtml() {
        let renderKey = DocsType.htmlCacheKey
        let token = key.objToken
        guard let prefix = User.current.info?.cacheKeyPrefix else {
            return
        }
        ///先判断cache是否已经存在了，如果存在则不去拉取 直接finish
        let cachedHtml = newCacheAPI.object(forKey: token, subKey: prefix + renderKey)
        if cachedHtml != nil {
            DocsLogger.info("preload html ,has cache，can load next", component: LogComponents.preload)
            didFinish()
        } else {
            preloadQueue.async {
                self.innerLoadHtml()
            }
        }
    }

    private func innerLoadHtml() {
        DocsLogger.info("htmlPreload start!", component: LogComponents.preload)
        expectOnQueue()
        DocsLogger.debug("start htmlPreload \(key)", component: LogComponents.preload)
        if key.objToken.isEmpty {
            didFinish()
        }
        ///获取clientVars后传给web进行预渲染html
        var parameters = [String: Any]()
        parameters["type"] = "doc"
        parameters["token"] = self.key.objToken
        let recordKey = H5DataRecordKey(objToken: self.key.objToken, key: self.key.clientVarKey)
        let clientvar = newCacheAPI.getH5RecordBy(recordKey)?.payload
        parameters["clientVars"] = clientvar
//        DocsLogger.info("preload html,token:\(self.key)")

        DispatchQueue.main.async {//串行、异步

            PreloadHtmlTask.delegate?.callFunction(DocsJSCallBack.preLoadHtml, params: parameters, completion: { (_, error) in
                if let err = error {
                    DocsLogger.error("preload html :error", extraInfo: nil, error: err, component: LogComponents.preload)
                } else {
//                    DocsLogger.error("preload html :success token:\(self.key)", extraInfo: nil, error: nil, component: nil)
                }
                //5s的超时逻辑，假如5秒钟还没生成html就当是失败，继续下一个
                preloadQueue.asyncAfter(deadline: DispatchTime.now() + 10) {
                    if self.htmlHasLoad.value == false, self.isCancel.value == false {
                        self.didFinish()
                    }
                }
            })
        }
    }
}

extension PreloadHtmlTask: Hashable {
    public static func == (lhs: PreloadHtmlTask, rhs: PreloadHtmlTask) -> Bool {
        return lhs.key == rhs.key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

extension PreloadKey {
    func makeHtmlTask(canUseCarrierNetwork: Bool, enqueueTime: TimeInterval, preloadQueue: DispatchQueue) -> PreloadHtmlTask {
        return PreloadHtmlTask(key: self, preloadQueue: preloadQueue, canUseCarrier: canUseCarrierNetwork, enqueueTime: enqueueTime)
    }
}
