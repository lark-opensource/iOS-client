//
//  GeckoPackageManager+folder.swift
//  SpaceKit
//
//  Created by Webster on 2018/11/21.
//

import SKFoundation
import Foundation

extension GeckoPackageManager {
    public class Folder {
        //最终存储的资源路径
        class func finalFolderPath(channel: String?) -> SKFilePath {
            let location = SKFilePath.globalSandboxWithLibrary
            var dataFolderName = "ResourceService"
            if let channelName = channel {
                dataFolderName = "ResourceService/" + channelName + "/"
            }
            let rootPath = location.appendingRelativePath(dataFolderName)
            return rootPath
        }

        /// 热更包解压后存放路径
        public class func geckoBackupPath(channel: String?) -> SKFilePath {
            let location = SKFilePath.globalSandboxWithLibrary
            var dataFolderName = "HotFixBackup"
            if let channelName = channel {
                dataFolderName = "HotFixBackup/" + channelName
            }
            let rootPath = location.appendingRelativePath(dataFolderName)
            return rootPath
        }

        /// 内嵌完整包解压后存放路径
        public class func bundleBackupPath(channel: String?) -> SKFilePath {
            let location = SKFilePath.globalSandboxWithLibrary
            var dataFolderName = "BundleBackup"
            if let channelName = channel {
                dataFolderName = "BundleBackup/" + channelName
            }
            let rootPath = location.appendingRelativePath(dataFolderName)
            return rootPath
        }

        /// 内嵌精简包的保留文件夹路径的path
        public class func simpleBundleBackupPath(channel: String?) -> SKFilePath {
            let location = SKFilePath.globalSandboxWithLibrary
            var dataFolderName = "simpleBundleBackup"
            if let channelName = channel {
                dataFolderName = "simpleBundleBackup/" + channelName
            }
            let rootPath = location.appendingRelativePath(dataFolderName)
            return rootPath
        }

        /// 当前正在使用的完整包文件夹路径的path
        class func fullPkgBackupPath(channel: String?) -> SKFilePath {
            return getAPath(channel: channel, folderName: "fullPkgBackup")
        }

        /// 保存下载的完整包zip文件的文件夹path
        class func fullPkgZipDownloadPath(channel: String?) -> SKFilePath {
            return getAPath(channel: channel, folderName: "fullPkgDownload/zipOrigin")
        }

        /// 完整包的解压path
        class func fullPkgUnzipPath(channel: String?) -> SKFilePath {
            return getAPath(channel: channel, folderName: "fullPkgDownload/unzip")
        }

        class func fullPkgDownloadRootPath(channel: String?) -> SKFilePath {
            return getAPath(channel: channel, folderName: "fullPkgDownload")
        }

        class func grayscalePkgZipDownloadPath(channel: String?) -> SKFilePath {
            return getAPath(channel: channel, folderName: "grayscalePkgDownload/zipOrigin")
        }
        class func grayscalePkgUnzipPath(channel: String?) -> SKFilePath {
            return getAPath(channel: channel, folderName: "grayscalePkgDownload/unzip")
        }
        class func grayscalePkgBackupPath(channel: String?) -> SKFilePath {
            return getAPath(channel: channel, folderName: "grayscalePkgBackup")
        }
        class func grayscalePkgDownloadRootPath(channel: String?) -> SKFilePath {
            return getAPath(channel: channel, folderName: "grayscalePkgDownload")
        }

        class func getAPath(channel: String?, folderName: String) -> SKFilePath {
            let location = SKFilePath.globalSandboxWithLibrary
            var dataFolderName = "\(folderName)"
            if let channelName = channel {
                dataFolderName = "\(folderName)/" + channelName
            }
            let rootPath = location.appendingRelativePath(dataFolderName)
            return rootPath
        }

        class func saviorBackupPath(channel: String?) -> SKFilePath {
            let location = SKFilePath.globalSandboxWithLibrary

            var dataFolderName = "SaviorBackup"
            if let channelName = channel {
                dataFolderName = "SaviorBackup/" + channelName
            }
            let rootPath = location.appendingRelativePath(dataFolderName)
            return rootPath
        }

