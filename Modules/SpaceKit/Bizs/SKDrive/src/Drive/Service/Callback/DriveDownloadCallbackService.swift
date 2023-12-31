//
//  DriveDownloadCallbackService.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/3/31.
//

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface

// MARK: - 处理分发下载回调Service
final class DriveDownloadCallbackService: DriveMultipDelegates, DriveDownloadCallback {

    static let shared = DriveDownloadCallbackService()

    /// 失败回调
    ///
    /// - Parameters:
    ///   - key: 失败的文件key
    ///   - errorCode: 错误码
    /// - Returns:
    func onFailed(key: String, errorCode: Int) {
        DocsLogger.debug("Rust - on_failed: key:\(key) errorCode: \(errorCode)")
        invoke({ (delegate: DriveDownloadCallback) in
            DispatchQueue.main.async {
                delegate.onFailed(key: key, errorCode: errorCode)
            }
        })
    }

    /// Rust下载回调
    ///
    /// - Parameters:
    ///   - key: 下载文件key
    ///   - status: 状态
    ///   - bytesTransferred: 已经传输的大小
    ///   - bytesTotal: 总大小
    /// - Returns:
    func updateProgress(context: DriveDownloadContext) {
        DocsLogger.debug("Rust - update_progress - status: \(context.status), bytes_transferred: \(context.bytesTransferred), bytes_total: \(context.bytesTotal)")
        invoke({ (delegate: DriveDownloadCallback) in
            DispatchQueue.main.async {
                delegate.updateProgress(context: context)
            }
        })
    }
}

extension DriveDownloadCallbackService: DriveDownloadCallbackServiceBase {
    
}
