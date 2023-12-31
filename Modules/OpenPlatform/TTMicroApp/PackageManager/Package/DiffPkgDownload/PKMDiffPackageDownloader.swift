//
//  BDPPackageModuleExtension.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/12/29.
//  包增量更新工具类(目前仅支持小程序)

import Foundation
import LKCommonsLogging
import OPSDK

fileprivate let logger = Logger.log(PKMDiffPackageDownloader.self, category: "BDPDiffPackageDownloader")

public typealias PKMDiffPkgDownloadCompletion = (_ success: Bool, _ reader: BDPPkgFileReadHandleProtocol?) -> Void

enum PKMDiffPkgDownloadStatus: String {
    case notStart
    case downloading
    case completed
}

final class PKMDiffPackageDownloadTask: Hashable {
    public let uniqueID: PKMUniqueID
    public let appType: PKMType
    public let packageContext: BDPPackageContext
    public private(set) var status: PKMDiffPkgDownloadStatus = .notStart
    public let downloadPriority: Float

    public private(set) var needCallbacks: [PKMDiffPkgDownloadCompletion]

    init(packageContext: BDPPackageContext,
         downloadPriority: Float,
         callbacks: [PKMDiffPkgDownloadCompletion]? = nil) {
        self.packageContext = packageContext
        self.uniqueID = PKMUtil.configPKMUniqueID(with: packageContext.uniqueID)
        self.appType = packageContext.uniqueID.appType.toPKMType()
        self.downloadPriority = downloadPriority
        if let callbacks = callbacks {
            self.needCallbacks = callbacks
        } else {
            self.needCallbacks = []
        }
    }

    @discardableResult
    func appendNeedCallbacks(from anotherTask: PKMDiffPackageDownloadTask) -> Bool {
        guard self !== anotherTask else {
            logger.warn("\(String.DiffPkgPrefix) same task: \(uniqueID.appID)")
            return false
        }

        let anotherCallbacks = anotherTask.needCallbacks
        needCallbacks += anotherCallbacks
        return true
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appType.rawValue)
        hasher.combine(uniqueID.appID)
        hasher.combine(uniqueID.identifier ?? "")
        hasher.combine(packageContext.packageName)
    }

    func updateDownloadStatus(_ status: PKMDiffPkgDownloadStatus) {
        self.status = status
    }

    static func == (lhs: PKMDiffPackageDownloadTask, rhs: PKMDiffPackageDownloadTask) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: 增量包下载器
public final class PKMDiffPackageDownloader: NSObject {
    // 当前队列中的下载任务
    var downloadingTaskSets = Set<PKMDiffPackageDownloadTask>()
    // 包下载工具类
    let packageDownloadDispatcher = BDPPackageDownloadDispatcher()
    // 串行队列(所有的操作都在该队列中执行)
    let workQueue = DispatchQueue(label: "com.bytedance.diffPackageWorkQueue",
                                  qos: .utility ,attributes: .init(rawValue: 0))

    /// 增量包下载(线程安全, 通过串行队列保证)
    /// - Parameters:
    ///   - packageContext: 包信息上下文
    ///   - priority: 下载优先级
    ///   - completion: 任务结果回调
    @objc public func diffPkgDownload(packageContext: BDPPackageContext,
                                      priority: Float,
                                      completion: PKMDiffPkgDownloadCompletion?) {
        self.workQueue.async {
            logger.info("\(String.DiffPkgPrefix) start download diff pkg for: \(packageContext.uniqueID.appID) pkgName: \(packageContext.packageName), loadType: \(packageContext.readType.rawValue)")

            // 这边如果添加失败则表示已经有相同的任务, 这边会保存completion, 等待任务完成后统一回调
            let downloadTask = self.downloadTask(with: packageContext, priority: priority, callback: completion)

            guard downloadTask.status == .notStart else {
                logger.info("\(String.DiffPkgPrefix) same task downloading")
                return
            }

            downloadTask.updateDownloadStatus(.downloading)

            self.startDiffPkgDownload(with: downloadTask)
        }
    }

