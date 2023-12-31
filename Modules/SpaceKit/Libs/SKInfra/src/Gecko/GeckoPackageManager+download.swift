//
//  GeckoPackageManager+download.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/5/4.
//  


import RxSwift
import RxRelay
import SKFoundation
import SpaceInterface
// https://bytedance.feishu.cn/docs/doccnQxO9CwBIHzCWi8IGjgz3Ze
extension GeckoPackageManager {
    private static var waitingDownloadFullPkgTime: TimeInterval = 0
    public func recordWaitingDownloadFullPkgTime(isStart: Bool) {
        let now = Date().timeIntervalSince1970
        if isStart {
            GeckoPackageManager.waitingDownloadFullPkgTime = now
        } else {
            let startTime = GeckoPackageManager.waitingDownloadFullPkgTime
            GeckoPackageManager.waitingDownloadFullPkgTime = now - startTime
        }
    }

    public static func getOpenUrlWaitingFullPkgDownloadTime() -> TimeInterval {
        return GeckoPackageManager.waitingDownloadFullPkgTime * 1000
    }
    
    public static func resetWaitingFullPkgDownloadTime() {
        GeckoPackageManager.waitingDownloadFullPkgTime = 0
    }
    
    /// 将解压好的包移动到目标目录下使用，并酌情触发webView资源的刷新
    private func applyFullPackage(from srcPath: SKFilePath, to dstPath: SKFilePath, for item: DocsChannelInfo, type: ResourceSource) -> Bool {
        GeckoLogger.info("fullPkg: willApplyFullPackage, name=\(item.type.channelName())")
        reportWillUpdate(type: item.type)
        let success = tryMoveFullPkgToBackup(from: srcPath, to: dstPath)
        if success {
            refreshOfflineResourceLocator(item)
            reportDidUpdate(type: item.type, finish: true, needReloadRN: false)
        }
        return success
    }

    private func tryMoveFullPkgToBackup(from srcPath: SKFilePath, to dstPath: SKFilePath) -> Bool {
        let version: String? = GeckoPackageManager.Folder.moveFilesIfVersionDiff(srcPath: srcPath, dstPath: dstPath)
        return version != nil
    }
    
    private func handleFullPkgDownloadCallBack(task: PackageDownloadTask) {
        guard let resourceInfo = task.resourceInfo, let channel = resourceInfo.channel else { return }
        let source: ResourceSource = .fullPkg
        let pkgPathInfo = source.pkgPathInfo()

        var applySuccess = false
        if task is PackageDownloadTaskDriveImpl {
            let isUnzipSuccess = unzipPkgZip(from: task.downloadPath, to: pkgPathInfo.tempUnzipFolderPath)
            if isUnzipSuccess {
                applySuccess = applyFullPackage(
                    from: pkgPathInfo.tempUnzipFolderPath,
                    to: resourceInfo.fullPkgRootFolder,
                    for: channel,
                    type: source
                )
            }
        } else {
            applySuccess = applyFullPackage(
                from: pkgPathInfo.tempUnzipFolderPath,
                to: resourceInfo.fullPkgRootFolder,
                for: channel,
                type: source
            )
        }
        
        removeFiles(at: pkgPathInfo.downloadRootPath, logTag: "下载的完整包")

        if applySuccess {
            DocsContainer.shared.resolve(SKBrowserInterface.self)?.editorPoolDrainAndPreload()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name.feFullPackageHasReady, object: nil)
            }
        }
    }

    private func unzipPkgZip(from srcPath: SKFilePath, to dstPath: SKFilePath) -> Bool {
        guard !srcPath.pathString.isEmpty, !dstPath.pathString.isEmpty else {
            GeckoLogger.error("解压资源包错误，操作路径为空，from:\(srcPath) to \(dstPath)")

            return false
        }
        //解压完整包
        GeckoLogger.info("Unzip the complete package，from:\(srcPath.pathString) to \(dstPath.pathString)")
        let success = unzip(zipFilePath: srcPath, to: dstPath)
        guard !success else {
            return true
        }
        do { try dstPath.removeItem() } catch { }
        let retryTime = 3
        for i in 0..<retryTime {
            let finish = unzip(zipFilePath: srcPath, to: dstPath)
            GeckoLogger.info("retry unzip full pkg, to:\(dstPath), is success: \(finish)")
            if finish {
                GeckoLogger.info("retry unzip full pkg success")
                return true
            } else {
                do { try dstPath.removeItem() } catch { }
                if i == retryTime - 1 {
                    GeckoLogger.info("retry unzip full pkg 3 times, all fail")
                }
            }
        }
        return false
    }
    
    /// 在本地eesz文件夹中搜索，是否存在文件名为feResourceName的资源位文件，如果存在，返回路径
    /// - Parameter feResourceName: 要找的资源名称的路径
    /// - Returns: 没找到返回nil，找到了返回真实值（完整路径）
    public func checkIfExist(feResourceName: String, in folder: SKFilePath) -> SKFilePath? {
        return getFullFilePath(at: folder, of: feResourceName)
    }
}