        @discardableResult
        class func moveFileIfNeed(channel: DocsChannelInfo, bundlePath: SKFilePath, dstPath: SKFilePath, fromBundle: Bool) -> String? {
            let finalVersion = self.revision(in: dstPath)
            let bundleVersion = self.revision(in: bundlePath)
            guard bundleVersion != nil else {
                GeckoLogger.info("找不到原目标的版本")
                return nil
            }
            if fromBundle {
                GeckoLogger.info("尝试考察bunlde的版本号: \(bundleVersion ?? "无"))")
            } else {
                GeckoLogger.info("尝试考擦gecko下发的版本号 \(bundleVersion ?? "无")")
            }

            guard finalVersion != nil else {
                self.moveFiles(bundlePath, to: dstPath)
                GeckoLogger.info("目标路径暂无资源，拷贝并应用版本号\(bundleVersion ?? "无")")
                return bundleVersion
            }

            guard let finalVer = finalVersion, let bundleVer = bundleVersion else {
                GeckoLogger.info("考察路径与目标路径下都没有版本号,路径如下")
                GeckoLogger.info("考察路径:\(bundlePath) ")
                GeckoLogger.info("目标路径:\(dstPath) ")
                return  nil
            }
            //如果目标文件夹的资源文件不是空，就对比版本号，确保目标文件夹的资源文件是最新的
            if finalVer.compare(bundleVer, options: .numeric) == .orderedAscending {
                GeckoLogger.info("考察路径下资源版本号比较高，拷贝考擦路径到目标路径， 最终版本\(bundleVer)")
                self.moveFiles(bundlePath, to: dstPath)
                return bundleVer
            } else {
                GeckoLogger.info("目标路径下资源版本号比较高，保持原有版本， 原有版本\(finalVer)")
                return finalVer
            }
        }

        @discardableResult
        class func moveFilesIfVersionDiff(srcPath: SKFilePath, dstPath: SKFilePath) -> String? {
            let geckoMgr = GeckoPackageManager.shared
            let srcDocsChannel = geckoMgr.appendDocsChannel(to: srcPath)
            let dstDocsChannel = geckoMgr.appendDocsChannel(to: dstPath)

            let srcVersionInfo = geckoMgr.getCurrentRevisionInfo(in: srcDocsChannel)
            if !srcVersionInfo.isExist || srcVersionInfo.channel.rawValue != GeckoChannleType.webInfo.unzipFolder() {
                showPkgErrorInfo(errorChannel: srcVersionInfo.channel.rawValue)
            }
            let dstVersionInfo = geckoMgr.getCurrentRevisionInfo(in: dstDocsChannel)
            var shouldMove = false
            var version: String?
            if !dstVersionInfo.isExist {
                shouldMove = true
            } else if srcVersionInfo.isExist, srcVersionInfo.version != dstVersionInfo.version {
                shouldMove = true
            }
            if shouldMove {
                Folder.moveFiles(srcPath, to: dstPath)
                version = srcVersionInfo.version
            }
            return version
        }

        class func moveGeckoFileIfNeed(channel: DocsChannelInfo, geckoPath: SKFilePath, dstPath: SKFilePath) -> String? {
           return moveFileIfNeed(channel: channel, bundlePath: geckoPath, dstPath: dstPath, fromBundle: false)
        }

        class func revision(in folder: SKFilePath) -> String? {
            guard let revision = getCurRevisionFileContent(in: folder) else {
                return nil
            }
            return DocsStringUtil.getValue(from: revision, of: "version")
        }

        class func getCurRevisionFileContent(in folder: SKFilePath) -> String? {
            guard folder.exists else {
                GeckoLogger.error("\(folder.pathString) unexists")
                return nil
            }
            var revision: String?
            let filePath = folder.appendingRelativePath("\(GeckoPackageManager.shared.revisionFile)")
            do {
                revision = try String.read(from: filePath)
            } catch {
                GeckoLogger.error("can't read content from: \(filePath.pathString)")
            }
           return revision
        }

        /// 获取指定目录下的current_revision文件内容，传入的folder必须是current_revision的父级folder
        public class func getCurentVersionInfo(in folder: SKFilePath) -> OfflineResourceZipInfo.CurVersionInfo {
            guard folder.exists else {
                GeckoLogger.error("Folder does not exist:\(folder.pathString)")
                return OfflineResourceZipInfo.CurVersionInfo()
            }
            let revision: String? = getCurRevisionFileContent(in: folder)
            guard let revisionContent = revision else {
                GeckoLogger.error("can’ t get current_revision file")
                return OfflineResourceZipInfo.CurVersionInfo()
            }

            var curVersionInfo = OfflineResourceZipInfo.CurVersionInfo()

