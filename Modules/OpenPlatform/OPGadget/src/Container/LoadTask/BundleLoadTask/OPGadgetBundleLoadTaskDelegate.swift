//
//  OPGadgetBundleLoadTaskDelegate.swift
//  OPGadget
//
//  Created by yinyuan on 2020/12/9.
//

import Foundation
import OPSDK
import TTMicroApp

class OPGadgetBundleLoadTaskInput: OPTaskInput {
    
    let containerContext: OPContainerContext
    weak var router: OPGadgetContainerRouterProtocol?
    
    required init(
        containerContext: OPContainerContext,
        router: OPGadgetContainerRouterProtocol) {
        self.containerContext = containerContext
        self.router = router
        super.init()
    }
}

class OPGadgetBundleLoadTaskOutput: OPTaskOutput {
    
    var packageReader: BDPPkgFileReadHandleProtocol?
    
    var meta: OPBizMetaProtocol?
    
    var shouldRemovePkg: Bool = false
    
    /// 当前加载的 Model
    var model: BDPModel?
    
    /// 更新的 Model
    var updateModel: BDPModel?
}

protocol OPGadgetBundleLoadTaskDelegate: AnyObject {
    
    // meta 开始加载
    func onMetaLoadStart()
    
    // meta 加载进度
    func onMetaLoadProgress(current: Float, total: Float)
    
    // meta 加载失败
    func onMetaLoadFailed(error: OPError)
    
    // meta 加载成功
    func onMetaLoadSuccess(model: BDPModel)
    
    // package 开始加载
    func onPackageLoadStart()
    
    // app-config 加载完成
    func onAppConfigLoaded(model: BDPModel,
                           appFileReader: BDPPkgFileReadHandleProtocol,
                           uniqueID: BDPUniqueID,
                           pkgName: String,
                           appConfigData: Data)
    
    // package 开始进度
    func onPackageLoadProgress(current: Float, total: Float)
    
    // package 开始失败
    func onPackageLoadFailed(error: OPError)
    
    // package 开始成功
    func onPackageLoadSuccess()
    
    // Meta 异步更新完成
    func onUpdateMetaInfoModelCompleted(error: OPError?, model: BDPModel?)
    
    // 包异步更新完成
    func onUpdatePkgCompleted(error: OPError?, model: BDPModel?)

}

extension OPGadgetBundleLoadTaskDelegate {
    
    func onMetaLoadStart() {}
    
    func onMetaLoadProgress(current: Float, total: Float) {}
    
    func onMetaLoadFailed(error: OPError) {}
    
    func onMetaLoadSuccess(model: BDPModel) {}
    
    func onPackageReaderReady(packageReader: BDPPkgFileReadHandleProtocol) {}
    
    func onPackageLoadStart() {}
    
    func onAppConfigLoaded(model: BDPModel,
                                  appFileReader: BDPPkgFileReadHandleProtocol,
                                  uniqueID: BDPUniqueID,
                                  pkgName: String,
                                  appConfigData: Data) {}
    
    func onPackageLoadProgress(current: Float, total: Float) {}
    
    func onPackageLoadFailed(error: OPError) {}
    
    func onPackageLoadSuccess() {}
    
    func onUpdateMetaInfoModelCompleted(error: OPError?, model: BDPModel?) {}
    
    func onUpdatePkgCompleted(error: OPError?, model: BDPModel?) {}
}

