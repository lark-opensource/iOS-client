//
//  OPBlockWebRender+OfflineResource.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/4/2.
//

import Foundation
import WebBrowser
import ECOInfra
import OPSDK
import EENavigator
import TTMicroApp
import OPBlockInterface

// web离线加载能力
extension OPBlockWebRender: OfflineResourceProtocol {

    /// 是否需要拦截请求
    /// - Returns: 是否拦截
    func browserCanIntercept(browser: WebBrowser, request: URLRequest) -> Bool {
        guard let url = request.url else {
            context.containerContext.trace?.error("web render resource can intercept: invalid request url",
                                                  additionalData: ["uniqueID": context.containerContext.uniqueID.fullString])
            return false
        }
        guard let blockMeta = context.containerContext.meta as? OPBlockMeta else {
            context.containerContext.trace?.error("web render resource can intercept: invalid meta type",
                                                  additionalData: ["uniqueID": context.containerContext.uniqueID.fullString])
            return false
        }
        guard blockMeta.extConfig.pkgType == .offlineWeb else {
            context.containerContext.trace?.error("web render resource can intercept: invalid block type",
                                                  additionalData: ["uniqueID": context.containerContext.uniqueID.fullString,
                                                                   "blockType": blockMeta.extConfig.pkgType.rawValue])
            return false
        }
        context.containerContext.trace?.info("request can intercept",
                                             additionalData: ["uniqueID": context.containerContext.uniqueID.fullString,
                                                              "vhost": blockMeta.extConfig.vHost,
                                                              "url": url.safeURLString])
        return url.absoluteString.starts(with: blockMeta.extConfig.vHost)
    }

    /// 返回请求资源
    func browserFetchResources(browser: WebBrowser, request: URLRequest, completionHandler: @escaping (Result<(URLResponse, Data), Error>) -> Void) {
        context.containerContext.trace?.info("web render fetch offline resource",
                                             additionalData: ["requestURL": request.url?.safeURLString ?? "nil",
                                                              "uniqueID":  context.containerContext.uniqueID.fullString])
        guard let url = request.url else {
            let error = OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail, message: "invalid request url")
            completionHandler(Result.failure(error))
            return
         }
        do {
            let (path, fullPath) = try getOfflineURLPath(url: url)
            let data = try packageReader.syncRead(file: path)
            let response = URLResponse(url: url,
                                           mimeType: BDPMIMETypeOfFilePath(fullPath),
                                           expectedContentLength: data.count,
                                           textEncodingName: nil)
            completionHandler(Result.success((response, data)))
        } catch {
            context.containerContext.trace?.error("web render fetch offline resource fail", error: error)
            completionHandler(Result.failure(error))
        }
    }

    private func getOfflineURLPath(url: URL) throws -> (reletivePath: String, absolutePath: String) {
        // 不是vhost下的离线资源请求不支持读包数据
        guard let blockMeta = context.containerContext.meta as? OPBlockMeta,
              !blockMeta.extConfig.vHost.isEmpty,
              url.absoluteString.hasPrefix(blockMeta.extConfig.vHost) else {
            throw OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail, message: "invalid meta/vhost/request")
        }
        // reader类型
        guard let reader = packageReader as? BDPPackageUncompressedFileHandle else {
            throw OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail, message: "invalid package reader")
        }
        // 去掉query和fragment
        var path = url.withoutQueryAndFragment
        // 去掉host，提取path
        path = String(path.dropFirst(blockMeta.extConfig.vHost.count))
        // 规范路径，防止逃逸
        let standardPath = (path as NSString).standardizingPath
        // 仅允许包路径下的文件访问
        let pkgDir = reader.pkgDirPath()
        let fullPath = (pkgDir as NSString).appendingPathComponent(standardPath)
        if FileSystemUtils.isSubpath(src: pkgDir, dest: fullPath) {
            return (standardPath, fullPath)
        } else {
            throw OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail, message: "file path not in pkgDir")
        }
    }

}
