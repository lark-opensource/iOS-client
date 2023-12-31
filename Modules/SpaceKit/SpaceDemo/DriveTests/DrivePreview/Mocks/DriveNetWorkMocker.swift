//
//  DriveNetWorkMocker.swift
//  DocsTests
//
//  Created by bupozhuang on 2019/12/2.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import UIKit
@testable import SpaceKit

class DriveNetWorkMocker: DrivePreviewNetManagerProtocol {
    private var requestTime: TimeInterval = 0.0
    private var docsInfo: DocsInfo
    private var fileInfo: DriveFileInfo
    private var previews: [DriveFilePreview]

    init(docsInfo: DocsInfo, fileInfo: DriveFileInfo, previews: [DriveFilePreview]) {
        self.docsInfo = docsInfo
        self.fileInfo = fileInfo
        self.previews = previews
    }

    func fetchDocsInfo(docsInfo: DocsInfo, completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + requestTime) {
            if self.fetchDocsSuccess {
                completion(nil)
            } else {
                let error = NSError(domain: "unit.test", code: 8, userInfo: ["test": "unit.test"])
                completion(error as Error)
            }
        }
    }
    func fetchFileInfo(showInRecent: Bool, version: String?, polling: (() -> Void), completion: @escaping (DriveResult<DriveFileInfo>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + requestTime) {
            if self.fetchFileInfoSuccess {
                completion(DriveResult.success(self.fileInfo))
            } else {
                let error = NSError(domain: "unit.test", code: 8, userInfo: ["test": "unit.test"])
                completion(DriveResult.failure(error as Error))
            }
        }
    }
    private var currentCount = 0
    func fetchPreviewURL(regenerate: Bool, mountPoint: String, mountToken: String, completion: @escaping (DriveResult<DriveFilePreview>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + requestTime) {
            if self.previewGetSuccess {
                completion(DriveResult.success(self.previews[self.currentCount]))
            } else {
                let error = NSError(domain: "unit.test", code: 8, userInfo: ["test": "unit.test"])
                completion(DriveResult.failure(error as Error))
            }
        }
    }
    func updateFileInfo(name: String, completion: @escaping (DriveResult<Bool>) -> Void) {

    }
    func saveToSpace(fileInfo: DriveFileInfo, completion: @escaping (DriveResult<Bool>) -> Void) {

    }
    func getReadingData(docsInfo: DocsInfo, callback: @escaping DriveGetReadingDataCallback) {

    }

    /// config mock
    /// requestTime: 每次请求耗时
    /// docsInfo: fetchDocsInfo返回结果
    /// fileInfo: fetchFileInfo返回结果
    /// previews: 轮询次数每次返回的结果
    func config(requestTime: TimeInterval, docsInfo: DocsInfo, fileInfo: DriveFileInfo, previews: [DriveFilePreview]) {
        self.requestTime = requestTime
        self.docsInfo = docsInfo
        self.fileInfo = fileInfo
        self.previews = previews
    }

    var fetchDocsSuccess: Bool = true
    var fetchFileInfoSuccess: Bool = true
    var previewGetSuccess: Bool = true
}
