//
//  WebBrowser+DriveDownload.swift
//  WebBrowser
//
//  Created by Ding Xu on 2022/7/18.
//

import Foundation
import LKCommonsLogging
import WebKit
import LarkSetting
import LarkWebViewContainer
import ECOProbe
import LarkUIKit
import EENavigator
import LarkStorage
import UniverseDesignToast
import UniverseDesignEmpty
import LarkSceneManager
import ECOInfra

public let OPWebBrowserDriveAppID = "1005"

// MARK: WebBrowser+DriveDownload
extension WebBrowser {
    public func isDownloadPreviewMode() -> Bool {
        guard webDriveDownloadPreviewEnable() else {
            return false
        }
        guard extensionManager.resolve(WebDownloadExtensionItem.self) != nil else {
            return false
        }
        return true
    }
    
    /// 网页容器端内下载预览内嵌视图方案开关
    func webDriveDownloadPreviewEnable() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.download.preview"))// user:global
    }
    
    /// 网页容器端内下载预览新页面方案开关
    static func webDrivePreviewEnhancedEnable() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.download.preview_enhanced"))// user:global
    }
    
    /// 端内下载drive预览空白页消除的开关，7.10稳定后可删除
    func closeBlankEnable() -> Bool {
        return OPUserScope.userResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.drivedownload.closeblank"))
    }
    
    func filename2FileExtension(filename: String) -> String? {
        let components = filename.components(separatedBy: ".")
        if components.count > 1, let last = components.last, !last.isEmpty {
            return last
        }
        return nil
    }
    
    func mime2FileExtension(mime: String) -> String? {
        guard let mimeFileType = LarkWebSettings.shared.settingsModel?.downloads?.mime_file_type else {
            return nil
        }
        guard let typeStr = mimeFileType[mime] else {
            return nil
        }
        return typeStr.components(separatedBy: ",").first
    }
    // 优先取filename, 否则降级取MIME对应文件类型, 否则返回空
    public func fileExtension(filename: String?, mime: String?) -> String? {
        if let filename = filename, let fileExtension = filename2FileExtension(filename: filename) {
            return fileExtension
        }
        if let mime = mime?.lowercased(), let fileExtension = mime2FileExtension(mime: mime) {
            return fileExtension
        }
        return nil
    }
    
    /// 务必回调，否则会阻塞网页加载
    func driveBrowser(_ browser: WebBrowser, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard browser.configuration.downloadEnable else {
            Self.logger.info("OPWDownload decidePolicyFor navigationAction, configuration downloadEnable false")
            decisionHandler(.allow)
            return
        }
        guard let url = navigationAction.request.url else {
            Self.logger.info("OPWDownload decidePolicyFor navigationAction, request url is nil")
            decisionHandler(.cancel)
            return
        }
        if ["http", "https", "blob"].contains(url.scheme) {
            pendingRequests[url.absoluteString] = navigationAction.request
        }
        decisionHandler(.allow)
    }
    /// 务必回调，否则会阻塞网页加载
    func driveBrowser(_ browser: WebBrowser, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        guard browser.configuration.downloadEnable else {
            Self.logger.info("OPWDownload decidePolicyFor navigationResponse, configuration.downloadEnable is false")
            decisionHandler(.allow)
            return
        }
        let response = navigationResponse.response
        guard let responseURL = response.url else {
            Self.logger.info("OPWDownload decidePolicyFor navigationResponse, response.url is nil")
            decisionHandler(.allow)
            return
        }
        guard let request = pendingRequests.removeValue(forKey: responseURL.absoluteString) else {
            Self.logger.info("OPWDownload decidePolicyFor navigationResponse, pendingRequests key-value is nil")
            decisionHandler(.allow)
            return
        }
        guard let fileTypeList = LarkWebSettings.shared.settingsModel?.downloads?.file_type_list else {
            Self.logger.info("OPWDownload decidePolicyFor navigationResponse, settings file_type_list is nil")
            decisionHandler(.allow)
            return
        }
        guard canDownload(browser: browser, navigationResponse: navigationResponse) else {
            Self.logger.info("OPWDownload decidePolicyFor navigationResponse, canDownload false")
            decisionHandler(.allow)
            return
        }
        let filename = response.suggestedFilename ?? ""
        var fileExtension: String? = fileExtension(filename: filename, mime: response.mimeType)?.lowercased()
        if fileExtension == nil {
            Self.logger.info("OPWDownload decidePolicyFor navigationResponse, fileExtension is nil")
        }
        // 是否DriveSDK本地预览支持的文件类型
        var isSupportPreview = false
        if let fileExtension = fileExtension,
           fileTypeList.contains(fileExtension),
           let driveService = try? self.resolver?.resolve(assert: DriveDownloadServiceProtocol.self),
           driveService.canOpen(fileName: filename, fileSize: nil, appID: OPWebBrowserDriveAppID) == true {
            isSupportPreview = true
        }
        let cookieStore = browser.webview.configuration.websiteDataStore.httpCookieStore
        let model = WebDownloadModel(request: request,
                                     response: response,
                                     cookieStore: cookieStore,
                                     filename: filename,
                                     fileExtension: fileExtension,
                                     preview: isSupportPreview)
        // 进入端内下载和本地预览流程
        if Self.webDrivePreviewEnhancedEnable() {
            handlePushDownloadAndPreview(browser, model: model, decisionHandler: decisionHandler)
        } else {
            handleEmbedDownloadAndPreview(browser, model: model, decisionHandler: decisionHandler)
        }
    }
    
    private func handleEmbedDownloadAndPreview(_ browser: WebBrowser, model: WebDownloadModel, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        do {
            try self.register(item: WebDownloadExtensionItem(browser: self, delegate: self, model: model))
        } catch {
            Self.logger.info("OPWDownload WebDownloadExtensionItem register fail")
        }
        // 导航栏标题, 优先显示文件名, 降级显示网页URL
        var title: String = ""
        if let filename = model.filename {
            title = filename
        } else if let suggestedFilename = model.response?.suggestedFilename {
            title = suggestedFilename
        } else if let urlStr = model.response?.url?.absoluteString {
            title = urlStr
        }
        updateNavigationTitle(title, lineBreakMode: .byTruncatingHead)
        // 下载前隐藏导航栏右侧按钮
        if browser.isNavigationRightBarExtensionDisable {
            if let items = self.navigationItem.rightBarButtonItems {
                rightBarBtnItems = items
                self.navigationItem.setRightBarButtonItems(nil, animated: false)
            }
        } else {
            if let navigationExtension = browser.resolve(NavigationBarRightExtensionItem.self) {
                navigationExtension.isHideRightItems = true
                navigationExtension.resetAndUpdateRightItems(browser: browser)
            }
        }
        
        Self.logger.info("OPWDownload decidePolicyFor navigationResponse, embed download and preview: \(model.isSupportPreview == true)")
        showPreviewMonitor(browser)
        decisionHandler(.cancel)
    }
    
    /// 网页容器端内下载预览新页面方案
    private func handlePushDownloadAndPreview(_ browser: WebBrowser, model: WebDownloadModel, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        var isInlineType: Bool = false
        if let fileExtension = model.fileExtension, canInlinePreview(fileExtension: fileExtension) {
            isInlineType = true
        }
        let isOctetStreamType: Bool = model.response?.mimeType?.lowercased() == MIMEType.OctetStream
        // 若未知类型下载并保存到本地再提示其他应用打开, 否则继续原生加载会出现乱码影响用户体验
        if isInlineType && !isOctetStreamType {
            Self.logger.info("OPWDownload decidePolicyFor navigationResponse, can inline preview")
            decisionHandler(.allow)
            return
        }
        if browser.isNavigationRightBarExtensionDisable {
            resolve(NavigationBarStyleExtensionItem.self)?.setNavigationRightBarBtnItemsHidden(browser: browser, hidden: true, animated: false)
        } else {
            if let navigationExtension = resolve(NavigationBarRightExtensionItem.self) {
                navigationExtension.isWebDownloadPreviewHidden = false
                navigationExtension.resetAndUpdateRightItems(browser: self)
            }
        }
        
        // 若URL再次打开存在本地文件, 则直接Drive本地预览
        if let urlStr = model.response?.url?.absoluteString,
           let localValue = WebDownloadStorage.get(url: urlStr),
           let localModel = downloadModelFrom(localValue) {
            showLocalStoragePreview(model: localModel)
            Self.logger.info("OPWDownload decidePolicyFor navigationResponse, local file preivew open again")
            showPreviewMonitor(browser)
            decisionHandler(.cancel)
            // 若是新容器打开的文件URL，则添加兜底页，并尝试关闭该容器
            if closeBlankEnable(), browser.webview.isFirstPage {
                addDefaultDownloadView(browser: browser, filename: localModel.filename ?? "")
                //尝试关闭本容器
                self.delayRemoveSelfInViewControllers()
            }
            return
        }
        
        // 若URL首次打开或再次打开不存在本地文件, 则新页面下载文件再Drive本地预览
        let vc = DownloadPercentController(model: model)
        vc.didStartDownload = { [weak self] model in
            self?.webDownloadDidStartDownload(model: model)
        }
        vc.didComplete = { [weak self] error, model in
            self?.webDownloadDidComplete(error: error, model: model)
        }
        vc.showDrivePreview = { [weak self] model in
            self?.webDownloadShowDrivePreview(model: model)
        }
        vc.showActivityVC = { [weak self] model, inView in
            self?.webDownloadShowActivityVC(model: model, view: inView)
        }
        Navigator.shared.push(vc, from: self)// user:global
        
        Self.logger.info("OPWDownload decidePolicyFor navigationResponse, drive download preview: \(model.isSupportPreview == true)")
        showPreviewMonitor(browser)
        decisionHandler(.cancel)
        // 若是新容器打开的文件URL，则添加兜底页
        if closeBlankEnable(), browser.webview.isFirstPage {
            Self.logger.info("OPWDownload decidePolicyFor navigationResponse, new browser opened, add DefaultDownloadView")
            addDefaultDownloadView(browser: browser, filename: model.filename ?? "")
        }
    }
    
    private func addDefaultDownloadView(browser: WebBrowser, filename: String) {
        // 添加兜底页
        let defaultViewConfig = UDEmptyConfig(
            description: UDEmptyConfig.Description(descriptionText: BundleI18n.WebBrowser.OpenPlatform_AttachmentPreview_OpeningText),
            type: .vcSharedStop,
            primaryButtonConfig: (BundleI18n.WebBrowser.OpenPlatform_AttachmentPreview_BackToPageBttn, { [weak self] (_) in
                Self.logger.info("OPWDownload addDefaultDownloadView, back button clicked")
                guard let self = self else { return }
                self.defaultViewButtonClickMonitor(browser: self, type: "back")
                if self.resolve(PadExtensionItem.self)?.tryGetSupportSceneCloseItem(browser: self) != nil {
                    // 关闭按钮是 iPad 分屏窗口的关闭按钮，则需要调用关闭分屏的方法
                    Self.logger.info("OPWDownload addDefaultDownloadView, close scene")
                    SceneManager.shared.deactive(from: self)
                } else {
                    self.closeBrowser()
                }
            }),
            secondaryButtonConfig: (BundleI18n.WebBrowser.OpenPlatform_AttachmentPreview_ViewAttachmentBttn, { [weak self] (_) in
                Self.logger.info("OPWDownload addDefaultDownloadView, open_file button clicked")
                guard let self = self else { return }
                self.defaultViewButtonClickMonitor(browser: self, type: "open_file")
                self.reload()
            })
        )
        let defaultDownloadView = UDEmptyView(config: defaultViewConfig)
        defaultDownloadView.useCenterConstraints = true
        
        browser.view.addSubview(defaultDownloadView)
        defaultDownloadView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        // 设置兜底页的导航栏标题为文件名
        updateNavigationTitle(filename, lineBreakMode: .byTruncatingTail)
    }
    
    private func downloadModelFrom(_ value: [String: String]) -> WebDownloadModel? {
        guard let filename = value["filename"],
              let fileExtension = value["type"],
              let isPreviewStr = value["preview"] as? NSString else {
            return nil
        }
        let path = OPDownload.downloadsFolderPath(isEmbed: false).appendingRelativePath(filename)
        guard path.exists else {
            return nil
        }
        let model = WebDownloadModel(filename: filename, fileExtension: fileExtension, preview: isPreviewStr.boolValue)
        model.localPath = path.absoluteString
        return model
    }
    
    private func showPreviewMonitor(_ browser: WebBrowser) {
        OPMonitor("wb_preview_download_show")
            .addCategoryValue("download_url", browser.browserURL?.safeURLString)
            .tracing(browser.webview.trace)
            .setPlatform([.tea, .slardar])
            .flush()
        browser.webview.recordWebviewCustomEvent(.didDownLoad)
    }
    
    private func defaultViewButtonClickMonitor(browser: WebBrowser, type: String) {
        OPMonitor("wb_download_click")
            .addCategoryValue("type", type)
            .addCategoryValue("url", browser.browserURL?.safeURLString)
            .tracing(browser.webview.trace)
            .setPlatform([.tea, .slardar])
            .flush()
    }
    
    private func showLocalStoragePreview(model: WebDownloadModel) {
        if model.isSupportPreview == true {
            webDownloadShowDrivePreview(model: model)
            Self.logger.info("OPWDownload local storage show drive preview")
            return
        }
        webDownloadShowActivityVC(model: model, view: view)
        Self.logger.info("OPWDownload local storage show activity view")
    }
    
    private func canDownload(browser: WebBrowser, navigationResponse: WKNavigationResponse) -> Bool {
        guard let mimeType = navigationResponse.response.mimeType?.lowercased() else {
            Self.logger.info("OPWDownload canDownload false, mimeType is nil")
            return false
        }
        // 若未知类型/附件形式/原生不能展示类型, 则需要下载并保存到本地
        if mimeType == MIMEType.OctetStream {
            Self.logger.info("OPWDownload canDownload true, Content-Type:\(MIMEType.OctetStream)")
            return true
        } else if let response = navigationResponse.response as? HTTPURLResponse,
                  let contentDisposition = HTTPHeaderInfoUtils.value(response: response, forHTTPHeaderField: "Content-Disposition"),
                  contentDisposition.starts(with: "attachment") {
            Self.logger.info("OPWDownload canDownload true, Content-Disposition:attachment")
            return true
        } else if navigationResponse.canShowMIMEType == false {
            // 若WebKit不支持原生显示, 则需要端内下载本地预览
            Self.logger.info("OPWDownload canDownload true, canShowMIMEType:false")
            return true
        }
        // 若新页面方案且白名单类型能够原生展示, 则后续流程进一步判断是否下载并保存到本地
        // 仅对主文档生效否则可能误拦iframe展示的媒体文件
        if Self.webDrivePreviewEnhancedEnable(),
           navigationResponse.isForMainFrame,
           let mimeFileType = LarkWebSettings.shared.settingsModel?.downloads?.mime_file_type,
           let fileType = mimeFileType[mimeType],
           !fileType.isEmpty {
            Self.logger.info("OPWDownload canDownload true, the main frame mime_file_type contains the element")
            return true
        }
        
        Self.logger.info("OPWDownload canDownload false, allowing a navigation response")
        return false
    }
    
    private func canInlinePreview(fileExtension: String) -> Bool {
        if let inlinePreviewType = LarkWebSettings.shared.settingsModel?.downloads?.inline_preview_type,
           inlinePreviewType.contains(fileExtension) {
            return true
        }
        Self.logger.info("OPWDownload canInlinePreview false, inline_preview_type is empty or not contain \(fileExtension)")
        return false
    }
    
    func updateNavigationTitle(_ title: String?, lineBreakMode: NSLineBreakMode) {
        resolve(NavigationBarMiddleExtensionItem.self)?.setNavigationTitle(browser: self, title: title ?? "", lineBreakMode: lineBreakMode)
    }
    
    func getHTTPHeaderFromModel(_ model: WebDownloadModel, header: String) -> String? {
        guard let response = model.response as? HTTPURLResponse else {
            return nil
        }
        return HTTPHeaderInfoUtils.value(response: response, forHTTPHeaderField: header)
    }
    
    func updateDownloadViewConstraintsIfNeed() {
        guard Display.pad else {
            return
        }
        guard let downloadItem = extensionManager.resolve(WebDownloadExtensionItem.self) else {
            return
        }
        downloadItem.updateConstraintsIfNeed()
    }
}