// MARK: - 灰度包下载处理逻辑
extension GeckoPackageManager {
    private func handleGrayscalePkgDownloadCallBack(isSuccess: Bool, task: PackageDownloadTask, channel: DocsChannelInfo? = nil) {
        guard isSuccess else {
            GeckoPackageManager.shared.curDownloadingChannelForGrayscale = nil
            return
        }
        guard let channel = channel else { return }
        if task is PackageDownloadTaskDriveImpl {
            unzipGrayscalePkgZip(zipPath: task.downloadPath)
        }
        GeckoPackageManager.shared.curDownloadingChannelForGrayscale = nil

        let isbrowserVCEmpty = DocsContainer.shared.resolve(SKBrowserInterface.self)?.browsersStackIsEmptyObsevable ?? BehaviorRelay<Bool>(value: true)
        let isOfflineSynIdle = SKInfraConfig.shared.offlineSynIdle
        let isDriveStackEmpty = DocsContainer.shared.resolve(DrivePreviewRecorderBase.self)?.stackEmptyStateChanged ?? Observable<Bool>.never()

        self.disposeBagForGrayscaleApply = DisposeBag()
        Observable.combineLatest(isbrowserVCEmpty, isOfflineSynIdle, isDriveStackEmpty)
            .distinctUntilChanged({ (l, r) -> Bool in return l == r })
            .observeOn(MainScheduler.instance)
            .filter({ (isBrowserVCEmpty, isOfflineSynIdle, isDriveStackEmpty) -> Bool in
                let msg = "grayscale: webInfo watch condition, isBrowserVCEmpty=\(isBrowserVCEmpty), isOfflineSynIdle=\(isOfflineSynIdle), isDriveStackEmpty=\(isDriveStackEmpty)"
                  GeckoLogger.info(msg)
                  return isBrowserVCEmpty && isOfflineSynIdle && isDriveStackEmpty
              })
            .take(1)
            .subscribe(onNext: { [weak self] (_, _, _) in
                GeckoLogger.info("grayscale: webInfo watch condition done, tryApplyPackage")
                self?.applyGrayScalePackage(item: channel)
            }).disposed(by: self.disposeBagForGrayscaleApply)
    }
    
    private func unzipGrayscalePkgZip(zipPath: SKFilePath) {

        guard !zipPath.pathString.isEmpty else { return }
        let unzipPath = GeckoPackageManager.Folder.grayscalePkgUnzipPath(channel: nil)
        GeckoLogger.info("解压灰度包，from:\(zipPath) to \(unzipPath)")
        let success = unzip(zipFilePath: zipPath, to: unzipPath)
        if !success {
            do { try unzipPath.removeItem() } catch { }
            let retryTime = 3
            for i in 0..<retryTime {
                let finish = unzip(zipFilePath: zipPath, to: unzipPath)
                GeckoLogger.info("解压灰度包，触发解压重试 to:\(unzipPath) success: \(finish)")
                if finish {
                    GeckoLogger.info("解压灰度包，重新加压成功")
                    break
                } else {
                    if i != retryTime - 1 {
                        do { try unzipPath.removeItem() } catch { }
                    } else {
                        GeckoLogger.info("解压灰度包，重新加压失败")
                    }
                }
            }
        }
    }

    func applyGrayScalePackage(item: DocsChannelInfo) {
        DispatchQueue.global().async {
            GeckoLogger.info("GrayScale: willApplyGrayScalePackage, name=\(item.type.channelName())")
            self.reportWillUpdate(type: item.type)
            self.tryMoveGrayscalePkgToBackup(channel: item)
            self.refreshOfflineResourceLocator(item)
            self.reportDidUpdate(type: item.type, finish: true, needReloadRN: false)
        }
    }

    func tryMoveGrayscalePkgToBackup(channel: DocsChannelInfo) {
        let grayscalePkgBackupPath = GeckoPackageManager.Folder.grayscalePkgBackupPath(channel: nil)
        let originPath = GeckoPackageManager.Folder.grayscalePkgUnzipPath(channel: nil)
        guard !grayscalePkgBackupPath.pathString.isEmpty,
              !originPath.pathString.isEmpty
        else {
             GeckoLogger.info("GrayScale: tryMoveGrayscalePkgToBackup grayscalePkgBackupPath=nil or originPath == nil")
             return
         }
         let type = channel.type
         GeckoLogger.info("GrayScale: \(type.channelName())尝试替换gecko的资源到目标路径")

         // 复用这个移动方法，并非只有gecko包才能用
         let version = GeckoPackageManager.Folder.moveFilesIfVersionDiff(srcPath: originPath, dstPath: grayscalePkgBackupPath)
         if version != nil {
             removeUnuseGrayscaleDownloadFiles(for: channel)
             GeckoLogger.info("GrayScale: 灰度包解压移动完成最终使用版本 \(String(describing: version))")
         }
     }

    private func removeUnuseGrayscaleDownloadFiles(for channel: DocsChannelInfo) {
         let grayscalePkgDownloadRootPath = GeckoPackageManager.Folder.grayscalePkgDownloadRootPath(channel: nil)
         removeFiles(at: grayscalePkgDownloadRootPath, logTag: "grayscalePkgDownloadRootPath after move succss")
     }
}

