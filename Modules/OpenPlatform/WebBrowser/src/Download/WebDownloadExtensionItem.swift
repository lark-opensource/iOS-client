//
//  WebDownloadExtensionItem.swift
//  WebBrowser
//
//  Created by Ding Xu on 2022/7/18.
//
//  端内下载&预览扩展

import Foundation
import UIKit
import WebKit
import ECOProbe
import LarkStorage
import UniverseDesignToast

// MARK: - WebDownloadExtensionItem
protocol WebDownloadExtensionItemProtocol: AnyObject {
    func webDownloadDidStartDownload(model: WebDownloadModel)
    func webDownloadDidComplete(error: Error?, model: WebDownloadModel)
    func webDownloadShowDrivePreview(model: WebDownloadModel)
    func webDownloadShowActivityVC(model: WebDownloadModel, view: UIView?)
}

class WebDownloadExtensionItem: WebBrowserExtensionItemProtocol {
    var itemName: String? = "WebDownload"
    lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebDownloadBrowserLifeCycle(item: self)
    private weak var browser: WebBrowser?
    private weak var delegate: WebDownloadExtensionItemProtocol?
    let model: WebDownloadModel
    let downloadQueue = OPDownloadQueue()
    var downloadView: DownloadContentView?
    var noSupportView: DownloadNoSupportView?
    
    func closeDownload() {
        if !downloadQueue.isEmpty {
            downloadQueue.cancelAll()
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    init(browser: WebBrowser, delegate: WebDownloadExtensionItemProtocol?, model: WebDownloadModel) {
        self.browser = browser
        self.delegate = delegate
        self.model = model
        didInit()
    }
    
    fileprivate func didInit() {
        removeAllFiles()
        downloadQueue.delegate = self
        addObserver()
        if model.isSupportPreview == true {
            createPreviewView()
            enqueueDownload()
        } else {
            createNoSupportView()
        }
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(opw_didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(opw_didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(opw_orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func enqueueDownload() {
        guard let response = model.response,
              let requeset = model.request,
              let cookieStore = model.cookieStore else {
            return
        }
        guard let download = OPHTTPDownload(response: response, request: requeset, cookieStore: cookieStore) else {
            return
        }
        self.downloadQueue.enqueue(download)
    }
    
    private func createPreviewView() {
        guard let browser = browser else {
            return
        }
        let view = DownloadContentView(frame: browser.view.bounds, fileExtension: model.fileExtension)
        view.delegate = self
        browser.view.addSubview(view)
        downloadView = view
    }
    
    private func createNoSupportView() {
        guard let browser = browser else {
            return
        }
        let view = DownloadNoSupportView(frame: browser.view.bounds)
        view.delegate = self
        browser.view.addSubview(view)
        noSupportView = view
    }
    
    func removeAllFiles() {
        do {
            if OPDownload.isEncryptedEnable() {
                let downloadsIsoPath = OPDownload.downloadsFolderPath(isEmbed: true)
                if downloadsIsoPath.exists {
                    try downloadsIsoPath.removeItem()
                }
            } else {
            let downloadsPath = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(OPEN_PLATFORM_WEB_DRIVE_DOWNLOAD_FOLDER).path
            if FileManager.default.fileExists(atPath: downloadsPath) {
                try FileManager.default.removeItem(atPath: downloadsPath)
            }
            }
            WebBrowser.logger.info("OPWDownload remove Caches/OPWDownloads success")
        } catch {
            WebBrowser.logger.error("OPWDownload remove Caches/OPWDownloads error", error: error)
        }
    }
    
    func updateConstraintsIfNeed() {
        opw_orientationDidChange()
    }
    
    @objc private func opw_didEnterBackground() {
        downloadQueue.pauseAll()
    }
    
    @objc private func opw_didBecomeActive() {
        downloadQueue.resumeAll()
    }
    
    @objc private func opw_orientationDidChange() {
        guard browser != nil else {
            return
        }
        if let downloadView = downloadView {
            downloadView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        if let noSupportView = noSupportView {
            noSupportView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension WebDownloadExtensionItem: OPDownloadQueueDelegate {
    func downloadQueue(_ queue: OPDownloadQueue, didStartDownload download: OPDownload) {
        downloadView?.totalBytes = download.totalBytes
        noSupportView?.totalBytes = download.totalBytes
        delegate?.webDownloadDidStartDownload(model: model)
    }
    
    func downloadQueue(_ queue: OPDownloadQueue, didDownloadBytes bytes: Int64, totalBytes: Int64?) {
//        WebBrowser.logger.debug("OPWDownload didDownloadCombinedBytes \(bytes) - \(totalBytes)")
        downloadView?.downloadedBytes = bytes
        noSupportView?.downloadedBytes = bytes
    }
    
    func downloadQueue(_ queue: OPDownloadQueue, download: OPDownload, didFinishDownloadingTo location: String) {
        WebBrowser.logger.debug("OPWDownload didFinishDownloadingTo \(location)")
        model.localPath = location
    }
    
    func downloadQueue(_ queue: OPDownloadQueue, didComplete error: Error?) {
        DispatchQueue.main.async {
            let isPreview = self.model.isSupportPreview == true
            self.downloadView?.didCompleteWithError(error)
            self.noSupportView?.didCompleteWithError(error)
            self.model.totalBytes = isPreview ? self.downloadView?.totalBytes : self.noSupportView?.totalBytes
            self.delegate?.webDownloadDidComplete(error: error, model: self.model)
            if error == nil {
                if isPreview {
                    self.delegate?.webDownloadShowDrivePreview(model: self.model)
                } else {
                    self.delegate?.webDownloadShowActivityVC(model: self.model, view: self.noSupportView)
                }
            }
        }
    }
}

extension WebDownloadExtensionItem: DownloadPercentHandleProtocol {
    func didClickCancel() {
        WebBrowser.logger.info("OPWDownload didClickCancel support_preview: \(model.isSupportPreview == true), queue.empty: \(downloadQueue.isEmpty)")
        guard !downloadQueue.isEmpty else {
            return
        }
        downloadQueue.cancelAll()
    }
    
    func didClickDownload() {
        WebBrowser.logger.info("OPWDownload didClickDownload support_preview: \(model.isSupportPreview == true), queue.empty: \(downloadQueue.isEmpty)")
        if !downloadQueue.isEmpty {
            downloadQueue.cancelAll()
        }
        enqueueDownload()
    }
    
    func didClickOpenInOthersApps(view: UIView?) {
        if OPDownload.isEncryptedEnable() {
            WebBrowser.logger.info("OPWDownload didClickOpenInOthersApps encrypt toast")
            if let view = self.browser?.view {
                UDToast.showFailure(with: BundleI18n.WebBrowser.Mail_FileCantShareOrOpenViaThirdPartyApp_Toast, on: view)
            }
        } else {
            WebBrowser.logger.info("OPWDownload didClickOpenInOthersApps showActivityVC")
            delegate?.webDownloadShowActivityVC(model: model, view: view)
        }
    }
    
    func didClickOpenDrivePreview() {
        WebBrowser.logger.info("OPWDownload didClickOpenDrivePreview")
        delegate?.webDownloadShowDrivePreview(model: model)
    }
}

// MARK: - WebDownloadBrowserLifeCycle
class WebDownloadBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: WebDownloadExtensionItem?
    
    init(item: WebDownloadExtensionItem) {
        self.item = item
    }
    
    func webBrowserDeinit(browser: WebBrowser) {
        item?.closeDownload()
        WebBrowser.logger.info("OPWDownload closeBrowser")
    }
}
