//
//  FilePreviewViewController.swift
//  SpaceKit
//
//  Created by bytedance on 2018/9/29.
//

import UIKit
import QuickLook
import AVFoundation
import AVKit
import SwiftyJSON
import UniverseDesignActionPanel
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import UniverseDesignIcon
import LarkSensitivityControl
import SKInfra

public final class FilePreviewViewController: BaseViewController {
    private lazy var avplayerViewController: AVPlayerViewController = {
        let player = AVPlayer(url: self.fileUrls.first!)
        let playerController = AVPlayerViewController()
        playerController.player = player
        return playerController
    }()

    private lazy var unsupportPreviewView: UnsupportPreviewView = {
        return UnsupportPreviewView(file: filePreviewModel, delegate: self)
    }()

    private var fileUrls: [URL] = []
    private var filePreviewModel: FilePreviewModel
    private var filePreviewService: FilePreviewService?

    public init(filePreviewModel: FilePreviewModel) {
        self.filePreviewModel = filePreviewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupFilePreviewService()
        filePreviewService?.start()
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        filePreviewService?.stopDownload()
    }
}

extension FilePreviewViewController {
    private func setupUI() {
        navigationBar.titleLabel.lineBreakMode = .byTruncatingMiddle
        title = filePreviewModel.name
        view.backgroundColor = UIColor.ud.N200
    }

    private func setupFilePreviewService() {
        // 这里 showLoading 为了避开导航栏，依赖了导航栏高度
        // FilePreviewViewController 是旧版 docs 附件预览的组件，若不再使用可以删除
        DispatchQueue.main.async {
            self.showLoading(duration: 0)
        }
        filePreviewService = FilePreviewService(file: filePreviewModel, delegate: self, completionHandler: { [weak self] (filePath, error) in
            self?.hideLoading()

            if let error = error {
                self?.showError()
                // 缓存错误上报

                if let strongSelf = self {
                    let paras = ["status_code": "1",
                                 "file_id": DocsTracker.encrypt(id: strongSelf.filePreviewModel.id),
                                 "file_type": strongSelf.filePreviewModel.type.rawValue,
                                 "file_size": strongSelf.filePreviewModel.size
                        ] as [String: Any]
                    DocsTracker.log(enumEvent: .clientAttachmentDownloaddonwAlert, parameters: paras)
                }
                DocsLogger.error("发生错误", extraInfo: ["error": error])
                return
            }

            guard let path = filePath else {
                DocsLogger.error("fileUrl 为空")
                return
            }

            self?.fileUrls = [path.pathURL]

            DispatchQueue.main.async {
                self?.openFileIfSupport()
            }
        })
    }

    private func openFileIfSupport() {
        showRightBarButton()
        if let previewItem = FilePreviewService.getLocalFilePath(file: filePreviewModel)?.pathURL as QLPreviewItem?,
            QLPreviewController.canPreview(previewItem) && filePreviewModel.isSupport2OpenNow() {
            if filePreviewModel.isVideoType() {
                showVideoController()
            } else {
                showQLPreviewController(fileItem: previewItem)
            }

            // 默认直接打开的上报
            let paras = ["open_type": "1",
                         "status_code": "1",
                         "file_id": DocsTracker.encrypt(id: filePreviewModel.id),
                         "file_type": filePreviewModel.type.rawValue,
                         "file_size": filePreviewModel.size
                ] as [String: Any]
            DocsTracker.log(enumEvent: .clickAttachmentOpen, parameters: paras)
        } else {
            showUnSupportView()
        }
    }

