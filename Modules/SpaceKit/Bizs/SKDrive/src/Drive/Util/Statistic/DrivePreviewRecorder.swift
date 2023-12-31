//
//  DrivePreviewRecorder.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/11.
//  

import Foundation
import RxRelay
import RxSwift
import SKCommon
import SKFoundation
import SpaceInterface

// 记录当前 drive 的预览状态，用于判断是否有 drive 文件正在预览，为前端资源包热更提供时机判断
class DrivePreviewRecorder {
    static let shared = DrivePreviewRecorder()

    let stackCountRelay = BehaviorRelay<UInt>(value: 0)

    var stackEmptyStateChanged: Observable<Bool> {
        return stackCountRelay.asObservable()
            .map { $0 == 0 }
            .distinctUntilChanged()
    }

    var isStackEmpty: Bool {
        return stackCount == 0
    }

    var stackCount: UInt {
        return stackCountRelay.value
    }

    private init() { }

    class func open() {
        shared.open()
    }

    class func close() {
        shared.close()
    }

    func open() {
        stackCountRelay.accept(stackCount + 1)
        DocsLogger.debug("drive.preview.recorder --- stack count increase to \(stackCount)")
    }

    func close() {
        guard !isStackEmpty else {
            spaceAssertionFailure("drive.preview.recorder --- stack is empty when exiting preview")
            DocsLogger.error("drive.preview.recorder --- stack is empty when exiting preview")
            return
        }
        stackCountRelay.accept(stackCount - 1)
        DocsLogger.debug("drive.preview.recorder --- stack count decrease to \(stackCount)")
    }
}

extension DrivePreviewRecorder: DrivePreviewRecorderBase {
    
}