    func startDiffPkgDownload(with downloadTask: PKMDiffPackageDownloadTask) {
        let packageContext = downloadTask.packageContext
        let priority = downloadTask.downloadPriority

        let increaseMonitor = OPMonitor(String.monitorEventName).setUniqueID(downloadTask.packageContext.uniqueID).timing()
        // 目前只有小程序支持该能力
        guard downloadTask.appType == .gadget else {
            logger.info("\(String.DiffPkgPrefix) current appType \(OPAppTypeToString(packageContext.uniqueID.appType)) not support")
            increaseMonitor.reportFailed(with: .appTypeNotSupport)
            callbackResult(with: downloadTask, success: false, reader: nil)
            return
        }

        //本地已经有新版本包这个文件夹了,则不要进行增量更新操作
        guard !BDPPackageLocalManager.isPackageDirectoryExist(for: packageContext.uniqueID, packageName: packageContext.packageName) else {
            logger.info("\(String.DiffPkgPrefix) target package already exist")
            increaseMonitor.reportFailed(with: .targetPkgAlreadyExist)
            callbackResult(with: downloadTask, success: false, reader: nil)
            return
        }

        // 获取本地有包且版本最高的meta信息, 作为基准包准备打patch
        guard let installedMeta = self.installedAppMeta(with: packageContext.uniqueID, appType: downloadTask.appType) else {
            logger.info("\(String.DiffPkgPrefix) installed meta not exist")
            increaseMonitor.reportFailed(with: .installedMetaNotExist)
            callbackResult(with: downloadTask, success: false, reader: nil)
            return
        }

        let oldPkgVersion = installedMeta.version
        let newPkgVersion = packageContext.version

        guard !BDPIsEmptyString(oldPkgVersion), !BDPIsEmptyString(newPkgVersion) else {
            logger.info("\(String.DiffPkgPrefix) old pkg version: \(oldPkgVersion) or new pkg version: \(newPkgVersion) invalid")
            increaseMonitor.reportFailed(with: .pkgVersionInvalid)
            callbackResult(with: downloadTask, success: false, reader: nil)
            return
        }

        // 从最新的meta中获取diff包路径
        guard let diffPathDic = packageContext.diffPkgInfos?[BDPSafeString(oldPkgVersion)] as? [String : Any],
                let urlStr = diffPathDic["path"] as? String,
                let diffPkgMD5 = diffPathDic["path_md5"] as? String else {
            logger.info("\(String.DiffPkgPrefix) diffPath info invalid for pkg version: \(oldPkgVersion), diffVersions: \(String(describing: packageContext.diffPkgInfos?.keys))")
            increaseMonitor.reportFailed(with: .metaIncreaseInfoInvalid)
            callbackResult(with: downloadTask, success: false, reader: nil)
            return
        }

        guard let url = URL(string: urlStr) else {
            logger.info("\(String.DiffPkgPrefix) config diff pkg URL failed")
            increaseMonitor.reportFailed(with: .configIncreaseURLFailed)
            callbackResult(with: downloadTask, success: false, reader: nil)
            return
        }

        let urls = [url]
        // diff包文件夹名:"老包的包版本_新包的包版本_diffPkg"
        let diffPkgName = oldPkgVersion + "_" + newPkgVersion + "_" + "diffPkg"

        // 构建diff包的PkgCtx
        let diffPkgCtx = BDPPackageContext(uniqueID: packageContext.uniqueID,
                                           version: installedMeta.version,
                                           urls: urls,
                                           packageName: diffPkgName,
                                           packageType: .raw,
                                           md5: diffPkgMD5,
                                           trace: packageContext.trace)

        packageDownloadDispatcher.downloadPackage(with: diffPkgCtx, priority: priority, begun: nil, progress: nil) {[weak self] error, isCancelled, handler in
            guard let `self` = self else {
                logger.warn("\(String.DiffPkgPrefix) self is nil")
                return
            }

            self.workQueue.async {
                logger.info("\(String.DiffPkgPrefix) download diff pkg finish. appID: \(packageContext.uniqueID.appID) pkgName: \(packageContext.packageName)")

                guard error == nil, !isCancelled else {
                    logger.info("\(String.DiffPkgPrefix) download diffPkg failed: \(String(describing: error)), isCancelled: \(isCancelled) handler is nil: \(handler == nil)")
                    increaseMonitor.reportFailed(with: .downloadIncreasePkgFailed)
                    self.downloadFailedCallback(with: downloadTask, deletePackages: [diffPkgCtx])
                    return
                }

                guard let diffPkgPath = BDPPackageLocalManager.localPackagePath(for: diffPkgCtx) else {
                    logger.info("\(String.DiffPkgPrefix) diffPkg not exist. diff pkgName: \(diffPkgCtx.packageName)")
                    increaseMonitor.reportFailed(with: .increasePkgNotExist)
                    self.downloadFailedCallback(with: downloadTask, deletePackages: [diffPkgCtx])
                    return
                }

                // 这边创建一个临时的BDPPackageContext对象用来创建一个临时的目录文件夹
                let tmpPkgName = packageContext.packageName + "_" + "diffPkg"
                let tmpPkgCtx = BDPPackageContext(uniqueID: packageContext.uniqueID, version: packageContext.version, urls: packageContext.urls, packageName: tmpPkgName, packageType: packageContext.packageType, md5: packageContext.md5, trace: packageContext.trace)

                //本地已经有新版本包这个文件夹了,则不要进行增量更新操作
                guard !BDPPackageLocalManager.isPackageDirectoryExist(for: tmpPkgCtx.uniqueID, packageName: tmpPkgCtx.packageName) else {
                    logger.info("\(String.DiffPkgPrefix) new package dir already exsit")
                    increaseMonitor.reportFailed(with: .targetPkgAlreadyExist)
                    self.downloadFailedCallback(with: downloadTask, deletePackages: [diffPkgCtx])
                    return
                }

                // 检查本地老包是否存在
                let oldPkgCtx = BDPPackageContext(appMeta: installedMeta, packageType: packageContext.packageType, packageName: nil, trace: packageContext.trace)

                guard let oldPkgPath = BDPPackageLocalManager.localPackagePath(for: oldPkgCtx) else {
                    logger.info("\(String.DiffPkgPrefix) old package \(oldPkgCtx.packageName) not exist")
                    increaseMonitor.reportFailed(with: .basePkgNotExist)
                    self.downloadFailedCallback(with: downloadTask, deletePackages: [diffPkgCtx])
                    return
                }

                // 创建合成包(新包)的文件路径, 没有对应文件后面打patch会失败
                guard self.createPackageFileDir(with: tmpPkgCtx) else {
                    increaseMonitor.reportFailed(with: .createTargetFileDirFailed)
                    self.downloadFailedCallback(with: downloadTask, deletePackages: [diffPkgCtx])
                    return
                }

                // Note: 后面失败了需要删除最新meta中对应的包文件夹,否则可能会影响本地是否有包的判断逻辑
                // 获取合成包目标路径
                guard let newPath = BDPPackageLocalManager.localPackagePath(for: tmpPkgCtx) else {
                    logger.info("\(String.DiffPkgPrefix) new package path not exist")
                    increaseMonitor.reportFailed(with: .targetPkpPathNotExist)
                    self.downloadFailedCallback(with: downloadTask, deletePackages: [tmpPkgCtx, diffPkgCtx])
                    return
                }

                // 开始进行BSPatch操作
                guard BDPBSPatcher.bsPatch(oldPkgPath, patchPath: diffPkgPath, newPath: newPath) else {
                    logger.info("\(String.DiffPkgPrefix) bsPatch failed")
                    increaseMonitor.reportFailed(with: .bsPatchFailed)
                    self.downloadFailedCallback(with: downloadTask, deletePackages: [tmpPkgCtx, diffPkgCtx])
                    return
                }

                // 对合成包进行MD5校验(PS: 增量包的MD5校验在下载过程中已经做了)
                guard self.packageMD5Check(with: tmpPkgCtx.md5, packagePath: newPath) else {
                    logger.info("\(String.DiffPkgPrefix) md5 check failed")
                    increaseMonitor.reportFailed(with: .mergedPkgMD5Invalid)
                    self.downloadFailedCallback(with: downloadTask, deletePackages: [tmpPkgCtx, diffPkgCtx])
                    return
                }

                // 将合成的包文件夹名重命名为正式包名
                guard self.renameFile(from: tmpPkgCtx, to: packageContext) else {
                    logger.info("\(String.DiffPkgPrefix) rename file \(tmpPkgCtx.packageName) to \(packageContext.packageName) failed")
                    increaseMonitor.reportFailed(with: .renameFileFailed)
                    self.downloadFailedCallback(with: downloadTask, deletePackages: [tmpPkgCtx, diffPkgCtx])
                    return
                }

                // 更新BDPPkgInfoTableV3这个数据库(这边要用正式的包名更新数据库)
                guard self.updatePackageDB(with: packageContext) else {
                    logger.info("\(String.DiffPkgPrefix) update db faield)")
                    increaseMonitor.reportFailed(with: .updateDBFailed)
                    // 即使这边更新数据失败了,也不要去删除正式文件夹,因为其他地方可能已经在使用了
                    self.downloadFailedCallback(with: downloadTask, deletePackages: [diffPkgCtx])
                    return
                }

                increaseMonitor.reportSuccess(with: diffPkgCtx, originPkgCtx: packageContext)

                let deleteResult = self.deletePackage(with: diffPkgCtx)
                logger.info("\(String.DiffPkgPrefix) addition pkg update success and delete increase pkg result: \(deleteResult)")

                let reader = self.createFileHandle(with: packageContext)
                self.callbackResult(with: downloadTask, success: true, reader: reader)
            }
        }
    }

