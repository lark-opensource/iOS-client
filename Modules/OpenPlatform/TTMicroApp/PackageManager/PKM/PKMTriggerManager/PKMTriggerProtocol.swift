//
//  PKMTriggerProtocol.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/12/8.
//

import Foundation
import ECOInfra

/// 包管理当前阶段枚举
public enum PKMPrepareProcessStep: Int {
    case loadMetaStart = 0
    case loadMetaProcess
    case loadMetaComplete
    case loadPkgStart
    // 包为可用状态(流式包主要内容下载完成)
    case loadPkgReady
    case loadPkgProgress
    case loadPkgComplete
}

/// 触发来源
public enum PKMLoadType: Int {
    // 应用启动
    case normal = 0
    // 更新
    case update
    // 预安装
    case prehandle

    func toString() -> String {
        switch self {
        case .normal:
            return "normal"
        case .update:
            // 字符串用来埋点上报
            return "async"
        case .prehandle:
            return "preload"
        }
    }
}

/// meta更新策略
public enum PKMMetaUpdateStrategy: String {
    /// 强制使用远端数据
    case forceRemote
    /// 尝试使用远端数据, 没有则使用本地数据
    case tryRemote
    /// 先试用本地数据然后再异步请求远端数据
    case useLocal
}

/// 包管理功能核心协议
public protocol PKMTriggerProtocol {
    /// 触发应用包更新
    /// - Parameters:
    ///   - triggerParam: 入参
    ///   - processCallback: 阶段回调(多次回调)
    ///   - completionCallback: 更新完毕回调(可能会触发多次)
    func triggerOpenAppUpdate(with triggerParam: PKMAppTriggerParams,
                              processCallback: PKMProcessCallback?,
                              completionCallback: PKMCompletionCallback?)
}

/// 包资源封装类
public struct PKMPackageResource {
    // meta信息
    public let meta: PKMBaseMetaProtocol?
    // meta是否来自缓存
    public let metaFromCache: Bool
    // 包句柄
    public let pkgReader: PKMPackageReaderProtocol?

    init(meta: PKMBaseMetaProtocol? = nil,
         pkgReader: PKMPackageReaderProtocol? = nil,
         metaFromCache: Bool = false) {
        self.meta = meta
        self.metaFromCache = metaFromCache
        self.pkgReader = pkgReader
    }
}

/// 包数据读取句柄
public protocol PKMPackageReaderProtocol {
    // 原来包文件读取句柄
    var originReader: BDPPkgFileManagerHandleProtocol? { get }
}

/// 应用触发请求包管理入参
public struct PKMAppTriggerParams {
    /// 应用ID
    public let uniqueID: PKMUniqueID
    /// 应用版本
    public let appVersion: String?
    /// 预览token
    public let previewToken: String?
    /// 业务类型(e.g.小程序/block/JSSDK)
    public let bizType: PKMType
    /// 触发的更新策略
    public let strategy: PKMTriggerStrategyProtocol
    /// meta对象构造器
    public let metaBuilder: PKMMetaBuilderProtocol?

    public init(uniqueID: PKMUniqueID,
                bizeType: PKMType,
                appVersion: String?,
                previewToken: String?,
                strategy: PKMTriggerStrategyProtocol,
                metaBuilder: PKMMetaBuilderProtocol?) {
        self.uniqueID = uniqueID
        self.appVersion = appVersion
        self.bizType = bizeType
        self.previewToken = previewToken
        self.strategy = strategy
        self.metaBuilder = metaBuilder
    }

    /// 是否为预览模式
    public func isPreview() -> Bool {
        !BDPIsEmptyString(previewToken)
    }

    public func description() -> String {
        "appID: \(uniqueID), isPreview: \(isPreview()), bizType: \(bizType.toString()), strategy: \(String(describing: strategy)), metaBuilder: \(String(describing: metaBuilder))"
    }
}

/// 当前包管理进度
public struct PKMPrepareProgress {
    public let process: PKMPrepareProcessStep
    public let pkgReceiveSize: Int
    public let pkgExpectedSize: Int
    public let url: URL?

    init(process: PKMPrepareProcessStep,
         pkgReceiveSize: Int = 0,
         pkgExpectedSize: Int = 0,
         url: URL? = nil) {
        self.process = process
        self.pkgReceiveSize = pkgReceiveSize
        self.pkgExpectedSize = pkgExpectedSize
        self.url = url
    }
}

/// 当前包管理加载结果
public struct PKMPrepareResult {
    public let success: Bool
    public let error: PKMError?
}

/// 包管理更新策略上下文信息
public struct PKMTriggerStrategyContext {
    /// 本地已有meta信息
    public let localMeta: PKMBaseMetaProtocol?
    /// localMeta本地化的时间戳; 如果没有localMeta,则为nil
    public let timestamp: NSNumber?
}

/// 包管理更新触发策略
public protocol PKMTriggerStrategyProtocol {
    /// 触发加载类型
    var loadType: PKMLoadType { get set }
    /// pkg下载优先级
    var pkgDownloadPriority: Float { get }
    /// 自定信息
    var extra: [String : Any]? { get }

    /// 业务方使用和更新meta的策略
    /// 业务方可以根据需要决定此次包管理的是否强制从远端更新或者是使用本地数据然后再异步更新
    /// - Parameter context: 当前上下文信息
    /// - Returns: 此次使用和更新meta的策略
    func updateStrategy(_ context: PKMTriggerStrategyContext, beforeInvoke:(() ->())?) -> PKMMetaUpdateStrategy

    func copy() -> PKMTriggerStrategyProtocol
}

/// Meta模型对象构造器
public protocol PKMMetaBuilderProtocol {
    func buildMeta(with json: String?) -> PKMBaseMetaProtocol?
}

public struct PKMError: Error {
    public enum PKMErrorDomain: String {
        case MetaError
        case PkgError
    }

    public init(domain: PKMErrorDomain, msg: String?, originError: Error? = nil) {
        self.domain = domain
        self.msg = msg
        self.originError = originError
    }

    public let domain: PKMErrorDomain

    public let msg: String?

    // 原始的错误信息
    public let originError: Error?
}

public typealias PKMProcessCallback = (_ prepareProgress: PKMPrepareProgress,
                                       _ pkgResource: PKMPackageResource?,
                                       _ triggerParams: PKMAppTriggerParams) -> Void

public typealias PKMCompletionCallback = (_ result: PKMPrepareResult,
                                          _ pkgResouce: PKMPackageResource?,
                                          _ triggerParams: PKMAppTriggerParams) -> Void
