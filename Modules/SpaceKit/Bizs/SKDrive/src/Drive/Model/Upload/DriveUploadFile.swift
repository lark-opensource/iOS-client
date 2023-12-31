//
//  DriveUploadFile.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/30.
//

import UIKit
import SKCommon
import SKFoundation
import SpaceInterface
import LarkDocsIcon

extension DriveUploadFile: DriveUploadTableCellPresenter {
    var wikiImage: UIImage? {
        return image
    }
    
    var image: UIImage? {
        let suffix = (fileName as NSString).pathExtension
        let type = DriveFileType(rawValue: suffix.lowercased()) ?? .unknown
        return type.roundImage
    }

    var name: String {
        return fileName
    }

    var uploadStatus: DriveUploadStatus {
        guard let transmissionStatus = DriveUploadCallbackStatus(rawValue: Int(status)) else {
            DocsLogger.warning("shouldn't reach, unknown TransmissionStatus")
            return DriveUploadStatus.broken
        }
        switch transmissionStatus {
        case .ready, .inflight:
            let transferred = CGFloat.fromString(bytesTransferred)
            let total = CGFloat.fromString(bytesTotal)
            let process = total > 0 ? (transferred / total) : 0
            DocsLogger.driveInfo("Transmission In Flight:, \(process)")
            return DriveUploadStatus.uploading(progress: process)
        case .cancel:
            return DriveUploadStatus.canceled
        case .failed:
            DocsLogger.driveInfo("Transmission Failed")
            if let code = Int(errorCode),
               let uploadErrorCode = FileUploaderErrorCode(rawValue: code),
               !uploadErrorCode.canRetry {
                return DriveUploadStatus.failNoRetry
            }
            return DriveUploadStatus.broken
        case .success:
            DocsLogger.driveInfo("Transmission Success")
            return DriveUploadStatus.completed
        case .queue, .pending:
            DocsLogger.driveInfo("Transmission Pending")
            return DriveUploadStatus.waiting
        @unknown default:
            spaceAssertionFailure("unknown type")
            return .broken
        }
    }
}
