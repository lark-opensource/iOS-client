//
//  MailSDK
//
//  Created by majx on 2019/6/20.
//

import Foundation
import WebKit
import RxSwift
import ByteWebImage
import LarkStorage

class RustSchemeTaskWrapper {
    weak var task: WKURLSchemeTask?
    var key: String? // 对应的下载key
    var webURL: URL?
    var msgID: String?
    var fileToken: String?
    var downloadChange: MailDownloadPushChange?
    var cancel: Bool = false
    var inlineImage: Bool = true
    var apmEvent: MailAPMEvent.MessageImageLoad?
    weak var loadImageMonitorDelegate: MailMessageListImageMonitorDelegate?
    init(task: WKURLSchemeTask?, webURL: URL?) {
        self.task = task
        self.webURL = webURL
    }
}

extension URL {
    /// 去除url中token敏感信息并进行 md5 脱敏
    var mailSchemeLogURLString: String {
        guard let scheme = MailCustomScheme(rawValue: scheme ?? "") else {
            return absoluteString.md5()
        }
        var logURL = absoluteString
        var shouldMD5 = true
        switch scheme {
        case MailCustomScheme.cid:
            // 去除后面的 msgToken
            var coms = absoluteString.components(separatedBy: "_msgToken")
            if coms.count > 1  {
                // 去掉后面拼接的msgToken
                coms.removeLast()
                logURL = coms.joined()
                let cidPrefix = "cid:"
                if logURL.starts(with: cidPrefix) {
                    logURL.removeFirst(cidPrefix.count)
                }
            }
        case MailCustomScheme.mailAttachmentIcon:
            shouldMD5 = false
            // 去除敏感文件名信息
            logURL = MailCustomScheme.mailAttachmentIcon.rawValue + ":" + NSString(string: absoluteString).pathExtension
        case .coverTokenThumbnail, .coverTokenFull, .template:
            // app预设的URL或者路径，不需要md5脱敏
            shouldMD5 = false
        case .token, .http, .https:
            break
        }
        return shouldMD5 ? "\(scheme.rawValue):md5_\(logURL.md5())" : logURL
    }
}

class URLSchemeTaskWrapper {
    weak var task: WKURLSchemeTask?
    var request: Any?
    
    var dataSession: MailSchemeDataSession? {
        return request as? MailSchemeDataSession
    }
    
    init(task: WKURLSchemeTask, dataSession: MailSchemeDataSession) {
        self.task = task
        self.request = dataSession
    }
    
    init(task: WKURLSchemeTask, requestTask: Any?) {
        self.task = task
        self.request = requestTask
    }
    
    init(task: WKURLSchemeTask) {
        self.task = task
        self.request = nil
    }
}

// MARK: - 处理 Mail 自定义协议
// iOS 11 以上系统使用本方法
// 兼容三方客户端 拦截缓存加载图片
@available(iOS 11.0, *)
class MailCustomSchemeHandler: NSObject, MailCustomSchemeHandling {

    /// 存储正在进行的所有请求
    private(set) var taskTable = NSMapTable<WKURLSchemeTask, URLSchemeTaskWrapper>.weakToStrongObjects()
    /// 任务出队开始下载时间

    var provider: MailSharedServicesProvider?

    init(provider: MailSharedServicesProvider?) {
        self.provider = provider
        super.init()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard MailCustomURLProtocolService.isSupportScheme(urlSchemeTask.request.url?.scheme) else {
            mailAssertionFailure("unsupported scheme \(urlSchemeTask.request.url?.scheme ?? "nil")")
            return
        }
            
        if let logUrl = urlSchemeTask.request.url?.mailSchemeLogURLString {
            let tid = (webView as? MailBaseWebViewAble)?.identifier ?? ""
            MailLogger.info("webview start url custom scheme task \(logUrl), t_id \(tid)")
        }

        if let url = urlSchemeTask.request.url,
           let scheme = url.scheme, scheme == MailCustomScheme.cid.rawValue,
           let superContainer = webView.superview as? MailMessageListView, superContainer.controller?.isMember(of: EmlPreviewViewController.self) == true {
            downloadAndCacheImgByEml(webView, start: urlSchemeTask)
        } else if let url = urlSchemeTask.request.url,
                  let scheme = url.scheme,
                  scheme == MailCustomScheme.template.rawValue {
            loadFileFromLocal(webView, start: urlSchemeTask)
        } else if shouldDownloadByRust(webView) {
            downloadAndCacheImgByRust(webView, start: urlSchemeTask)
        } else {
            downloadAndCacheImgByNative(webView, start: urlSchemeTask)
        }
    }

