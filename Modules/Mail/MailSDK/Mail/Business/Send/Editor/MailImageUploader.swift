//
//  MailImageUploader.swift
//  MailSDK
//
//  Created by majx on 2019/6/14.
//

import Foundation
import RxSwift
import LarkRustClient
import RustPB

private let mailImageUploaderQueue: DispatchQueue = {
    let queue = DispatchQueue(label: "com.bytedance.mail.imageUploader", qos: .utility)
    return queue
}()

private let mailImageUploaderScheduler = SerialDispatchQueueScheduler(
    queue: mailImageUploaderQueue,
    internalSerialQueueName: mailImageUploaderQueue.label
)

class MailImageUploader {
    static let _wifiUploadTimeoutPerMB: Double = 5.0
    static let _celluarUploadTimeoutPerMB: Double = 5.0
    private var uploadTaskInfos = [UploadTaskInfo]()
    weak var uploaderDelegate: MailUploaderDelegate?
    var apiClient: MailImageUploadClient?
//    var apiClient2: AAA?
    private let disposeBag = DisposeBag()
    private var threadId: String? {
        return uploaderDelegate?.threadID
    }
    var draftId: String? {
        return uploaderDelegate?.draftID
    }

    init(with delegate: MailUploaderDelegate?) {
        self.uploaderDelegate = delegate
        self.apiClient = MailImageUploadClient(delegate: delegate)
//        self.apiClient2
    }

    deinit {
        cancelAllTasks()
    }
}

// MARK: - 类型定义
extension MailImageUploader {
    struct UploadTaskInfo {
        let uuid: String
        let fileSize: Int64
        let filePath: String
        let fileName: String
        let params: [String: Any]
        let completionHandler: (_ fileKey: String,
                                _ token: String?,
                                _ respKey: String?, // mailclient
                                _ dataSize: Int64,
                                _ progress: Float,
                                _ error: Error?,
                                _ startDownloadTime: Int) -> Void
    }
}

// MARK: - 图片上传流程
extension MailImageUploader {
    // 上传多张图片
    func uploadImages(_ taskInfos: [UploadTaskInfo], threadId: String?) {
        // 加入上传任务队列
        for info in taskInfos {
            uploadTaskInfos.append(info)
        }
        startUpload()
    }

    // 开始
    private func startUpload() {
        guard let taskInfo = uploadTaskInfos.first else {
            return
    }
        uploadTaskInfos.removeFirst()
        let fileKey = taskInfo.uuid
        let imgDataSize: Int64 = taskInfo.fileSize
        let startTime = MailTracker.getCurrentTime()
        if Store.settingData.mailClient {
            self.apiClient?.uploadImage(filePath: taskInfo.filePath, fileName: taskInfo.fileName,
                                        threadId: draftId,
                                        cid: taskInfo.uuid)
            .subscribe(onNext: { [weak self] (token, progress) in // 三方客户端传入的token为respKey 方法待抽离
                guard let `self` = self else { return }
                MailLogger.info("[mail_client_upload] apiClient?.uploadImage callback token: \(token) progress: \(progress)")
                taskInfo.completionHandler(fileKey, nil, token, imgDataSize, progress, nil, startTime)
                self.continueUpload()
            }, onError: { [weak self](err) in
                guard let `self` = self else { return }
                taskInfo.completionHandler(fileKey, nil, nil, imgDataSize, 0.00, err, startTime)
                self.continueUpload()
            }).disposed(by: disposeBag)
        } else {
            self.apiClient?.uploadImage(filePath: taskInfo.filePath, fileName: taskInfo.fileName, threadId: threadId, cid: nil)
            .subscribe(onNext: { [weak self] (token, progress) in
                guard let `self` = self else { return }
                taskInfo.completionHandler(fileKey, token, nil, imgDataSize, progress, nil, startTime)
                self.continueUpload()
            }, onError: { [weak self](err) in
                guard let `self` = self else { return }
                taskInfo.completionHandler(fileKey, nil, nil, imgDataSize, 0.00, err, startTime)
                self.continueUpload()
            }).disposed(by: disposeBag)
        }
    }

    private func continueUpload() {
        self.startUpload()
    }

    private func cancelAllTasks() {
        uploadTaskInfos.removeAll()
    }
}

// MARK: - 图片上传接口
protocol MailImageUploadAPI {
    /// 上传到draft
    func uploadImage(filePath: String, fileName: String, threadId: String?, cid: String?) -> Observable<(String, Float)>
}

class MailImageUploadClient: MailImageUploadAPI {
    let uploader: MailUploader
    weak var delegate: MailUploaderDelegate?
    private var user: User?

    init(delegate: MailUploaderDelegate?) {
        self.delegate = delegate
        self.user = delegate?.serviceProvider?.user
        uploader = MailUploader(commonUploader: delegate?.serviceProvider?.provider.attachmentUploader)
        uploader.delegate = delegate
    }

    /// 上传到draft
    func uploadImage(filePath: String, fileName: String, threadId: String?, cid: String?) -> Observable<(String, Float)> {
        let defaultError = NSError(domain: "com.bytedance.mail.error.uploadImage",
                                   code: -1,
                                   userInfo: nil)
        guard var userId = user?.info?.userID ?? user?.userID else {
            return Observable.error(defaultError)
        }
        /// 确保文件存在
        guard FileOperator.isExist(at: filePath) else {
            return Observable.error(defaultError)
        }

        if Store.settingData.mailClient {
            let initialProgress: Float = 0.3
            return uploader
                .upload(path: filePath, msgID: threadId ?? "", cid: cid ?? "")
                .map { respKey in
                    return (respKey, initialProgress) // TODO: progress
                }
        }

        var mountNodePoint = ""
        if self.delegate?.isSharedAccount() ?? false, let sharedAccountId = self.delegate?.sharedAccountId {
            mountNodePoint = "shared_mailbox_" + sharedAccountId
        } else if let threadId = threadId,
                  !threadId.isEmpty,
                    threadId != "0" {
            mountNodePoint = threadId
        } else {
            if userId.isEmpty || userId == "0" {
                if let id = user?.userID,
                    !id.isEmpty,
                    id != "0" {
                    userId = id
                } else {
                    mailAssertionFailure("[image_upload] userId invalid")
                    return Observable.error(defaultError)
                }
            }
            mountNodePoint = userId
        }
        MailLogger.info("[image_upload] threadId: \(threadId), cid: \(cid?.md5()), mountNodePoint=\(mountNodePoint)")

        return
        self.uploader
            .upload(localPath: filePath, fileName: fileName, mountNodePoint: mountNodePoint, mountPoint: "email")
            .map { (rustKey, progress, fileToken, _) in
                return (fileToken, progress)
            }
    }
}
