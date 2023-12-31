//
//  DriveCacheServiceMocker.swift
//  DocsTests
//
//  Created by bupozhuang on 2019/12/2.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import UIKit
@testable import SpaceKit

class DriveCacheServiceMocker: DriveCacheServiceProtocol {
    private var videoFileExist = false

    private var originFileNode: DriveCacheFileNode?
    private var previewFileNode: DriveCacheFileNode?

    func isDriveFileExist(token: String, dataVersion: String?, extension fileExtension: String?) -> Bool {
        return originFileNode != nil || previewFileNode != nil
    }

    func getDriveFile(token: String, dataVersion: String?, extension fileExtension: String?) -> DriveCacheFileNode? {
        return originFileNode ?? previewFileNode
    }

    func getDriveFile(type: DriveCacheType, token: String, dataVersion: String?, extension fileExtension: String?) -> DriveCacheFileNode? {
        switch type {
        case .origin:
            return originFileNode
        case .preview:
            return previewFileNode
        case .associate:
            return nil
        }
    }

    func isDriveFileExist(type: DriveCacheType, token: String, dataVersion: String?, extension fileExtension: String?) -> Bool {
        switch type {
        case .origin:
            return originFileNode != nil
        case .preview:
            return previewFileNode != nil
        case .associate:
            return false
        }
    }

    func deleteDriveFile(token: String, dataVersion: String?, completion: ((Bool) -> Void)?) {

    }

    static func driveFileDownloadURL(cacheType: DriveCacheType, fileToken: String, dataVersion: String, type: String) -> URL {
        return URL(fileURLWithPath: "http://abc.unittest")
    }

    // config mocker
    func config(videoFileExist: Bool, originFileNode: DriveCacheFileNode?, previewFileNode: DriveCacheFileNode? ) {
        self.videoFileExist = videoFileExist
        self.originFileNode = originFileNode
        self.previewFileNode = previewFileNode
    }

    static func cachehasPreviewFile() -> DriveCacheServiceProtocol {
        let cacheService = DriveCacheServiceMocker()
        cacheService.config(videoFileExist: false, originFileNode: nil, previewFileNode: DriveCacheFileNode(key: "xxxxx",
                                                                                                       fileName: "xxxx.sketch",
                                                                                                       originFileName: "origin.jpg",
                                                                                                       fileRootURL: URL(fileURLWithPath: "/abc/"),
                                                                                                       fileSize: 10240,
                                                                                                       version: "xxx"))
        return cacheService
    }
}
