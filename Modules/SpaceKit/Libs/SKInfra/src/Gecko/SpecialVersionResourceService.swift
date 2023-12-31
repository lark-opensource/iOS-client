//
//  SpecialVersionResourceService.swift
//  SpaceKit
//
//  Created by Webster on 2018/12/9.
//

//强制使用前端指定的离线资源包
import Foundation
import SSZipArchive
import EENavigator
import SKUIKit
import SKFoundation
import UniverseDesignToast
extension GeckoChannleType {

    ///资源包解压出来的文件夹名字，就是前端资源包的channel，以后新增channel统计在此处新增
    /// 从设计的角度，应该定义在SpaceKit之外，由业务方传入的，但是为了方便统一管理，还是写到一处吧
    /// - Returns:
    func unzipFolder() -> String {
        switch self {
        case .webInfo:
            let curChannel = GeckoPackageManager.shared.currentUsingAppChannel
            if curChannel == .unknown {
                GeckoLogger.error("GeckoPackageManager.currentUsingAppChannel 未被初始化就调用了，不应该发生, 如果新增了类型，要做适配")
                return SKFoundationConfig.shared.isInLarkDocsApp ? GeckoPackageAppChannel.docs_app.rawValue : GeckoPackageAppChannel.docs_channel.rawValue
            }
            return curChannel.rawValue
        case .bitable:
            return "bitable"
        default:
            return "unknow"
        }
    }
}

public final class SpecialVersionResourceService {

    ///zip包下载存放的路径 ~/Library/Caches/CustomResource/SPECIAL_PATH/xxx.zip
    static let customResourceZipStr = SKFilePath.globalSandboxWithCache.appendingRelativePath("CustomResource")
    ///zip包的解压存放路径 ~/Library/Caches/CustomResourceTemp/
    static let unZipTempPath = SKFilePath.globalSandboxWithCache.appendingRelativePath("CustomResourceTemp")
    ///最终提供资源访问的路径 ~/Library/DocsSDK/CustomResourceService/SPECIAL_PATH
    static var customRoot = SKFilePath.globalSandboxWithLibrary.appendingRelativePath("CustomResourceService")
    private static let specialVerKey = "com.bytedance.ee.docssdk.specialVer"

    class func isUsingSpecial(_ type: GeckoChannleType) -> Bool {
        return version(type) != nil
    }

    class func resPath(_ type: GeckoChannleType) -> SKFilePath {
        let path = SpecialVersionResourceService.customRoot
        return path
    }

    class func version(_ type: GeckoChannleType) -> String? {
        let key = storeKey(type)
        return CCMKeyValue.globalUserDefault.string(forKey: key)
    }

    public class func updateVersion(_ version: String?, type: GeckoChannleType) {
        let key = storeKey(type)
        CCMKeyValue.globalUserDefault.set(version, forKey: key)
    }
    
    public class func isUseSimplePackage() -> Bool {
        return SKInfraConfig.shared.isUseSimplePackage
    }

    public class func updateIsUseSimplePackage(on: Bool, onView: UIView) {
        UDToast.docs.showMessage("重启生效", on: onView, msgType: .tips)
        CCMKeyValue.globalUserDefault.set(on, forKey: UserDefaultKeys.isUseSimplePackage)
    }

}

////////////////// 以下所有的替换逻辑来自 OfflineSyncManager //////////////////
extension SpecialVersionResourceService {

    public class func setCustomResource(_ type: GeckoChannleType, version: String, msgOnView: UIView, successHandle: ((Bool) -> Void)?) {
        let downloadPath = zipDownloadPath(type, version: version)
        let releasePath = resDestinationPath(type)
        if downloadPath.exists {
            unZipResource(from: downloadPath, to: releasePath, with: version, by: type, msgOnView: msgOnView, successHandle)
        } else {
            downloadCustomResource(version: version, type: type, msgOnView: msgOnView) { response in
                UDToast.removeToast(on: msgOnView)
                if response?.statusCode == 200 {
                    unZipResource(from: downloadPath, to: releasePath, with: version, by: type, msgOnView: msgOnView, successHandle)
                } else if response?.statusCode == 404 {
                    successHandle?(false)
                
                    UDToast.docs.showMessage("下载资源包出错,没有该资源包", on: msgOnView, msgType: .failure)
                } else {
                    successHandle?(false)
                    let msg = "下载资源包出错,错误码\(String(describing: response?.statusCode ?? 0) )"
                    UDToast.docs.showMessage(msg, on: msgOnView, msgType: .failure)
                }
            }
        }
    }