    func shouldDownloadByRust(_ webView: WKWebView) -> Bool {
        if Store.settingData.mailClient {
            if let superContainer = webView.superview as? MailMessageListView,
                  superContainer.controller?.isMember(of: MailMessageListController.self) == true,
               let statInfo = superContainer.controller?.statInfo {
                return statInfo.from != .chat
            } else if let view = webView as? MailNewBaseWebView, view.isSaasSig {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
    
    func loadFileFromLocal(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            mailAssertionFailure("Failed to get url from task")
            return
        }
        
        let taskWrapper = URLSchemeTaskWrapper(task: urlSchemeTask)
        taskTable.setObject(taskWrapper, forKey: urlSchemeTask)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let path = url.relativePath
            let fileURL = URL(fileURLWithPath: path)
            if let data = try? Data.read(from: fileURL.asAbsPath()) {
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    let response = URLResponse.mail.customImageResponse(urlSchemeTask: urlSchemeTask, originUrl: url, data: data)
                    if !self.sendResponseToTask(urlSchemeTask, response: response, data: data, dataDecorator: nil) {
                        MailLogger.error("Load template task removed, path: \(path)")
                    } else {
                        MailLogger.debug("Load template file from: \(path)")
                    }
                }
            } else {
                mailAssertionFailure("Failed to load script from file, path: \(path)")
            }
        }
    }

    func downloadAndCacheImgByRust(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let provider = provider else {
            mailAssertionFailure("[UserContainer] provider should not be nil in scheme handler")
            return
        }

        var cid = provider.imageService.imageAdapter.getCidFromUrl(urlSchemeTask.request.url)
        var msgId = provider.imageService.imageAdapter.getMsgIdFromUrl(urlSchemeTask.request.url)
        let tid = (webView as? MailBaseWebViewAble)?.identifier ?? ""
        
        let taskWrapper = URLSchemeTaskWrapper(task: urlSchemeTask)
        taskTable.setObject(taskWrapper, forKey: urlSchemeTask)

        /// 读信页附件icon
        if urlSchemeTask.request.url?.scheme == MailCustomScheme.mailAttachmentIcon.rawValue {
            let fileName = urlSchemeTask.request.url?.absoluteString ?? ""
            let iconImage = MailSendAttachment.fileLadderIcon(with: fileName)
            if let iconData = iconImage.pngData() {
                let defaultResponse = URLResponse(url: urlSchemeTask.request.url ?? URL(fileURLWithPath: fileName),
                                                  mimeType: fileName.extension,
                                                  expectedContentLength: iconData.count, textEncodingName: nil)
                sendResponseToTask(urlSchemeTask, response: defaultResponse, data: iconData, dataDecorator: nil)
                return
            }
        }

        let logUrl = urlSchemeTask.request.url?.mailSchemeLogURLString ?? ""
        let user = provider.user
        guard !cid.isEmpty && !msgId.isEmpty else {
            if let url = urlSchemeTask.request.url, url.absoluteString.contains("cid:") {
                if let data = provider.cacheService.object(forKey: MailImageInfo.getImageUrlCacheKey(urlString: url.absoluteString, userToken: user.token, tenantID: user.tenantID)) as? Data {
                    cid = url.absoluteString.replacingOccurrences(of: "cid:", with: "")
                    // 写信的拦截图片返回 根据cid从缓存 拿到文件data返回
                    MailLogger.info("[mail_client_image] webview mail download redirect -- logUrl: \(logUrl) msgid: \(msgId) t_id: \(tid) data: \(data.count)")
                    var imageType = data.mail.imageType
                    if imageType == .unknown {
                        // 异常case默认使用png
                        imageType = .png
                        MailLogger.error("[mail_client_image] webview image data type error")
                    }
                    let defaultResponse = URLResponse(url: url,
                                                      mimeType: imageType.description,
                                                      expectedContentLength: data.count, textEncodingName: nil)
                    sendResponseToTask(urlSchemeTask, response: defaultResponse, data: data, dataDecorator: MailNewCustomSchemeHandler.imgDataCompressorFor(tid: tid))
                } else if let draftInfo = provider.cacheService.object(forKey: "draft_\(url.absoluteString)") as? [String: String],
                          let draftId = draftInfo["draft_id"] {
                    msgId = draftId
                    if cid.isEmpty {
                        cid = url.absoluteString.replacingOccurrences(of: "cid:", with: "")
                    }
                    if let token = draftInfo["fileToken"], Store.settingData.getCachedCurrentAccount()?.protocol == .exchange {
                        cid = token
                    }
                    mailClientDownload(webView, cid: cid, msgId: msgId, tid: tid, urlSchemeTask: urlSchemeTask)
                } else {
                    MailLogger.error("vvImage webview mail download Empty Info -- logUrl: \(logUrl) msgid: \(msgId) t_id: \(tid)")
                }
            }
            return
        }

        mailClientDownload(webView, cid: cid, msgId: msgId, tid: tid, urlSchemeTask: urlSchemeTask)
    }