    /// 应用的包来源
    /// - Parameter context: 包上下文
    /// - Returns: 包来源类型
    public static func packageSourceType(with context: BDPPackageContext) -> BDPPkgSourceType {
        guard OPSDKFeatureGating.packageIncremetalUpdateEnable() else {
            return .default
        }

        guard let packageManager = BDPModuleManager(of: context.uniqueID.appType).resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol else {
            return .default
        }

        guard let extDic = packageManager.packageInfoManager.extDictionary(context.uniqueID, pkgName: context.packageName), let pkgSource = extDic[kPkgTableExtPkgSource] as? Int else {
            return .default
        }

        return BDPPkgSourceType(rawValue: pkgSource) ?? .default
    }

    /// 获取本地已经有包的PKMApp对象
    func installedAppInfo(with pkmUniqueID: PKMUniqueID, appType: PKMType) -> PKMApp? {
        let appPool = PKMAppPoolManager.sharedInstance.appPoolWith(pkmType: appType)
        let appInfo = appPool.allApps(PKMUniqueID(appID: pkmUniqueID.appID, identifier: nil))

        guard let apps = appInfo[pkmUniqueID.appID], let app = apps.first(where: {
            $0.isInstalled()
        }) else {
            return nil
        }

        return app
    }

    /// 获取本地已经有包的Meta对象
    func installedAppMeta(with oldUniqueID: BDPUniqueID, appType: PKMType) -> AppMetaProtocol? {
        let pkmUniqueID = PKMUtil.configPKMUniqueID(with: oldUniqueID)
        guard let app = installedAppInfo(with: pkmUniqueID, appType: appType) else {
            logger.info("\(String.DiffPkgPrefix) can not get installed app")
            return nil
        }

        // 这边后面可以根据应用形态来构建对应的meta对象
        guard let installedMeta = try? GadgetMetaProvider(type: .gadget).buildMetaModel(with: app.originalJSONString, context: MetaContext(uniqueID: oldUniqueID, token: nil)) else {
            logger.info("\(String.DiffPkgPrefix) build meta failed")
            return nil
        }

        return installedMeta
    }

