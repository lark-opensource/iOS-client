//
//  CommonAppLoader.swift
//  Timor
//
//  Created by 新竹路车神 on 2020/7/20.
//

import Foundation
import LKCommonsLogging
import OPSDK
import OPFoundation

private let log = Logger.oplog(CommonAppLoader.self, category: "CommonAppLoader")

/// 加载类型
public enum CommonAppLoadType: String {
    case normal
    case async
    case preload
}

/// 通用meta & pkg下载流程
@objcMembers
public final class CommonAppLoader: NSObject, CommonAppLoadProtocol {
    /// 模块管理对象
    public var moduleManager: BDPModuleManager?
}

// MARK: - 预下载
extension CommonAppLoader {
    public func preloadMetaAndPackage(
        with context: MetaContext,
        packageType: BDPPackageType,
        getMetaSuccess: ((AppMetaProtocol) -> Void)?,
        getMetaFailure: ((Error) -> Void)?,
        downloadPackageBegun: BDPPackageDownloaderBegunBlock?,
        downloadPackageProgress: BDPPackageDownloaderProgressBlock?,
        downloadPackageCompleted: BDPPackageDownloaderCompletedBlock?
    ) {
        updateMetaAndPackage(
            with: context,
            updateType: .preload,
            packageType: packageType,
            getMetaSuccess: getMetaSuccess,
            getMetaFailure: getMetaFailure,
            downloadPackageBegun: downloadPackageBegun,
            downloadPackageProgress: downloadPackageProgress,
            downloadPackageCompleted: downloadPackageCompleted
        )
    }
}

// MARK: - 异步更新
extension CommonAppLoader {
    public func asyncUpdateMetaAndPackage(
        with context: MetaContext,
        packageType: BDPPackageType,
        getMetaSuccess: ((AppMetaProtocol) -> Void)?,
        getMetaFailure: ((Error) -> Void)?,
        downloadPackageBegun: BDPPackageDownloaderBegunBlock?,
        downloadPackageProgress: BDPPackageDownloaderProgressBlock?,
        downloadPackageCompleted: BDPPackageDownloaderCompletedBlock?
    ) {
        updateMetaAndPackage(
            with: context,
            updateType: .async,
            packageType: packageType,
            getMetaSuccess: getMetaSuccess,
            getMetaFailure: getMetaFailure,
            downloadPackageBegun: downloadPackageBegun,
            downloadPackageProgress: downloadPackageProgress,
            downloadPackageCompleted: downloadPackageCompleted
        )
    }
}