    private func mailClientDownload(_ webView: WKWebView, cid: String, msgId: String, tid: String, urlSchemeTask: WKURLSchemeTask) {
        guard let provider = provider else {
            mailAssertionFailure("[UserContainer] provider should not be nil in scheme handler")
            return
        }

        let superContainer = webView.superview as? MailMessageListView
        let logUrl = urlSchemeTask.request.url?.mailSchemeLogURLString ?? ""
        MailLogger.info("[mail_client_att] webview mail download logUrl: \(logUrl) msgid: \(msgId)")
        superContainer?.onWebViewStartURLSchemeTask(with: urlSchemeTask.request.url?.absoluteString)
        MailDataSource.shared.mailDownloadRequest(token: cid, messageID: msgId, isInlineImage: true)
            .subscribe(onNext: { [weak self] (resp) in
                // 接收push获取进度
                MailLogger.info("[mail_client_att] webview mail download resp key: \(resp.key)")
                if !resp.filePath.isEmpty {
                    // Rust Cache已下载该图片，直接返回展示
                    var path = resp.filePath
                    var data: Data?
                    if AbsPath(path).exists {
                        data = try? Data.read(from: AbsPath(path))
                    } else {
                        // 兜底
                        path = path.correctPath
                        data = try? Data.read(from: AbsPath(path))
                    }
                    if let data = data {
                        let user = provider.user
                        // 保存到cache，复制图片到draft时读取，新读信图片查看器使用
                        provider.cacheService.set(object: data as NSCoding, for: MailImageInfo.getImageUrlCacheKey(urlString: "cid:\(cid)", userToken: user.token, tenantID: user.tenantID))
                    }
                    let defaultResponse = URLResponse.mail.customImageResponse(urlSchemeTask: urlSchemeTask,
                                                                               originUrl: urlSchemeTask.request.url ?? URL(fileURLWithPath: path),
                                                                               data: data ?? Data())
                    // tea: 数据上报，从缓存返回图片数据
                    if let url = urlSchemeTask.request.url, let data = data {
                        superContainer?.onWebViewSetUpURLSchemeTask(with: url.absoluteString, fromCache: true)
                        superContainer?.onWebViewFinishImageDownloading(with: url.absoluteString,
                                                                        dataLength: data.count,
                                                                        finishWithDrive: false,
                                                                        downloadType: .rust)
                    }
                    self?.sendResponseToTask(urlSchemeTask, response: defaultResponse, data: data ?? Data(), dataDecorator: MailNewCustomSchemeHandler.imgDataCompressorFor(tid: tid))


                    MailLogger.info("[mail_client_att] webview mail download resp key: \(resp.key) resp db cache: \(resp.filePath)")
                } else {
                    let taskWrapper = RustSchemeTaskWrapper(task: urlSchemeTask, webURL: urlSchemeTask.request.url)
                    taskWrapper.key = resp.key
                    taskWrapper.msgID = msgId
                    taskWrapper.fileToken = cid
                    taskWrapper.inlineImage = true
                    taskWrapper.downloadChange = MailDownloadPushChange(status: .pending, key: resp.key)
                    MailLogger.info("[mail_client_att] webview mail download rustTaskTable accept resp key: \(resp.key) with pending")
                    // tea: 数据上报，开始下载
                    if let url = urlSchemeTask.request.url {
                        superContainer?.onWebViewSetUpURLSchemeTask(with: url.absoluteString, fromCache: false)
                        taskWrapper.loadImageMonitorDelegate = superContainer
                    }
                    provider.imageService.startDownTask((resp.key, taskWrapper))
                }
            }, onError: { (error) in
                MailLogger.info("[mail_client_att] webview mail download error: \(error)")
                if let url = urlSchemeTask.request.url {
                    superContainer?.onWebViewSetUpURLSchemeTask(with: url.absoluteString, fromCache: false)
                    let errorInfo: APMErrorInfo = (code: error.mailErrorCode, errMsg: error.getMessage() ?? "")
                    superContainer?.onWebViewImageDownloadFailed(with: url.absoluteString, finishWithDrive: false, downloadType: .rust, errorInfo: errorInfo)
                }
                urlSchemeTask.didFailWithError(error)
            }).disposed(by: provider.imageService.disposeBag)
    }

