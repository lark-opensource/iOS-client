//
//  CommonAppLoadProtocol.swift
//  Timor
//
//  Created by 新竹路车神 on 2020/7/20.
//

import Foundation

/// meta或者包的返回类型
@objc public enum CommonAppLoadReturnType: UInt {
    /// 本地回调
    case local
    /// 纯网络回调
    case remote
    /// 异步回调
    case asyncUpdate
}
public typealias CommonAppLoadPackageReceivedSizeType = Int
public typealias CommonAppLoadPackageExpectedSizeType = Int

/// 应用加载协议
@objc public protocol CommonAppLoadProtocol: BDPModuleProtocol {

    /// 预下载Meta和包
    /// - Parameters:
    ///   - context: Meta加载上下文
    ///   - packageType: 包类型
    ///   - getMetaSuccess: 获取到meta成功的回调
    ///   - getMetaFailure: 获取到meta失败的回调
    ///   - downloadPackageBegun: 开始下载代码包的回调
    ///   - downloadPackageProgress: 下载代码包的进度回调
    ///   - downloadPackageCompleted: 下载代码包的结果（成功/失败）回调
    func preloadMetaAndPackage(
        with context: MetaContext,
        packageType: BDPPackageType,
        getMetaSuccess: ((AppMetaProtocol) -> Void)?,
        getMetaFailure: ((Error) -> Void)?,
        downloadPackageBegun: BDPPackageDownloaderBegunBlock?,
        downloadPackageProgress: BDPPackageDownloaderProgressBlock?,
        downloadPackageCompleted: BDPPackageDownloaderCompletedBlock?
    )

    /// 异步更新Meta和包
    /// - Parameters:
    ///   - context: Meta加载上下文
    ///   - packageType: 包类型
    ///   - getMetaSuccess: 获取到meta成功的回调
    ///   - getMetaFailure: 获取到meta失败的回调
    ///   - downloadPackageBegun: 开始下载代码包的回调
    ///   - downloadPackageProgress: 下载代码包的进度回调
    ///   - downloadPackageCompleted: 下载代码包的结果（成功/失败）回调
    func asyncUpdateMetaAndPackage(
        with context: MetaContext,
        packageType: BDPPackageType,
        getMetaSuccess: ((AppMetaProtocol) -> Void)?,
        getMetaFailure: ((Error) -> Void)?,
        downloadPackageBegun: BDPPackageDownloaderBegunBlock?,
        downloadPackageProgress: BDPPackageDownloaderProgressBlock?,
        downloadPackageCompleted: BDPPackageDownloaderCompletedBlock?
    )

    /// 启动时加载meta和包
    /// - Parameters:
    ///   - context: Meta加载上下文
    ///   - packageType: 包类型
    ///   - getMetaSuccess: 获取到meta的回调
    ///   - getMetaFailure: 获取meta失败的回调
    ///   - downloadPackageBegun: 开始下载代码包的回调
    ///   - downloadPackageProgress: 下载代码包的进度回调 可以知道类型
    ///   - downloadPackageCompleted: 获取本地/远端/异步更新的代码包结果（成功/失败）回调，返回包的packageReader
    func launchLoadMetaAndPackage(
        with context: MetaContext,
        packageType: BDPPackageType,
        getMetaSuccess: ((AppMetaProtocol, CommonAppLoadReturnType) -> Void)?,
        getMetaFailure: ((Error, CommonAppLoadReturnType) -> Void)?,
        downloadPackageBegun: ((BDPPkgFileManagerHandleProtocol?, CommonAppLoadReturnType) -> Void)?,
        downloadPackageProgress: ((CommonAppLoadPackageReceivedSizeType, CommonAppLoadPackageExpectedSizeType, URL?, CommonAppLoadReturnType) -> Void)?,
        downloadPackageCompleted: @escaping (BDPPkgFileManagerHandleProtocol?, Error?, CommonAppLoadReturnType) -> Void
    )
}