// MARK: WebDownloadExtensionItemProtocol
extension WebBrowser: WebDownloadExtensionItemProtocol {
    func webDownloadDidStartDownload(model: WebDownloadModel) {
        let contentLength = getHTTPHeaderFromModel(model, header: "Content-Length") ?? ""
        let contentDisposition = getHTTPHeaderFromModel(model, header: "Content-Disposition") ?? ""
        let contentType = getHTTPHeaderFromModel(model, header: "Content-Type") ?? ""
        Self.logger.info("OPWDownload didStartDownload download_url: \(browserURL?.safeURLString ?? ""), content length: \(contentLength), disposition: \(contentDisposition), type: \(contentType)")
        
        OPMonitor("wb_download_start")
            .addCategoryValue("type", "normal")
            .addCategoryValue("download_url", browserURL?.safeURLString)
            .tracing(webview.trace)
            .setPlatform([.tea, .slardar])
            .flush()
    }
    
    func webDownloadDidComplete(error: Error?, model: WebDownloadModel) {
        var filenameType = ""
        let contentDisposition = getHTTPHeaderFromModel(model, header: "Content-Disposition")
        if let disposition = contentDisposition {
            let components = disposition.components(separatedBy: ";")
            if let filename1 = components.first(where: { $0.hasPrefix("filename*=") }) {
                filenameType = filename1.components(separatedBy: "=").last ?? ""
            } else if let filename2 = components.first(where: { $0.hasPrefix("filename=") }) {
                filenameType = filename2.components(separatedBy: "=").last ?? ""
            }
        }
        let contentType = getHTTPHeaderFromModel(model, header: "Content-Type")
        
        var resultType: String = ""
        var errorLog: String = ""
        if let error = error {
            resultType = "fail"
            let errorCode = (error as NSError).code
            if errorCode == -999 {
                resultType = "cancel"
            }
            errorLog = "error_code: \(errorCode), error_msg: \(error.localizedDescription)"
        } else {
            // 下载完成显示导航栏右侧按钮
            if isNavigationRightBarExtensionDisable {
                if rightBarBtnItems != nil {
                    self.navigationItem.setRightBarButtonItems(rightBarBtnItems, animated: false)
                    rightBarBtnItems = nil
                }
            } else {
                if let navigationExtension = resolve(NavigationBarRightExtensionItem.self) {
                    navigationExtension.isHideRightItems = false
                    navigationExtension.resetAndUpdateRightItems(browser: self)
                }
            }
            
            resultType = "success"
            errorLog = "error is nil"
        }
        
        Self.logger.info("OPWDownload didComplete \(resultType), download_url: \(browserURL?.safeURLString ?? ""), length: \(String(model.totalBytes ?? 0)), disposition: \(contentDisposition ?? ""), type: \(contentType ?? ""), fileType: \(model.fileExtension ?? ""), \(errorLog)")
        
        OPMonitor("wb_download_result")
            .addCategoryValue("type", "normal")
            .addCategoryValue("download_url", browserURL?.safeURLString)
            .addCategoryValue("result_type", resultType)
            .addCategoryValue("content_length", String(model.totalBytes ?? 0))
            .addCategoryValue("content_type", contentType)
            .addCategoryValue("filename_type", filenameType)
            .addCategoryValue("filetype", model.fileExtension)
            .addCategoryValue("error_code", (error as? NSError)?.code ?? -1)
            .addCategoryValue("error_msg", error?.localizedDescription ?? "")
            .addCategoryValue("appId", configuration.appId ?? "")
            .tracing(webview.trace)
            .setPlatform([.tea, .slardar])
            .flush()
    }
    