    func downloadAndCacheImgByEml(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        // if eml, use filePath
        guard let url = urlSchemeTask.request.url,
              let scheme = url.scheme, scheme == MailCustomScheme.cid.rawValue,
              let superContainer = webView.superview as? MailMessageListView else {
                  mailAssertionFailure("Not cid protocol in eml.")
                  return
              }

        let taskWrapper = URLSchemeTaskWrapper(task: urlSchemeTask)
        taskTable.setObject(taskWrapper, forKey: urlSchemeTask)
        
        let replacedCid = provider?.imageService.htmlAdapter.getReplacedCidFromSrc(url.absoluteString)
        let tid = (webView as? MailBaseWebViewAble)?.identifier ?? ""
        if let replacedCid = replacedCid,
           let image = superContainer.viewModel?.cidImageMap[replacedCid],
           !image.filePath.isEmpty {
            DispatchQueue.global().async { [weak self] in
                do {
                    let data = try Data.read(from: URL(fileURLWithPath: image.filePath).asAbsPath())
                    DispatchQueue.main.async {
                        let response = URLResponse.mail.customImageResponse(urlSchemeTask: urlSchemeTask, originUrl: url, data: data)
                        self?.sendResponseToTask(urlSchemeTask, response: response, data: data, dataDecorator: MailNewCustomSchemeHandler.imgDataCompressorFor(tid: tid))
                    }
                } catch {
                    DispatchQueue.main.async {
                        mailAssertionFailure("eml image filePath error: \(error)")
                        self?.sendErrorToTask(urlSchemeTask, error: error)
                    }
                }
            }
        } else {
            mailAssertionFailure("eml image filePath empty")
            let response = URLResponse.mail.customImageResponse(urlSchemeTask: urlSchemeTask, originUrl: url, data: Data())
            self.sendResponseToTask(urlSchemeTask, response: response, data: Data(), dataDecorator: nil)
        }
    }

