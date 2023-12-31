//
//  TTGeckoModel.swift
//  SpaceKit
//
//  Created by Webster on 2019/12/6.
//

import Foundation
import IESGeckoKit
import OfflineResourceManager
import SKFoundation

public typealias GeckoFetchSingleFinishBlock = (Bool, GeckoFetchResult) -> Void

public struct GeckoFetchResult {
    public var config: GeckoBizConfig
    public var syncStatus: OfflineResourceStatus
    public var isSuccess: Bool {
        return syncStatus == OfflineResourceStatus.ready
    }
    public init(config: GeckoBizConfig, status: OfflineResourceStatus) {
        self.config = config
        self.syncStatus = status
    }
}

public struct GeckoBizConfig {
    public var identifier: String
    public var accessKey: String
    public var channel: String
    public init(identifier: String, key: String, channel: String) {
        self.identifier = identifier
        self.accessKey = key
        self.channel = channel
    }
}


/// 资源包的来源
public enum ResourceSource {
    case bundleFull /**app里面的bundle*/
    case bundleSlim /**app里面的bundle，但是是精简包*/
    case fullPkg   /** app内嵌的精简包指定的完整包，网络下载得到*/
    case hotfix /**gecko热更*/
    case specialFull /**指定资源包*/
    case specialSlim /**指定资源包*/
    case grayscaleFull /*灰度资源包*/
    case grayscaleSlim /*灰度资源包*/

    public var name: String {
        switch self {
        case .bundleFull:
            return "内嵌完整包"
        case .bundleSlim:
            return "内嵌精简包"
        case .fullPkg:
            return "内嵌精简包的完整包"
        case .hotfix:
            return "gecko热更包"
        case .specialFull:
            return "指定完整包"
        case .specialSlim:
            return "指定精简包"
        case .grayscaleFull:
            return "灰度完整包"
        case .grayscaleSlim:
            return "灰度精简包"
        }
    }


    /// 获取对应类型包的三个路径，注意，在不同的阶段，各个路径下可能都没有文件, 调用这个方法是为了获取下载对应的完整包，所以精简包类型就返回了空字符串
    func pkgPathInfo() -> (downloadZipFolderPath: SKFilePath, tempUnzipFolderPath: SKFilePath, downloadRootPath: SKFilePath) {
        let downloadZip = "fullPkgDownloadZip"
        let tempUnzip = "fullPkgTempUnzip"
        let emptyPath = SKFilePath.absPath("")
        switch self {
        case .bundleFull, .bundleSlim, .hotfix, .specialSlim, .grayscaleSlim:
            return (emptyPath, emptyPath, emptyPath)
        case .fullPkg:
            let dlZipFolderPath = GeckoPackageManager.Folder.fullPkgZipDownloadPath(channel: nil)
            let unzipFolderPath = GeckoPackageManager.Folder.fullPkgUnzipPath(channel: nil)
            let dlRootPath = GeckoPackageManager.Folder.fullPkgDownloadRootPath(channel: nil)
            guard !dlZipFolderPath.pathString.isEmpty,
                  !unzipFolderPath.pathString.isEmpty,
                  !dlRootPath.pathString.isEmpty
            else {
                    return (emptyPath, emptyPath, emptyPath)
            }
            return (dlZipFolderPath, unzipFolderPath, dlRootPath)
        case .specialFull:
            let downloadZipPath = SpecialVersionResourceService.customResourceZipStr.appendingRelativePath(downloadZip)
            let unzipPath = SpecialVersionResourceService.unZipTempPath.appendingRelativePath(tempUnzip)
            return (downloadZipPath, unzipPath, emptyPath)
        case .grayscaleFull:
            let dlRootPath = GeckoPackageManager.Folder.grayscalePkgDownloadRootPath(channel: nil)
            guard !dlRootPath.pathString.isEmpty else {
                return (emptyPath, emptyPath, emptyPath)
            }
            let downloadZipPath = dlRootPath.appendingRelativePath(downloadZip)
            let unzipPath = dlRootPath.appendingRelativePath(tempUnzip)
            return (downloadZipPath, unzipPath, dlRootPath)

        }
    }
}

