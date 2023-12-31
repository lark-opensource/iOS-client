//
//  BTFetchDataManager.swift
//  SKBitable
//
//  Created by zoujie on 2022/10/19.
//  


import SKFoundation
import ThreadSafeDataStructure

protocol BTFetchDataDelegate: AnyObject {
    func executeRequest(request: BTGetCardListRequest, isRetry: Bool)
    ///处理请求状态变化
    func handleRequestStatusChange(request: BTGetCardListRequest,
                                   status: BTGetCardListRequestStatus,
                                   result: BTTableValue?)
}

final class BTFetchDataManager {
    //卡片请求队列
    var cardListRequestQueue = SafeSet<BTGetCardListRequest>()

    var currentCardListRequest: BTGetCardListRequest? //当前正在处理的请求

    //卡片请求等待队列
    var cardListRequestWaitingQueue = SafeSet<BTGetCardListRequest>()
    
    weak var delegate: BTFetchDataDelegate?
    
    /// 请求队列执行clear时的时间戳
    private var clearRequestTimestamp: String = "0"
    
    /// 是否需要处理请求的callback，被从队列清理的请求，后续callback回来后不需要处理
    func shouldHandleCallback(request: BTGetCardListRequest) -> Bool {
        guard !UserScopeNoChangeFG.ZJ.btLinkPanleSearchDisable else { return true }
        return request.requestId > clearRequestTimestamp
    }
    
    func disposeRequest(request: BTGetCardListRequest) {
        DocsLogger.btInfo("[BTFetchDataManager] start disposeRequest type:\(request.requestType)")
        guard !cardListRequestWaitingQueue.contains(request) else {
            //已在等待队列中的请求不触发
            request.completionBlock?(false)
            DocsLogger.btError("[BTFetchDataManager] disposeRequest request is watting type:\(request.requestType)")
            return
        }
        
        //先请求，放入请求队列，数据在loading再放入等待队列
        let (insertSuccess, _) = cardListRequestQueue.insert(request)

        if currentCardListRequest == nil, insertSuccess {
            currentCardListRequest = request
            executeRequest(request: request)
        } else if !insertSuccess {
            request.completionBlock?(false)
        }
    }

    func executeRequest(request: BTGetCardListRequest?,
                                isRetry: Bool = false) {
        guard var request = request else {
            return
        }

        request.requestStatus = .processing
        _ = cardListRequestQueue.update(with: request)
        delegate?.executeRequest(request: request, isRetry: isRetry)
    }
    
    ///开启请求超时计时器
    func startRequestTimer(request: BTGetCardListRequest) {
        DocsLogger.btInfo("[BTFetchDataManager] startRequestTimer type:\(request.requestType)")
        var currentRequest = request

        currentRequest.requestTimer?.invalidate()
        currentRequest.requestTimer = nil
        let timer = Timer(timeInterval: request.overTimeInterval, repeats: false) { [weak self] _ in
            guard let self = self, self.shouldHandleCallback(request: request) else {
                currentRequest.requestTimer?.invalidate()
                currentRequest.requestTimer = nil
                return
            }
            self.delegate?.handleRequestStatusChange(request: currentRequest, status: .timeOut, result: nil)
        }
        RunLoop.main.add(timer, forMode: .common)
        currentRequest.requestTimer = timer
        _ = cardListRequestWaitingQueue.update(with: currentRequest)
    }
    
    ///处理请求队列中的请求
    func handleNextRequest() {
        DocsLogger.btInfo("[BTFetchDataManager] handleNextRequest currentCardListRequest:\(String(describing: currentCardListRequest?.requestType))")
        guard let request = currentCardListRequest,
              cardListRequestQueue.contains(request) else {
            return
        }
        
        _ = cardListRequestQueue.remove(request)
        currentCardListRequest = cardListRequestQueue.first
        //执行下一个请求
        executeRequest(request: currentCardListRequest)
    }
    
    ///清空等待中或处理中的请求
    func clearWaitingAndDisposingRequests() {
        DocsLogger.btInfo("[BTFetchDataManager] clearCardListRequestWaitingQueue")
        //清空请求等待队列，但需要保留initialize的请求，因为会有case是打开关联面板时，收到前端的update事件过来
        //收到update事件需要清空等待队列，但是不能移除initialize请求
        var initialRequest: BTGetCardListRequest?
        cardListRequestWaitingQueue.forEach { r in
            if case .initialize(_) = r.requestType {
                initialRequest = r
            } else if r.requestType == .linkCardInitialize {
                initialRequest = r
            }
        }
        
        //需要取消所有等待请求的timer
        cardListRequestWaitingQueue.forEach { r in
            var request = r
            guard request.requestType != .linkCardInitialize else {
                return
            }

            request.invalidateTimer()
        }
        
        reset()
        if let initialRequest = initialRequest {
            cardListRequestWaitingQueue.insert(initialRequest)
        }
    }
    
    func reset() {
        clearRequestTimestamp = String(Date().timeIntervalSince1970)
        currentCardListRequest = nil
        cardListRequestQueue.removeAll()
        cardListRequestWaitingQueue.removeAll()
    }
}
