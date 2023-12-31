//
//  ECONetworkProgress.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/16.
//

import Foundation
public final class ECONetworkProgress {
    private let semaphore = DispatchSemaphore(value: 1)
    private let callbackQueue: DispatchQueue
    private(set) var listeners: WeakArray<ECOProgressListener> = WeakArray([])
    public var totalBytesSent: Int64 = 0
    public var totalBytesExpectedToSend: Int64 = 0
    public var totalBytesReceive: Int64 = 0
    public var totalBytesExpectedToReceive: Int64 = 0
    
    init(callbackQueue: DispatchQueue) {
        self.callbackQueue = callbackQueue
    }
}

extension ECONetworkProgress {
    // ❗勿对模块外暴露接口, 只允许内部操作
    /// 添加监听者, 线程安全
    func addListener(listener: ECOProgressListener) {
        semaphore.wait(); defer { semaphore.signal() }
        listeners.append(listener)
    }
    
    // ❗勿对模块外暴露接口, 只允许内部操作
    /// 移除监听者, 线程安全
    func removeListener(listener: ECOProgressListener) {
        semaphore.wait(); defer { semaphore.signal() }
        _ = listeners.remove{ $0 === listener }
    }
    
    /// 上传进度回调
    /// - Parameters:
    ///   - context: 提供发起请求时的上下文信息供内部使用(createTask 时传入的 context)
    func didSendData(
        context: ECONetworkServiceContext?,
        bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        self.totalBytesSent = totalBytesSent
        self.totalBytesExpectedToSend = totalBytesExpectedToSend
        callbackQueue.async { [weak self] in
            self?.listeners.forEach{
                $0?.didUploadData(
                    context: context,
                    bytesSent: bytesSent,
                    totalBytesSent: totalBytesSent,
                    totalBytesExpectedToSend: totalBytesExpectedToSend
                )
            }
        }
    }
    
    /// 下载进度回调
    /// - Parameters:
    ///   - context: 提供发起请求时的上下文信息供内部使用(createTask 时传入的 context)
    func didDownloadData(
        context: ECONetworkServiceContext?,
        bytesReceive: Int64,
        totalBytesReceive: Int64,
        totalBytesExpectedToReceive: Int64
    ) {
        self.totalBytesReceive = totalBytesReceive
        self.totalBytesExpectedToReceive = totalBytesExpectedToReceive
        callbackQueue.async { [weak self] in
            self?.listeners.forEach{
                $0?.didDownloadData(
                    context: context,
                    bytesReceive: bytesReceive,
                    totalBytesReceive: totalBytesReceive,
                    totalBytesExpectedToReceive: totalBytesExpectedToReceive
                )
            }
        }
    }
}