// MARK: - 更新Meta和Pkg
extension CommonAppLoader {
    private func updateMetaAndPackage(
        with context: MetaContext,
        updateType: CommonAppLoadType,
        packageType: BDPPackageType,
        getMetaSuccess: ((AppMetaProtocol) -> Void)?,
        getMetaFailure: ((Error) -> Void)?,
        downloadPackageBegun: BDPPackageDownloaderBegunBlock?,
        downloadPackageProgress: BDPPackageDownloaderProgressBlock?,
        downloadPackageCompleted: BDPPackageDownloaderCompletedBlock?
    ) {
        log.info("start update meta and pkg, identifier: \(context.uniqueID.identifier), common load type: \(updateType.rawValue)", tag: BDPTag.appLoad)
        if let opError = context.isVaild() {
            getMetaFailure?(opError)
            assertionFailure("\(opError)")
            return
        }
        //判断是否要切换到 PKM 加载流程
        if OPSDKFeatureGating.pkmLoadAboutPageEnable() {
            let pkmUniqueID = context.uniqueID.toPKMUniqueID()
            let pkmType = context.uniqueID.appType.toPKMType()
            let strategy = PKMCommonStrategy(uniqueID: context.uniqueID,
                                             loadType: .update,
                                             useLocalMeta: false,
                                             expireStrategy: .async,
                                             metaProvider: GadgetMetaProvider(type: .gadget))
            let triggerParams = PKMAppTriggerParams(uniqueID: pkmUniqueID,
                                                    bizeType: pkmType,
                                                    appVersion: nil,
                                                    previewToken: nil,
                                                    strategy: strategy,
                                                    metaBuilder: strategy)
            let gadgetMetaProvider = GadgetMetaProvider(type: .gadget)
            PKMTriggerManager.shared.triggerOpenAppUpdate(with: triggerParams) { prepareProgress, pkgResource, triggerParams in
                //meta加载完成且成功获取数据
                if prepareProgress.process == .loadMetaComplete {
                    if let remoteMeta = pkgResource?.meta {
                        do {
                            let gadgetMeta = try  gadgetMetaProvider.buildMetaModel(with: remoteMeta.originalJSONString)
                            getMetaSuccess?(gadgetMeta)
                        } catch  {
                            getMetaFailure?(error)
                        }
                    }
                }
                if prepareProgress.process == .loadPkgStart {
                    downloadPackageBegun?(pkgResource?.pkgReader?.originReader)
                }
                if prepareProgress.process == .loadPkgProgress {
                    downloadPackageProgress?(prepareProgress.pkgReceiveSize, prepareProgress.pkgExpectedSize,  prepareProgress.url)
                }
            } completionCallback: { result, pkgResource, triggerParams in
                //如果报错了，流程终结
                if let error = result.error as? PKMError {
                    let errorMessage = "triggerOpenAppUpdate with error: \(error.originError)"
                    let opError = error.originError as? OPError ?? error.originError?.newOPError(monitorCode: OPSDKMonitorCode.unknown_error, message: errorMessage)
                    //meta错误
                    if error.domain == .MetaError {
                        getMetaFailure?(error)
                        //包错误
                    } else if error.domain == .PkgError {
                        downloadPackageCompleted?(opError, false, nil)
                    } else {
                        //其他未知错误
                        log.warn("unknow error when triggerOpenAppUpdate:\(error)")
                    }
                } else {
                    downloadPackageCompleted?(nil, false, pkgResource?.pkgReader?.originReader)
                }
            }
            return
        }
        
        //  尝试获取加载器
        let metaAndPkgManager: (MetaInfoModuleProtocol, BDPPackageModuleProtocol)
        do {
            metaAndPkgManager = try tryGetMetaAndPkgManager()
        } catch {
            //  必定不会走到
            let opError = error.newOPError(monitorCode: CommonMonitorCode.fail)
            assertionFailure(opError.description)
            return
        }
        OPMonitor(kEventName_op_common_install_update_start)
            .setAppLoadInfo(context, updateType)
            .tracing(context.trace)
            .flush()
        let installUpdateResult = OPMonitor(kEventName_op_common_install_update_result)
            .setAppLoadInfo(context, updateType)
            .timing()
            .tracing(context.trace)
        //  从网络获取最新Meta
        metaAndPkgManager
            .0
            .requestRemoteMeta(
                with: context,
                shouldSaveMeta: false,
                success: { [weak self] (meta, saveMetaBlock) in
                    guard let `self` = self else {
                        //  必定不会走到
                        let opError = OPError.error(monitorCode: CommonMonitorCode.fail)
                        assertionFailure(opError.description)
                        return
                    }
                    //  回调meta
                    getMetaSuccess?(meta)
                    installUpdateResult.addCategoryValue(kEventKey_app_version, meta.version)
                    let pkgContext = self.buildPackageContext(with: meta, packageType: packageType, trace: context.trace)
                    let pkgCompletedBlock: BDPPackageDownloaderCompletedBlock = { [weak self] (error, cancelled, packageReader) in
                        guard let `self` = self else {
                            //  必定不会走到
                            let opError = OPError.error(monitorCode: CommonMonitorCode.fail)
                            assertionFailure(opError.description)
                            return
                        }
                        installUpdateResult
                            .timing()
                        downloadPackageCompleted?(error, cancelled, packageReader)
                        if let error = error {
                            installUpdateResult
                                .setResultTypeFail()
                                .setError(error)
                                .addCategoryValue(kEventKey_meta, try? meta.toJson())
                                .flush()
                            return
                        }
                        //  packageReader必须不为空才算做成功
                        guard let pt = packageReader else {
                            let msg = "predownload packages error, pkg packageReader is nil"
                            let opError = OPError.error(monitorCode: CommonMonitorCodePackage.pkg_download_failed, message: msg)
                            installUpdateResult
                                .setResultTypeFail()
                                .setError(opError)
                                .addCategoryValue(kEventKey_meta, try? meta.toJson())
                                .flush()
                            return
                        }
                        //  下包成功，存入meta
                        saveMetaBlock?()
                        installUpdateResult
                            .setResultTypeSuccess()
                            .flush()
                    }
                    switch updateType {
                    case .async:
                        metaAndPkgManager
                            .1
                            .asyncDownloadPackage(
                                with: pkgContext,
                                priority: URLSessionTask.lowPriority,
                                begun: downloadPackageBegun,
                                progress: downloadPackageProgress,
                                completed: pkgCompletedBlock
                            )
                    case .preload:
                        metaAndPkgManager
                            .1
                            .predownloadPackage(
                                with: pkgContext,
                                priority: URLSessionTask.lowPriority,
                                begun: downloadPackageBegun,
                                progress: downloadPackageProgress,
                                completed: pkgCompletedBlock
                            )
                    case .normal:
                        let msg = "should not use normal"
                        let opError = OPError.error(monitorCode: CommonMonitorCode.fail, message: msg)
                        assertionFailure(opError.description)
                    }
                }
            ) { (error) in
                //  Meta获取失败
                installUpdateResult
                    .timing()
                    .setResultTypeFail()
                    .setError(error)
                    .flush()
                //  批量请求meta失败
                getMetaFailure?(error)
            }
    }
}

