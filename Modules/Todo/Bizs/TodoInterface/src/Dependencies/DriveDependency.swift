//
//  DriveDependency.swift
//  TodoInterface
//
//  Created by baiyantao on 2022/12/27.
//

import Foundation
import RxSwift
import LarkStorage

public protocol DriveDependency {
    func upload(localPath: String, fileName: String) -> Observable<TaskUploadInfo>
    func resumeUpload(key: String) -> Observable<TaskUploadInfo>
    func cancelUpload(key: String) -> Observable<Bool>
    func deleteUploadResource(key: String) -> Observable<Bool>
    func previewFile(from: UIViewController, fileToken: String)
    func previewFileInPresent(from: UIViewController, fileToken: String)
    func getUploadCachePath(with fileName: String) -> IsoPath
}

public struct TaskUploadInfo: Equatable {
    public let guid: String
    // 可用来cancel、resume、delete上传任务
    public var uploadKey: String?
    public var progress: Float?
    public var fileToken: String?
    public var uploadStatus: TaskUploadStatus

    public init(
        uploadKey: String? = nil,
        progress: Float? = nil,
        fileToken: String? = nil,
        uploadStatus: TaskUploadStatus = .uploading
    ) {
        self.guid = UUID().uuidString.lowercased()
        self.uploadKey = uploadKey
        self.progress = progress
        self.fileToken = fileToken
        self.uploadStatus = uploadStatus
    }
}

public enum TaskUploadStatus: Int {
    case uploading
    case failed
    case success
    case cancel
}

public struct TaskFileInfo {
    public let name: String
    public let fileURL: String
    public let size: UInt?
    public let uploadTime: Int64

    public init(name: String, fileURL: String, size: UInt?, uploadTime: Int64? = nil) {
        self.name = name
        self.fileURL = fileURL
        self.size = size
        self.uploadTime = uploadTime ?? Int64(Date().timeIntervalSince1970 * 1_000)
    }
}

extension TaskUploadInfo {
    public var logInfo: String {
        return "key: \(uploadKey ?? ""), pro: \(progress ?? 0), token: \(fileToken ?? ""), status: \(uploadStatus.rawValue)"
    }
}

extension TaskFileInfo {
    public var logInfo: String {
        return "n: \(name.count), f: \(fileURL.count), s: \(size ?? 0), u: \(uploadTime)"
    }
}
