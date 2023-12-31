//
//  EventEditCoordinator+Attachment.swift
//  Calendar
//
//  Created by 张威 on 2020/4/13.
//

import UIKit
import Foundation
import RxSwift
import Photos
import CalendarFoundation
import UniverseDesignActionPanel
import LarkAssetsBrowser
import LarkStorage
import LarkSensitivityControl

/// 编辑日程附件

extension EventEditCoordinator: EventEditAttachmentDelegate {

    // The system may purge this directory when the app is not running.
    fileprivate static let tempAttachmentPath: IsoPath = .global.in(domain: Domain.biz.calendar).build(.temporary)

    // https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html
    fileprivate static let localFileType = ["public.content",
                                            "public.data",
                                            "public.item",
                                            "public.text",
                                            "public.source-code",
                                            "public.image",
                                            "public.audiovisual-content",
                                            "com.adobe.pdf",
                                            "com.apple.keynote.key",
                                            "com.microsoft.word.doc",
                                            "com.microsoft.excel.xls",
                                            "com.microsoft.powerpoint.ppt"]

    func addAttachment(from fromVC: EventEditViewController) {

        // suiteView 只是一个 picker 的壳子，不是通常意义上的 view，所以该场景下无需 add 到 view 上，仅复用其内部 picker 逻辑
        suiteView = .init(assetType: .imageAndVideoWithTotalCount(totalCount: 9), cameraType: .custom(false), sendButtonTitle: I18n.Calendar_Common_Confirm, isOriginalButtonHidden: true, presentVC: fromVC)
        suiteView?.supportVideoEditor = true
        suiteView?.delegate = self

        let config = UDActionSheetUIConfig(style: .autoAlert, isShowTitle: true)
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(I18n.Calendar_Attachment_SelectMethod)
        actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel)
        actionSheet.addItem(UDActionSheetItem(title: I18n.Calendar_Upload_Album) { [unowned self] in
            suiteView?.showPhotoLibrary(selectedItems: [], useOriginal: false)
        })
        actionSheet.addItem(UDActionSheetItem(title: I18n.Calendar_Upload_TakePhoto) { [unowned self] in
            suiteView?.takePhoto()
        })
        actionSheet.addItem(UDActionSheetItem(title: I18n.Calendar_Upload_File) { [unowned self] in
            let types = Self.localFileType
            let localFilePicker = UIDocumentPickerViewController(documentTypes: types, in: .import)
            localFilePicker.delegate = self
            fromVC.present(localFilePicker, animated: true)
        })
        fromVC.present(actionSheet, animated: true)
    }

    func deleteAttachment(from fromVC: EventEditViewController, with index: Int) {
        guard let eventViewModel = eventViewController?.viewModel else { return }
        eventViewModel.attachmentModel?.deleteAttachment(with: index)
    }

    func reuploadAttachment(from fromVC: EventEditViewController, with index: Int) {
        guard let eventViewModel = eventViewController?.viewModel,
              let attachmentModel = eventViewModel.attachmentModel else {
            assertionFailure()
            return
        }
        if let attachment = attachmentModel.rxDisplayingAttachmentsInfo.value.attachments[safeIndex: index] {
            attachmentModel.rxUploadInfoStream.accept(.init(status: .awaiting, index: index))
            attachmentModel.attachmentUploader?.append(with: attachment)
        } else {
            EventEdit.logger.error("reUploadAttachment error: Index(\(index)) out of range")
        }
    }

    func selectAttachment(from fromVC: EventEditViewController, withToken token: String) {
        guard let naviVC = navigationController else {
            assertionFailure()
            calendarDependency?.jumpToAttachmentPreviewController(token: token, from: fromVC)
            return
        }
        calendarDependency?.jumpToAttachmentPreviewController(token: token, from: naviVC)
    }

    private func uploadDocument(with url: URL) {
        guard let eventViewModel = eventViewController?.viewModel,
              let attachmentModel = eventViewModel.attachmentModel else {
            assertionFailure()
            return
        }

        let startIndex = attachmentModel.rxDisplayingAttachmentsInfo.value.attachments.count
        let localPath = url.path
        let fileDictionary = try? FileManager.default.attributesOfItem(atPath: localPath)
        let fileSize = fileDictionary?[FileAttributeKey.size] as? UInt64 ?? 0
        var editAttachment = CalendarEventAttachmentEntity(name: url.lastPathComponent, path: localPath, fileSize: fileSize)
        editAttachment.index = startIndex
        attachmentModel.appendAttachment(with: editAttachment)
    }
}