    /// 更新BDPPkgInfoTableV3信息
    /// - Parameter context: 包上下文
    /// - Returns: 更新是否成功
    func updatePackageDB(with context: BDPPackageContext) -> Bool {
        guard let packageManager = BDPModuleManager(of: context.uniqueID.appType).resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol else {
            return false
        }
        // 保存下载包信息
        packageManager.packageInfoManager.updatePkgInfoStatus(.downloaded, with: context.uniqueID, pkgName: context.packageName, readType: context.readType)
        // 更新包来源信息
        packageManager.packageInfoManager.updatePackageType(context.uniqueID, pkgName: context.packageName, packageSource: .incremental)

        return true
    }

    /// 验证包MD5信息(逻辑参考BDPPackageManagerStrategy)
    /// - Parameters:
    ///   - context: 包上下文
    ///   - packagePath: 需要校验包文件路径
    /// - Returns: MD5校验结果
    func packageMD5Check(with md5: String?, packagePath: String) -> Bool {
        // 这边为了防止出现使用错误包的情况, 当没有MD5标准值时, 这边则认为校验不通过;
        // 这个和BDPPackageManagerStrategy有所不同;
        guard let md5 = md5, !BDPIsEmptyString(md5) else {
            logger.info("\(String.DiffPkgPrefix) base md5 is empty")
            return false
        }

        guard let fileMD5 = TMAMD5.getMD5withPath(packagePath), !BDPIsEmptyString(fileMD5) else {
            logger.info("\(String.DiffPkgPrefix) file md5 is empty")
            return false
        }

        return fileMD5.hasPrefix(md5)
    }