extension GeckoPackageManager {
    public func getFinalSaverPkgPath() -> SKFilePath {
        guard let channel = getWebInfoChannels().first else {
            spaceAssertionFailure("不能没有webinfo channel")
            GeckoLogger.error("gecko_hotfix1: webinfo channel is missed when prepare saver pkg path")
            return SKFilePath.absPath("")
        }

        let zipInfo = OfflineResourceZipInfo.info(by: channel)
        guard zipInfo.usingZip, zipInfo.isVaild else {
            GeckoLogger.info("gecko_hotfix1: getFinalSaverPkgPath, zip信息不合法 \(channel.type.identifier())")
            return SKFilePath.absPath("")
        }

        let unzipPath = channelSaviorPath()
        let isExist = checkIsPackageExist(at: unzipPath)
        GeckoLogger.info("savior pkg target path has reversion file? :\(isExist), path is: \(unzipPath)")

        if isExist {
            return unzipPath
        }

        let result = unzip(zipFilePath: zipInfo.zipFileFullPath, to: unzipPath)
        GeckoLogger.info("SaviorPkg unzip is success? --> \(result), from: \(zipInfo.zipFileFullPath), to:\(unzipPath)")
        if result == false {
            spaceAssertionFailure("check savior pkg logic")
        }
        return result ? unzipPath : SKFilePath.absPath("")
    }

    public func getTargetFileFullPath(in folder: SKFilePath, fileName: String, needFullPath: Bool) -> SKFilePath {
        GeckoLogger.info("getTargetFileFullPath, begin, folder:\(folder.pathString), fileName:\(fileName)")
        guard folder.exists else {
            return folder
        }
        guard let subPaths = try? folder.subpathsOfDirectory() else {
            GeckoLogger.info("getTargetFileFullPath, fileMgr.subpaths(atPath: folder) failed, folder:\(folder.pathString), fileName:\(fileName)")
            return folder
        }

        var targetPath = ""
        subPaths.forEach { (path) in
            guard !path.isEmpty,
                  let name = path.components(separatedBy: "/").last, !name.isEmpty,
                  name == fileName
                  else { return }
            targetPath = path
        }

        var res = folder.appendingRelativePath(targetPath)
        if !needFullPath {
            //返回上一级目录，是否跟replacingOccurrences(of: "/\(fileName)", with: "")效果一样
            res = res.deletingLastPathComponent
        }
        GeckoLogger.info("getTargetFileFullPath, end res:\(res.pathString), folder:\(folder.pathString), fileName:\(fileName), needFullPath: \(needFullPath)")
        return res
    }
}


extension GeckoPackageManager: PackageDownloadTaskDelegate {
    
    func onSuccess(task: PackageDownloadTask) {
        if task.isGrayscale {
            GeckoLogger.info("灰度包下载成功,path:\(task.downloadPath)")
            if let channel = GeckoPackageManager.shared.curDownloadingChannelForGrayscale {
                // 因为不知道mina下发的版本对应的包是精简包，还是完整包，所以单独走这个逻辑，如果是精简包，后续逻辑会触发下载对应完整包的逻辑
                handleGrayscalePkgDownloadCallBack(isSuccess: true, task: task, channel: channel)
            }
        } else {
            // 完整包
            let isForUnzipFailed = task.isForUnzipBundleSlimFailed
            GeckoLogger.info("精简包对应的完整包下载成功,path:\(task.downloadPath), 是否由解压内置精简包失败后触发:\(isForUnzipFailed)")
            if isForUnzipFailed { // 如果是由解压内置精简包失败后触发的任务，则忽略检查locator.version
                handleFullPkgDownloadCallBack(task: task)
            } else {
                if let resourceInfo = task.resourceInfo,
                   let locator = locatorMapping.value(ofKey: .webInfo),
                   locator.version == resourceInfo.simplePkgInfo.version {
                    handleFullPkgDownloadCallBack(task: task)
                } else {
                    let locatorVersion = locatorMapping.value(ofKey: .webInfo)?.version ?? ""
                    let resourceVersion = task.resourceInfo?.simplePkgInfo.version ?? ""
                    GeckoLogger.info("精简包对应的完整包下载成功, 但version异常, locatorVersion:\(locatorVersion),resourceVersion:\(resourceVersion)")
                }
            }
        }
        pkgDownloadTasks.removeAll { $0 === task }
    }
    
    func onFailure(task: PackageDownloadTask, errorMsg: String) {
        GeckoLogger.info("package download fail，errorMsg:\(errorMsg)")
        if task.isGrayscale, let channel = GeckoPackageManager.shared.curDownloadingChannelForGrayscale {
            // 因为不知道mina下发的版本对应的包是精简包，还是完整包，所以单独走这个逻辑，如果是精简包，后续逻辑会触发下载对应完整包的逻辑
            handleGrayscalePkgDownloadCallBack(isSuccess: false, task: task, channel: channel)
        }

        pkgDownloadTasks.removeAll { $0 === task }
    }
}
