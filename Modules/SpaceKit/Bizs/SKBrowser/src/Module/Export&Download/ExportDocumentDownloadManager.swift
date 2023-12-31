//
//  ExportDocumentDownloadManager.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/23.
//

import Foundation
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast

class ExportDocumentDownloadManager {
    static let shared = ExportDocumentDownloadManager()

    /// source config
    private(set) weak var hostViewController: UIViewController?
    private(set) var popoverSourceFrame: CGRect?
    private(set) var padPopDirection: UIPopoverArrowDirection?
    private(set) weak var sourceView: UIView?

    /// forTracker
    private(set) var trackerParams: [String: Any]?

    private var download: ExportDocumentDownload?
    private weak var loadingView: ExportDownloadLoadingView?
    private var exportProgress: Float = 0.1 // 生成文件的时候进度设置为10%
    private var pollProgress: Float = 0.2 // 轮询一次+5%,后面真实下载跑完剩下的80%

    private init() { }

    func resetConfig(hostViewController: UIViewController?,
                     popoverSourceFrame: CGRect? = nil,
                     padPopDirection: UIPopoverArrowDirection? = nil,
                     sourceView: UIView? = nil) {
        self.hostViewController = hostViewController
        self.popoverSourceFrame = popoverSourceFrame
        self.padPopDirection = padPopDirection
        self.sourceView = sourceView
    }

    func exportDocumentWithType(_ type: ExportDocumentType, docsInfo: DocsInfo, needComment: Bool?, trackerParams: [String: Any]? = nil) {
        guard let hostVC = hostViewController else {
            return
        }

        download = ExportDocumentDownload(format: type, token: docsInfo.token, docsType: docsInfo.inherentType, fileName: docsInfo.name ?? "Untitled", needComment: needComment, delegate: self)
        loadingView = ExportDownloadLoadingView.show(fromVC: hostVC)
        loadingView?.cancelAction = { [weak self] in
            guard let `self` = self else { return }
            self.didCanceled()
        }
        download?.start()
        self.trackerParams = trackerParams
    }

    func didCanceled() {
        DocsLogger.info("ExportDocumentDownloadManager 第三方应用打开取消")
        download?.cancel()
        _resetDownload()
        loadingView?.complete()
        _trackerExportDocument(statusCode: "100", statusName: "canceled")
    }

    private func _resetDownload() {
        download = nil
    }
}

extension ExportDocumentDownloadManager: ExportDocumentDownloadDelegate {
    func exportDocumentDownload(_ download: ExportDocumentDownload, getTicketFinish result: Result<String, Error>) {
        switch result {
        case .success:
            loadingView?.updateProgress(exportProgress)
        case .failure:
            _resetDownload()
            return
        }
    }

    func exportDocumentDownload(_ download: ExportDocumentDownload, continuePollExportResult: Bool) {
        if continuePollExportResult, let curProgress = loadingView?.progress, curProgress < pollProgress {
            loadingView?.updateProgress(curProgress + 0.05)
        } else {
            loadingView?.updateProgress(pollProgress)
        }
    }

    func exportDocumentDownload(_ download: ExportDocumentDownload, downloadFile result: Result<URL, Error>) {
        loadingView?.complete()
        _resetDownload()
        switch result {
        case .success(let url):
            _showSystemPreviewPage([url])
            _trackerExportDocument(statusCode: "0", statusName: "success")
        case .failure(let error):
            var description = error.localizedDescription
            if let oldExportErr = error as? ExportDownloadError {
                description = oldExportErr.displayDescription
            } else if let newExportErr = error as? NewExportDownloadError {
                description = newExportErr.displayDescription
                if case let .dlpError(code) = newExportErr {
                    PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .EXPORT, dlpErrorCode: code)
                }
            }
            UDToast.showFailure(with: description, on: self.hostViewController?.view.window ?? UIView())
            _trackerExportDocument(statusCode: "100", statusName: "failed")
        }
    }

    func exportDocumentDownload(_ download: ExportDocumentDownload, downloadProgress: Float) {
        let realProgress: Float = pollProgress + downloadProgress * (1.0 - pollProgress)
        loadingView?.updateProgress(realProgress)
    }
}

extension ExportDocumentDownloadManager {
    ///使用第三方应用打开
    private func _showSystemPreviewPage(_ urls: [URL]) {
        let systemActivityController = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        // 注册分享回调
        let completionItemsHandler: UIActivityViewController.CompletionWithItemsHandler = { _, complete, _, error in
            guard error == nil else {
                DocsLogger.error("ExportDocumentDownloadManager 第三方应用打开失败")
                return
            }

            if let targetUrl = urls.first, complete {
                let targetPath = SKFilePath(absUrl: targetUrl)
                if targetPath.exists {
                    try? targetPath.removeItem()
                }
            }
        }
        guard let sourceRect = popoverSourceFrame, let popDirection = padPopDirection, let sourceView = sourceView else {
            DocsLogger.error("ExportDocumentDownloadManager 参数丢失导致第三方应用打开失败")
            return
        }
        systemActivityController.popoverPresentationController?.sourceRect = sourceRect
        systemActivityController.popoverPresentationController?.permittedArrowDirections = popDirection
        systemActivityController.popoverPresentationController?.sourceView = sourceView
        systemActivityController.completionWithItemsHandler = completionItemsHandler
        self.hostViewController?.present(systemActivityController, animated: true, completion: nil)
    }
}

// MARK: tracker
extension ExportDocumentDownloadManager {
    private func _trackerExportDocument(statusCode: String, statusName: String) {
        guard let trackerParams = trackerParams else {
            return
        }
        var params: [String: Any] = trackerParams
        params["status_code"] = statusCode
        params["status_name"] = statusName
        DocsTracker.log(enumEvent: .clickExport, parameters: params)
    }
}
