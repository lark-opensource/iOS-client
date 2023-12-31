//
//  File.swift
//  Action
//
//  Created by tefeng liu on 2019/6/3.
//

import Foundation
import RxSwift
import RustPB
import LarkStorage
import LarkCache


/// 用于MailSend页面更高级的封装
protocol MailSendUploaderProtocol {
    func upload(attachments: [MailSendAttachment])
    func addObserver(_ observer: MailSendUploaderObserver)
    func removeObserver(_ observer: MailSendUploaderObserver)
}

private var attachmentsToUploadKey: Void?
private var mailSendObservers: Void?

private let mailMountPoint: String = "email"

typealias MailSendAttachmentUploadStatus = Space_Drive_V1_PushUploadCallback.Status

protocol MailSendUploaderObserver: AnyObject {

    func mailUploader(_ uploader: MailUploader, didUploadProgressUpdate progress: Float, attachment: MailSendAttachment, fileToken: String)
    func mailUploader(_ uploader: MailUploader, didUploadStatusChange status: MailSendAttachmentUploadStatus, attachment: MailSendAttachment,
                      fileToken: String, respKey: String?)
    func mailUploader(_ uploader: MailUploader, didUploadFinishHasFailedState hasFailed: Bool, attachmentsSize: Int64)
}

final private class Wrapper {
    let base: Any
    init(_ base: Any) {
        self.base = base
    }
}

private let uploadingFileSubPath = "attachment_upload_caches/uploading"

extension MailUploader: MailSendUploaderProtocol {
    private var uploadingFilePath: FileOperator {
        FileOperator.getAttachmentLibraryDir(userID: delegate?.serviceProvider?.user.userID)
    }

