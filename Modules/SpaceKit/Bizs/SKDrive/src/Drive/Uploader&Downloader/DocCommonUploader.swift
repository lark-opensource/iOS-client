//
//  DocCommonUploader.swift
//  LarkApp
//
//  Created by maxiao on 2019/8/2.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import SpaceInterface
import ThreadSafeDataStructure
import SKCommon
import SKFoundation

extension DocCommonUploadPriority {
    var rustPriority: DriveUploadPriority {
        switch self {
        case .userInteraction:
            return .userInteraction
        case .defaultHigh:
            return .defaultHigh
        case .default:
            return .default
        case .defaultLow:
            return .defaultLow
        case .background:
            return .background
        default:
            return .custom(priority: rawValue)
        }
    }
}

public final class DocCommonUploader {
    private let uploader = SpaceRustRouter.shared
    private var jobs = SafeDictionary<String, PublishSubject<(String, Float, String, DocCommonUploadStatus)>>()
    public init() {
        DriveUploadCallbackService.shared.addObserver(self)
    }
}

extension DocCommonUploader: DocCommonUploadProtocol {
    public var ready: Observable<Bool> {
        return uploader.driveInitFinishObservable.asObservable()
    }

    public func upload(
        localPath: String,
        fileName: String,
        mountNodePoint: String,
        mountPoint: String,
        copyInsteadMoveAfterSuccess: Bool,
        priority: DocCommonUploadPriority
    ) -> Observable<(String, Float, String, DocCommonUploadStatus)> {
        return upload(
            localPath: localPath,
            fileName: fileName,
            mountNodePoint: mountNodePoint,
            mountPoint: mountPoint,
            copyInsteadMoveAfterSuccess: copyInsteadMoveAfterSuccess,
            priority: priority,
            extra: nil
        )
    }

    public func upload(localPath: String,
                       fileName: String,
                       mountNodePoint: String, // obj:$obj_type:$obj_token  eg => obj:2:fsadfereafdsferw
                       mountPoint: String,
                       copyInsteadMoveAfterSuccess: Bool,
                       priority: DocCommonUploadPriority,
                       extra: [String: String]?) -> Observable<(String, Float, String, DocCommonUploadStatus)> {
        let context = DriveUploadRequestContext(localPath: localPath,
                                                fileName: fileName,
                                                mountNodePoint: mountNodePoint,
                                                mountPoint: mountPoint,
                                                uploadCode: nil,
                                                scene: .unknown,
                                                objType:  nil,
                                                apiType: nil,
                                                priority: priority.rustPriority,
                                                extraParams: [:],
                                                extRust: extra ?? [:])
        return uploader.upload(context: context)
            .flatMap {[weak self] (key) -> Observable<(String, Float, String, DocCommonUploadStatus)> in
                guard let self = self else { return .empty() }
                let progressSubject = PublishSubject<(String, Float, String, DocCommonUploadStatus)>()
                self.jobs[key] = progressSubject
                if copyInsteadMoveAfterSuccess {
                    DriveUploadCallbackService.shared.addToUploadSuccessCopyInsteadOfMove(key: key)
                }
                return progressSubject.asObserver()
            }
    }

    public func upload(localPath: String,
                       fileName: String,
                       mountPoint: String,
                       uploadCode: String,
                       copyInsteadMoveAfterSuccess: Bool,
                       priority: DocCommonUploadPriority) -> Observable<(String, Float, String, DocCommonUploadStatus)> {
        let context = DriveUploadRequestContext(localPath: localPath,
                                                fileName: fileName,
                                                mountNodePoint: "",
                                                mountPoint: mountPoint,
                                                uploadCode: uploadCode,
                                                scene: .unknown,
                                                objType:  nil,
                                                apiType: nil,
                                                priority: priority.rustPriority,
                                                extraParams: [:],
                                                extRust: [:])
        return uploader.upload(context: context)
            .flatMap {[weak self] (key) -> Observable<(String, Float, String, DocCommonUploadStatus)> in
                guard let self = self else { return .empty() }
                let progressSubject = PublishSubject<(String, Float, String, DocCommonUploadStatus)>()
                self.jobs[key] = progressSubject
                if copyInsteadMoveAfterSuccess {
                    DriveUploadCallbackService.shared.addToUploadSuccessCopyInsteadOfMove(key: key)
                }
                return progressSubject.asObserver()
            }
    }
    public func cancelUpload(key: String) -> Observable<Bool> {
        return uploader.cancelUpload(key: key).map { (result) -> Bool in
            return result == -1 ? false : true
        }
    }

    public func resumeUpload(key: String, copyInsteadMoveAfterSuccess: Bool) -> Observable<(String, Float, String, DocCommonUploadStatus)> {
        return uploader.resumeUpload(key: key).flatMap { [weak self] (result) -> Observable<(String, Float, String, DocCommonUploadStatus)> in
            guard let self = self else {
                return Observable.never()
            }
            guard result != -1 else {
                DocsLogger.error("resume upload failed with key: \(key), result code: \(result)")
                return Observable.error(NSError(domain: "drivesdk.common.uploader.error", code: -1, userInfo: ["fileKey": key]))
            }
            let progressSubject = PublishSubject<(String, Float, String, DocCommonUploadStatus)>()
            self.jobs[key] = progressSubject
            if copyInsteadMoveAfterSuccess {
                DriveUploadCallbackService.shared.addToUploadSuccessCopyInsteadOfMove(key: key)
            }
            return progressSubject.asObserver()
        }
    }
    
    public func resumeUpload(key: String) -> Observable<Bool> {
        return uploader.resumeUpload(key: key).map { (result) -> Bool in
            return result == -1 ? false : true
        }
    }

    public func deleteUploadResource(key: String) -> Observable<Bool> {
        return uploader.deleteUploadResource(key: key).map { (result) -> Bool in
            return result == -1 ? false : true
        }
    }
}

extension DocCommonUploader: DriveUploadCallback {

    public func updateProgress(context: DriveUploadContext) {
        guard let subject = jobs[context.key] else { return }
        subject.onNext((context.key, Float(context.bytesTransferred) / Float(context.bytesTotal), context.fileToken, DocCommonUploadStatus(rawValue: context.status.rawValue) ?? .pending))
        if context.status == .success {
            subject.onCompleted()
            jobs.removeValue(forKey: context.key)
        }
    }

    public func onFailed(key: String, mountPoint: String, scene: DriveUploadScene, errorCode: Int, fileSize: Int64) {
        guard let subject = jobs[key] else { return }
        subject.onError(NSError(domain: "drivesdk.common.uploader.error",
                                code: errorCode,
                                userInfo: ["fileKey": key]))
        jobs.removeValue(forKey: key)
    }
}

extension DriveUploadFile: DocCommonFile {
    public var commonKey: String { return self.key }
    public var commonFileName: String { return self.fileName }
    public var commonType: String { return self.fileType }
}
