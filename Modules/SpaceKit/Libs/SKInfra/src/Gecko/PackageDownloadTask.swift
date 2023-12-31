//
//  PackageDownloadTask.swift
//  SKCommon
//
//  Created by ByteDance on 2022/7/4.
//

import Foundation
import SKFoundation

protocol PackageDownloadTaskDelegate: AnyObject {
    /// 任务成功回调
    /// - Parameter task: 下载任务
    func onSuccess(task: PackageDownloadTask)
    
    /// 任务失败回调
    /// - Parameters:
    ///   - task: 下载任务
    ///   - errorCode: 错误码。常见错误码：1007网络不可用，1005请求错误，1002超时 https://bytedance.feishu.cn/docs/doccnPv5NHZelDU67B7skU
    func onFailure(task: PackageDownloadTask, errorMsg: String)
}

protocol PackageDownloadTask: AnyObject {
    var delegate: PackageDownloadTaskDelegate? { get }
    var isGrayscale: Bool { get }
    var version: String { get }
    var downloadPath: SKFilePath { get }
    var resourceInfo: GeckoPackageManager.FEResourceInfo? { get }
    var isForUnzipBundleSlimFailed: Bool { get set }
    func start()
    func cancel()
}