    /// 删除对应的包
    @discardableResult
    func deletePackage(with context: BDPPackageContext) -> Bool {
        do {
            try BDPPackageLocalManager.deleteLocalPackage(with: context)
            logger.info("\(String.DiffPkgPrefix) delete package \(context.packageName) success")
            return true
        } catch {
            logger.info("\(String.DiffPkgPrefix) delete package \(context.packageName) failed: \(error)")
            // 重要: 这种删除包失败的需要关注; (虽然不属于增量中失败的case, 但是有这个错误上报就需要关注)
            OPMonitor(String.monitorEventName).setUniqueID(context.uniqueID).reportFailed(with: .deleteFileFailed)
            return false
        }
    }

    /// 创建对应包的文件夹路径
    func createPackageFileDir(with packageContext: BDPPackageContext) -> Bool {
        do {
            try BDPPackageLocalManager.createFileHandle(for: packageContext)
            return true
        } catch {
            logger.info("\(String.DiffPkgPrefix) create package path \(packageContext.packageName) failed, error: \(error)")
            return false
        }
    }

    func renameFile(from srcPkgCtx: BDPPackageContext, to desPkgCtx: BDPPackageContext) -> Bool {
        guard let srcPath = BDPPackageLocalManager.localPackageDirectoryPath(for: srcPkgCtx), let desPath = BDPPackageLocalManager.localPackageDirectoryPath(for: desPkgCtx) else {
            logger.info("\(String.DiffPkgPrefix) can not get package dirctory")
            return false
        }

        do {
            try LSFileSystem.main.moveItem(atPath: srcPath, toPath: desPath)
            return true
        } catch {
            logger.info("\(String.DiffPkgPrefix) move file failed: \(error)")
            return false
        }
    }

    private func callbackResult(with task: PKMDiffPackageDownloadTask,
                                success: Bool,
                                reader: BDPPkgFileReadHandleProtocol?) {
        for callback in task.needCallbacks {
            callback(success, reader)
        }

        task.updateDownloadStatus(.completed)

        let revmovedTask = downloadingTaskSets.remove(task)
        logger.info("\(String.DiffPkgPrefix) remove task \(task.uniqueID.appID) success? \(revmovedTask != nil) remainTask count: \(downloadingTaskSets.count)")
    }

    private func downloadFailedCallback(with task: PKMDiffPackageDownloadTask,
                                        deletePackages : [BDPPackageContext]) {
        // 下载失败需要移除diff包
        for packageContext in deletePackages {
            deletePackage(with: packageContext)
        }

        callbackResult(with: task, success: false, reader: nil)
    }

    /// 创建文件句柄, 当前是小程序在使用, 因此这边创建的是流式包的文件句柄
    private func createFileHandle(with context: BDPPackageContext) -> BDPPkgFileReadHandleProtocol {
        let packageReader = BDPPackageStreamingFileHandle(afterDownloadedWith: context)
        return packageReader
    }
}

