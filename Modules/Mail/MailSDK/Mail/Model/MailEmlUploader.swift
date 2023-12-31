//
//  File.swift
//  Action
//
//  Created by tanghaojin on 2023/4/6.
//

import Foundation
import RxSwift
import RxRelay
import ServerPB
import RustPB
import ThreadSafeDataStructure


protocol MailEmlUploaderDelegate: AnyObject {
    func emlUploadFailed(bizId: String, uuid: String, errorText: String)
    func emlUploadSuccess(bizId: String,
                          uuid: String,
                          fileToken: String,
                          status: ServerPB_Mails_UploadEmlAsAttachmentStatus)
    func emlUploadStarted(bizId: String, uuid: String)
    func emlUploadPending(tasks: [EmlUploadTask])
}

struct EmlUploadTask {
    var uuid: String
    var bizId: String
    var retryCnt: Int
}
class MailEmlUploader {
    let disposeBag: DisposeBag = DisposeBag()
    let emlTooLargeCode = 250702
    let retryInterval: TimeInterval = 5 // 失败后重试间隔为5s
    let reqTimeOut = 30 // 超时时间30s
    static let maxRetryCnt = 3 // 最大重试次数
    
    let serialQueue = DispatchQueue(label: "MailSDK.EmlUploader.Queue",
                                                       attributes: .init(rawValue: 0))
    weak var delegate: MailEmlUploaderDelegate? =  nil
    private var pendingTasks: SafeArray<EmlUploadTask> = SafeArray([],
                                                                     synchronization: .readWriteLock)
    private var failedTasks: SafeArray<EmlUploadTask> = SafeArray([],
                                                                    synchronization: .readWriteLock)
    private var uploadTask: SafeAtomic<EmlUploadTask?> = nil + .readWriteLock

    init() {}

    deinit {
        MailLogger.info("[mail_eml_upload] eml uploader deinit")
    }
    public func retryTask(task: EmlUploadTask) {
        self.serialQueue.async { [weak self] in
            guard let `self` = self else { return }
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.emlUploadPending(tasks: [task])
            }
            // 过滤掉retry任务
            self.failedTasks = self.failedTasks.filter { taskItem in
                return taskItem.bizId != task.bizId
            }
            self.pendingTasks.insert(task, at: 0)
            self.uploadIfNeed()
        }
    }
    public func addAttachments(tasks: [EmlUploadTask]) {
        self.serialQueue.async { [weak self] in
            guard let `self` = self else { return }
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.emlUploadPending(tasks: tasks)
            }
            self.pendingTasks.append(contentsOf: tasks)
            self.uploadIfNeed()
        }
    }
    public func cancelAttachment(tasks: [EmlUploadTask]) {
        self.serialQueue.async { [weak self] in
            guard let `self` = self else { return }
            let taskBizIds = tasks.map { $0.bizId }
            self.pendingTasks = self.pendingTasks.filter { task in
                return !taskBizIds.contains(task.bizId)
            }
            self.failedTasks = self.failedTasks.filter { task in
                return !taskBizIds.contains(task.bizId)
            }
        }
    }
    public func cancelAll() {
        self.serialQueue.async { [weak self] in
            guard let `self` = self else { return }
            self.pendingTasks.removeAll()
            self.failedTasks.removeAll()
        }
    }
    public func AllTaskFinished() -> Bool {
        return self.pendingTasks.isEmpty && self.failedTasks.isEmpty && self.uploadTask.value == nil
    }
    private func uploadIfNeed(delay: TimeInterval = 0) {
        self.serialQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let `self` = self else { return }
            guard self.uploadTask.value == nil else { return }
            guard self.pendingTasks.isEmpty == false else { return }
            if let firstTask = self.pendingTasks.first {
                self.pendingTasks.remove(at: 0)
                self.uploadTask.value = firstTask
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.emlUploadStarted(bizId: firstTask.bizId, uuid: firstTask.uuid)
                }
                MailDataServiceFactory.commonDataService?.uploadEmlAsAttachmentRequest(bizId: firstTask.bizId,
                                                                                       uuid: firstTask.uuid).timeout(.seconds(self.reqTimeOut), scheduler: MainScheduler.instance).subscribe( onNext: { [weak self] resp in
                    guard let `self` = self else { return }
                    
                    if self.uploadTask.value?.uuid == firstTask.uuid {
                        self.uploadTask.value = nil
                    }
                    if resp.status == .processing {
                        MailLogger.info("upload eml processing, res=\(resp)")
                        self.retryLogic(firstTask: firstTask,
                                        errorText: "",
                                        errorCode: 0)
                    } else {
                        MailLogger.info("upload eml success, res=\(resp)")
                        self.delegate?.emlUploadSuccess(bizId: firstTask.bizId, uuid: firstTask.uuid, fileToken: resp.fileToken, status: resp.status)
                        self.uploadIfNeed()
                    }
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    MailLogger.error("upload eml failed \(error), code=\(error.mailErrorCode)")
                    self.uploadTask.value = nil
                    var errorText = ""
                    if error.mailErrorCode == self.emlTooLargeCode {
                        errorText = BundleI18n.MailSDK.Mail_MailAttachment_TooLargeDownloadThenUpload_Error
                    }
                    self.retryLogic(firstTask: firstTask,
                                    errorText: errorText,
                                    errorCode: error.mailErrorCode)
                }).disposed(by: self.disposeBag)
            }
        }
    }

    private func retryLogic(firstTask: EmlUploadTask,
                            errorText: String,
                            errorCode: Int) {
        if errorCode != self.emlTooLargeCode &&
            firstTask.retryCnt > 0 {
            // 需要重试
            var retryTask = firstTask
            retryTask.retryCnt = retryTask.retryCnt - 1
            self.pendingTasks.insert(retryTask, at: 0)
            self.uploadIfNeed(delay: self.retryInterval)
        } else {
            self.delegate?.emlUploadFailed(bizId: firstTask.bizId,
                                           uuid: firstTask.uuid,
                                           errorText: errorText)
            self.failedTasks.append(firstTask)
            self.uploadIfNeed()
        }
    }
    
}

