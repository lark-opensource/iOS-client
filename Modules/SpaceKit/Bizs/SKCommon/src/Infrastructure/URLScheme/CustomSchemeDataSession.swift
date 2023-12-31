//
//  CustomSchemeDataSession.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/9/4.
//

import UIKit
import RxSwift
import SKFoundation
import SpaceInterface
import SKInfra

public typealias WebRequestInterceptCallBack = (Data?, URLResponse?, Error?) -> Void

public protocol WebRequestInterceptHandleAble: AnyObject {
    func webRequestCanIntercept(urlString: String?) -> Bool
    func webRequestIntercept(urlString: String, completeHandle: WebRequestInterceptCallBack?)
}

extension WebRequestInterceptHandleAble {
    func webRequestCanIntercept(urlString: String?) -> Bool { return false }
}

public protocol CustomSchemeDataSessionDelegate: AnyObject {
    func session(_ session: CustomSchemeDataSession, didBeginWith newRequest: NSMutableURLRequest)
}

public final class CustomSchemeDataSession: NSObject {
    private static var intercepterMap = NSHashTable<AnyObject>(options: NSPointerFunctions.Options.weakMemory)
    private static let requestQueue = DispatchQueue(label: "com.docs.CustomSchemeDataSession")
    //Add和Remove必须成对出现
    public static func addIntercepter(_ intercepter: WebRequestInterceptHandleAble) {
        intercepterMap.add(intercepter)
    }
    public static func removeIntercepter(_ intercepter: WebRequestInterceptHandleAble) {
        intercepterMap.remove(intercepter)
    }
//    static func removeAllIntercepter() {
//        intercepterMap.removeAllObjects()
//    }

    let request: URLRequest
    lazy var downloader: DocCommonDownloadProtocol = DocsContainer.shared.resolve(DocCommonDownloadProtocol.self)!
    lazy var downloadCacheServive: SpaceDownloadCacheProtocol = DocsContainer.shared.resolve(SpaceDownloadCacheProtocol.self)!
    let disposeBag: DisposeBag = DisposeBag()
    let newCacheAPI: NewCacheAPI
    var downloadingDriveKey: String?

    var webviewWidth: CGFloat = 0
    var webIdentifyId: String?
    lazy var coverVariableFg: Bool = LKFeatureGating.coverVariableFg
    var sessionTask: DocsRequest<Any>?
    weak var sessionDelegate: CustomSchemeDataSessionDelegate?
    public var webviewUrl: URL?
    public var fileType: DocsType? /// 文档类型

    init(request: URLRequest, delegate: CustomSchemeDataSessionDelegate?, resolver: DocsResolver = DocsContainer.shared) {
        self.newCacheAPI = resolver.resolve(NewCacheAPI.self)!
        self.request = request
        self.sessionDelegate = delegate
        super.init()
    }

    func start(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var hasCustomtHandle = false
        CustomSchemeDataSession.intercepterMap.allObjects.forEach { (itemIntercepter) in
            guard hasCustomtHandle == false,
                let inter = itemIntercepter as? WebRequestInterceptHandleAble ,
                let urlString = self.request.url?.absoluteString,
                inter.webRequestCanIntercept(urlString: self.request.url?.absoluteString) else { return }
            DocsLogger.info("自定义拦截-URL")
#if DEBUG
            DocsLogger.debug("CustomSchemeDataSession Intercept: \(urlString.encryptToShort)")
#endif
            inter.webRequestIntercept(urlString: urlString, completeHandle: { (data, response, error) in
                if data == nil, error == nil { //容错
                    completionHandler(nil, response, NSError(domain: "data is nil", code: -1, userInfo: nil))
                } else {
                    completionHandler(data, response, error)
                }
            })
            hasCustomtHandle = true
        }
        guard hasCustomtHandle == false else { return }


        guard let originUrl = self.request.url else {
            DispatchQueue.global().async {
                let error = NSError(domain: "url error", code: -1, userInfo: nil)
                completionHandler(nil, nil, error)
            }
            spaceAssertionFailure()
            return
        }
#if DEBUG
        DocsLogger.debug("CustomSchemeDataSession start Intercept: \(originUrl.absoluteString.encryptToShort)")
#endif
        CustomSchemeDataSession.requestQueue.async {
            let isForWikiName = originUrl.path.contains("/api/wiki/tool")

            if DocsUrlUtil.isDriveImageUrl(originUrl.absoluteString), originUrl.absoluteString.contains("type=image") || originUrl.absoluteString.contains("mount_point") {
                self.downloadDriveFile(url: originUrl, completionHandler: completionHandler)
            } else if self.isDocsPic(url: originUrl.absoluteString) {
                self.downLoadPicByDocRequest(originUrl: originUrl, completionHandler: completionHandler)
            } else if let data = ResourceService.resource(url: originUrl, identifyId: self.webIdentifyId), !isForWikiName {
                DispatchQueue.global().async {
                    completionHandler(data, nil, nil)
                }
            } else {
                self.downLoadSourceByDocRequest(originUrl: originUrl, completionHandler: completionHandler)
            }
        }
    }

