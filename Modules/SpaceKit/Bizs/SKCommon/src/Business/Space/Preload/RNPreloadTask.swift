//
//  RNPreloadTask.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/9.
//

import SKFoundation

extension Preload {
    enum RNTaskType {
        case poll
        case comment

        var typeNameInRN: String {
            switch self {
            case .poll: return "POLL_DATA"
            case .comment: return "COMMENTS_DATA"
            }
        }
    }
}

protocol RNPreloadTaskDelegate: AnyObject {
    func sendRNToPreload(_ task: RNPreloadTask)
}

/// 让RN 去做加载的队列
struct RNPreloadTask: PreloadTask {
    fileprivate weak var rnPreloaderDelegate: RNPreloadTaskDelegate?
    private var completeBlock: ((Result<Any, Preload.Err>) -> Void)?
    private var preloadQueue: DispatchQueue
    let key: PreloadKey
    let type: Preload.RNTaskType
    let canUseCarrierNet: Bool
    private var enqueueTime: TimeInterval
    var finishTask: (() -> Void)?
    private var loadPriority: PreloadPriority // 预加载优先级
    private let clientvarHasLoad = Strong<Bool>(false)
    init(key: PreloadKey, preloadQueue: DispatchQueue, type: Preload.RNTaskType, canUseCarrier: Bool, enqueueTime: TimeInterval) {
        self.type = type
        self.key = key
        self.enqueueTime = enqueueTime
        self.loadPriority = key.loadPriority
        self.canUseCarrierNet = canUseCarrier
        self.preloadQueue = DispatchQueue(label: "RNPreloadTask-\(UUID())", target: preloadQueue)
    }
    
    func currentPriority() -> PreloadPriority  {
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
        self.clientvarHasLoad.value = false
    }
    private func expectOnQueue() {
        #if DEBUG
        //dispatchPrecondition(condition: .onQueue(preloadQueue))
        #endif
    }

    mutating func start(complete: @escaping (Result<Any, Preload.Err>) -> Void) {
        self.completeBlock = complete
        self.load()
    }

    func didFinishRNPreload(_ preloadKey: PreloadKey) {
        guard preloadKey == key else {
            return
        }
//        DocsLogger.info("end preload \(type) \(key)  from RN", component: LogComponents.preload)
        didFinish()
    }

    private func didFinish() {
        preloadQueue.asyncAfter(deadline: DispatchTime.now() + 0.01, execute: {
            self.innerFinish()
        })
    }

    private func innerFinish() {
        expectOnQueue()
        guard !self.clientvarHasLoad.value else {
            return
        }
        self.clientvarHasLoad.value = true
//        DocsLogger.debug("\(self.key) \(type) clientvar ok", component: LogComponents.preload)

        self.finishTask?()
        self.completeBlock?(.success(()))
    }

    private func load() {
        preloadQueue.async {
            self.innerLoad()
        }
    }

    private func innerLoad() {
        DocsLogger.info("\(type) \(key) start!", component: LogComponents.preload)
        expectOnQueue()
        if key.objToken.isEmpty || !key.needPreload(type) {
            didFinish()
            return
        }

        rnPreloaderDelegate?.sendRNToPreload(self)
        preloadQueue.asyncAfter(deadline: DispatchTime.now() + 20) {
            self.didFinish()
        }
        return
    }
}

extension RNPreloadTask {
    /// 给RN的数据
    func getDataToRN() -> [String: Any] {
        var body = [String: Any]()
        body["type"] = key.type.rawValue
        body["objToken"] = key.objToken
        body["dataType"] = type.typeNameInRN
        body["key"] = key.cacheKeyPrefix + type.typeNameInRN
        if type == .poll {
            body["dataToken"] = key.getPollTokens()
        }
        let data: [String: Any] = ["operation": "preloadData",
                                   "body": body]
        let composedData: [String: Any] = ["business": "base",
                                           "data": data]
        return composedData
    }
}

extension RNPreloadTask: Hashable {
    static func == (lhs: RNPreloadTask, rhs: RNPreloadTask) -> Bool {
        return lhs.key == rhs.key && lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(type)
    }
}

extension PreloadKey {
    func makeVoteTask(canUseCarrierNetwork: Bool = true, preloadQueue: DispatchQueue, delegate: RNPreloadTaskDelegate, enqueueTime: TimeInterval) -> RNPreloadTask {
        var task = RNPreloadTask(key: self, preloadQueue: preloadQueue, type: .poll, canUseCarrier: canUseCarrierNetwork, enqueueTime: enqueueTime)
        task.rnPreloaderDelegate = delegate
        return task
    }

    func makeCommentTask(canUseCarrierNetwork: Bool = true, preloadQueue: DispatchQueue, delegate: RNPreloadTaskDelegate, enqueueTime: TimeInterval) -> RNPreloadTask {
        var task = RNPreloadTask(key: self,  preloadQueue: preloadQueue, type: .comment, canUseCarrier: canUseCarrierNetwork, enqueueTime: enqueueTime)
        task.rnPreloaderDelegate = delegate
        return task
    }
}

extension PreloadKey {
    func needPreload(_ type: Preload.RNTaskType) -> Bool {
        switch type {
        case .poll:
            if getPollTokens().isEmpty {
                return false
            }
            let isComplete = newCacheAPI.object(forKey: objToken, subKey: "\(cacheKeyPrefix)POLL_DATA_COMPLETE") as? Bool
            return !(isComplete ?? false)
        case .comment:
            if resources?["comments"] == nil, customeParseComments == nil {
                return false
            }
            let isComplete = newCacheAPI.object(forKey: objToken, subKey: "\(cacheKeyPrefix)COMMENTS_DATA_COMPLETE") as? Bool
            return !(isComplete ?? false)
        }
    }

    func getPollTokens() -> [String] {
        guard let res = resources else { return [] }
        guard let polls = res["polls"] as? [[String: Any]] else {
            return []
        }
        let tokens = polls.compactMap { return $0["token"] as? String }
        if tokens.count <= 5 {
            return tokens
        }
        let subTokens = tokens[0..<maxRNPreloadSubBlockNum] as? [String]
        return subTokens ?? tokens
    }
}
