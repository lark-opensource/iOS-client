//
//  OPPackageModel.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/4.
//

import Foundation
import LarkOPInterface
import OPFoundation

/// 包文件下载状态
@objc
public enum OPPackageLoadStatus: Int {
    /// 未知状态：初始值
    case unknown
    /// 头文件未解析完成
    case headerNotReady
    /// 内容下载中
    case contentDownloading
    /// 下载完成
    case downloaded
}

typealias PackagePogressHandler = (_ received: Float, _ total: Float) -> Void
typealias PackageCompletionHandler = (_ success: Bool, _ packagePath: String?, _ error: OPError?) -> Void

/// 包下载上下文
@objc
public final class OPPackageDownloadContext: NSObject {

    let uniqueID: OPAppUniqueID

    let priority: Float

    let packageInfo: OPMetaPackageProtocol

    var progressHandler: PackagePogressHandler?

    var completionHandler: PackageCompletionHandler?

    init(uniqueID: OPAppUniqueID,
         priority: Float,
         packageInfo: OPMetaPackageProtocol,
         progressHandler: PackagePogressHandler? = nil,
         completionHandler: PackageCompletionHandler? = nil) {
        self.uniqueID = uniqueID
        self.priority = priority
        self.packageInfo = packageInfo
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
    }
}