public struct  OfflineResourceLocator {
    //离线资源包的来源
    public var source: ResourceSource = .bundleFull
    //资源的根目录
    public var rootFolder: SKFilePath = SKFilePath(absPath: "")
    //资源版本号
    public var version: String = "1.0.0.0"

    /// 是否是精简包
    public var isSlim: Bool = false

    public var channel: GeckoPackageAppChannel = .unknown

    public func equalTo(another: OfflineResourceLocator) -> Bool {
        return self.source == another.source
            && self.rootFolder == another.rootFolder
            && self.version == another.version
            && self.isSlim == another.isSlim
    }
}

public struct OfflineResourceZipInfo {

    public struct CurVersionInfo {
        /// 下面几个字段是精简包才有的
        // https://bytedance.feishu.cn/docs/doccncAqXh9MJ3R9vWoq6zspvvg#ggf4E6
        public var version = "unknow" // 这个字段先冗余出来
        var isSlim = false
        /// 完整包版本号
        public var fullPkgScmVersion = "unknow"
        /// 完整包国内url
        var fullPkgUrlHome = ""
        /// 完整包海外url
        var fullPkgUrlOversea = ""

        var channel: GeckoPackageAppChannel = .unknown

        var isExist: Bool {
            return version != "unknow" && !version.isEmpty
        }
    }
    var usingZip = true
    var originalFullPath = SKFilePath.absPath("")
    var originalBaseFolder = SKFilePath.absPath("")
    var zipFileFullPath = SKFilePath.absPath("")
    public var zipFileBaseFolder = SKFilePath.absPath("")
    var zipName = ""
    var version = "unknow"
    var pathName = ""
//    var curVersionInfo = CurVersionInfo()

    var isVaild: Bool {
        if version == "unknow" { return false }
        if usingZip { return !zipFileFullPath.pathString.isEmpty }
        if !usingZip { return !originalFullPath.pathString.isEmpty }
        return true
    }
    var channelName: String {
        return usingZip ? zipNameWithoutSuffix : pathName
    }
    var zipNameWithoutSuffix: String {
        guard let dotLocation = zipName.firstIndex(of: ".") else { return zipName }
        return String(zipName.prefix(upTo: dotLocation))
    }

    /// 获取bundle内嵌包信息，返回的是从bundle里得到的信息
    public static func info(by channel: DocsChannelInfo) -> OfflineResourceZipInfo {
        var info = OfflineResourceZipInfo()
        info.zipName = channel.zipName
        guard let resourceBundle = GeckoPackageManager.bundle(from: channel.path) else {
            let msg = "找不到\(channel.type.channelName())的bundle"
            spaceAssertionFailure(msg)
            GeckoLogger.info(msg)
            return info
        }
        let pathBase = GeckoPathBase.pathWithString(pathInfo: channel.path)
        info.pathName = pathBase.path
        let formats = BundlePackageExtractor.Format.allCases
        let suffixMatch = formats.contains(where: { channel.zipName.hasSuffix($0.fileExtension) })
        if suffixMatch {
            let path = resourceBundle.bundlePath + pathBase.path
            let absPath = SKFilePath(absPath: path)
            info.zipFileBaseFolder = absPath
            info.zipFileFullPath = absPath.appendingRelativePath(channel.zipName)
            info.version = GeckoPackageManager.Folder.revision(in: absPath) ?? "unknow"
            info.usingZip = true
        } else {
            let bundlePath = SKFilePath(absPath: resourceBundle.bundlePath)
            info.originalBaseFolder = bundlePath
            let path = bundlePath.appendingRelativePath(pathBase.path)
            info.originalFullPath = path
            info.version = GeckoPackageManager.Folder.revision(in: path) ?? "unknow"
            info.usingZip = false
        }
        return info
    }
}
