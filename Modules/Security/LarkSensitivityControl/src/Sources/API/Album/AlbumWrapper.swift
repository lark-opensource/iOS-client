//
//  AlbumWrapper.swift
//  LarkSensitivityControl
//
//  Created by yangyifan on 2023/3/15.
//

import Photos
import PhotosUI
import UIKit

/// 对api的内部封装，业务侧需要可以继承并重写相关方法
final class AlbumWrapper: NSObject, AlbumApi {

    /// PHAsset fetchAssetsWithMediaType
    static func fetchAssets(forToken token: Token,
                            withMediaType mediaType: PHAssetMediaType,
                            options: PHFetchOptions?) throws -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(with: mediaType, options: options)
    }

    /// PHAssetChangeRequest creationRequestForAsset
    static func creationRequestForAsset(forToken token: Token,
                                        fromImage image: UIImage) throws -> PHAssetChangeRequest {
        return PHAssetChangeRequest.creationRequestForAsset(from: image)
    }

    /// PHAssetChangeRequest creationRequestForAssetFromImage
    static func creationRequestForAssetFromImage(forToken token: Token,
                                                 atFileURL fileURL: URL) throws -> PHAssetChangeRequest? {
        return PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
    }

    /// PHAssetChangeRequest creationRequestForAssetFromVideo
    static func creationRequestForAssetFromVideo(forToken token: Token,
                                                 atFileURL fileURL: URL) throws -> PHAssetChangeRequest? {
        return PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
    }

    /// PHAssetCreationRequest forAsset
    static func forAsset(forToken token: Token) throws -> PHAssetCreationRequest {
        return PHAssetCreationRequest.forAsset()
    }

    /// PHCollectionList fetchTopLevelUserCollections
    static func fetchTopLevelUserCollections(forToken token: Token,
                                             withOptions options: PHFetchOptions?) throws -> PHFetchResult<PHCollection> {
        return PHCollectionList.fetchTopLevelUserCollections(with: options)
    }

    /// PHPhotoLibrary requestAuthorization
    static func requestAuthorization(forToken token: Token,
                                     handler: @escaping (PHAuthorizationStatus) -> Void) throws {
        PHPhotoLibrary.requestAuthorization(handler)
    }

    /// PHPhotoLibrary requestAuthorizationForAccessLevel
    @available(iOS, introduced: 14.0)
    static func requestAuthorization(forToken token: Token,
                                     forAccessLevel accessLevel: PHAccessLevel,
                                     handler: @escaping (PHAuthorizationStatus) -> Void) throws {
        PHPhotoLibrary.requestAuthorization(for: accessLevel, handler: handler)
    }

    /// PHAssetCollection fetchAssetCollections
    static func fetchAssetCollections(forToken token: Token,
                                      withType type: PHAssetCollectionType,
                                      subtype: PHAssetCollectionSubtype,
                                      options: PHFetchOptions?) throws -> PHFetchResult<PHAssetCollection> {
        return PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: options)
    }

    /// PHAssetResourceManager requestData
    static func requestData(forToken token: Token,
                            manager: PHAssetResourceManager,
                            forResource resource: PHAssetResource,
                            options: PHAssetResourceRequestOptions?,
                            dataReceivedHandler handler: @escaping (Data) -> Void,
                            completionHandler: @escaping (Error?) -> Void) throws -> PHAssetResourceDataRequestID {
        return manager.requestData(for: resource, options: options, dataReceivedHandler: handler, completionHandler: completionHandler)
    }

    /// PHAssetResourceManager writeData
    static func writeData(forToken token: Token,
                          manager: PHAssetResourceManager,
                          forResource resource: PHAssetResource,
                          toFile fileURL: URL,
                          options: PHAssetResourceRequestOptions?,
                          completionHandler: @escaping (Error?) -> Void) throws {
        manager.writeData(for: resource, toFile: fileURL, options: options, completionHandler: completionHandler)
    }

    /// PHImageManager requestAVAsset
    static func requestAVAsset(
        forToken token: Token,
        manager: PHImageManager,
        forVideoAsset asset: PHAsset,
        options: PHVideoRequestOptions?,
        resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID {
        return manager.requestAVAsset(forVideo: asset, options: options, resultHandler: resultHandler)
    }

    /// PHImageManager requestExportSession
    static func requestExportSession(
        forToken token: Token,
        manager: PHImageManager,
        forVideoAsset asset: PHAsset,
        options: PHVideoRequestOptions?,
        exportPreset: String,
        resultHandler: @escaping (AVAssetExportSession?, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID {
        return manager.requestExportSession(forVideo: asset, options: options,
                                            exportPreset: exportPreset, resultHandler: resultHandler)
    }

    /// PHImageManager requestImage
    static func requestImage(forToken token: Token,
                             manager: PHImageManager,
                             forAsset asset: PHAsset,
                             targetSize: CGSize,
                             contentMode: PHImageContentMode,
                             options: PHImageRequestOptions?,
                             resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) throws -> PHImageRequestID {
        return manager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode,
                                    options: options, resultHandler: resultHandler)
    }

    /// PHImageManager requestPlayerItem
    static func requestPlayerItem(forToken token: Token,
                                  manager: PHImageManager,
                                  forVideoAsset asset: PHAsset,
                                  options: PHVideoRequestOptions?,
                                  resultHandler: @escaping (AVPlayerItem?, [AnyHashable: Any]?) -> Void) throws -> PHImageRequestID {
        return manager.requestPlayerItem(forVideo: asset, options: options, resultHandler: resultHandler)
    }

    /// PHPickerViewController createPickerViewControllerWithConfiguration
    @available(iOS, introduced: 14.0)
    static func createPickerViewControllerWithConfiguration(forToken token: Token,
                                                            configuration: PHPickerConfiguration) throws -> PHPickerViewController {
        return PHPickerViewController(configuration: configuration)
    }

    /// UIImagePickerController createImagePickerController
    static func createImagePickerController(forToken token: Token) throws -> UIImagePickerController {
        return UIImagePickerController()
    }

    /// UIImageWriteToSavedPhotosAlbum
    static func UIImageWriteToSavedPhotosAlbum(forToken token: Token,
                                               _ image: UIImage,
                                               _ completionTarget: Any?,
                                               _ completionSelector: Selector?,
                                               _ contextInfo: UnsafeMutableRawPointer?) throws {
        UIKit.UIImageWriteToSavedPhotosAlbum(image, completionTarget, completionSelector, contextInfo)
    }

    /// UISaveVideoAtPathToSavedPhotosAlbum
    static func UISaveVideoAtPathToSavedPhotosAlbum(forToken token: Token,
                                                    _ videoPath: String,
                                                    _ completionTarget: Any?,
                                                    _ completionSelector: Selector?,
                                                    _ contextInfo: UnsafeMutableRawPointer?) throws {
        UIKit.UISaveVideoAtPathToSavedPhotosAlbum(videoPath, completionTarget, completionSelector, contextInfo)
    }

    /// PHImageManager requestImageData
    @available(iOS, introduced: 8.0, deprecated: 13.0)
    static func requestImageData(
        forToken token: Token,
        manager: PHImageManager,
        forAsset asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID {
        return manager.requestImageData(for: asset, options: options, resultHandler: resultHandler)
    }

    /// PHImageManager requestImageDataAndOrientation
    @available(iOS, introduced: 13.0)
    static func requestImageDataAndOrientation(
        forToken token: Token,
        manager: PHImageManager,
        forAsset asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (Data?, String?, CGImagePropertyOrientation, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID {
        return manager.requestImageDataAndOrientation(for: asset, options: options, resultHandler: resultHandler)
    }
}
