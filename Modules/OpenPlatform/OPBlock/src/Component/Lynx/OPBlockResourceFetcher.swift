//
//  OPBlockResourceFetcher.swift
//  OPSDK
//
//  Created by 王飞 on 2021/6/9.
//

import Foundation
import Lynx
import LKCommonsLogging
import OPFoundation
import TTMicroApp
import LarkStorage
import LarkSetting
import OPBlockInterface
import OPSDK

/// 直接拍的 domain 和 code
private let resourceFetcherErrorDomain = "OPBlockResourceFetcher"
private let resourceFetcherErrorCode = -10

/// OPBlock 中 lynx 的统一的资源加载拦截
class OPBlockResourceFetcher: NSObject, LynxResourceFetcher {

    private let containerContext: OPContainerContext

    private var trace: BlockTrace {
        containerContext.blockTrace
    }

    init(containerContext: OPContainerContext) {
        self.containerContext = containerContext
        super.init()
    }

    func loadResource(with url: URL, type: LynxFetchResType, completion completionBlock: @escaping LynxResourceLoadCompletionBlock) -> () -> Void {

        guard OPUnsafeObject(completionBlock) != nil else {
            let msg = "resource fetch invoke without completionBlock"
            trace.error("OPBlockResourceFetcher.loadResource error: \(msg)")
            return {}
        }

        guard OPUnsafeObject(url) != nil else {
            let msg = "url for resource is nil"
            completionBlock(true, nil, resourceFetcherError(with: msg), url)
            trace.error("OPBlockResourceFetcher.loadResource error: \(msg)")
            return {}
        }

        let session = BDPNetworking.sharedSession()
        let dataTask = session.downloadTask(with: url) { (fileURL, _, error) in

            // 下载失败时，直接将下载错误的 error 返回
            if let err = error {
                completionBlock(false, nil, err, url)
                self.trace.error("OPBlockResourceFetcher.loadResource.downloadTask error: \(err.localizedDescription)")
                return
            }

            // 下载成功，但是本地并没有对应的文件
            guard let fileURL = fileURL else {
                let msg = "download failed, local url nonexist"
                completionBlock(false, nil, resourceFetcherError(with: msg), url)
                self.trace.error("OPBlockResourceFetcher.loadResource.downloadTask error: \(msg)")
                return
            }

            do {
                guard let absPath = AbsPath(url: fileURL) else {
                    let msg = "download failed, local url convert abspath failed"
                    completionBlock(false, nil, resourceFetcherError(with: msg), url)
                    self.trace.error("OPBlockResourceFetcher.loadResource.downloadTask error: \(msg)")
                    return
                }
                let data: Data = try Data.read(from: absPath)
                completionBlock(false, data, nil, url)
                self.trace.info("OPBlockResourceFetcher.loadResource.downloadTask info: resource download successful")
            } catch let err {
                completionBlock(false, nil, err, url)
                self.trace.error("OPBlockResourceFetcher.loadResource.downloadTask error: \(err.localizedDescription)")
            }
        }
        dataTask.resume()
        trace.info("OPBlockResourceFetcher.loadResource info: download begin url: \(String(describing: NSString.safeURL(url)))")
        return {
            dataTask.cancel()
            self.trace.info("OPBlockResourceFetcher.loadResource, info: download cancel, url: \(String(describing: NSString.safeURL(url)))")
        }
    }
}

/// 资源下载错误
/// - Parameter msg: 错误信息
private func resourceFetcherError(with msg: String) -> Error {
    NSError(
        domain: resourceFetcherErrorDomain,
        code: resourceFetcherErrorCode,
        userInfo: [
            NSLocalizedDescriptionKey: msg
        ]
    )
}
