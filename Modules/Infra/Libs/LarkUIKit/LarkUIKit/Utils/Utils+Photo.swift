//
//  Utils+Photo.swift
//  Lark
//
//  Created by 刘晚林 on 2017/5/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkFoundation
import LKCommonsLogging
import Photos
import ByteWebImage
import LarkSensitivityControl
import LarkStorage

public extension Utils {
    /*
    static let latestImageLocalId = "latest-image-local-id"

    static func fetchLatestImage(_ callback: @escaping (UIImage?) -> Void) {
        // 按creationDate降序
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 1
        let results = PHAsset.fetchAssets(with: .image, options: options)
        // 获得2分钟内创建的图片
        guard let asset = results.firstObject,
            let creationDate = asset.creationDate,
            creationDate.isLater(than: Date().add(-2.minutes)) else {
                callback(nil)
                return
        }
        // 之前拿到过的图片不返回
        let localId = UserDefaults.standard.string(forKey: Utils.latestImageLocalId)
        if localId == asset.localIdentifier {
            callback(nil)
            return
        }

        // 获取高清图片
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = .exact
        requestOptions.deliveryMode = .highQualityFormat

        PHImageManager.default().requestImage(for: asset,
                                              targetSize: PHImageManagerMaximumSize,
                                              contentMode: .aspectFit,
                                              options: requestOptions,
                                              resultHandler: { image, _ in
            guard let image = image else {
                callback(nil)
                return
            }
            callback(image)

            // 读取到图片后保存id
            UserDefaults.standard.set(asset.localIdentifier, forKey: Utils.latestImageLocalId)
            UserDefaults.standard.synchronize()
        })
    }
    */

    /// 检查是否有相册读写权限 (PHAccessLevel.readWrite)
    static func checkPhotoReadWritePermission(_ handler: @escaping (_ granted: Bool) -> Void) {
        func hasPhotoReadPermission() -> Bool {
            if #available(iOS 14, *) {
                return [.authorized, .limited].contains(PHPhotoLibrary.authorizationStatus(for: .readWrite))
            } else {
                return PHPhotoLibrary.authorizationStatus() == .authorized
            }
        }

        func needsToRequestPhotoReadPermission() -> Bool {
            return PHPhotoLibrary.authorizationStatus() == .notDetermined
        }

