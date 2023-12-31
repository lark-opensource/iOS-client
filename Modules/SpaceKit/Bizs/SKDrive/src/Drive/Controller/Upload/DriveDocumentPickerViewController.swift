//
//  DriveDocumentPickerController.swift
//  SpaceKit
//
//  Created by liweiye on 2019/2/17.
//

import Foundation
import SKCommon
import SKResource
import SKFoundation
import SpaceInterface

/// 参考文档：https://docs.bytedance.net/doc/doccnqBxBdV5FJdImdxWoP
private let documentTypes = [
    "public.item"    //范围太广
//    "public.content",
//    "public.data",
//    "public.database",
//    "public.calendar-event",
//    "public.message",
//    "public.contact",
//    "public.archive",
]

class DriveDocumentPickerViewController: UIDocumentPickerViewController {

    private var mountToken: String
    private var mountPoint: String
    private var scene: DriveUploadScene
    weak var sourceViewController: UIViewController?
    private var completion: ((Bool) -> Void)?

    init(mountToken: String, mountPoint: String, scene: DriveUploadScene, sourceViewController: UIViewController?, completion: ((Bool) -> Void)?) {
        self.mountToken = mountToken
        self.mountPoint = mountPoint
        self.scene = scene
        self.sourceViewController = sourceViewController
        self.completion = completion
        super.init(documentTypes: documentTypes, in: .import)
        delegate = self
        modalPresentationStyle = .fullScreen
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNetworkMonitor()
    }
}

extension DriveDocumentPickerViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let isValid = DriveUploadCacheService.saveICouldFileToLocal(urls: urls, mountToken: mountToken, mountPoint: mountPoint, scene: scene)
        if !isValid {
            showInvalidFileAlert()
        }
        completion?(true)
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion?(false)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let isValid = DriveUploadCacheService.saveICouldFileToLocal(urls: [url], mountToken: mountToken, mountPoint: mountPoint, scene: scene)
        if !isValid {
            showInvalidFileAlert()
        }
        completion?(false)
    }
}

extension DriveDocumentPickerViewController {

    private func setupNetworkMonitor() {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] _, isReachable in
            guard let self = self else { return }
            // 如果网络可用返回，不可用则退出选择器，弹出无网通知
            guard !isReachable else { return }
            guard let sourceViewController = self.sourceViewController else {
                DocsLogger.error("no root VC for file picker to show")
                return
            }
            self.dismiss(animated: false, completion: nil)
            self.showNoNetworkAlert(sourceViewController)
        }
    }

    private func showInvalidFileAlert() {
        guard let sourceViewController = sourceViewController else {
            DocsLogger.error("Failed to get source view controller")
            return
        }
        let alert = UIAlertController(title: BundleI18n.SKResource.Drive_Drive_UploadUnsupportFileErrorTitle,
                                      message: BundleI18n.SKResource.Drive_Drive_UploadUnsupportFileErrorMessage,
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: BundleI18n.SKResource.Drive_Drive_Confirm, style: .default, handler: nil)
        alert.addAction(action)
        sourceViewController.present(alert, animated: true, completion: nil)
    }

    private func showNoNetworkAlert(_ viewController: UIViewController) {
        let alert = UIAlertController(title: nil, message: BundleI18n.SKResource.Drive_Drive_NetInterrupt, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: BundleI18n.SKResource.Drive_Drive_Confirm, style: UIAlertAction.Style.default, handler: nil))
        viewController.present(alert, animated: false, completion: nil)
    }
}