// MARK: - 启动
extension CommonAppLoader {
    public func launchLoadMetaAndPackage(
        with context: MetaContext,
        packageType: BDPPackageType,
        getMetaSuccess: ((AppMetaProtocol, CommonAppLoadReturnType) -> Void)?,
        getMetaFailure: ((Error, CommonAppLoadReturnType) -> Void)?,
        downloadPackageBegun: ((BDPPkgFileManagerHandleProtocol?, CommonAppLoadReturnType) -> Void)?,
        downloadPackageProgress: ((CommonAppLoadPackageReceivedSizeType, CommonAppLoadPackageExpectedSizeType, URL?, CommonAppLoadReturnType) -> Void)?,
        downloadPackageCompleted: @escaping (BDPPkgFileManagerHandleProtocol?, Error?, CommonAppLoadReturnType) -> Void
    ) {
        log.info("start launch load meta and pkg, identifier: \(context.uniqueID.identifier)", tag: BDPTag.appLoad)
        if let opError = context.isVaild() {
            getMetaFailure?(opError, .local)
            assertionFailure("\(opError)")
            return
        }
        //判断是否要切换到 PKM 加载流程
        if OPSDKFeatureGating.pkmLoadAboutPageEnable() {
            let pkmUniqueID = context.uniqueID.toPKMUniqueID()
            let pkmType = context.uniqueID.appType.toPKMType()
            let strategy = PKMCommonStrategy(uniqueID: context.uniqueID,
                                             loadType: .update,
                                             useLocalMeta: false,
                                             expireStrategy: .async,
                                             metaProvider: GadgetMetaProvider(type: .gadget))
            let triggerParams = PKMAppTriggerParams(uniqueID: pkmUniqueID,
                                                    bizeType: pkmType,
                                                    appVersion: nil,
                                                    previewToken: nil,
                                                    strategy: strategy,
                                                    metaBuilder: strategy)
            let gadgetMetaProvider = GadgetMetaProvider(type: .gadget)
            PKMTriggerManager.shared.triggerOpenAppUpdate(with: triggerParams) { prepareProgress, pkgResource, triggerParams in
                //meta加载完成且成功获取数据
                if prepareProgress.process == .loadMetaComplete {
                    if let pkgResource = pkgResource,
                       let remoteMeta = pkgResource.meta {
                        let returnType: CommonAppLoadReturnType = pkgResource.metaFromCache ? .local : .remote
                        do {
                            let gadgetMeta = try gadgetMetaProvider.buildMetaModel(with: remoteMeta.originalJSONString)
                            getMetaSuccess?(gadgetMeta, returnType)
                        } catch  {
                            getMetaFailure?(error, returnType)
                        }
                    }
                }
                let returnType: CommonAppLoadReturnType = (pkgResource?.metaFromCache ?? false) ? .local : .remote
                if prepareProgress.process == .loadPkgStart {
                    downloadPackageBegun?(pkgResource?.pkgReader?.originReader, returnType)
                }
                if prepareProgress.process == .loadPkgProgress {
                    downloadPackageProgress?(prepareProgress.pkgReceiveSize, prepareProgress.pkgExpectedSize,  prepareProgress.url, returnType)
                }
            } completionCallback: { result, pkgResource, triggerParams in
                var returnType: CommonAppLoadReturnType = .remote
                if let createLoadStatus = pkgResource?.pkgReader?.originReader?.createLoadStatus(),
                   createLoadStatus.rawValue >= BDPPkgFileLoadStatus.downloaded.rawValue {
                    returnType = .local
                }
                //如果报错了，流程终结
                if let error = result.error as? PKMError {
                    let errorMessage = "triggerOpenAppUpdate with error: \(error.originError)"
                    let opError = error.originError as? OPError ?? error.originError?.newOPError(monitorCode: OPSDKMonitorCode.unknown_error, message: errorMessage)
                    //meta错误
                    if error.domain == .MetaError {
                        getMetaFailure?(error, returnType)
                        //包错误
                    } else if error.domain == .PkgError {
                        downloadPackageCompleted(nil, opError, returnType)
                    } else {
                        //其他未知错误
                        log.warn("unknow error when triggerOpenAppUpdate:\(error)")
                    }
                } else {
                    downloadPackageCompleted(pkgResource?.pkgReader?.originReader, nil, returnType)
                }
            }
            return
        }
        
        //  尝试获取加载器
        let metaAndPkgManager: (MetaInfoModuleProtocol, BDPPackageModuleProtocol)
        do {
            metaAndPkgManager = try tryGetMetaAndPkgManager()
        } catch {
            //  必定不会走到
            let opError = error.newOPError(monitorCode: CommonMonitorCode.fail)
            assertionFailure(opError.description)
            return
        }

        OPMonitor(kEventName_op_common_load_meta_start)
            .setAppLoadInfo(context, .normal)
            .addCategoryValue(String.kCommonAppLoader, true)
            .tracing(context.trace)
            .flush()
        let loadMetaResult = OPMonitor(kEventName_op_common_load_meta_result)
            .setAppLoadInfo(context, .normal)
            .addCategoryValue(String.kCommonAppLoader, true)
            .timing()
            .tracing(context.trace)
        let loadMetaResultAsync = OPMonitor(kEventName_op_common_load_meta_result)
            .setAppLoadInfo(context, .async)
            .addCategoryValue(String.kCommonAppLoader, true)
            .tracing(context.trace)

        func loadPkg(with metaModel: AppMetaProtocol) {
            ///  加载包
            self.loadPkg(
                with: metaAndPkgManager.1,
                meta: metaModel,
                uniqueID: metaModel.uniqueID,
                context: self.buildPackageContext(
                    with: metaModel,
                    packageType: packageType,
                    trace: context.trace
                ),
                downloadBegun: downloadPackageBegun,
                downloadProgress: downloadPackageProgress,
                downloadCompleted: downloadPackageCompleted
            )
        }

        var localMetaModel: AppMetaProtocol?
        //  获取Meta
        metaAndPkgManager
            .0
            .launchGetMeta(
                with: context,
                local: { [weak self] (metaModel) in
                    guard let `self` = self else {
                        //  必定不会走到
                        let opError = OPError.error(monitorCode: CommonMonitorCode.fail)
                        assertionFailure(opError.description)
                        return
                    }
                    loadMetaResult
                        .timing()
                        .setResultTypeSuccess()
                        .addCategoryValue("meta_cache", 1)
                        .addCategoryValue(kEventKey_app_version, metaModel.version)
                        .flush()
                    loadMetaResultAsync
                        .timing()
                    //  获取到本地Meta
                    getMetaSuccess?(metaModel, .local)
                    localMetaModel = metaModel
                    loadPkg(with: metaModel)
                },
                asyncUpdate: { [weak self] (metaModel, error, saveMetaBlock) in
                    //  异步更新回调
                    guard let `self` = self else {
                        //  必定不会走到
                        let opError = OPError.error(monitorCode: CommonMonitorCode.fail)
                        assertionFailure(opError.description)
                        return
                    }
                    loadMetaResultAsync
                        .addCategoryValue("meta_cache", 0)
                        .timing()
                    if let error = error {
                        getMetaFailure?(error, .asyncUpdate)
                        loadMetaResultAsync
                            .setResultTypeFail()
                            .setError(error)
                            .flush()
                        return
                    }
                    guard let metaModel = metaModel else {
                        let msg = "meta asyncUpdate meta is nil"
                        let opError = OPError.error(monitorCode: CommonMonitorCode.fail, message: msg)
                        getMetaFailure?(opError, .asyncUpdate)
                        loadMetaResultAsync
                            .setResultTypeFail()
                            .setError(opError)
                            .flush()
                        return
                    }
                    loadMetaResultAsync
                        .setResultTypeSuccess()
                        .addCategoryValue(kEventKey_app_version, metaModel.version)
                        .flush()
                    getMetaSuccess?(metaModel, .asyncUpdate)
                    //  版本更新才需要异步更新包
                    guard self.shouldUpdatePackage(localMeta: localMetaModel, netMeta: metaModel) else {
                        //  可能meta更新了但是包没更新，还是需要持久化
                        log.info("version is updated, need not to update pkg, but still save meta to local db", tag: BDPTag.appLoad)
                        saveMetaBlock?()
                        return
                    }
                    //  异步更新
                    self.asyncUpdatePkg(
                        with: metaAndPkgManager.1,
                        packageType: packageType,
                        metaModel: metaModel,
                        saveMetaBlock: saveMetaBlock,
                        downloadBegun: downloadPackageBegun,
                        downloadProgress: downloadPackageProgress,
                        downloadCompleted: downloadPackageCompleted,
                        trace: context.trace
                    )
                }
            ) { [weak self] (metaModel, error) in
                guard let `self` = self else {
                    //  必定不会走到
                    let opError = OPError.error(monitorCode: CommonMonitorCode.fail)
                    assertionFailure(opError.description)
                    return
                }
                loadMetaResult
                    .addCategoryValue("meta_cache", 0)
                    .timing()
                //  无缓存时网络请求meta的回调
                if let error = error {
                    //  纯网络请求meta失败
                    getMetaFailure?(error, .remote)
                    loadMetaResult
                        .setResultTypeFail()
                        .setError(error)
                        .flush()
                    return
                }
                //  远程meta回调
                guard let metaModel = metaModel else {
                    let msg = "build meta model failed"
                    let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_request_error, message: msg)
                    assertionFailure(opError.description)
                    getMetaFailure?(opError, .remote)
                    loadMetaResult
                        .setResultTypeFail()
                        .setError(opError)
                        .flush()
                    return
                }
                getMetaSuccess?(metaModel, .remote)
                loadMetaResult
                    .setResultTypeSuccess()
                    .addCategoryValue(kEventKey_app_version, metaModel.version)
                    .flush()

                loadPkg(with: metaModel)
            }
    }

    /// 使用meta加载包
    /// - Parameters:
    ///   - pkgManager: 包管理器
    ///   - identifier: 应用唯一id
    ///   - context: 包请求上下文
    ///   - downloadCompleted: 包任务完成回调
    private func loadPkg(
        with pkgManager: BDPPackageModuleProtocol,
        meta: AppMetaProtocol,
        uniqueID: BDPUniqueID,
        context: BDPPackageContext,
        downloadBegun: ((BDPPkgFileManagerHandleProtocol?, CommonAppLoadReturnType) -> Void)?,
        downloadProgress: ((CommonAppLoadPackageReceivedSizeType, CommonAppLoadPackageExpectedSizeType, URL?, CommonAppLoadReturnType) -> Void)?,
        downloadCompleted: @escaping (BDPPkgFileManagerHandleProtocol?, Error?, CommonAppLoadReturnType) -> Void
    ) {
        OPMonitor(kEventName_op_common_load_package_start)
            .addTag(.appLoad)
            .setUniqueID(context.uniqueID)
            .addCategoryValue(kEventKey_app_version, meta.version)
            .addCategoryValue(String.kCommonAppLoader, true)
            .setLoadType(.normal)
            .tracing(context.trace)
            .flush()
        let loadPkgResult = OPMonitor(kEventName_op_common_load_package_result)
            .addTag(.appLoad)
            .setUniqueID(context.uniqueID)
            .addCategoryValue(kEventKey_app_version, meta.version)
            .addCategoryValue(String.kCommonAppLoader, true)
            .setLoadType(.normal)
            .tracing(context.trace)
            .timing()
        //  启动时加载本地包或无本地包时下载
        pkgManager
            .checkLocalOrDownloadPackage(
                with: context,
                localCompleted: { (packageReader) in
                    //  获取到本地包
                    downloadCompleted(packageReader, nil, .local)
                    loadPkgResult
                        .setResultTypeSuccess()
                        .addCategoryValue("package_cache", true)
                        .timing()
                        .flush()
                },
                downloadPriority: URLSessionTask.highPriority,
                downloadBegun: { (packageReader) in
                    downloadBegun?(packageReader, .remote)
                },
                downloadProgress: { (receivedSize, expectedSize, url) in
                    downloadProgress?(receivedSize, expectedSize, url, .remote)
                }
            ) { (error, _, packageReader) in
                if context.isSubpackageEnable() {
                    loadPkgResult.addCategoryValue("is_subpackage_mode", "true")
                }
                //  网络包回调 上下两个block只会调用一个
                loadPkgResult
                    .timing()
                    .addCategoryValue("package_cache", false)
                if let error = error {
                    downloadCompleted(nil, error, .remote)
                    loadPkgResult
                        .setResultTypeFail()
                        .setError(error)
                        .addCategoryValue(kEventKey_meta, try? meta.toJson())
                        .flush()
                    return
                }
                //  packageReader必须不为空才算做成功
                guard let packageReader = packageReader else {
                    let msg = "has no package reader form pkg manager"
                    let opError = OPError.error(monitorCode: CommonMonitorCodePackage.pkg_download_failed, message: msg)
                    downloadCompleted(nil, opError, .remote)
                    loadPkgResult
                        .setError(opError)
                        .setResultTypeFail()
                        .addCategoryValue(kEventKey_meta, try? meta.toJson())
                        .flush()
                    return
                }
                downloadCompleted(packageReader, nil, .remote)
                loadPkgResult
                    .setResultTypeSuccess()
                    .flush()
            }
    }

    /// 异步更新包
    /// - Parameters:
    ///   - pkgManager: 包管理器
    ///   - packageType: 包类型
    ///   - metaModel: meta对象
    ///   - saveMetaBlock: 持久化meta的block
    private func asyncUpdatePkg(
        with pkgManager: BDPPackageModuleProtocol,
        packageType: BDPPackageType,
        metaModel: AppMetaProtocol,
        saveMetaBlock: (() -> Void)?,
        downloadBegun: ((BDPPkgFileManagerHandleProtocol?, CommonAppLoadReturnType) -> Void)?,
        downloadProgress: ((CommonAppLoadPackageReceivedSizeType, CommonAppLoadPackageExpectedSizeType, URL?, CommonAppLoadReturnType) -> Void)?,
        downloadCompleted: @escaping (BDPPkgFileManagerHandleProtocol?, Error?, CommonAppLoadReturnType) -> Void,
        trace: BDPTracing
    ) {
        OPMonitor(kEventName_op_common_load_package_start)
            .addTag(.appLoad)
            .setUniqueID(metaModel.uniqueID)
            .addCategoryValue(kEventKey_app_version, metaModel.version)
            .setLoadType(.async)
            .addCategoryValue(String.kCommonAppLoader, true)
            .tracing(trace)
            .flush()
        let loadPkgResult = OPMonitor(kEventName_op_common_load_package_result)
            .addTag(.appLoad)
            .setUniqueID(metaModel.uniqueID)
            .addCategoryValue(kEventKey_app_version, metaModel.version)
            .addCategoryValue(String.kCommonAppLoader, true)
            .setLoadType(.async)
            .tracing(trace)
            .timing()
        pkgManager
            .asyncDownloadPackage(
                with: buildPackageContext(
                    with: metaModel,
                    packageType: packageType,
                    trace: trace
                ),
                priority: URLSessionTask.lowPriority,
                begun: { (packageReader) in
                    downloadBegun?(packageReader, .asyncUpdate)
                },
                progress: { (receivedSize, expectedSize, url) in
                    downloadProgress?(receivedSize, expectedSize, url, .asyncUpdate)
                }
            ) { (error, _, packageReader) in
                downloadCompleted(packageReader, error, .asyncUpdate)
                loadPkgResult
                    .timing()
                    .addCategoryValue("package_cache", false)
                if let error = error {
                    loadPkgResult
                        .setResultTypeFail()
                        .setError(error)
                        .flush()
                    return
                }
                //  packageReader必须不为空才算做成功
                guard let packageReader = packageReader else {
                    let msg = "has no package reader form pkg manager"
                    let opError = OPError.error(monitorCode: CommonMonitorCodePackage.pkg_download_failed, message: msg)
                    downloadCompleted(nil, opError, .remote)
                    loadPkgResult
                        .setError(opError)
                        .setResultTypeFail()
                        .flush()
                    return
                }
                //  启动时异步更新的meta需要等异步更新的包下载完毕才可以持久化
                saveMetaBlock?()
                loadPkgResult
                    .setResultTypeSuccess()
                    .flush()
            }
    }
}