        if hasPhotoReadPermission() {
            handler(true)
        } else {
            if needsToRequestPhotoReadPermission() {
                PHPhotoLibrary.requestAuthorization { _ in
                    let granted = hasPhotoReadPermission()
                    DispatchQueue.main.async {
                        handler(granted)
                    }
                }
            } else {
                handler(false)
            }
        }
    }

    static func checkPhotoReadWritePermission(token: Token, _ handler: @escaping (_ granted: Bool) -> Void) throws {
        let context = Context([AtomicInfo.Album.requestAuthorization.rawValue])
        try SensitivityManager.shared.checkToken(token, context: context)
        self.checkPhotoReadWritePermission(handler)
    }

    /// 检查是否有相册写权限 (PHAccessLevel.addOnly)
    static func checkPhotoWritePermission(_ handler: @escaping (_ granted: Bool) -> Void) {
        @Sendable
        func hasPhotoWritePermission() -> Bool {
            if #available(iOS 14, *) {
                return [.authorized, .limited].contains(PHPhotoLibrary.authorizationStatus(for: .addOnly))
            } else {
                return PHPhotoLibrary.authorizationStatus() == .authorized
            }
        }

        func needsToRequestPhotoWritePermission() -> Bool {
            if #available(iOS 14, *) {
                return PHPhotoLibrary.authorizationStatus(for: .addOnly) == .notDetermined
            } else {
                return PHPhotoLibrary.authorizationStatus() == .notDetermined
            }
        }

        func requestWritePermission(completion: @escaping (Bool) -> Void) {
            if #available(iOS 14, *) { // 14 以上适配更精细的权限申请，最小权限原则
                Task {
                    _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                    let authorized = hasPhotoWritePermission()
                    await MainActor.run {
                        completion(authorized)
                        Self.recordPreconditionOfIOS17PhotoPermissionBug()
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization({ _ in
                    let granted = hasPhotoWritePermission()
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                })
            }
        }

        if hasPhotoWritePermission() {
            handler(true)
        } else {
            if needsToRequestPhotoWritePermission() {
                requestWritePermission(completion: handler)
            } else {
                handler(false)
            }
        }
    }

    /// 判断用户的操作是否触发了 iOS17 的权限 bug。
    ///
    /// - 判断条件1：先请求 .addOnly 权限（允许），再请求 .readOnly 权限（保持 addOnly）
    /// - 判断条件2：.addOnly == .authorized && .readWrite == .denied
    ///
    /// - NOTE: 背景：https://bytedance.feishu.cn/docx/IiStdYAWMoVGV1xWu2ucoDEanzh?theme=FOLLOW_SYSTEM&contentTheme=DARK
    static func hasTriggeredIOS17PhotoPermissionBug() -> Bool {
        guard #available(iOS 17, *) else { return false }
        guard PHPhotoLibrary.authorizationStatus(for: .addOnly) == .authorized,
                PHPhotoLibrary.authorizationStatus(for: .readWrite) == .denied else { return false }
        guard let meetPrecondition: Bool = KVStores.in(space: .global).in(domain: Domain.biz.infra).udkv()
            .value(forKey: "ios17AuthBugPrecondition") else { return false }
        return meetPrecondition
    }

    /// 记录用户的权限操作，是否在 .readWrite 之前先授予了 .addOnly 权限（只有这种情况 bug 才会触发）
    private static func recordPreconditionOfIOS17PhotoPermissionBug() {
        guard #available(iOS 17, *) else { return }
        guard PHPhotoLibrary.authorizationStatus(for: .addOnly) == .authorized, PHPhotoLibrary.authorizationStatus(for: .readWrite) == .notDetermined else { return }
        KVStores.in(space: .global).in(domain: Domain.biz.infra).udkv().set(true, forKey: "ios17AuthBugPrecondition")
    }

    /// 检查是否有相册写权限 (PHAccessLevel.addOnly)
    static func checkPhotoWritePermission(token: Token, _ handler: @escaping (_ granted: Bool) -> Void) throws {
        let context = Context([AtomicInfo.Album.requestAuthorization.rawValue, AtomicInfo.Album.requestAuthorizationForAccessLevel.rawValue])
        try SensitivityManager.shared.checkToken(token, context: context)
        self.checkPhotoWritePermission(handler)
    }

    static func savePhoto(image: UIImage, handler: @escaping (_ success: Bool, _ granted: Bool) -> Void) {
        func saveData() {
            if let data = (image as? ByteImage)?.animatedImageData {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
                }, completionHandler: { (success, error) in
                    DispatchQueue.main.async {
                        handler(success, true)
                    }
                    PhotoSaveLogger.logIfNeeded(error)
                })
            } else {
                UIImageWriteToSavedPhotosAlbum(image, PhotoSaveLogger.self,
                                               #selector(PhotoSaveLogger.saveComplete), nil)
                handler(true, true)
            }
        }

        self.checkPhotoWritePermission { granted in
            granted ? saveData() : handler(false, false)
        }
    }

    static func savePhoto(token: Token, image: UIImage, handler: @escaping (_ success: Bool, _ granted: Bool) -> Void) throws {
        let context = Context([AtomicInfo.Album.UIImageWriteToSavedPhotosAlbum.rawValue, AtomicInfo.Album.forAsset.rawValue,
                               AtomicInfo.Album.requestAuthorization.rawValue, AtomicInfo.Album.requestAuthorizationForAccessLevel.rawValue])
        try SensitivityManager.shared.checkToken(token, context: context)
        self.savePhoto(image: image, handler: handler)
    }

    static func savePhoto(url: URL, handler: @escaping (_ success: Bool, _ granted: Bool) -> Void) {
        func saveURL() {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCreationRequest.forAsset().addResource(with: .photo, fileURL: url, options: nil)
                }, completionHandler: { (success, error) in
                    DispatchQueue.main.async {
                        handler(success, true)
                    }
                    PhotoSaveLogger.logIfNeeded(error)
                })
        }

        self.checkPhotoWritePermission { granted in
            granted ? saveURL() : handler(false, false)
        }
    }

    static func savePhoto(token: Token, url: URL, handler: @escaping (_ success: Bool, _ granted: Bool) -> Void) throws {
        let context = Context([AtomicInfo.Album.forAsset.rawValue, AtomicInfo.Album.requestAuthorization.rawValue,
                               AtomicInfo.Album.requestAuthorizationForAccessLevel.rawValue])
        try SensitivityManager.shared.checkToken(token, context: context)
        self.savePhoto(url: url, handler: handler)
    }

    static func saveVideo(url: URL, handler: @escaping (_ success: Bool, _ granted: Bool) -> Void) {
        func save() {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.forAsset().addResource(with: .video, fileURL: url, options: nil)
            }, completionHandler: { (success, error) in
                DispatchQueue.main.async {
                    handler(success, true)
                }
                PhotoSaveLogger.logIfNeeded(error)
            })
        }

        self.checkPhotoWritePermission { granted in
            granted ? save() : handler(false, false)
        }
    }

    static func saveVideo(token: Token, url: URL, handler: @escaping (_ success: Bool, _ granted: Bool) -> Void) throws {
        let context = Context([AtomicInfo.Album.forAsset.rawValue, AtomicInfo.Album.requestAuthorization.rawValue,
                               AtomicInfo.Album.requestAuthorizationForAccessLevel.rawValue])
        try SensitivityManager.shared.checkToken(token, context: context)
        self.saveVideo(url: url, handler: handler)
    }
}

private final class PhotoSaveLogger: NSObject {
    static let logger = Logger.log(Utils.self, category: "Utils+Photo")

    static func logIfNeeded(_ error: Error?) {
        if let error = error {
            logger.error("save image to album failed from Utils: \(error)")
        }
    }

    @objc
    static func saveComplete(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        logIfNeeded(error)
    }
}