    private func showVideoController() {
        addChild(avplayerViewController)
        view.addSubview(avplayerViewController.view)
        avplayerViewController.didMove(toParent: self)
        avplayerViewController.view.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }
    }

    private func showQLPreviewController(fileItem: QLPreviewItem) {
        let previewController = DocsQLPreviewViewController(fileItem: fileItem)
    
        addChild(previewController)
        view.addSubview(previewController.view)
        previewController.didMove(toParent: self)
        previewController.view.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }
    }

    private func showError() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: BundleI18n.SKResource.Doc_Facade_Cancel, style: .default, handler: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)

            if let strongSelf = self {
                // 上报
                let paras = ["open_type": "3",
                             "status_code": "1",
                             "file_id": DocsTracker.encrypt(id: strongSelf.filePreviewModel.id),
                             "file_type": strongSelf.filePreviewModel.type.rawValue,
                             "file_size": strongSelf.filePreviewModel.size
                    ] as [String: Any]
                DocsTracker.log(enumEvent: .clientAttachmentDownloaddonwAlertCancel, parameters: paras)
            }
        })
        cancelAction.setValue(UIColor.ud.N1000, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        let okAction = UIAlertAction(title: BundleI18n.SKResource.Doc_Facade_DownloadRetry, style: .default, handler: { [weak self] (_) in
            self?.filePreviewService?.start()

            if let strongSelf = self {
                // 上报
                let paras = ["open_type": "3",
                             "status_code": "1",
                             "file_id": DocsTracker.encrypt(id: strongSelf.filePreviewModel.id),
                             "file_type": strongSelf.filePreviewModel.type.rawValue,
                             "file_size": strongSelf.filePreviewModel.size
                    ] as [String: Any]
                DocsTracker.log(enumEvent: .clientAttachmentDownloaddonwAlertGoon, parameters: paras)
            }
        })
        alert.addAction(okAction)
        let message = NSMutableAttributedString(string: BundleI18n.SKResource.Doc_Normal_PreviewFailure)
        message.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)], range: NSRange(location: 0, length: message.length))
        alert.setValue(message, forKey: "attributedMessage")
        present(alert, animated: true, completion: nil)
    }

    private func showRightBarButton() {
        let rightBarButtonItem = SKBarButtonItem(image: UDIcon.moreOutlined,
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(showMore))
        rightBarButtonItem.id = .more
        navigationBar.trailingBarButtonItem = rightBarButtonItem
    }

    @objc
    private func showSystemPreviewPage() {
        let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmFileDownload, fileBizDomain: .ccm, docType: .file, token: filePreviewModel.id)
        if !result.allow, result.validateSource == .fileStrategy {
            CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmFileDownload, fileBizDomain: .ccm, docType: .file, token: filePreviewModel.id)
            return
        }
        if !result.allow, result.validateSource == .securityAudit {
            UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: self.view.window ?? self.view)
            return
        }
        let shareUrl = self.fileUrls.first
        let systemActivityController = UIActivityViewController(activityItems: [shareUrl as Any], applicationActivities: nil)
        present(systemActivityController, animated: true, completion: nil)
    }

    private func showUnSupportView() {
        view.addSubview(unsupportPreviewView)

        unsupportPreviewView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(-30)
        }
    }

    @objc
    private func showMore() {
        let alert = UDActionSheet.actionSheet()
        if filePreviewModel.isVideoType() || filePreviewModel.isImageType() {
            alert.addItem(text: BundleI18n.SKResource.Doc_Facade_SaveToAlbum) {
                self.save2Album()

                // 保存到相册的上报
                let paras = ["open_type": "3",
                             "status_code": "1",
                             "file_id": DocsTracker.encrypt(id: self.filePreviewModel.id),
                             "file_type": self.filePreviewModel.type.rawValue,
                             "file_size": self.filePreviewModel.size
                    ] as [String: Any]
                DocsTracker.log(enumEvent: .clickAttachmentOpen, parameters: paras)
            }
        }
        alert.addItem(text: BundleI18n.SKResource.Doc_Facade_OpenInOtherApp) {
            self.showSystemPreviewPage()
        }
        alert.addItem(text: BundleI18n.SKResource.Doc_Facade_Cancel, style: .cancel)
        present(alert, animated: true, completion: nil)
    }

    private func save2Album() {
        if filePreviewModel.isVideoType() {
            saveVideo2Album()
        } else if filePreviewModel.isImageType() {
            saveImage2Album()
        }
    }

    private func saveImage2Album() {
        guard let file = FilePreviewService.getLocalFilePath(file: filePreviewModel) else {
            DocsLogger.error("can not get filePath from url")
            return
        }
        if let image = try? UIImage.read(from: file) {
            do {
                try AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: Token(PSDATokens.DocX.doc_or_sheet_open_image), image, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
            } catch {
                DispatchQueue.main.async {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_SaveFailed, on: self.view.window ?? self.view)
                    DocsLogger.error("AlbumEntry UIImageWriteToSavedPhotosAlbum err")
                }
            }
        } else {
            DocsLogger.error("can not get image from url")
        }
    }

    private func saveVideo2Album() {
        if let filePath = FilePreviewService.getLocalFilePath(file: filePreviewModel), UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath.pathString) {
            do {
                try AlbumEntry.UISaveVideoAtPathToSavedPhotosAlbum(forToken: Token(PSDATokens.DocX.doc_or_sheet_open_video), filePath.pathString, self, #selector(video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
            } catch {
                DispatchQueue.main.async {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_SaveFailed, on: self.view.window ?? self.view)
                    DocsLogger.error("AlbumEntry UISaveVideoAtPathToSavedPhotosAlbum err")
                }
            }
        }
    }

    @objc
    private func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) { // 保存结果
        if let e = error {
            DocsLogger.info("保存图片发生错误", extraInfo: ["error": e])
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_SaveFailed, on: self.view.window ?? self.view)
        } else {
            DocsLogger.info("保存图片成功")
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Doc_SaveToAlbumSuccessfully, on: self.view.window ?? self.view)
        }
    }

    @objc
    private func video(videoPath: String, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        if let e = error {
            DocsLogger.info("保存视频发生错误", extraInfo: ["error": e])
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_SaveFailed, on: self.view.window ?? self.view)
        } else {
            DocsLogger.info("保存视频成功")
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Doc_SaveToAlbumSuccessfully, on: self.view.window ?? self.view)
        }
    }
}

extension FilePreviewViewController: FilePreviewServiceProtocol {
    public func download(progress: Float) {
//        DispatchQueue.main.async {
//            self.showLoading(frame: CGRect(0, SKDisplay.realTopBarHeight(), SKDisplay.width, SKDisplay.height - SKDisplay.realTopBarHeight()), duration: 0)
//        }
    }

    public func didFinishDownloadingTo(location: SKFilePath) {

    }
}

extension FilePreviewViewController: UnsupportPreviewViewDelegate {
    func didClickPreviewButton(button: UIButton) { // 点击触发启用其他应用打开
        showSystemPreviewPage()

        // 使用其他程序打开的上报
        // 默认直接打开的上报
        let paras = ["open_type": "2",
                     "status_code": "1",
                     "file_id": DocsTracker.encrypt(id: filePreviewModel.id),
                     "file_type": filePreviewModel.type.rawValue,
                     "file_size": filePreviewModel.size
            ] as [String: Any]
        DocsTracker.log(enumEvent: .clickAttachmentOpen, parameters: paras)
    }
}
