//
//  MomentsDependency.swift
//  Moment
//
//  Created by zhuheng on 2021/1/4.
//

import Foundation
import RxSwift
public typealias LarkMomentDependency = DirveSDKUploadDependency

public enum MomentsUploadStatus: Int {
    case uploading
    case failed
    case success
    case cancel
}

public struct MomentsUploadInfo {
    // uploadKey: 此次上传任务的token，可以用来cancel、resume、delete上传任务
    public let uploadKey: String
    // progress: 上传进度百分比
    public let progress: Float
    // fileToken: 文档token
    public let fileToken: String
    // 上传状态
    public let uploadStatus: MomentsUploadStatus
    public init(uploadKey: String, progress: Float, fileToken: String, uploadStatus: MomentsUploadStatus) {
        self.uploadKey = uploadKey
        self.progress = progress
        self.fileToken = fileToken
        self.uploadStatus = uploadStatus
    }
}

public protocol DirveSDKUploadDependency {

    /// 上传接口
    /// - Parameters:
    ///   - localPath: 本地路径
    ///   - fileName: 文件名字
    ///   - mountNodePoint
    ///   - mountPoint
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String) -> Observable<MomentsUploadInfo>?
}

extension DirveSDKUploadDependency {
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String) -> Observable<MomentsUploadInfo> {
        upload(localPath: localPath,
               fileName: fileName,
               mountNodePoint: mountNodePoint,
               mountPoint: mountPoint) ?? .just(MomentsUploadInfo(uploadKey: "", progress: 0, fileToken: "", uploadStatus: .failed))
    }
}
