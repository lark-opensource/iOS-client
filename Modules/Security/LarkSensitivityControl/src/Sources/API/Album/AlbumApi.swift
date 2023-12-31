//
//  AlbumApi.swift
//  LarkSensitivityControl
//
//  Created by yangyifan on 2023/3/15.
//

import Photos
import PhotosUI

public extension AlbumApi {
    /// 外部注册自定义api使用的key值
    static var tag: String {
        "album"
    }
}

/// album相关方法
public protocol AlbumApi: SensitiveApi {

    /// PHAsset fetchAssetsWithMediaType
    static func fetchAssets(forToken token: Token,
                            withMediaType mediaType: PHAssetMediaType,
                            options: PHFetchOptions?) throws -> PHFetchResult<PHAsset>

    /// PHAssetChangeRequest creationRequestForAsset
    static func creationRequestForAsset(forToken token: Token,
                                        fromImage image: UIImage) throws -> PHAssetChangeRequest

    /// PHAssetChangeRequest creationRequestForAssetFromImage
    static func creationRequestForAssetFromImage(forToken token: Token,
                                                 atFileURL fileURL: URL) throws -> PHAssetChangeRequest?

    /// PHAssetChangeRequest creationRequestForAssetFromVideo
    static func creationRequestForAssetFromVideo(forToken token: Token,
                                                 atFileURL fileURL: URL) throws -> PHAssetChangeRequest?

    /// PHAssetCreationRequest forAsset
    static func forAsset(forToken token: Token) throws -> PHAssetCreationRequest

    /// PHCollectionList fetchTopLevelUserCollections
    static func fetchTopLevelUserCollections(forToken token: Token,
                                             withOptions options: PHFetchOptions?) throws -> PHFetchResult<PHCollection>

    /// PHPhotoLibrary requestAuthorization
    static func requestAuthorization(forToken token: Token,
                                     handler: @escaping (PHAuthorizationStatus) -> Void) throws

    /// PHPhotoLibrary requestAuthorizationForAccessLevel
    @available(iOS, introduced: 14.0)
    static func requestAuthorization(forToken token: Token,
                                     forAccessLevel accessLevel: PHAccessLevel,
                                     handler: @escaping (PHAuthorizationStatus) -> Void) throws

    /// PHAssetCollection fetchAssetCollections
    static func fetchAssetCollections(forToken token: Token,
                                      withType type: PHAssetCollectionType,
                                      subtype: PHAssetCollectionSubtype,
                                      options: PHFetchOptions?) throws -> PHFetchResult<PHAssetCollection>

    /// PHAssetResourceManager requestData
    static func requestData(
        forToken token: Token,
        manager: PHAssetResourceManager,
        forResource resource: PHAssetResource,
        options: PHAssetResourceRequestOptions?,
        dataReceivedHandler handler: @escaping (Data) -> Void,
        completionHandler: @escaping (Error?) -> Void
    ) throws -> PHAssetResourceDataRequestID

    /// PHAssetResourceManager writeData
    static func writeData(forToken token: Token,
                          manager: PHAssetResourceManager,
                          forResource resource: PHAssetResource,
                          toFile fileURL: URL,
                          options: PHAssetResourceRequestOptions?,
                          completionHandler: @escaping (Error?) -> Void) throws

    /// PHImageManager requestAVAsset
    static func requestAVAsset(
        forToken token: Token,
        manager: PHImageManager,
        forVideoAsset asset: PHAsset,
        options: PHVideoRequestOptions?,
        resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID

    /// PHImageManager requestExportSession
    static func requestExportSession(
        forToken token: Token,
        manager: PHImageManager,
        forVideoAsset asset: PHAsset,
        options: PHVideoRequestOptions?,
        exportPreset: String,
        resultHandler: @escaping (AVAssetExportSession?, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID

    /// PHImageManager requestImage
    static func requestImage(forToken token: Token,
                             manager: PHImageManager,
                             forAsset asset: PHAsset,
                             targetSize: CGSize,
                             contentMode: PHImageContentMode,
                             options: PHImageRequestOptions?,
                             resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) throws -> PHImageRequestID

    /// PHImageManager requestPlayerItem
    static func requestPlayerItem(forToken token: Token,
                                  manager: PHImageManager,
                                  forVideoAsset asset: PHAsset,
                                  options: PHVideoRequestOptions?,
                                  resultHandler: @escaping (AVPlayerItem?, [AnyHashable: Any]?) -> Void) throws -> PHImageRequestID

    /// PHPickerViewController createPickerViewControllerWithConfiguration
    @available(iOS, introduced: 14.0)
    static func createPickerViewControllerWithConfiguration(forToken token: Token,
                                                            configuration: PHPickerConfiguration) throws -> PHPickerViewController

    /// UIImagePickerController createImagePickerController
    static func createImagePickerController(forToken token: Token) throws -> UIImagePickerController

    /// UIImageWriteToSavedPhotosAlbum
    static func UIImageWriteToSavedPhotosAlbum(forToken token: Token,
                                               _ image: UIImage,
                                               _ completionTarget: Any?,
                                               _ completionSelector: Selector?,
                                               _ contextInfo: UnsafeMutableRawPointer?) throws

    /// UISaveVideoAtPathToSavedPhotosAlbum
    static func UISaveVideoAtPathToSavedPhotosAlbum(forToken token: Token,
                                                    _ videoPath: String,
                                                    _ completionTarget: Any?,
                                                    _ completionSelector: Selector?,
                                                    _ contextInfo: UnsafeMutableRawPointer?) throws

    /// PHImageManager requestImageData
    @available(iOS, introduced: 8.0, deprecated: 13.0)
    static func requestImageData(
        forToken token: Token,
        manager: PHImageManager,
        forAsset asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID

    /// PHImageManager requestImageDataAndOrientation
    @available(iOS, introduced: 13.0)
    static func requestImageDataAndOrientation(
        forToken token: Token,
        manager: PHImageManager,
        forAsset asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (Data?, String?, CGImagePropertyOrientation, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID
}