            if let version = getSimplePkgVersion(from: revisionContent) {
                curVersionInfo.version = version
            }
            // 是否是精简包
            if let isSlimStr = getIsSlim(from: revisionContent), isSlimStr == "1"{
                curVersionInfo.isSlim = true
            }

            if let fullPkgVersion = getFullPkgScmVersion(from: revisionContent) {
                curVersionInfo.fullPkgScmVersion = fullPkgVersion
            }

            if let fullPkgUrlHome = getFullPkgUrlHome(from: revisionContent) {
                curVersionInfo.fullPkgUrlHome = fullPkgUrlHome
            }

            if let fullPkgUrlOversea = getFullPkgUrlOversea(from: revisionContent) {
                curVersionInfo.fullPkgUrlOversea = fullPkgUrlOversea
            }

            if let channel = getChannel(from: revisionContent),
               let channelType = GeckoPackageAppChannel(rawValue: channel) {
                curVersionInfo.channel = channelType
            }

            return curVersionInfo
        }

        class func showPkgErrorInfo(errorChannel: String) {
            GeckoLogger.error("Docs前端资源包使用出错，套件和单品的包不能混用, errorChannel:\(errorChannel), 希望的是：\(GeckoChannleType.webInfo.unzipFolder())")
        }

        /// 将下载的热更包转移到热更包最终存放路径
        @discardableResult
        class func moveFiles(_ srcFolder: SKFilePath, to destFolder: SKFilePath) -> Bool {
            let startTime = Date().timeIntervalSince1970
            defer {
                let endTime = Date().timeIntervalSince1970
                GeckoLogger.info("move files cost time: \((endTime - startTime) * 1000) ms")
            }
            let srcVer = self.revision(in: srcFolder)
            let dstVer = self.revision(in: destFolder)
            
            let fileManager = FileManager.default

            if !destFolder.exists {
                do {
                    try destFolder.createDirectoryIfNeeded(withIntermediateDirectories: true)
                } catch let error {
                    GeckoLogger.warning("createDirectory failed with error :\(error)")
                    logForFailure(.createDirFail, srcVersion: srcVer, dstVersion: dstVer)
                    return false
                }
            }

            // 由于前端下发的热更包里面的 rn/... 不一定是齐全的
            // 所以这里要先保存一份 destFolder/../rn 的资源, 然后再用前端下发的热更包来替换 destFolder/../rn 里面资源
            // 替换完毕后, 再尝试把保存的的资源覆盖 destFolder/../rn 来确保 destFolder/../rn 的 rn.bundle 一定是完整的

            // 保存一份 destFolder/../rn 的文件
            // CB5C7E848A7626CCF912471DB2BB44E8 = stash_front_end_resource.md5
            let destRNPath = destFolder.appendingRelativePath("rn")
            let stashFolder = SKFilePath.globalSandboxWithTemporary.appendingRelativePath("CB5C7E848A7626CCF912471DB2BB44E8")
            do {
                try stashFolder.removeItem()
            } catch let error {
                GeckoLogger.error("remove rn stash", error: error)
            }

            do {
                try destRNPath.moveItem(to: stashFolder)
            } catch let error {
                GeckoLogger.error("stash rn", error: error)
            }

            // 清空 dst 里面的文件
            do {
                try destFolder.removeItem()
            } catch let error {
                GeckoLogger.warning("remove files in xxx failed with error", error: error)
                logForFailure(.removeItemFail, srcVersion: srcVer, dstVersion: dstVer)
                GeckoLogger.info("RN Have in the directory: \(String(describing: try? destFolder.contentsOfDirectory()))")
                GeckoLogger.info("eesz/template Have in the directory: \(String(describing: try? destFolder.appendingRelativePath("template").contentsOfDirectory()))")
                GeckoLogger.info("eesz/template/bear directory have：\(String(describing: try? destFolder.appendingRelativePath("template/bear").contentsOfDirectory()))")
                let bearAttri = try? destFolder.appendingRelativePath("template/bear").attributes
                let templateAttri = try? destFolder.appendingRelativePath("template")
                let destFolderAttri = try? destFolder.attributes
                GeckoLogger.info("bear属性：\(String(describing: bearAttri)), eesz/template属性：\(String(describing: templateAttri)), eesz属性：\(String(describing: destFolderAttri))")

                // 删不了尝试重命名 https://bytedance.feishu.cn/docs/doccnMD9bYAXcvxK8vJTGT1Sule#
                if let cocoaError = error as? CocoaError, cocoaError.code == CocoaError.fileWriteNoPermission {
                    tryRenameFolderToRandomName(folderPath: destFolder)
                }
            }

