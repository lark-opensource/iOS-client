//
//  ECOProgressListener.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/4.
//

import Foundation
@objc public protocol ECOProgressListener: AnyObject {
    
    /// 上传进度回调
    /// - Parameters:
    ///   - context: 提供发起请求时的上下文信息供内部使用(createTask 时传入的 context)
    func didUploadData(
        context: ECONetworkServiceContext?,
        bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    )
    
    /// 下载进度回调
    /// - Parameters:
    ///   - context: 提供发起请求时的上下文信息供内部使用(createTask 时传入的 context)
    func didDownloadData(
        context: ECONetworkServiceContext?,
        bytesReceive: Int64,
        totalBytesReceive: Int64,
        totalBytesExpectedToReceive: Int64
    )
}