    func downloadAndCacheImgByNative(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let superContainer = webView.superview as? MailMessageListView
        let tid = (webView as? MailBaseWebViewAble)?.identifier ?? ""
        let dataSession = MailSchemeDataSession(request: urlSchemeTask.request, delegate: self, readMailThreadID: tid)
        dataSession.webviewUrl = webView.url
        dataSession.webviewWidth = webView.frame.width
        let taskWrapper = URLSchemeTaskWrapper(task: urlSchemeTask, dataSession: dataSession)
        taskTable.setObject(taskWrapper, forKey: urlSchemeTask)

        superContainer?.onWebViewStartURLSchemeTask(with: urlSchemeTask.request.url?.absoluteString)
        dataSession.imageLogHandler = { [weak superContainer] logInfo in
            var fromCache = false
            if let tokenInfo = logInfo.fileTokenInfo {
                fromCache = tokenInfo.fileTokenResult == .cache
                if let webView = webView as? MailBaseWebViewAble, let superContainer = webView.weakRef.superContainer as? MailMessageListPageCell {
                    superContainer.mailMessageListView?.startDownloadTokenImage(token: tokenInfo.fileToken, result: tokenInfo.fileTokenResult)
                }
            } else {
                superContainer?.startDownloadCidImage(url: logInfo.originURLString)
            }
            superContainer?.onWebViewSetUpURLSchemeTask(with: logInfo.originURLString, fromCache: fromCache)
        }
        let urlString = urlSchemeTask.request.url?.absoluteString
        dataSession.downloadProgressHandler = { [weak superContainer] (urlString) in
            superContainer?.downloadProgessHandler(url: urlString)
        }
        dataSession.inflightCallback = { [weak superContainer, weak self] in
            guard let self = self,
                  let urlString = urlString,
                  let viewController = superContainer?.controller
            else { return }
            // 记录开始下载时间点，用于tea上报
            superContainer?.onWebViewImageDownloading(with: urlString)
            viewController.callJavaScript("window.onImageStartDownloading('\(urlString)')")
        }
        let isMessagePage = superContainer != nil
        var finishWithDrive = false
        let image = getImage(with: urlSchemeTask.request.url?.absoluteString, superContainer: superContainer)
        dataSession.start(isSendMail: superContainer == nil,
                          image: image,
                          finishWithDrive: &finishWithDrive) { (data1, response, error, downloadType) in
            DispatchQueue.main.async { [weak self, weak superContainer, weak urlSchemeTask] in
                guard let self = self else {
                    MailLogger.info("MailCustomSchemeHandler deinit")
                    return
                }
                guard let urlSchemeTask = urlSchemeTask else {
                    MailLogger.info("MailCustomSchemeHandler start urlSchemeTask hasbeen release")
                    return
                }
                let logURL = urlSchemeTask.request.url?.mailSchemeLogURLString ?? ""
                MailLogger.info("webview start url custom scheme task finish tid: \(tid), url:\(logURL)")

                defer {
                    self.taskTable.removeObject(forKey: urlSchemeTask)
                }

                if let error = error {
                    var logMessage = ""
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                        logMessage += " s-\(statusCode)"
                    }

                    logMessage += " e-\(error.mailErrorCode)"
                    self.sendErrorToTask(urlSchemeTask, error: error)

                    if isMessagePage {
                        if let url = urlString { // 下载失败场景上报到tea，成功会在前端回调imageOnLoad上报
                            let debugMessage = (error as? MailURLError)?.errorMessage ?? error.underlyingError.localizedDescription
                            let errorInfo: APMErrorInfo = (code: error.mailErrorCode, errMsg: "\(debugMessage);\(logMessage)")
                            superContainer?.onWebViewImageDownloadFailed(with: url, finishWithDrive: finishWithDrive,  downloadType: downloadType, errorInfo: errorInfo)
                        }
                        // slardar 处理读信页图片加载错误打点
                        let debugMessage = (error as? MailURLError)?.errorMessage ?? error.underlyingError.localizedDescription
                        logMessage += ",\(debugMessage)"
                    }

                    var encryptedToken = ""
                    if let token = image?.fileToken, !token.isEmpty {
                        encryptedToken = token.md5()
                    }
                    MailLogger.error("webview start url custom scheme task error tid: \(tid), url:\(logURL), token: \(encryptedToken) \(error.underlyingError.localizedDescription), \(logMessage)")
                } else {
                    guard let data = data1, let originUrl = urlSchemeTask.request.url else {
                        mailAssertionFailure("fail to get data or url")
                        return
                    }
                    superContainer?.downloadImgSuccessHandler(url: originUrl.absoluteString)
                    superContainer?.onWebViewFinishImageDownloading(with: originUrl.absoluteString,
                                                                    dataLength: data.count,
                                                                    finishWithDrive: finishWithDrive,
                                                                    downloadType: downloadType)
                    let response = response ?? URLResponse.mail.customImageResponse(urlSchemeTask: urlSchemeTask,
                                                                                    originUrl: originUrl, data: data)
                    var dataCompressor: ((Data) -> Data)?
                    if originUrl.scheme == MailCustomScheme.cid.rawValue {
                        dataCompressor = MailNewCustomSchemeHandler.imgDataCompressorFor(tid: tid)
                    }
                    self.sendResponseToTask(urlSchemeTask,
                                            response: response,
                                            data: data,
                                            dataDecorator: dataCompressor)
                }
            }
        }
    }
    
    private func getImage(with urlString: String?, superContainer: MailMessageListView?) -> MailClientDraftImage? {
        guard let url = urlString else {
            MailLogger.info("MailCustomSchemeHandler no request url")
            return nil
        }
        guard let superContainer = superContainer else {
            MailLogger.info("MailCustomSchemeHandler has no super container")
            return nil
        }
        guard let provider = provider else {
            mailAssertionFailure("[UserContainer] provider should not be nil in scheme handler")
            return nil
        }
        let replacedCid = provider.imageService.htmlAdapter.getReplacedCidFromSrc(url)
        guard !replacedCid.isEmpty else {
            MailLogger.info("MailCustomSchemeHandler cannot get cid from url")
            return nil
        }
        return superContainer.viewModel?.cidImageMap[replacedCid]
    }

    @available(iOS 11.0, *)
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        MailLogger.info("MailCustomSchemeHandler stop urlSchemeTask")
        let schemeTaskWrapper = self.taskTable.object(forKey: urlSchemeTask)
        schemeTaskWrapper?.task = nil
        schemeTaskWrapper?.dataSession?.stop()
        taskTable.removeObject(forKey: urlSchemeTask)
    }
}

@available(iOS 11.0, *)
extension MailCustomSchemeHandler: MailSchemeDataSessionDelegate {
    func session(_ session: MailSchemeDataSession, didBeginWith newRequest: NSMutableURLRequest) {
    }
}
