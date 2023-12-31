//
//  AlbumEntry.swift
//  LarkSensitivityControl
//
//  Created by yangyifan on 2023/3/15.
//

import Photos
import PhotosUI

/// 业务方直接使用
@objc
final public class AlbumEntry: NSObject, AlbumApi {

    private static func getService() -> AlbumApi.Type {
        if let service = LSC.getService(forTag: tag) as? AlbumApi.Type {
            return service
        }
        return AlbumWrapper.self
    }

    /// PHAsset fetchAssetsWithMediaType
    public static func fetchAssets(forToken token: Token,
                                   withMediaType mediaType: PHAssetMediaType,
                                   options: PHFetchOptions?) throws -> PHFetchResult<PHAsset> {
        let context = Context([AtomicInfo.Album.fetchAssetsWithMediaType.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().fetchAssets(forToken: token, withMediaType: mediaType, options: options)
    }

    /// PHAssetChangeRequest creationRequestForAsset
    @objc
    public static func creationRequestForAsset(forToken token: Token,
                                               fromImage image: UIImage) throws -> PHAssetChangeRequest {
        let context = Context([AtomicInfo.Album.creationRequestForAsset.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().creationRequestForAsset(forToken: token, fromImage: image)
    }

    /// PHAssetChangeRequest creationRequestForAssetFromImage
    public static func creationRequestForAssetFromImage(forToken token: Token,
                                                        atFileURL fileURL: URL) throws -> PHAssetChangeRequest? {
        let context = Context([AtomicInfo.Album.creationRequestForAssetFromImage.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().creationRequestForAssetFromImage(forToken: token, atFileURL: fileURL)
    }

    /// PHAssetChangeRequest creationRequestForAssetFromVideo
    public static func creationRequestForAssetFromVideo(forToken token: Token,
                                                        atFileURL fileURL: URL) throws -> PHAssetChangeRequest? {
        let context = Context([AtomicInfo.Album.creationRequestForAssetFromVideo.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().creationRequestForAssetFromVideo(forToken: token, atFileURL: fileURL)
    }

    /// PHAssetCreationRequest forAsset
    public static func forAsset(forToken token: Token) throws -> PHAssetCreationRequest {
        let context = Context([AtomicInfo.Album.forAsset.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().forAsset(forToken: token)
    }

    /// PHCollectionList fetchTopLevelUserCollections
    public static func fetchTopLevelUserCollections(forToken token: Token,
                                                    withOptions options: PHFetchOptions?) throws -> PHFetchResult<PHCollection> {
        let context = Context([AtomicInfo.Album.fetchTopLevelUserCollections.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().fetchTopLevelUserCollections(forToken: token, withOptions: options)
    }

    /// PHPhotoLibrary requestAuthorization
    @objc
    public static func requestAuthorization(forToken token: Token,
                                            handler: @escaping (PHAuthorizationStatus) -> Void) throws {
        let context = Context([AtomicInfo.Album.requestAuthorization.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestAuthorization(forToken: token, handler: handler)
    }

    /// PHPhotoLibrary requestAuthorizationForAccessLevel
    @objc
    @available(iOS, introduced: 14.0)
    public static func requestAuthorization(forToken token: Token,
                                            forAccessLevel accessLevel: PHAccessLevel,
                                            handler: @escaping (PHAuthorizationStatus) -> Void) throws {
        let context = Context([AtomicInfo.Album.requestAuthorizationForAccessLevel.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestAuthorization(forToken: token, forAccessLevel: accessLevel, handler: handler)
    }

    /// PHAssetCollection fetchAssetCollections
    public static func fetchAssetCollections(forToken token: Token,
                                             withType type: PHAssetCollectionType,
                                             subtype: PHAssetCollectionSubtype,
                                             options: PHFetchOptions?) throws -> PHFetchResult<PHAssetCollection> {
        let context = Context([AtomicInfo.Album.fetchAssetCollections.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().fetchAssetCollections(forToken: token, withType: type,
                                                      subtype: subtype, options: options)
    }

    /// PHAssetResourceManager requestData
    public static func requestData(
        forToken token: Token,
        manager: PHAssetResourceManager,
        forResource resource: PHAssetResource,
        options: PHAssetResourceRequestOptions?,
        dataReceivedHandler handler: @escaping (Data) -> Void,
        completionHandler: @escaping (Error?) -> Void
    ) throws -> PHAssetResourceDataRequestID {
        let context = Context([AtomicInfo.Album.requestData.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().requestData(forToken: token, manager: manager, forResource: resource,
                                            options: options, dataReceivedHandler: handler,
                                            completionHandler: completionHandler)
    }

    /// PHAssetResourceManager writeData
    public static func writeData(forToken token: Token,
                                 manager: PHAssetResourceManager,
                                 forResource resource: PHAssetResource,
                                 toFile fileURL: URL,
                                 options: PHAssetResourceRequestOptions?,
                                 completionHandler: @escaping (Error?) -> Void) throws {
        let context = Context([AtomicInfo.Album.writeData.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().writeData(forToken: token, manager: manager, forResource: resource,
                                   toFile: fileURL, options: options,
                                   completionHandler: completionHandler)
    }

    /// PHImageManager requestAVAsset
    public static func requestAVAsset(
        forToken token: Token,
        manager: PHImageManager,
        forVideoAsset asset: PHAsset,
        options: PHVideoRequestOptions?,
        resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID {
        let context = Context([AtomicInfo.Album.requestAVAsset.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().requestAVAsset(forToken: token, manager: manager, forVideoAsset: asset,
                                               options: options, resultHandler: resultHandler)
    }

    /// PHImageManager requestExportSession
    public static func requestExportSession(
        forToken token: Token,
        manager: PHImageManager,
        forVideoAsset asset: PHAsset,
        options: PHVideoRequestOptions?,
        exportPreset: String,
        resultHandler: @escaping (AVAssetExportSession?, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID {
        let context = Context([AtomicInfo.Album.requestExportSession.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().requestExportSession(forToken: token, manager: manager,
                                                     forVideoAsset: asset, options: options,
                                                     exportPreset: exportPreset,
                                                     resultHandler: resultHandler)
    }

    /// PHImageManager requestImage
    public static func requestImage(forToken token: Token,
                                    manager: PHImageManager,
                                    forAsset asset: PHAsset,
                                    targetSize: CGSize,
                                    contentMode: PHImageContentMode,
                                    options: PHImageRequestOptions?,
                                    resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) throws -> PHImageRequestID {
        let context = Context([AtomicInfo.Album.requestImage.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().requestImage(forToken: token, manager: manager, forAsset: asset, targetSize: targetSize,
                                             contentMode: contentMode, options: options, resultHandler: resultHandler)
    }

    /// PHImageManager requestPlayerItem
    public static func requestPlayerItem(forToken token: Token,
                                         manager: PHImageManager,
                                         forVideoAsset asset: PHAsset,
                                         options: PHVideoRequestOptions?,
                                         resultHandler: @escaping (AVPlayerItem?, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID {
        let context = Context([AtomicInfo.Album.requestPlayerItem.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().requestPlayerItem(forToken: token, manager: manager, forVideoAsset: asset,
                                                  options: options, resultHandler: resultHandler)
    }

    /// PHPickerViewController createPickerViewControllerWithConfiguration
    @available(iOS, introduced: 14.0)
    public static func createPickerViewControllerWithConfiguration(
        forToken token: Token,
        configuration: PHPickerConfiguration) throws -> PHPickerViewController {
        let context = Context([AtomicInfo.Album.createPickerViewControllerWithConfiguration.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().createPickerViewControllerWithConfiguration(forToken: token, configuration: configuration)
    }

    /// UIImagePickerController createImagePickerController
    public static func createImagePickerController(forToken token: Token) throws -> UIImagePickerController {
        let context = Context([AtomicInfo.Album.createImagePickerController.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().createImagePickerController(forToken: token)
    }

    /// UIImageWriteToSavedPhotosAlbum
    public static func UIImageWriteToSavedPhotosAlbum(forToken token: Token,
                                                      _ image: UIImage,
                                                      _ completionTarget: Any?,
                                                      _ completionSelector: Selector?,
                                                      _ contextInfo: UnsafeMutableRawPointer?) throws {
        let context = Context([AtomicInfo.Album.UIImageWriteToSavedPhotosAlbum.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().UIImageWriteToSavedPhotosAlbum(forToken: token, image, completionTarget, completionSelector, contextInfo)
    }

    /// UISaveVideoAtPathToSavedPhotosAlbum
    public static func UISaveVideoAtPathToSavedPhotosAlbum(forToken token: Token,
                                                           _ videoPath: String,
                                                           _ completionTarget: Any?,
                                                           _ completionSelector: Selector?,
                                                           _ contextInfo: UnsafeMutableRawPointer?) throws {
        let context = Context([AtomicInfo.Album.UISaveVideoAtPathToSavedPhotosAlbum.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().UISaveVideoAtPathToSavedPhotosAlbum(forToken: token, videoPath, completionTarget,
                                                             completionSelector, contextInfo)
    }

    /// PHImageManager requestImageData
    @available(iOS, introduced: 8.0, deprecated: 13.0)
    public static func requestImageData(
        forToken token: Token,
        manager: PHImageManager,
        forAsset asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID {
        let context = Context([AtomicInfo.Album.requestImageData.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().requestImageData(forToken: token, manager: manager, forAsset: asset,
                                                 options: options, resultHandler: resultHandler)
    }

    /// PHImageManager requestImageDataAndOrientation
    @available(iOS, introduced: 13.0)
    public static func requestImageDataAndOrientation(
        forToken token: Token,
        manager: PHImageManager,
        forAsset asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (Data?, String?, CGImagePropertyOrientation, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID {
        let context = Context([AtomicInfo.Album.requestImageDataAndOrientation.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().requestImageDataAndOrientation(forToken: token, manager: manager, forAsset: asset,
                                                               options: options, resultHandler: resultHandler)
    }
}
