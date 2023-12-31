//
//  OPAppLoader.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/10/29.
//

import Foundation
import LarkOPInterface
import OPFoundation

/// loader上下文，用于做串联
@objcMembers public final class OPAppLoaderContext: NSObject {
    /// Application 上下文
    public let applicationContext: OPApplicationContext

    /// Loader 唯一ID
    public let uniqueID: OPAppUniqueID

    /// Loader 预览token
    public let previewToken: String

    public init(applicationContext: OPApplicationContext, uniqueID: OPAppUniqueID,
                previewToken: String) {
        self.applicationContext = applicationContext
        self.uniqueID = uniqueID
        self.previewToken = previewToken
    }

}

/// 应用loader需要遵循的协议，后续需要补上bundlemanager
public protocol OPAppLoaderProtocol: OPAppLoaderSimpleProtocol {
    /// loader 上下文
    var loaderContext: OPAppLoaderContext { get }
}

public protocol OPAppLoaderSimpleProtocol: AnyObject {
    /// 冷加载meta和package
    /// - Parameter listener: 事件监听者
    func loadMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?)

    /// 异步更新meta和package
    /// - Parameter listener: 事件监听者
    func asyncUpdateMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?)

    /// 预加载meta和package
    /// - Parameter listener: 事件监听者
    func preloadMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?)

    /// 取消加载meta和package
    func cancelLoadMetaAndPackage()
}

/// loader策略，外部需要根据不同策略进行不同的处理（比如异步更新后的升级弹窗逻辑）
@objc
public enum OPAppLoaderStrategy: Int {
    // 正常加载：一般指冷启动
    case normal
    // 异步更新：冷启动从本地加载成功后，进行预加载
    case update
    // 预加载：收到meta更新push后按需进行预加载
    case preload
}

public extension OPAppLoaderStrategy {
    var packageDownloadPriority: Float {
        switch self {
        case .normal:
            return URLSessionTask.highPriority
        default:
            return URLSessionTask.lowPriority
        }
    }
}

/// meta & package 加载流程事件监听协议
public protocol OPAppLoaderMetaAndPackageEvent: AnyObject {

    /// meta开始加载回调
    /// - Parameter strategy: 加载策略
    func onMetaLoadStarted(strategy: OPAppLoaderStrategy)

    /// meta加载进度回调：目前meta请求没有真正的进度，直接从0-1
    /// - Parameters:
    ///   - strategy: 加载策略
    ///   - current: 当前进度
    ///   - total: 总进度
     func onMetaLoadProgress(strategy: OPAppLoaderStrategy, current: Float, total: Float)

    /// meta加载完成回调
    /// - Parameters:
    ///   - strategy: 加载策略
    ///   - success: 是否加载成功
    ///   - meta: 加载成功时的meta数据
    ///   - error: 加载失败时的错误信息
    ///   - fromCache: 是否从本地缓存加载
    func onMetaLoadComplete(strategy: OPAppLoaderStrategy, success: Bool, meta: OPBizMetaProtocol?, error: OPError?, fromCache: Bool)

    /// package开始加载回调
    /// - Parameter strategy: 加载策略
    func onPackageLoadStart(strategy: OPAppLoaderStrategy)

    /// package加载进度回调
    /// - Parameters:
    ///   - strategy: 加载策略
    ///   - current: 当前进度
    ///   - total: 总进度
    func onPackageLoadProgress(strategy: OPAppLoaderStrategy, current: Float, total: Float)

    /// package加载时，reader可用回调，zip包下载完成后发出，pkg包当header解析完成后发出
    /// - Parameters:
    ///   - strategy: 加载策略
    ///   - reader: 包文件读取器
    func onPackageReaderReady(strategy: OPAppLoaderStrategy, reader: OPPackageReaderProtocol)

    /// package加载完成回调
    /// - Parameters:
    ///   - strategy: 加载策略
    ///   - success: 是否成功加载
    ///   - error: 加载失败时的错误信息
    func onPackageLoadComplete(strategy: OPAppLoaderStrategy, success: Bool, error: OPError?)

}

public extension OPAppLoaderMetaAndPackageEvent {
    func onMetaLoadStarted(strategy: OPAppLoaderStrategy) {}
    func onMetaLoadProgress(strategy: OPAppLoaderStrategy, current: Float, total: Float) {}
    func onMetaLoadComplete(strategy: OPAppLoaderStrategy, success: Bool, meta: OPBizMetaProtocol?, error: OPError?, fromCache: Bool) {}
    func onPackageLoadStart(strategy: OPAppLoaderStrategy) {}
    func onPackageLoadProgress(strategy: OPAppLoaderStrategy, current: Float, total: Float) {}
    func onPackageReaderReady(strategy: OPAppLoaderStrategy, reader: OPPackageReaderProtocol) {}
    func onPackageLoadComplete(strategy: OPAppLoaderStrategy, success: Bool, error: OPError?) {}
}
