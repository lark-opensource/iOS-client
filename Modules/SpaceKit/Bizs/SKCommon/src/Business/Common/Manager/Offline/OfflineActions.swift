//
//  OfflineActions.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/22.
//  

import Foundation
import SwiftyJSON
import SKFoundation

public enum UpSyncStatus: Int {
    case none = 1       // 没有任何同步状态
    case waiting = 2    // 等待同步
    case uploading = 3  // 正在同步中
    case finish = 4     // 同步完成，还没到达1s
    case finishOver1s = 5 //同步完成，已经过了1s
    case failed = 6 // 同步失败

    var hasFinished: Bool {
        return self == .finish || self == .finishOver1s || self == .failed
    }
}

public enum DownloadStatus: Int {
    case none = 1
    case waiting = 2
    case downloading = 3
    case success = 4
    case successOver2s = 5
    case fail = 6

    var hasSuccess: Bool {
        return self == .success || self == .successOver2s
    }
}

public struct SyncStatus: Equatable {
    public let upSyncStatus: UpSyncStatus
    public let downloadStatus: DownloadStatus

    public init(upSyncStatus: UpSyncStatus, downloadStatus: DownloadStatus) {
        self.upSyncStatus = upSyncStatus
        self.downloadStatus = downloadStatus
    }

    public func modifingUpSyncStatus(_ newUpSyncStatus: UpSyncStatus) -> SyncStatus {
        return SyncStatus(upSyncStatus: newUpSyncStatus, downloadStatus: downloadStatus)
    }

    public func modifingDownLoadStatus(_ newDownlaodStatus: DownloadStatus) -> SyncStatus {
        return SyncStatus(upSyncStatus: upSyncStatus, downloadStatus: newDownlaodStatus)
    }
}