extension EventEditCoordinator: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        urls.forEach { [weak self] url in
            let tempURL = Self.copyTempAttachment(from: url)
            guard let tempURL = tempURL else { return }
            self?.uploadDocument(with: tempURL)
        }
    }
}

extension EventEditCoordinator: AssetPickerSuiteViewDelegate {

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        self.uploadDocument(with: url)
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        guard let url = Self.parseEditedImage(from: photo) else { return }
        self.uploadDocument(with: url)
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        // 异步过程，故暂时无法真正批量添加
        result.selectedAssets.forEach { [weak self] asset in
            if asset.mediaType == .image {
                if let editImage = asset.editImage {
                    guard let url = Self.parseEditedImage(from: editImage) else { return }
                    self?.uploadDocument(with: url)
                } else {
                    let option = PHContentEditingInputRequestOptions()
                    option.isNetworkAccessAllowed = true
                    asset.requestContentEditingInput(with: option) { [weak self] input, _ in
                        guard let url = input?.fullSizeImageURL else {
                            EventEdit.logger.error("Fail to transform asset data. Empty input.")
                            return
                        }
                        self?.uploadDocument(with: url)
                    }
                }
            } else if asset.mediaType == .video {
                if let editVideo = asset.editVideo {
                    self?.uploadDocument(with: editVideo)
                } else {
                    let options: PHVideoRequestOptions = PHVideoRequestOptions()
                    options.version = .current
                    options.isNetworkAccessAllowed = true
                    PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: {(asset: AVAsset?, _, _) -> Void in
                        if let urlAsset = asset as? AVURLAsset {
                            let localVideoUrl: URL = urlAsset.url as URL
                            self?.uploadDocument(with: localVideoUrl)
                        } else {
                            EventEdit.logger.error("Fail to transform asset data, user can retry after saving to local file.")
                        }
                    })
                }
            }
        }
    }
}

extension EventEditCoordinator {
    // 存储到 tmp 路径，以支持 reUpload（picker 创建的会被自动回收
    private static func copyTempAttachment(from url: URL) -> URL? {
        var toURL: URL?
        do {
            var tempPath = Self.tempAttachmentPath.appendingRelativePath(Date().timeIntervalSince1970.description)
            try tempPath.createDirectoryIfNeeded()
            tempPath = tempPath.appendingRelativePath(url.lastPathComponent)

            try tempPath.notStrictly.copyItem(from: .init(url.path))
            toURL = tempPath.url
            EventEdit.logger.info("Copy temp attachment success!")
        } catch {
            EventEdit.logger.error("Copy file to tempURL failed \(error)")
        }
        return toURL
    }

    private static func parseEditedImage(from: UIImage) -> URL? {
        var toURL: URL?
        do {
            let tempPath = Self.tempAttachmentPath.appendingRelativePath(Date().timeIntervalSince1970.description)
            try tempPath.createDirectoryIfNeeded()
            let path = tempPath + "IMG_\(Date().string(withFormat: "YYMMddHHmmss")).JPG"
            if let data = from.jpegData(compressionQuality: 1) {
                try path.createFileIfNeeded(with: data)
            }
            toURL = path.url
            EventEdit.logger.info("Edited image save success!")
        } catch {
            EventEdit.logger.error("Save edited image to tempURL failed \(error)")
        }
        return toURL
    }
}
