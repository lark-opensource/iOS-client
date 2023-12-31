//
//  File.swift
//  Action
//
//  Created by tefeng liu on 2019/5/30.
//

import Foundation
import RxSwift
import RxRelay
import ThreadSafeDataStructure

/// 基础上传方法
// swiftlint:disable large_tuple
// 三方客户端复用此协议
protocol MailUploaderProtocol {

    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String) -> Observable<(String, Float, String, AttachmentUploadStatus)>
    // 超大附件管理走这个
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String,
                extra: [String: String]?) -> Observable<(String, Float, String, AttachmentUploadStatus)>
    
    func cancelUpload(key: String) -> Observable<Bool>

    func deleteUploadResource(key: String) -> Observable<Bool>

    func upload(path: String, msgID: String, cid: String) -> Observable<String>
}

protocol MailUploaderDelegate: AnyObject {
    var threadID: String? { get }
    func isSharedAccount() -> Bool
    var sharedAccountId: String? { get }
    var draftID: String? { get }
    var serviceProvider: MailSharedServicesProvider? { get }
}

///////////////////////////////////////////////////////////////////////////
class MailUploader {
    weak var delegate: MailUploaderDelegate?
    let disposeBag: DisposeBag = DisposeBag()

    var reference: Any? // 指向正在上传的的
    var currentFileKey: String = ""
    var canceledAttachments = SafeArray<String>(synchronization: .readWriteLock)

    var uploadTask = BehaviorRelay<(String, MailUploadPushChange?)>(value: ("", nil))
    private var _uploadTask = [String: MailUploadPushChange]()
    
    var commonUploader: AttachmentUploadProxy?
    
    // 超大附件是否有上传失败 bossSize = 邮箱容量（file + text + image） + 超大附件Size 【这里只负责超大附件】
    var hasUploadFailed: Bool = false
    var uploadFailedFileSizes: Int64 = 0
    
    init(commonUploader: AttachmentUploadProxy?) {
        self.commonUploader = commonUploader
        MailCommonDataMananger
            .shared
            .uploadPushChange
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] change in
                self?.mailUploadPushChange(change)
            }).disposed(by: disposeBag)
    }

    func mailUploadPushChange(_ change: MailUploadPushChange) {
        MailLogger.info("[mail_client_upload] uploadTaskObservable mailUploadPushChange -- key: \(change.key) status: \(change.status) token: \(change.token)")
        let key = change.key
        _uploadTask.updateValue(change, forKey: change.key)
        if change.status == .success {
            MailLogger.info("[mail_client_upload] uploadTaskObservable uploadTask accept -- key: \(change.key) status: \(change.status) token: \(change.token)")
            uploadTask.accept((key, change))
            _uploadTask.removeValue(forKey: key)
        }
    }

    deinit {
        MailLogger.info("[mail_client_upload] Uploader deinit")
    }
}

extension MailUploader: MailUploaderProtocol {
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String,
                extra: [String : String]?) -> RxSwift.Observable<(String, Float, String, AttachmentUploadStatus)> {
        guard let uploader = commonUploader else {
            return PublishSubject<(String, Float, String, AttachmentUploadStatus)>()
        }
        return Observable.create { [weak self] observer in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let `self` = self else { return }
                uploader.upload(localPath: localPath,
                                fileName: fileName,
                                mountNodePoint: mountNodePoint,
                                mountPoint: mountPoint,
                                extra: extra)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: {(rustKey, progress, fileToken, status) in
                        observer.onNext((rustKey, progress, fileToken, status))
                    }, onError: {(error) in
                        observer.onError(error)
                    }, onCompleted: {
                        observer.onCompleted()
                    }).disposed(by: self.disposeBag)
            }
            return Disposables.create()
        }
    }
    
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String, // obj:$obj_type:$obj_token  eg => obj:2:fsadfereafdsferw
                mountPoint: String = "email") -> Observable<(String, Float, String, AttachmentUploadStatus)> {
        guard let uploader = commonUploader else {
            return PublishSubject<(String, Float, String, AttachmentUploadStatus)>()
        }
        return Observable.create { [weak self] observer in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let `self` = self else { return }
                uploader.upload(localPath: localPath,
                                fileName: fileName,
                                mountNodePoint: mountNodePoint,
                                mountPoint: mountPoint)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: {(rustKey, progress, fileToken, status) in
                        observer.onNext((rustKey, progress, fileToken, status))
                    }, onError: {(error) in
                        observer.onError(error)
                    }, onCompleted: {
                        observer.onCompleted()
                    }).disposed(by: self.disposeBag)
            }
            return Disposables.create()
        }
    }

    func cancelUpload(key: String) -> Observable<Bool> {
        guard let uploader = commonUploader else {
            return Observable.just(false)
        }
        return uploader.cancelUpload(key: key)
    }

    func deleteUploadResource(key: String) -> Observable<Bool> {
        guard let uploader = commonUploader else {
            return Observable.just(false)
        }
        return uploader.deleteUploadResource(key: key)
    }

    func upload(path: String, msgID: String, cid: String) -> Observable<String> {
        MailLogger.info("[mail_client_upload] upload attachment path: \(path) msgID: \(msgID) cid: \(cid.md5())")
        return Observable.create { [weak self] observer in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let `self` = self else { return }
                MailDataSource.shared.mailUploadRequest(path: path, messageID: msgID)
                    .subscribe(onNext: { [weak self] (resp) in
                        guard let `self` = self else { return }
                        MailLogger.info("[mail_client_upload] upload attachment for preview resp key: \(resp.key)")
                        observer.onNext((resp.key))
                    }, onError: { (error) in
                        observer.onError(error)
                        MailLogger.info("[mail_client_upload] upload attachment error: \(error)")
                    }, onCompleted: {
                        observer.onCompleted()
                    }).disposed(by: self.disposeBag)
            }
            return Disposables.create()
        }
    }
}
// swiftlint:enable large_tuple
