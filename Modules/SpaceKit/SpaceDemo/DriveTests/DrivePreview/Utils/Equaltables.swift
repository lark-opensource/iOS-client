//
//  Equaltables.swift
//  DriveTests
//
//  Created by bupozhuang on 2020/1/1.
//  Copyright © 2020 Bytedance. All rights reserved.
//

import Foundation
@testable import SpaceKit

typealias ViewModelAction = DrivePreviewCellBaseViewModel.ViewModelAction
extension DriveUnsupportPreviewType: Equatable {
    public static func == (lhs: DriveUnsupportPreviewType, rhs: DriveUnsupportPreviewType) -> Bool {
        switch (lhs, rhs) {
        case let (.unknown(code1), .unknown(code2)):
            return code1 == code2
        case (.typeUnsupport, .typeUnsupport),
             (.sizeTooBig, .sizeTooBig),
             (.sizeIsZero, .sizeIsZero),
             (.typeUnsupportInArchive, .typeUnsupportInArchive),
             (.fileRenderFailed, .fileRenderFailed):
            return true
        default:
            return false
        }
    }
}

extension DriveVideoInfo: Equatable {
    public static func == (lhs: DriveVideoInfo, rhs: DriveVideoInfo) -> Bool {
        return lhs.type == rhs.type && lhs.transcodeURLs == rhs.transcodeURLs
    }
}

extension DriveFileMeta: Equatable {
    public static func == (lhs: DriveFileMeta, rhs: DriveFileMeta) -> Bool {
        return lhs.fileToken == rhs.fileToken
    }
}

extension DriveFilePreview: Equatable {
    public static func == (lhs: DriveFilePreview, rhs: DriveFilePreview) -> Bool {
        return lhs.previewStatus == rhs.previewStatus && lhs.previewURL == rhs.previewURL
    }
}



extension DrivePreviewCellBaseViewModel.ViewModelAction: Equatable {
    
    // swiftlint:disable cyclomatic_complexity
    public static func == (lhs: DrivePreviewCellBaseViewModel.ViewModelAction,
                           rhs: DrivePreviewCellBaseViewModel.ViewModelAction) -> Bool {
        switch (lhs, rhs) {
        case (.startOpenFile, .startOpenFile),
             (.openFilePreView, .openFilePreView),
             (.showDownloading, .showDownloading),
             (.downloadCompleted, .downloadCompleted),
             (.downloadingError, .downloadingError),
             (.startLoading, .startLoading),
             (.endLoading, .endLoading),
             (.showAuditFailureView, .showAuditFailureView),
             (.showFileDeleted, .showFileDeleted),
             (.showFileNotFound, .showFileNotFound),
             (.publicPermissionChanged, .publicPermissionChanged),
             (.downloading, .downloading),
             (.userPermissionChanged, .userPermissionChanged):
            return true
        case let (.showUnsupportView(type1), .showUnsupportView(type2)):
            return type1 == type2
        case let (.showFetchFailedView(retry1), .showFetchFailedView(retry2)):
            return retry1 == retry2
        case let (.readyForDriveVideoPlayer(info1), .readyForDriveVideoPlayer(info2)):
            return info1 == info2
        case let (.showNoPermissionView(docs1, canrequest1), .showNoPermissionView(docs2, canrequest2)):
            return docs1 == docs2 && canrequest1 == canrequest2
        case let (.directOpenCacheFile(meta1), .directOpenCacheFile(meta2)):
            return meta1 == meta2
        case let (.exitPreview(hud1), .exitPreview(hud2)):
            return hud1 == hud2
        case let (.exitPreviewWithHUD(msg1), .exitPreviewWithHUD(msg2)):
            return msg1 == msg2
        case let (.networkReachable(reachable1), .networkReachable(reachable2)):
            return reachable1 == reachable2
        case let (.driveTranscoding(encoding1), .driveTranscoding(encoding2)):
            return encoding1 == encoding2
        case let (.showErrorHUD(msg1), .showErrorHUD(msg2)):
            return msg1 == msg2
        case let (.showSuccHUD(msg1), .showSuccHUD(msg2)):
            return msg1 == msg2
        case let (.setupProgressiveImage(filePreview1, fileInfo1), .setupProgressiveImage(filePreview2, fileInfo2)):
            return filePreview1 == filePreview2 && fileInfo1 == fileInfo2
        case let (.setupArchivePreview(fileInfo1, filePreview1), .setupArchivePreview(fileInfo2, filePreview2)):
            return filePreview1 == filePreview2 && fileInfo1 == fileInfo2
        case let (.setupHtmlPreview(fileInfo1, filePreview1), .setupHtmlPreview(fileInfo2, filePreview2)):
            return filePreview1 == filePreview2 && fileInfo1 == fileInfo2
        default:
            return false
        }
    }
}
