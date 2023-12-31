//
//  LynxCustomPkgManager.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2022/4/25.
//  


import Foundation
import SKFoundation
import LibArchiveKit
import SKInfra

class LynxCustomPkgManager: NSObject {
    typealias Completion = (Bool, String?) -> Void
    
    static let shared = LynxCustomPkgManager()
    
    /// debug面板开启“lynx指定资源包”，且默认位置存在资源包，才返回true
    var shouldUseCustomPkg: Bool {
        get {
            let enable = CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.lynxCustomPkgEnable)
            if enable == true {
                let folderPath = savePathOfCustomPkg
                var isFolder: Bool = folderPath.isDirectory
                let exist = folderPath.exists
                return exist && isFolder
            }
            return false
        }
        set {
            CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.lynxCustomPkgEnable)
        }
    }
    
    /// lynx指定资源包 默认保存路径
    private var savePathOfCustomPkg: SKFilePath {
        return LynxIOHelper.Path.getSourceFolder_(for: LynxEnvManager.bizID, type: .custom)
    }
    
    func savePathOfCustomPkg(with channel: String) -> SKFilePath {
        return savePathOfCustomPkg.appendingRelativePath(channel)
    }
    
    func versionOfCurrentSavedCustomPkg(with channel: String) -> String? {
        let path = savePathOfCustomPkg(with: channel).appendingRelativePath("current_revision")
        return LynxIOHelper.syncGetVersion(from: path)
    }
    
    private static var zipSavePathOfCustomPkg: SKFilePath {
        return SKFilePath.globalSandboxWithTemporary.appendingRelativePath("docsSDK-custom-lynx-pkg.tar.gz")
    }
    
    func downloadCustomPkg(_ version: String, completion: Completion?) {
        let urlStr = "http://d.scm.byted.org/api/download/ceph:lark.lynx.docs_\(version).tar.gz"
        guard let request = URLRequest(method: .get, url: urlStr) else {
            completion?(false, "create request fail")
            return
        }
        let task = URLSession.shared.downloadTask(with: request) { [weak self] location, response, error in
            guard let self = self else { return }
            guard response?.statusCode == 200,
                let fileURL = location, !fileURL.path.isEmpty,
                  SKFilePath.init(absUrl: fileURL).exists else {
                DispatchQueue.main.async {
                    let errorMessage = "\(error?.localizedDescription ?? "download fail"), statusCode:\(String(describing: response?.statusCode))"
                    completion?(false, errorMessage)
                }
                return
            }
            self.unzip(downloadPath: fileURL, to: self.savePathOfCustomPkg, completion: completion)
        }
        task.resume()
    }
    private func unzip(downloadPath: URL, to unzipFolder: SKFilePath, completion: Completion?) {
        let zipPath = Self.zipSavePathOfCustomPkg
        let targetDirPath = zipPath.deletingLastPathComponent
        if !targetDirPath.exists {
            targetDirPath.createDirectoryIfNeeded()
        }
        
        if !move(srcPath: downloadPath, to: zipPath) {
            DispatchQueue.main.async {
                completion?(false, "can't move downloaded custom zip pkg")
            }
            return
        }
        if !createFolder(path: unzipFolder) {
            DispatchQueue.main.async {
                completion?(false, "can't create custom unzip pkg folder")
            }
            return
        }
        
        do {
            let archFile = try LibArchiveFile(path: zipPath.pathString)
            try archFile.extract(toDir: URL(fileURLWithPath: unzipFolder.pathString))
        } catch {
            DocsLogger.error("custom lynx pkg unzip fail", error: error)
            DispatchQueue.main.async {
                completion?(false, error.localizedDescription)
            }
            return
        }
        let success = moveCurrentVersionFile(at: unzipFolder)
        DispatchQueue.main.async {
            completion?(success, success ? nil : "move current_revision fail")
        }
    }
    private func moveCurrentVersionFile(at rootPath: SKFilePath) -> Bool {
        let oriVersionFilePath = rootPath.appendingRelativePath("current_revision")
        let newVersionFilePath = rootPath.appendingRelativePath(LynxEnvManager.channel).appendingRelativePath("current_revision")
        if !newVersionFilePath.exists {
            if oriVersionFilePath.exists {
                do {
                    try oriVersionFilePath.moveItem(to: newVersionFilePath)
                } catch {
                    DocsLogger.error("move current_revision of custom pkg fail", error: error, component: LogComponents.lynx)
                    return false
                }
            } else {
                return false
            }
        }
        return true
    }
    private func move(srcPath: URL, to dstPath: SKFilePath) -> Bool {
        if dstPath.exists {
            do {
                try dstPath.removeItem()
            } catch {
                DocsLogger.error(error.localizedDescription, component: LogComponents.lynx)
                return false
            }
        }
        do {
            try dstPath.moveItemFromUrl(from: srcPath)
        } catch {
            DocsLogger.error(error.localizedDescription, component: LogComponents.lynx)
            return false
        }
        return true
    }
    private func createFolder(path: SKFilePath) -> Bool {
        var isFolder: Bool = path.isDirectory
        let isExists = path.exists
        if isExists && isFolder {
            do {
                try path.removeItem()
            } catch {
                DocsLogger.error(error.localizedDescription, component: LogComponents.lynx)
                return false
            }
        }
        do {
            try path.createDirectoryIfNeeded(withIntermediateDirectories: true)
        } catch {
            DocsLogger.error(error.localizedDescription, component: LogComponents.lynx)
            return false
        }
        return true
    }
}