// MARK: - 工具方法
extension CommonAppLoader {
    /// 尝试获取Meta和包管理器
    /// - Returns: 管理器元组
    private func tryGetMetaAndPkgManager() throws -> (MetaInfoModuleProtocol, BDPPackageModuleProtocol) {
        guard let metaManager = BDPModuleManager(of: moduleManager?.type ?? .unknown)
                .resolveModule(with: MetaInfoModuleProtocol.self) as? MetaInfoModuleProtocol else {
            let msg = "has no meta module manager"
            let opError = OPError.error(monitorCode: CommonMonitorCode.fail, message: msg)
            assertionFailure(opError.description)
            throw opError
        }
        guard let packageManager = BDPModuleManager(of: moduleManager?.type ?? .unknown)
                .resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol else {
            let msg = "has no pkg module manager"
            let opError = OPError.error(monitorCode: CommonMonitorCode.fail, message: msg)
            assertionFailure(opError.description)
            throw opError
        }
        return (metaManager, packageManager)
    }

    private func buildPackageContext(with meta: AppMetaProtocol, packageType: BDPPackageType, trace: BDPTracing) -> BDPPackageContext {
        //  组装包相关请求上下文
        BDPPackageContext(
            appMeta: meta,
            packageType: packageType,
            packageName: nil,
            trace: trace
        )
    }

    /// 判断是否需要升级包
    /// - Parameters:
    ///   - localMeta: 本地的Meta
    ///   - netMeta: 网络来的Meta
    /// - Returns: 结果
    private func shouldUpdatePackage(localMeta: AppMetaProtocol?, netMeta: AppMetaProtocol) -> Bool {
        guard let lm = localMeta else {
            //  拿不到localMeta肯定要升级了
            return true
        }
        return lm.version != netMeta.version
    }

    /// 获取H5App的版本，临时逻辑，等待H5小程序删除
    /// - Parameter meta: H5小程序的Meta
    /// - Returns: H5小程序版本
    private func getH5AppVersionCode(with meta: GadgetMeta) -> String {
        ((meta.businessData as! GadgetBusinessData).extraDict["web_app"] as? [String: Any])?["version_code"] as? String ?? ""
    }
}

fileprivate extension String {
    static let kCommonAppLoader = "commonAppLoader"
}
