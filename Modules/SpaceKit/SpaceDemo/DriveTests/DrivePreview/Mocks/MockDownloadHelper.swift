//
//  MockDownloadHelper.swift
//  DocsTests
//
//  Created by bupozhuang on 2019/12/2.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import UIKit
@testable import SpaceKit

class MockDownloadHelper: DriveDownloadHelperProtocol {
    private var sum: UInt64 = 0
    private var stoped = false
    private var downloadOriginFileCalled = false
    private var downloadPreviewFileCalled = false
    private var updateTimer: Timer?
    private var failed: Bool = false
    private var forbid: Bool = false

    var downloadStatusHandler: ((DriveDownloadService.DownloadStatus) -> Void)?
    var forbidDownloadHandler: (() -> Void)?
    var beginDownloadHandler: (() -> Void)?
    var cacheStageHandler: ((DriveStage) -> Void)?
    
    func stop() {
        updateTimer?.invalidate()
        updateTimer = nil
        stoped = true
    }
    func downloadOriginFile(fileInfo: DriveFileInfo, isLatest: Bool) {
        downloadOriginFileCalled = true
        startDownload(fileSize: fileInfo.size)
    }
    func downloadPreviewFile(fileInfo: DriveFileInfo, isLatest: Bool, cacheCustomID: String?) {
        downloadPreviewFileCalled = true
        startDownload(fileSize: fileInfo.size)
    }
    func retryDownload(fileInfo: DriveFileInfo, isLatest: Bool) {
        startDownload(fileSize: fileInfo.size)
    }

    func configDownloadStatus(_ failed: Bool, isForbid: Bool) {
        self.failed = failed
        self.forbid = isForbid
    }

    // veryfy
    func stopedIsCall() -> Bool {
        return stoped
    }
    func downloadOriginFileIsCalled() -> Bool {
        return downloadOriginFileCalled
    }
    func downloadPreviewFileIsCalled() -> Bool {
        return downloadPreviewFileCalled
    }
}

extension MockDownloadHelper {
    private func startDownload(speed: UInt64 = 1024, fileSize: UInt64) {
        if failed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.downloadStatusHandler?(DriveDownloadService.DownloadStatus.failed(errorCode: "UnitTest"))
            }
        } else if forbid {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.forbidDownloadHandler?()
            }
        } else {
//            sum = 0
//            updateTimer = Timer.lu.scheduledTimer(timerInterval: 0.5, repeats: true) { (timer) in
//                let progress = Float(self.sum) / Float(fileSize)
//                self.sum += (speed / 2)
//                DispatchQueue.main.async {
//                    if self.sum >= fileSize {
//                        self.downloadStatusHandler?(DriveDownloadService.DownloadStatus.success)
//                        timer.invalidate()
//                    } else {
//                        self.downloadStatusHandler?(DriveDownloadService.DownloadStatus.downloading(progress: progress))
//                    }
//                }
//              }
                self.downloadStatusHandler?(DriveDownloadService.DownloadStatus.downloading(progress: 0))
                self.downloadStatusHandler?(DriveDownloadService.DownloadStatus.success)
        }

    }
}
