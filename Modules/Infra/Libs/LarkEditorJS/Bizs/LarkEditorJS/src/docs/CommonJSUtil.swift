//
//  CommonJSUtil.swift
//  LarkEditorJS
//
//  Created by maxiao on 2020/4/13.
//

import Foundation
import SSZipArchive
import LKCommonsLogging
import LibArchiveKit // for 7z

///
/// 各业务公共js处理工具类，提供给mail，小程序使用
/// 在DocSDK初始化的时候，会调用unzipIfNeeded()方法，判断是否需要解压拷贝
/// 如果沙盒没有，或者有但是版本较老，则解压覆盖
/// 同时将js.version文件覆盖更新到最新的版本
///
public class CommonJSUtil {
    
    /// 资源包压缩格式
    private enum ZipFileFormat {
        case zip
        case archive_7z
    }
    
    static private let logger = Logger.log(CommonJSUtil.self, category: "LarkEditorJS.CommonJSUtil")
    static private let selfBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/LarkEditorJS", withExtension: "framework") {
            return Bundle(url: url) ?? Bundle.main
        } else {
            return Bundle.main
        }
    }()

    static private let larkEditorBundleUrl: URL = {
        if let url = selfBundle.url(forResource: "LarkEditorJS",
                                    withExtension: "bundle") {
            return url
        }
        assertionFailure("can't get LarkEditorJS bundle file url")
        logInfo("can't get LarkEditorJS bundle file url")
        return Bundle.main.bundleURL
    }()

    /// 待解压的文件包的目录
    static private let sourceFilesPath: URL = {
        var bundleUrl = larkEditorBundleUrl
        // 在bundle中，这个目录不被识别
//        bundleUrl.appendPathComponent("sourceFiles")
        return bundleUrl
    }()
    /// 资源文件zip包格式 & 路径
    static private var newZipFileFormatAndPath: (ZipFileFormat, String)? {
        let bundle = Bundle(url: sourceFilesPath)
        let resName = "EditorVendorJS"
        if let path = bundle?.path(forResource: resName, ofType: "zip") {
            return (.zip, path)
        }
        if let path = bundle?.path(forResource: resName, ofType: "7z") {
            return (.archive_7z, path)
        }
        assertionFailure("can't find LarkEditorJS source files archive path")
        logInfo("can't find LarkEditorJS source files archive path")
        return nil
    }

    static private let libPath = PathHelper.libPath

    static private let jsVersionFileName = PathHelper.jsVersionFileName
    static private let vendorJSFileName = PathHelper.vendorJSFileName

    public class func unzipIfNeeded(forceUnzip: Bool = false) {

        let fileManager = FileManager.default

        let isJSFileExist = fileManager.fileExists(atPath: PathHelper.bundle.jsFilePath)
        // 已经存在
        if isJSFileExist {
            do {
                LarkEditorJS.shared.isReady = false
                logInfo("find new editor_kit.vendor.js，delete old one")
                copyVersionFile()
                unzip()
            } catch { (error)
                logInfo("editor_kit.vendor.js delete fail: \(error)")
            }
        // 不存在则解压
        } else {
            LarkEditorJS.shared.isReady = false
            if !isJSFileExist {
                logInfo("can't find editor_kit.vendor.js，unzip one")
                unzip()
            }
        }

        LarkEditorJS.shared.isReady = true
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name.LarkEditorJS.BUNDLE_RESOUCE_HAS_BEEN_UNZIP, object: nil)
        }
        /// 删除老的文件夹下的JS文件，考虑到第一次集成LarkEditorJS pod库时，老的目录下可能还存在editor_kit.vendor.js文件，所以要清除沙盒中多余的文件
        removeAbandonedJSFilesIfNeeded()
    }

    private class func copyVersionFile() {
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: PathHelper.bundle.versionFilePath) {
                try fileManager.removeItem(atPath: PathHelper.bundle.versionFilePath)
            }
            if !fileManager.fileExists(atPath: PathHelper.bundle.larkEditorJSPath) {
                try? fileManager.createDirectory(atPath: PathHelper.bundle.larkEditorJSPath,
                                                 withIntermediateDirectories: true, attributes: nil)
            }
        } catch { (error)
            logInfo("EditorVendorJS.version copy fail \(PathHelper.bundle.versionFilePath)")
        }
    }

    /// 存放各业务方实际使用前端资源的文件夹
    static var executeFilesPath: String {
        return PathHelper.bundle.executeFilesPath
    }

    /// 获取vendor.js文件的真实路径
    public class func getJSPath() -> String {
        return  PathHelper.bundle.jsFilePath
    }

    /// 获取存放vendor.js, 小程序html，mail的html的文件夹路径
    public class func getExecuteJSPath() -> String {
        return PathHelper.bundle.executeFilesPath
    }
}

// MARK: Bundle resource
extension CommonJSUtil {
    private class func unzip() {
        let newZipFileInfo = newZipFileFormatAndPath
        guard let zipFormat = newZipFileInfo?.0 else {
            logInfo("zipFormat error")
            return
        }
        guard let zipPath = newZipFileInfo?.1, !zipPath.isEmpty else {
            logInfo("zipPath error")
            return
        }
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: PathHelper.bundle.larkEditorJSPath) {
            try? fileManager.createDirectory(atPath: PathHelper.bundle.larkEditorJSPath,
                                             withIntermediateDirectories: true, attributes: nil)
        }
        if fileManager.fileExists(atPath: PathHelper.bundle.executeFilesPath) {
            try? fileManager.removeItem(atPath: PathHelper.bundle.executeFilesPath)
        }
        let destPath = PathHelper.bundle.larkEditorJSPath
        switch zipFormat {
        case .zip:
            let result = SSZipArchive.unzipFile(atPath: zipPath, toDestination: destPath)
            if result == true {
                logInfo("editor_kit.vendor.js unzip success, zip")
            } else {
                logInfo("editor_kit.vendor.js unzip fail, zip")
            }
        case .archive_7z:
            do {
                let file = try LibArchiveFile(path: zipPath)
                try file.extract7z(toDir: URL(fileURLWithPath: destPath))
                logInfo("editor_kit.vendor.js unzip success, 7z")
            } catch { (error)
                logInfo("editor_kit.vendor.js unzip fail, 7z:\(error)")
            }
        }
    }

}

extension CommonJSUtil {
    /// 删除老的文件夹下的JS文件，考虑到第一次集成LarkEditorJS pod库时，老的目录下可能还存在editor_kit.vendor.js文件，所以要清除沙盒中多余的文件
    private class func removeAbandonedJSFilesIfNeeded() {
        DispatchQueue.global().async {
            let oldJSUnzipFolderPath = (libPath as NSString).appendingPathComponent("DocsSDK")
            let oldJSFilePath = oldJSUnzipFolderPath.appendingPathComponent(vendorJSFileName)
            let oldJSVerisonPath = oldJSUnzipFolderPath.appendingPathComponent(jsVersionFileName)
            removeFileIfExist(at: oldJSFilePath)
            removeFileIfExist(at: oldJSVerisonPath)
        }
    }

    private class func removeFileIfExist(at path: String) {
        let fileManager = FileManager.default
        let isJSFileExist = fileManager.fileExists(atPath: path)
        guard isJSFileExist else { return }

        do {
            logInfo("delete old file")
            try fileManager.removeItem(atPath: path)

        } catch { (error)
            logInfo("delete old file fail: \(error)")
        }
    }

    private class func logInfo(_ info: String) {
        CommonJSUtil.logger.info(info)
    }
}

