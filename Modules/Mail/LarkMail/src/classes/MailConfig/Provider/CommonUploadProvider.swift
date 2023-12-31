//
//  DocsUploaderProvider.swift
//  LarkMail
//
//  Created by tefeng liu on 2019/12/6.
//
// swiftlint:disable all

#if CCMMod
import Foundation
import SpaceInterface
import Swinject
import RxSwift
import MailSDK
import LarkContainer

class CommonUploadProvider {
    private var uploader: DocCommonUploadProtocol? {
        return try? resolver.resolve(assert: DocCommonUploadProtocol.self)
    }
    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }
}

extension DocCommonUploadStatus {
    var toAttachmentUploadStatus: AttachmentUploadStatus {
        switch self {
        case .cancel: return .cancel
        case .failed: return .failed
        case .inflight: return .inflight
        case .pending: return .pending
        case .queue: return .queue
        case .ready: return .ready
        case .success: return .success
        @unknown default:
            assert(false, "@liutefeng")
            return .failed
        }
    }
}

extension CommonUploadProvider: AttachmentUploadProxy {
    func upload(localPath: String,
                       fileName: String,
                       mountNodePoint: String,
                       mountPoint: String) -> Observable<(String, Float, String, AttachmentUploadStatus)> {
        guard let uploader = uploader else {
            return Observable<(String, Float, String, AttachmentUploadStatus)>.empty()
        }
        return uploader.upload(localPath: localPath,
                               fileName: fileName,
                               mountNodePoint: mountNodePoint,
                               mountPoint: mountPoint).map({ ($0.0, $0.1, $0.2, $0.3.toAttachmentUploadStatus) })
    }
    
    // 超大附件上传新增extra
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String,
                extra: [String: String]?) -> Observable<(String, Float, String, AttachmentUploadStatus)> {
        guard let uploader = uploader else {
            return Observable<(String, Float, String, AttachmentUploadStatus)>.empty()
        }
        return uploader.upload(localPath: localPath,
                    fileName: fileName,
                    mountNodePoint: mountNodePoint,
                    mountPoint: mountPoint,
                    extra: extra).map({ ($0.0, $0.1, $0.2, $0.3.toAttachmentUploadStatus) })
    }
    
    func cancelUpload(key: String) -> Observable<Bool> {
        guard let uploader = uploader else {
            return Observable<Bool>.just(false)
        }
        return uploader.cancelUpload(key: key)
    }

    func resumeUpload(key: String) -> Observable<Bool> {
        guard let uploader = uploader else {
            return Observable<Bool>.just(false)
        }
        return uploader.resumeUpload(key: key)
    }

    func deleteUploadResource(key: String) -> Observable<Bool> {
        guard let uploader = uploader else {
            return Observable<Bool>.just(false)
        }
        return uploader.deleteUploadResource(key: key)
    }
}
#endif