// MARK: 构建PKMDiffPackageDownloadTask对象
extension PKMDiffPackageDownloader {
    func downloadTask(with packageContext: BDPPackageContext,
                      priority: Float,
                      callback: PKMDiffPkgDownloadCompletion?) -> PKMDiffPackageDownloadTask {
        let newDownloadTask = configDownloadTask(with: packageContext, priority: priority, callback: callback)

        var executeTask = newDownloadTask

        if let exsitedTask = downloadingTaskSets.first(where: {
            $0 == newDownloadTask
        }) {
            // 如果有相同的任务, 则添加回调到已存在的任务中即可
            logger.info("\(String.DiffPkgPrefix) find same task for \(newDownloadTask.uniqueID.appID)")
            exsitedTask.appendNeedCallbacks(from: newDownloadTask)
            executeTask = exsitedTask
        } else {
            // 如果没有相同的任务, 则添加到任务sets中
            logger.info("\(String.DiffPkgPrefix) add new task for \(newDownloadTask.uniqueID.appID)")
            downloadingTaskSets.insert(newDownloadTask)
        }

        logger.info("\(String.DiffPkgPrefix) current task count: \(downloadingTaskSets.count)")
        return executeTask
    }

    func configDownloadTask(with packageContext: BDPPackageContext, priority: Float, callback: PKMDiffPkgDownloadCompletion?) -> PKMDiffPackageDownloadTask {
        if let callback = callback {
            return PKMDiffPackageDownloadTask(packageContext: packageContext, downloadPriority: priority, callbacks: [callback])
        }

        return PKMDiffPackageDownloadTask(packageContext: packageContext, downloadPriority: priority)
    }
}

fileprivate extension OPMonitor {
    func reportFailed(with reason: PKMIncrementalFailedReason) {
        self.setResultTypeFail().setErrorMessage(reason.rawValue).timing().flush()
    }

    func reportSuccess(with increasePkgCtx: BDPPackageContext, originPkgCtx: BDPPackageContext) {
        let incrementalPkgSize = fileSize(with: increasePkgCtx)
        let originPackageSize = fileSize(with: originPkgCtx)

        self.setResultTypeSuccess().timing()
            .addMap(["diffPackageSize" : incrementalPkgSize,
                     "originPackageSize" : originPackageSize]).flush()
    }

    // 计算文件大小
    func fileSize(with packageContext: BDPPackageContext) -> Int {
        guard let appFilePath = BDPPackageLocalManager.localPackagePath(for: packageContext) else {
            return 0
        }
        return Int(LSFileSystem.fileSize(path: appFilePath))
    }
}

fileprivate extension String {
    static let DiffPkgPrefix = "[DiffPkg]"
    static let monitorEventName = "op_package_incremental_result"
}

enum PKMIncrementalFailedReason: String {
    // 应用类型不支持增量更新
    case appTypeNotSupport = "app type not support"
    // 期望合成包已经存在
    case targetPkgAlreadyExist = "target package exist"
    // 本地没有作为base包的meta存在
    case installedMetaNotExist = "installed meta not exist"
    // 包版本非法
    case pkgVersionInvalid = "package version invalid"
    // meta中的diff信息不合法
    case metaIncreaseInfoInvalid = "meta diff info invalid"
    // 构建Diff包下载路径URL失败
    case configIncreaseURLFailed = "config URL failed"
    // 下载增量包失败
    case downloadIncreasePkgFailed = "donwload increase package failed"
    // 增量包不存在
    case increasePkgNotExist = "increase package not exist"
    // 基准包不存在
    case basePkgNotExist = "base package not exist"
    // 创建合成包文件夹失败
    case createTargetFileDirFailed = "create target file dir failed"
    // 合成包路径不存在
    case targetPkpPathNotExist = "new package path not exist"
    // 调用bsPatch失败
    case bsPatchFailed = "bsPatch failed"
    // 重命名文件失败
    case renameFileFailed = "rename file failed"
    // 合成包MD5校验失败
    case mergedPkgMD5Invalid = "md5 check failed"
    // 更新包信息的DB失败
    case updateDBFailed = "update db faield"
    // 删除本地包失败
    case deleteFileFailed = "delete file failed"
}
