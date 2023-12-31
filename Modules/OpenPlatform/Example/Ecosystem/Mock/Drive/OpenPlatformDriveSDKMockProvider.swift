//
//  OpenPlatformDriveSDKMockProvider.swift
//  Ecosystem
//
//  Created by baojianjun on 2023/2/2.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import RxSwift
import OPPlugin

final class OpenPlatformDriveSDKMockProvider {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }
}

extension OpenPlatformDriveSDKMockProvider: OpenPluginDriveUploadProxy {
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String,
                extra: [String : String]?) -> Observable<(String, Float, String, OpenPluginDriveUploadStatus)> {
        return Observable<(String, Float, String, OpenPluginDriveUploadStatus)>
            .just(("mockUploadKey", 100, "mockFileToken", .success))
    }

    func cancelUpload(key: String) -> Observable<Bool> {
        return Observable<Bool>.just(true)
    }

    func resumeUpload(key: String) -> Observable<Bool> {
        return Observable<Bool>.just(true)
    }

    func deleteUploadResource(key: String) -> Observable<Bool> {
        return Observable<Bool>.just(true)
    }
}

extension OpenPlatformDriveSDKMockProvider: OpenPluginDriveDownloadProxy {
    
    func download(with context: OpenPluginDriveDownloadRequestContext) -> Observable<OpenPluginDriveDownloadResponseContext> {
        return Observable<OpenPluginDriveDownloadResponseContext>.just(
            .init(requestContext: context,
                  downloadStatus: .success,
                  downloadProgress: (100, 100),
                  key: "mockKey",
                  localFilePath: "mockLocalFilePath",
                  fileName: "mockFileName",
                  fileType: "mockFileType"))
    }
    
    func cancelDownload(key: String) -> Observable<Bool> {
        return Observable<Bool>.just(true)
    }
}

// MARK: - Preview

extension OpenPlatformDriveSDKMockProvider: OpenPluginDrivePreviewProxy {
    func preview(
        contexts: [OpenPluginDrivePreviewContext],
        actions: [OpenPluginDrivePreviewAction]?
    ) -> UIViewController? {
        return UIViewController()
    }
}