    private var attachmentsToUpload: ThreadSafeArray<MailSendAttachment>? { // 后面看有无必要换成线程安全的container。
        get {
            let value = objc_getAssociatedObject(self, &attachmentsToUploadKey) as? Wrapper
            return value?.base as? ThreadSafeArray<MailSendAttachment>
        }
        set(newValue) {
            if let value = newValue {
                let wrapper = Wrapper(value)
                objc_setAssociatedObject(self, &attachmentsToUploadKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else {
                objc_setAssociatedObject(self, &attachmentsToUploadKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    private var observersContainer: ObserverContainer<MailSendUploaderObserver> { // 换成弱引用
        get {
            var container = objc_getAssociatedObject(self, &mailSendObservers) as? ObserverContainer<MailSendUploaderObserver>
            if container == nil {
                container = ObserverContainer<MailSendUploaderObserver>()
                objc_setAssociatedObject(self, &mailSendObservers, container, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return container!
        }
        set(newValue) {
            objc_setAssociatedObject(self, &mailSendObservers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func addObserver(_ observer: MailSendUploaderObserver) {
        observersContainer.add(observer)
    }
    
    func removeObserver(_ observer: MailSendUploaderObserver) {
        observersContainer.remove(observer)
    }
    
    func upload(attachments: [MailSendAttachment]){
        guard !attachments.isEmpty else {
            return
        }
        let totalStartTime = MailTracker.getCurrentTime()
        if let upload = attachmentsToUpload {
            let all = upload.all
            attachments.forEach { att in
                if !all.contains(att) {
                    attachmentsToUpload?.append(newElement: att)
                }
            }
        } else {
            attachmentsToUpload = ThreadSafeArray<MailSendAttachment>(array: attachments)
        }

        func nextUploadAttachment() -> MailSendAttachment? {
            guard let uploadList = attachmentsToUpload else {
                return nil
            }
            return uploadList.isEmpty ? nil : uploadList.first!
        }

        guard var mountNodePoint = delegate?.serviceProvider?.user.info?.userID else {
            return
        }
        
        func recursiveUpload () {
            guard var uploadItem = nextUploadAttachment(), let localFile = uploadItem.fileInfo else {
                // 回调所有文件上传完成时机
                self.mailUploader(self, didUploadFinishHasFailedState: self.hasUploadFailed, attachmentsSize:self.uploadFailedFileSizes)
                return
            }
            guard !uploadItem.fileExtension.isHarmful else {
                attachmentsToUpload?.removeFirst()
                recursiveUpload()
                return
            }
                        
            var currentFileToken: String = ""
            var cachePath = uploadItem.cachePath ?? ""
            if cachePath.isEmpty {
                cachePath = copyItemToUploadingPath(localPath: localFile.fileURL, fileName: "\(Date.init().timeIntervalSince1970)" + localFile.name)
            }
            if cachePath.isEmpty {
                MailLogger.info("upload cachePath empty")
                assert(true) // 查一下为什么拷贝不成功
                return
            }
            uploadItem.cachePath = cachePath
            reference = uploadItem
            /// for shared account mount node point
            if delegate?.isSharedAccount() == true {
                guard let sharedAccountId = delegate?.sharedAccountId, sharedAccountId.count > 0 else {
                    mailAssertionFailure("must have thread id in colla mail")
                    return
                }
                mountNodePoint = "shared_mailbox_" + sharedAccountId
            }
            /// 超大附件 mount node point 需要拼接标识符
            if FeatureManager.open(.largeAttachmentManage, openInMailClient: false) {
                mountNodePoint += "SupportLargeAttachmentPermanent"
            }
            let event = MailAPMEvent.DraftUploadAttachment()
            event.markPostStart()
            let size = uploadItem.fileSize
            
            if Store.settingData.mailClient {
                _ = upload(path: cachePath, msgID: delegate?.draftID ?? "", cid: "").subscribe(
                    onNext: { [weak self] (respKey) in
                        guard let `self` = self else { return }
                        self.mailUploader(self, didUploadStatusChange: .success, attachment: uploadItem, fileToken: "", respKey: respKey)
                        self.removeFirstIfNeed()
                        self.reference = nil
                        recursiveUpload()
                        
                    }, onError: { [weak self] (error) in
                        MailLogger.error("upload fail!\(error.localizedDescription)")
                        guard let `self` = self else { return }
                        let fileExist = FileOperator.isExist(at: cachePath)
                        let fileCnt = self.uploadingPathFileCount()
                        MailLogger.info("upload fail，fileExist=\(fileExist), fileCnt=\(fileCnt)")
                        self.mailUploader(self, didUploadStatusChange: .failed, attachment: uploadItem, fileToken: currentFileToken, respKey: nil)
                        self.removeFirstIfNeed()
                        self.reference = nil
                        recursiveUpload()
                    }, onCompleted: { [weak self] in
                        // 成功会走这个
                        guard let `self` = self else { return }
                    }).disposed(by: disposeBag)
            } else {
                let extra : [String: String]? = uploadItem.type == .large ? ["extra":String(uploadItem.fileSize)] : nil
                _ = upload(localPath: cachePath, fileName: localFile.name, mountNodePoint: mountNodePoint, mountPoint: mailMountPoint, extra: extra).subscribe(
                    onNext: { [weak self] (rustKey, progress, fileToken, status) in
                        currentFileToken = fileToken
                        self?.currentFileKey = rustKey
                        
                        if status == .inflight, let `self` = self {
                            self.mailUploader(self, didUploadProgressUpdate: progress, attachment: uploadItem, fileToken: currentFileToken)
                        }
                    }, onError: { [weak self] (error) in
                        MailLogger.error("上传失败!\(error.localizedDescription)")
                        guard let `self` = self else { return }
                        self.hasUploadFailed = true
                        self.uploadFailedFileSizes += Int64(uploadItem.fileSize)
                        let fileExist = FileOperator.isExist(at: cachePath)
                        let fileCnt = self.uploadingPathFileCount()
                        MailLogger.info("上传失败，fileExist=\(fileExist), fileCnt=\(fileCnt)")
                        self.mailUploader(self, didUploadStatusChange: .failed, attachment: uploadItem, fileToken: currentFileToken, respKey: nil)
                        self.removeFirstIfNeed()
                        self.reference = nil
                        recursiveUpload()
                        let driveErrCode: Int32 = 13001
                        if self.canceledAttachments.contains(uploadItem.displayName) {
                            MailLogger.info("canceled attachment, abandon report")
                            event.abandon()
                        } else if let errorCode = error.errorCode(), errorCode != driveErrCode { // 需要过滤掉drive容量不足的case
                            event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                            event.endParams.appendError(error: error)
                            event.endParams.append(MailAPMEvent.DraftUploadAttachment.EndParam.resource_content_length(size))
                            event.postEnd()
                        } else {
                            event.abandon()
                        }
                        InteractiveErrorRecorder.recordError(event: .compose_attachment_upload_failed)
                    }, onCompleted: { [weak self] in
                        // 成功会走这个
                        guard let `self` = self else { return }
                        self.mailUploader(self, didUploadStatusChange: .success, attachment: uploadItem, fileToken: currentFileToken, respKey: nil)
                        self.removeFirstIfNeed()
                        self.reference = nil
                        recursiveUpload()
                        event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                        event.endParams.append(MailAPMEvent.DraftUploadAttachment.EndParam.resource_content_length(size))
                        event.endParams.append(MailAPMEvent.DraftUploadAttachment.EndParam
                            .upload_ms(MailTracker.getCurrentTime() - Int(1000 * event.recordDate.timeIntervalSince1970)))
                        // 比较奇葩的埋点需求，需要记录距离用户上传开始了多久。。。所以强行重置起点
                        event.recordDate = Date(timeIntervalSince1970: Double(totalStartTime / 1000))
                        event.postEnd()
                    }).disposed(by: disposeBag)
            }
        }
        if self.reference == nil {
            recursiveUpload()
        }
    }
    
    func cancellAll() {
        if  attachmentsToUpload != nil &&
                !attachmentsToUpload!.isEmpty { // 不为空
            attachmentsToUpload!.removeFirst() // 掉第一个。
            cancelUpload(key: currentFileKey).subscribe(onNext: {_ in
            }).disposed(by: disposeBag)
            deleteUploadResource(key: currentFileKey).subscribe(onNext: {_ in
            }).disposed(by: disposeBag)
            cleanUploadingDirectory()
            reference = nil
            attachmentsToUpload = ThreadSafeArray<MailSendAttachment>(array: []) // clean
            return
        }
    }
    
    func cancel(attachment: MailSendAttachment) {
        if let temp = reference {
            if temp is MailSendAttachment &&
                attachmentsToUpload != nil &&
                attachmentsToUpload!.first == attachment { // 当前正在上传的就是取消的。
                attachmentsToUpload!.removeFirst() // 掉第一个。
                cancelUpload(key: currentFileKey).subscribe(onNext: { [weak self] _ in
                    self?.canceledAttachments.append(attachment.displayName)
                }).disposed(by: disposeBag)
                deleteUploadResource(key: currentFileKey).subscribe(onNext: {_ in
                }).disposed(by: disposeBag)
                cleanUploadingDirectory()
                reference = nil
                // 判断是否需要继续接下来的。
                if !attachmentsToUpload!.isEmpty {
                    upload(attachments: attachmentsToUpload!.all)
                }
                return
            }
        }
        
        let newArray = attachmentsToUpload?.all.filter({ (item) -> Bool in
            item != attachment
        })
        if let newArray = newArray {
            attachmentsToUpload = ThreadSafeArray<MailSendAttachment>(array: newArray)
        }
    }
    
    // MARK: helper
    
    private func removeFirstIfNeed() {
        if let reference = reference {
            if reference is MailSendAttachment &&
                attachmentsToUpload != nil &&
                !attachmentsToUpload!.isEmpty &&
                attachmentsToUpload!.first == (reference as! MailSendAttachment) {
                attachmentsToUpload!.removeFirst()
            }
        }
    }
    
    /// 将要上传的文件拷贝到目标文件夹
    private func copyItemToUploadingPath(localPath: URL, fileName: String) -> String {
        let uploadingFilePath = uploadingFilePath.path + fileName
        let cachePath = uploadingFilePath + fileName
        if FileOperator.copyItem(at: localPath.asAbsPath(), to: cachePath) {
            if cachePath.url.pathExtension == "eml" || cachePath.url.pathExtension == "msg" {
                if let decodePath = try? cachePath.url.path.decrypt() {
                    return decodePath.rawValue
                }
            }
            return cachePath.url.path
        }
        return ""
    }
    
    /// 取消后清除正在上传目录
    private func cleanUploadingDirectory() {
        let uploadingFilePath = uploadingFilePath.path + uploadingFileSubPath
        uploadingFilePath.children(recursive: false).map { try? $0.removeItem() }
    }
    
    private func uploadingPathFileCount() -> Int {
        return uploadingFilePath.path.children(recursive: false).count
    }
    
    // MARK: Observer
    func mailUploader(_ uploader: MailUploader, didUploadProgressUpdate progress: Float, attachment: MailSendAttachment, fileToken: String) {
        observersContainer.enumerateObjectUsing { (_, observer) in
            observer.mailUploader(uploader, didUploadProgressUpdate: progress, attachment: attachment, fileToken: fileToken)
        }
    }
    
    func mailUploader(_ uploader: MailUploader, didUploadStatusChange status: MailSendAttachmentUploadStatus, attachment: MailSendAttachment, fileToken: String, respKey: String?) {
        observersContainer.enumerateObjectUsing { (_, observer) in
            observer.mailUploader(uploader, didUploadStatusChange: status, attachment: attachment, fileToken: fileToken, respKey: respKey)
        }
    }
    
    func mailUploader(_ uploader: MailUploader, didUploadFinishHasFailedState hasFailed: Bool, attachmentsSize: Int64) {
        observersContainer.enumerateObjectUsing { (_, observer) in
            observer.mailUploader(uploader, didUploadFinishHasFailedState: hasFailed, attachmentsSize: attachmentsSize)
        }
    }
}

extension MailUploader {
    var isFinished: Bool {
        guard let attachments = attachmentsToUpload else {
            return true
        }
        return attachments.isEmpty
    }
}