    private func downLoadSourceByDocRequest(originUrl: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        
        //预加载页面禁止下载，用fg控制直接返回，后续fg去掉，将回调和return整合到上面埋点上报一起
        if UserScopeNoChangeFG.HZK.forbidDownloadDuringPreloading {
            
            if URLValidator.isMainFrameTemplateURL(self.webviewUrl?.url) {
                //埋点上报
                JSFileDownloadStatistics.statisticsForbidDownloadJSFileTask(for: originUrl)
                DocsLogger.error("downLoadSource: Forbid downloading resources during preloading - \(originUrl)")
                //预加载的时候，禁止下载资源：走到这里请联系 juyou or zhikai
                skAssertionFailure("Forbid downloading resources during preloading - \(originUrl)")
                
                DispatchQueue.global().async {
                    let error = NSError(domain: "Forbid downloading resources during preloading", code: -1, userInfo: nil)
                    completionHandler(nil, nil, error)
                }
                return
            }
        }
        
        let requestModify = getModifyRequest(originUrl: originUrl)
        guard let request = requestModify else {
            DispatchQueue.global().async {
                let error = NSError(domain: "url error", code: -1, userInfo: nil)
                completionHandler(nil, nil, error)
            }
            spaceAssertionFailure()
            return
        }
        JSFileDownloadStatistics.statisticsDownloadJSFileTaskIfNeed(isStart: true, isSuccess: false, for: originUrl)
        request.setValue(DocsCustomHeaderValue.fromMobileWeb, forHTTPHeaderField: DocsCustomHeader.fromSource.rawValue)
        self.sessionDelegate?.session(self, didBeginWith: request)
        self.sessionTask = DocsRequest(request: request as URLRequest, trafficType: .docsFetch)
        self.sessionTask?.start(rawResult: { (data, response, error) in
            if let data = data, error == nil {
                if let httpRespnose = response as? HTTPURLResponse, httpRespnose.statusCode != 200, httpRespnose.statusCode != 304 {
                    DocsLogger.info("downLoadSource,token=\(DocsTracker.encrypt(id: request.url?.absoluteString ?? "")), response=\(httpRespnose)")
                    let rawError = NSError(domain: "docsource", code: httpRespnose.statusCode, userInfo: nil)
                    completionHandler(nil, nil, rawError)
                } else {
                    completionHandler(data, response, nil)
                }
            } else {
                DocsLogger.info("downLoadSource,token=\(DocsTracker.encrypt(id: request.url?.absoluteString ?? "")), response=\(String(describing: response)), error=\(String(describing: error))")
                completionHandler(nil, nil, error)
            }
        })
    }

    func getModifyRequest(originUrl: URL) -> NSMutableURLRequest? {
        var modifiedUrl = DocsUrlUtil.changeUrl(originUrl, schemeTo: OpenAPI.docs.currentNetScheme)
          modifiedUrl = DocsUrlUtil.changeUrlForNewDomain(modifiedUrl, webviewUrl: self.webviewUrl)

          guard let request = (self.request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
              return nil
          }
          request.url = modifiedUrl
          return request
    }

    private func isDocsPic(url: String?) -> Bool {
        return isReactionResImage(url: url) ||
        isNeedUploadImage(url: url) ||
        isContentNetWorkImage(url: url) ||
        isOtherDrivePic(url: url) ||
        isDocCoverImage(url: url)
    }

    // reaction图片
    private func isReactionResImage(url: String?) -> Bool {
        guard let url = url else { return false }
        let path: String = "/ee/lark-weekly-data/internal"
        return url.contains(path)
    }

    // 未同步图片
    private func isNeedUploadImage(url: String?) -> Bool {
        guard let url = url else { return false }
        let path: String = "com.bytedance.net/file/f/"
        return url.contains(path)
    }

    // 正文图片
    private func isContentNetWorkImage(url: String?) -> Bool {
        guard let url = url else { return false }
        let urlHost = URL(string: url)?.host ?? ""
        let domainPool = DomainConfig.validatedDomains
        let validDomain = domainPool.contains(where: { urlHost.contains($0) })
        let path: String = "/file/f/"
        return validDomain && url.contains(path)
    }

    // 其它类型drive图片（sheet里面的图片目前是这种格式图片）
    private func isOtherDrivePic(url: String?) -> Bool {
        guard let url = url else { return false }
        let path: String = "api/box/stream/download/v2/cover"
        return url.contains(path)
    }

    // 封面图片
    private func isDocCoverImage(url: String?) -> Bool {
        guard let url = url else { return false }
        let path: String = "/obj/creation-image-system/"
        return url.contains(path)
    }

    func getFileToken() -> String? {
        guard let webUrl = self.webviewUrl else {
            return nil
        }
        return DocsUrlUtil.getFileToken(from: webUrl)
    }

    func isOfflineToken() -> Bool {
        guard let token = getFileToken() else {
            return false
        }
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            return false
        }
        let manuOfflineTokens = dataCenterAPI.manualOfflineTokens
        let isOfflined = manuOfflineTokens.contain(objToken: token)
        return isOfflined
    }
 
    func stop() {
        self.sessionTask?.cancel()
        self.sessionTask = nil
        if let key = downloadingDriveKey {
            downloader.cancelDownload(key: key)
        }
    }
}
