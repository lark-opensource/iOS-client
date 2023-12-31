//
//  AttachmentUploadProxy.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/10/28.
//

import Foundation
import RxSwift

public enum AttachmentUploadStatus: Int {
    case pending
    case inflight
    case failed
    case success
    case queue
    case ready
    case cancel
}

// swiftlint:disable large_tuple
public protocol AttachmentUploadProxy {
    /// 使用默认优先级上传文件
    func upload(localPath: String,
                       fileName: String,
                       mountNodePoint: String,
                       mountPoint: String) -> Observable<(String, Float, String, AttachmentUploadStatus)>
    
    // 超大附件上传新增extra
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String,
                extra: [String: String]?) -> Observable<(String, Float, String, AttachmentUploadStatus)>
    
    func cancelUpload(key: String) -> Observable<Bool>

    func resumeUpload(key: String) -> Observable<Bool>

    func deleteUploadResource(key: String) -> Observable<Bool>
}
