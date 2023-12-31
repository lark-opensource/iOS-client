//
//  ArchivePreviewProcessor.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/1/8.
//

import SKFoundation

class ArchivePreviewProcessor: DefaultPreviewProcessor {
    override func handleReady(preview: DriveFilePreview, completion: @escaping (() -> Void)) {
        defer {
            completion()
        }
        DocsLogger.driveInfo("ArchivePreviewProcessor -- preview get success handle ready: downloadPreview")
        handler?.updateState(.endTranscoding(status: preview.previewStatus))
        let vm = DriveArchivePreviewViewModel(fileID: fileInfo.fileID,
                                              fileName: fileInfo.name,
                                              archiveContent: preview.extra,
                                              previewFrom: config.previewFrom,
                                              additionalStatisticParameters: nil)
        let info = DriveProccesPreviewInfo.archive(viewModel: vm)
        handler?.updateState(.setupPreview(fileType: fileInfo.fileType, info: info))
    }
}