    private class func unZipResource(from zipPath: SKFilePath,
                                     to dstPath: SKFilePath,
                                     with version: String,
                                     by channel: GeckoChannleType,
                                     msgOnView: UIView,
                                     _ successHandle: ((Bool) -> Void)?) {
        //清空临时解压路径
        if unZipTempPath.exists {
            do { try unZipTempPath.removeItem() } catch { }
        }

        try? dstPath.createDirectory(withIntermediateDirectories: true)

        //清空最终替换的文件夹
        if dstPath.exists {
            do { try dstPath.removeItem() } catch { }
        }
        UDToast.docs.showMessage("正在解压前端资源包", on: msgOnView, msgType: .tips)
        //解压zip到临时目录
        SSZipArchive.unzipFile(atPath: zipPath.pathString, toDestination: unZipTempPath.pathString)
        UDToast.removeToast(on: msgOnView)
        let unzipResRootPath = unZipTempPath.appendingRelativePath(channel.unzipFolder())
        //生成下plist文件
        GeckoLogger.info("custom pkg - create plist：\(unzipResRootPath)")
        let dic = GeckoPackageManager.shared.createFilePathsPlist(at: unzipResRootPath)
        GeckoLogger.info("custom pkg - plist count：\(dic?.count ?? 0)")
        replaceResource(atPath: unzipResRootPath, toPath: dstPath) { success in
            if success {
                let alert = UIAlertController(title: "替换资源成功", message: "当前资源包版本：\(version)，请重新打开app", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { (_) in
                    successHandle?(true)
                }))
                if let rootVC = msgOnView.window?.rootViewController,
                   let vc = UIViewController.docs.topMost(of: rootVC) {
                    Navigator.shared.present(alert, from: vc)
                }
                updateVersion(version, type: channel)
            } else {
                UDToast.docs.showMessage("替换资源包时出错", on: msgOnView, msgType: .failure)
                successHandle?(false)
            }
        }
    }

    private class func replaceResource(atPath currentStr: SKFilePath, toPath destination: SKFilePath, successHandle: ((Bool) -> Void)?) {
        if currentStr.exists {
            do {
                try currentStr.moveItem(to: destination)
                successHandle?(true)
            } catch {
                successHandle?(false)
            }
        } else {
            successHandle?(false)
        }
    }

    private class func downloadCustomResource(version: String,
                                              type: GeckoChannleType,
                                              msgOnView: UIView,
                                              completionHandler: ((HTTPURLResponse?) -> Void)?) {
        let downloadLink = downloadURL(type: type, version: version)
        guard let sourceUrl = URL(string: downloadLink) else { return }
        let fileURL = zipDownloadPath(type, version: version) // URL(fileURLWithPath: zipDownloadPath(type, version: version).absoluteString, isDirectory: true)
        UDToast.docs.showMessage("下载中", on: msgOnView, msgType: .loading)
        downloadResZip(by: sourceUrl, to: fileURL, type: type, completionHandler: completionHandler)
    }
    
    /// 使用rust下载在boe环境会有502问题，本方法仅仅用于下载自定义资源包
    private class func downloadResZip(by url: URL, to: SKFilePath, type: GeckoChannleType, completionHandler: ((HTTPURLResponse?) -> Void)?) {
        let task = URLSession.shared.downloadTask(with: url) { (localUrl, response, error) in
            if let path = localUrl?.path, !path.isEmpty, SKFilePath(absPath: path).exists {
                do {
                    GeckoLogger.info("try to move special resource zip from: \(path) to: \(to.pathString)")
                    let folder = zipDownloadFolder(type)
                    if !folder.exists {
                        try folder.createDirectoryIfNeeded(withIntermediateDirectories: true)
                    }
                    try to.moveItemFromUrl(from: URL(fileURLWithPath: path, isDirectory: true))
                    DispatchQueue.main.async {
                        completionHandler?(response as? HTTPURLResponse)
                    }

                } catch {
                    GeckoLogger.error("move special resource error: \(error)")
                }
            }
            
        }
        task.resume()
    }

    private class func downloadURL(type: GeckoChannleType, version: String) -> String {
        /*
         1、3.34之前，前端包上传到tos平台时，对应zip的url类似：http://.../scm_zip/22513/ios/docs_channel.zip, 对应的前端包版本号是1.0.1.22513
         2、3.34及之后，这个url变成了：http://.../scm_zip/1_0_2_8/ios/docs_channel.zip，对应的前端包版本号是1.0.2.8
         当时定方案，说url中path中有"."是不规范的，所以改成下划线了，下面的写法为了兼容老版本的包也能下载到
         */
        var newVersion = version
        if version.contains(".") {
            newVersion = version.replacingOccurrences(of: ".", with: "_")
        }
        // 这个名字是docs_channel，前端历史使用的都是这个，如果变更，要考虑热更包在老版本的兼容问题
        let folderName = GeckoChannleType.webInfo.unzipFolder()
        let url = "http://tosv.byted.org/obj/bytedance-oss-bear-web-test/scm_zip/\(newVersion)/ios/\(folderName).zip"
        return url
    }

    /// 版本号存储的key
    ///
    /// - Parameter type: gecko channel
    /// - Returns: 存储key
    private class func storeKey(_ type: GeckoChannleType) -> String {
        return specialVerKey + type.unzipFolder()
    }

    /// 资源包的下载路径
    ///
    /// - Parameter channel: channel名
    private class func zipDownloadPath(_ type: GeckoChannleType, version: String) -> SKFilePath {
        let path = zipDownloadFolder(type).appendingRelativePath("\(version).zip")
        return path
    }
    
    private class func zipDownloadFolder(_ type: GeckoChannleType) -> SKFilePath {
        return customResourceZipStr.appendingRelativePath(type.unzipFolder())
    }

    /// 最终资源的存放路径
    ///
    /// - Parameter type: gecko的channel
    /// - Returns: 解压路径
    private class func resDestinationPath(_ type: GeckoChannleType) -> SKFilePath {
        let path = SpecialVersionResourceService.customRoot.appendingRelativePath(type.unzipFolder())
        return path
    }
}
