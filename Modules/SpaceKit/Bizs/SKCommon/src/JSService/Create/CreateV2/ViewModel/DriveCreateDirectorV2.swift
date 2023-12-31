//
//  DriveCreateDirectorV2.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/8/28.
//  

import Foundation
import SKFoundation
import SpaceInterface
import SKInfra

public final class DriveCreateDirectorV2 {
    private let parent: String
    private let type: DocsType
    private let fromVC: UIViewController?
    ///
    /// - Parameters:
    ///   - type: 文档类型
    ///   - folder: 创建的文件夹的 token
    required init(type: DocsType, in folder: String, fromVC: UIViewController?) {
        self.type = type
        self.parent = folder
        self.fromVC = fromVC
    }
}

extension DriveCreateDirectorV2 {
    public static func upload(_ files: [URL], folder: String = "") {
        _ = DocsContainer.shared.resolve(DriveUploadCacheServiceBase.self)?.type().saveICouldFileToLocal(urls: files,
                                                                                                         mountToken: folder,
                                                                                                         mountPoint: DriveConstants.driveMountPoint,
                                                                                                         scene: .unknown)
    }
}

extension DriveCreateDirectorV2: SKCreateAPI {
    public func upload(completion: UploadCompletion?) {
        switch type {
        case .file:
            if let from = getFromVC() {
                DocsContainer.shared.resolve(DriveRouterBase.self)?.type()
                    .showDocumentPickerViewController(sourceViewController: from,
                                                      mountToken: parent,
                                                      mountPoint: DriveConstants.driveMountPoint,
                                                      scene: .unknown,
                                                      completion: { finish in
                                                        completion?(DocsType.file, finish)
                                                      })

            } else {
                spaceAssertionFailure("Source View Controller cannot be nil")
            }

        case .mediaFile:
            if let from = getFromVC() {
                DocsContainer.shared.resolve(DriveRouterBase.self)?.type()
                    .showAssetPickerViewController(sourceViewController: from,
                                                          mountToken: parent,
                                                          mountPoint: DriveConstants.driveMountPoint,
                                                          scene: .unknown,
                                                          completion: { finish in
                                                            completion?(DocsType.mediaFile, finish)
                                                          })
            } else {
                spaceAssertionFailure("Source View Controller cannot be nil")
            }
        default: ()
        }
    }

    private func getFromVC() -> UIViewController? {
        return fromVC
    }
}