            // 替换 dst 资源
            do {
                try srcFolder.moveItem(to: destFolder)
            } catch let error {
                GeckoLogger.warning("move files failed with error", error: error)
                logForFailure(.moveItemFail, srcVersion: srcVer, dstVersion: dstVer)
                GeckoLogger.info("RN Have in the directory: \(String(describing: try? destFolder.contentsOfDirectory()))")
                return false
            }
            
            GeckoLogger.info("destFolderContent= \(String(describing: destFolder.fileListInDirectory()))")

            // 再次将原本的 destFolder/../rn move 现在的 destFolder/../rn
            // 如果有重复的文件 -> 不覆盖! 不覆盖！不覆盖！
            if
                let stashItems = stashFolder.fileListInDirectory(),
                let destItems = destRNPath.fileListInDirectory(),
                !stashItems.isEmpty {

                // 计算原文件夹有的，但是现文件夹没有的资源
                let shouldBeMoveItems = stashItems.filter { !destItems.contains($0) }
                GeckoLogger.info("被原资源文件覆盖的文件 \(shouldBeMoveItems)")
                for item in shouldBeMoveItems {
                    let stashMovePath = stashFolder.appendingRelativePath("\(item)")
                    let destMovePath = destRNPath.appendingRelativePath("\(item)")
                    if destMovePath.exists {
                        try? destMovePath.removeItem()
                    }
                    try? stashMovePath.moveItem(to: destMovePath)
                }
            }

            try? stashFolder.removeItem()

            GeckoLogger.info("destRNContent= \(String(describing: destRNPath.fileListInDirectory()))")
            return true
        }
        
        private class func tryRenameFolderToRandomName(folderPath: SKFilePath) {
            let parentFolderPath = folderPath.deletingLastPathComponent
            let randomName = String.randomStr(len: 12)
            let newPath = parentFolderPath.appendingRelativePath(randomName)
            do {
                try folderPath.moveItem(to: newPath)
            } catch let error {
                GeckoLogger.warning("rename folder to random name failed", error: error)
            }
        }
    }
    
    private enum FailReason: Int {
        case createDirFail
        case removeItemFail
        case moveItemFail
        
        func toBadCaseCode() -> FEPkgManageBadCaseCode {
            switch self {
            case .createDirFail: return .createItemFail
            case .removeItemFail: return .removeItemFail
            case .moveItemFail: return .moveItemFail
            }
        }
    }
    
    private class func logForFailure(_ reason: FailReason, srcVersion: String?, dstVersion: String?) {
        DispatchQueue.main.async {
            let applicationState = UIApplication.shared.applicationState
            let isProtectedDataAvailable = UIApplication.shared.isProtectedDataAvailable
            DispatchQueue.global().async {
                let code = reason.toBadCaseCode()
                let msg = "state:\(applicationState) dataAvail:\(isProtectedDataAvailable) srcVer:\(String(describing: srcVersion)) dstVer:\(String(describing: dstVersion))"
                GeckoPackageManager.shared.logBadCase(code: code, msg: msg)
            }
        }
    }
}

// MARK: - 处理current_revision的内容匹配
extension GeckoPackageManager.Folder {
    /// 获取完整包的版本号
    private class func getFullPkgScmVersion(from content: String) -> String? {
        return DocsStringUtil.getValue(from: content, of: "full_pkg_scm_version")
    }

    private class func getIsSlim(from content: String) -> String? {
        return DocsStringUtil.getValue(from: content, of: "is_slim")
    }

    private class func getSimplePkgVersion(from content: String) -> String? {
        return DocsStringUtil.getValue(from: content, of: "version")
    }

    /// 获取完整包的url, 国内
     private class func getFullPkgUrlHome(from content: String) -> String? {
         return DocsStringUtil.getValue(from: content, of: "full_pkg_url_home")
     }

    /// 获取完整包的url，海外
    private class func getFullPkgUrlOversea(from content: String) -> String? {
        return DocsStringUtil.getValue(from: content, of: "full_pkg_url_oversea")
    }

    /// 获取channel，这个字段表示给套件还是单品用的
    private class func getChannel(from content: String) -> String? {
        return DocsStringUtil.getValue(from: content, of: "channel")
    }
}