    func webDownloadShowDrivePreview(model: WebDownloadModel) {
        guard let filepath = model.localPath else {
            return
        }
        Self.logger.info("OPWDownload show drive preview")
        var filename: String = ""
        if let modelFilename = model.filename {
            filename = modelFilename
        } else if let suggestedFilename = model.response?.suggestedFilename {
            filename = suggestedFilename
        }
        var fileURL = URL(fileURLWithPath: filepath)
        if OPDownload.isEncryptedEnable() {
            do {
                let isoPath = try IsoPath.parse(from: filepath, space: WebDownloadStorage.space(), domain: Domain.biz.webApp)
                fileURL = try AbsPath(isoPath.absoluteString).decrypted().url
            } catch let error {
                Self.logger.info("OPWDownload showDrivePreview isoPath decrypted failed: \(error.localizedDescription)")
            }
        }
        if let driveService = try? self.resolver?.resolve(assert: DriveDownloadServiceProtocol.self) {
            driveService.showDrivePreview(filename, fileURL: fileURL, filetype: model.fileExtension, fileId: nil, thirdPartyAppID: currrentWebpageAppID(), appID: OPWebBrowserDriveAppID, from: self)
        }
        if closeBlankEnable(), self.webview.isFirstPage {
            //尝试关闭本容器
            Self.logger.info("OPWDownload showDrivePreview, new browser opened, try close self")
            self.delayRemoveSelfInViewControllers()
        }

        OPMonitor("wb_preview_start")
            .addCategoryValue("download_url", browserURL?.safeURLString)
            .addCategoryValue("filetype", model.fileExtension)
            .tracing(webview.trace)
            .setPlatform([.tea, .slardar])
            .flush()
    }
    
    func webDownloadShowActivityVC(model: WebDownloadModel, view: UIView?) {
        // 若开启文件加密, 则禁止第三方应用打开
        if OPDownload.isEncryptedEnable() {
            Self.logger.info("OPWDownload webDownloadShowActivityVC encrypt toast")
            UDToast.showFailure(with: BundleI18n.WebBrowser.Mail_FileCantShareOrOpenViaThirdPartyApp_Toast, on: view ?? self.view)
            return
        }
        // 若未开启文件加密
        guard let filepath = model.localPath else {
            return
        }
        Self.logger.info("OPWDownload show activity view")
        let fileURL = URL(fileURLWithPath: filepath)
        let activityVC = UIActivityViewController(activityItems: [fileURL as Any], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = view
        var sourceRect: CGRect
        if let view = view {
            sourceRect = CGRect(x: view.bounds.size.width / 2, y: view.bounds.size.height, width: 0, height: 0)
        } else {
            sourceRect = .zero
        }
        activityVC.popoverPresentationController?.sourceRect = sourceRect
        self.present(activityVC, animated: true, completion: nil)
    }
}
