//
//  LinearizedImagePreviewProcessor.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/1/8.
//

import Foundation
import SKCommon
import SKFoundation
import LarkDocsIcon

class LinearizedImagePreviewProcessor: DefaultPreviewProcessor {
    override func handleReady(preview: DriveFilePreview, completion: @escaping (() -> Void)) {
        defer {
            completion()
        }
        handler?.updateState(.endTranscoding(status: preview.previewStatus))
        guard let previewType = fileInfo.getPreferPreviewType(isInVCFollow: config.isInVCFollow) else {
            spaceAssertionFailure("LinearizedImagePreviewProcessor -- previewType is nil")
            handler?.updateState(.unsupport(type: .typeUnsupport))
            return
        }
        if preview.linearized == false {
            DocsLogger.driveInfo("LinearizedImagePreviewProcessor -- linearized is false")
            if fileInfo.fileType.isSupport {
                downloadOriginOrSimilarIfNeed()
            } else {
                DocsLogger.driveInfo("LinearizedImagePreviewProcessor -- origin file unsupport")
                handler?.updateState(.unsupport(type: .typeUnsupport))
            }
        } else {
            DocsLogger.driveInfo("LinearizedImagePreviewProcessor -- preview linear image progressive")
            let info = DriveProccesPreviewInfo.linearizedImage(preview: preview)
            let type = previewType.toDriveFileType(originType: fileInfo.fileType)
            handler?.updateState(.setupPreview(fileType: type, info: info))
        }
    }

    override var downgradeWhenGenerating: Bool {
        return config.allowDowngradeToOrigin
    }
}
