//
//  AlbumFile.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/9/20.
//

import Foundation
import Photos
import RxSwift
import LarkUIKit
import LarkMessengerInterface
import LarkFoundation
import LarkEMM
import LarkSensitivityControl

/// 相册文件
struct AlbumFile: AttachedFile {
    let asset: PHAsset

    private let resource: PHAssetResource?

    var id: String {
        return asset.localIdentifier
    }

    var type: AttachedFileType {
        return .albumVideo
    }

    var name: String {
        return resource?.originalFilename ?? ""
    }

    var size: Int64 {
        var fileSize: Int64 = 0
        do {
            try ObjcExceptionHandler.catchException({
                fileSize = (self.resource?.value(forKey: "fileSize") as? Int64) ?? 0
            })
        } catch {
            fileSize = 0
        }
        return fileSize
    }

    var filePath: String {
        ""
    }

    init(asset: PHAsset, resourceCache: NSCache<NSString, PHAssetResource>) {
        self.asset = asset
        if let resource = resourceCache.object(forKey: asset.localIdentifier as NSString) {
            self.resource = resource
        } else {
            let resources = PHAssetResource.assetResources(for: asset)
            if let firstResource = resources.first {
                resourceCache.setObject(firstResource, forKey: asset.localIdentifier as NSString)
                self.resource = firstResource
            } else {
                self.resource = nil
            }
        }
    }
}

extension AlbumFile {

    enum AlbumFileExportError: Error {
        case sandboxExtensionTokenKeyMissingError
        case copyVideoToSandBox(Error)
        case exportSessionCreateError
        case exportSessionExportError
    }

    func export(to sandboxURL: URL) -> Observable<URL> {
        exportByExportSession(with: asset, to: sandboxURL)
    }

    /// 使用requestExportSession导出视频，这种方式可能会发生转码，比较慢
    private func exportByExportSession(with asset: PHAsset, to sandboxURL: URL) -> Observable<URL> {
        return Observable<URL>.create { (observer) -> Disposable in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            try? AlbumEntry.requestExportSession(forToken: FileToken.requestExportSession.token,
                                                 manager: PHImageManager.default(),
                                                 forVideoAsset: asset,
                                                 options: options,
                                                 exportPreset: AVAssetExportPresetPassthrough,
                                                 resultHandler: { (exportSession, _) in
                guard let exportSession = exportSession else {
                    observer.onError(AlbumFileExportError.exportSessionCreateError)
                    return
                }

                exportSession.outputURL = sandboxURL
                exportSession.outputFileType = AVFileType.mov
                exportSession.exportAsynchronously(completionHandler: {
                    switch exportSession.status {
                    case .completed:
                        observer.onNext(sandboxURL)
                        observer.onCompleted()
                    default:
                        observer.onError(AlbumFileExportError.exportSessionExportError)
                    }
                })
            })
            return Disposables.create()
        }
    }
}
