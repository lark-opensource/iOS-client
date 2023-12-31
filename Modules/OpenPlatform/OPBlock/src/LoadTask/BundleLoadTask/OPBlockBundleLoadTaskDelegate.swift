//
//  OPBlockBundleLoadTaskDelegate.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/4.
//

import Foundation
import OPSDK
import LarkOPInterface
import OPBlockInterface

public final class OPBlockBundleLoadTaskInput: OPTaskInput {
    
    public let containerContext: OPContainerContext
    
    required public init(containerContext: OPContainerContext) {
        self.containerContext = containerContext
        super.init()
    }
}

public final class OPBlockBundleLoadTaskOutput: OPTaskOutput {
    
    public var packageReader: OPPackageReaderProtocol?
    public var meta: OPBizMetaProtocol?
}

public protocol OPBlockBundleLoadTaskDelegate: AnyObject {
    
    // meta 开始加载
    func onMetaLoadStart()
    
    // meta 加载进度
    func onMetaLoadProgress(current: Float, total: Float)
    
    // meta 加载失败
    func onMetaLoadFailed(error: OPError)
    
    // meta 加载成功
    func onMetaLoadSuccess(meta: OPBizMetaProtocol)
    
    // package 开始加载
    func onPackageLoadStart()
    
    // package 开始进度
    func onPackageLoadProgress(current: Float, total: Float)
    
    // package 开始失败
    func onPackageLoadFailed(error: OPError)
    
    // package 开始成功
    func onPackageLoadSuccess()

    // meta 及 pkg 更新成功
    func onBundleUpdateSuccess(info: OPBlockUpdateInfo)

}

extension OPBlockBundleLoadTaskDelegate {
    
    public func onMetaLoadStart() {}
    
    public func onMetaLoadProgress(current: Float, total: Float) {}
    
    public func onMetaLoadFailed(error: OPError) {}
    
    public func onMetaLoadSuccess(meta: OPBizMetaProtocol) {}
    
    public func onPackageReaderReady(packageReader: OPPackageReaderProtocol) {}
    
    public func onPackageLoadStart() {}
    
    public func onPackageLoadProgress(current: Float, total: Float) {}
    
    public func onPackageLoadFailed(error: OPError) {}
    
    public func onPackageLoadSuccess() {}

    public func onBundleUpdateSuccess(info: OPBlockUpdateInfo) {}
}
