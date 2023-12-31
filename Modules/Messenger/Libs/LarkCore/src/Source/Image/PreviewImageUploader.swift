//
//  PreviewImageUploader.swift
//  Lark
//
//  Created by liuwanlin on 2018/8/17.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LKCommonsLogging
import RxSwift
import Reachability
import LarkSDKInterface
import LarkAvatar
import LarkUIKit
import LarkAssetsBrowser
import LarkImageEditor
import ByteWebImage
import LarkFeatureGating

final class DefaultImageUploader: PreviewImageUploader {

    static let log = Logger.log(UploadImageViewController.self, category: "Modules.common")

    private static let reach = Reachability()

    private let imageAPI: ImageAPI

    var imageEditAction: ((ImageEditEvent) -> Void)? {
        let imageEditAction: ((ImageEditEvent) -> Void)? = {
            CoreTracker.trackImageEditEvent($0.event, params: $0.params)
        }
        return imageEditAction
    }

    init(imageAPI: ImageAPI) {
        self.imageAPI = imageAPI
    }

    func upload(_ imageSources: [ImageSourceProvider], isOrigin: Bool) -> Observable<[String]> {
        var imageCompressedSizeKb: Int64 = 0

        if !isOrigin {
            if (DefaultImageUploader.reach?.connection ?? .none) == .wifi {
                imageCompressedSizeKb = 500
            } else if (DefaultImageUploader.reach?.connection ?? .none) == .cellular {
                imageCompressedSizeKb = 300
            }
        }

        let imageAPI = self.imageAPI
        return Observable<[Data]>.create({ (observer) -> Disposable in
            DispatchQueue.global().async {
                var images: [UIImage] = []
                imageSources.forEach { (getResource) in
                    guard let image = getResource() else {
                        return
                    }
                    images.append(image)
                }
                let datas = images.compactMap { (image) -> Data? in
                    let imageData = (image as? ByteImage)?.animatedImageData ?? image.jpegData(compressionQuality: 1)
                    if imageData == nil {
                        DefaultImageUploader.log.error("无法获取图片数据")
                    }
                    return imageData
                }
                observer.onNext(datas)
            }
            return Disposables.create()
        }).flatMap({ (datas) -> Observable<[String]> in
            let observables = datas.map({ (data) -> Observable<String> in
                return imageAPI.uploadImage(data: data, imageCompressedSizeKb: imageCompressedSizeKb).map {
                    return $0.origin.firstUrl
                }
            })
            return Observable.combineLatest(observables)
        }).observeOn(MainScheduler.instance)
    }
}

final class AvatarImageUploader: PreviewImageUploader {
    private let chatterAPI: ChatterAPI

    var imageEditAction: ((ImageEditEvent) -> Void)? {
        let imageEditAction: ((ImageEditEvent) -> Void)? = {
            CoreTracker.trackImageEditEvent($0.event, params: $0.params)
        }
        return imageEditAction
    }

    init(chatterAPI: ChatterAPI) {
        self.chatterAPI = chatterAPI
    }

    func upload(_ imageSources: [ImageSourceProvider], isOrigin: Bool) -> Observable<[String]> {
        guard let image = imageSources.first?() else { return .empty() }
        let sendImageByAvatar = SendImageUploadByAvatar(chatAPI: self.chatterAPI)
        let avatarUploadConfig = LarkImageService.shared.imageUploadSetting.avatarConfig
        let compressRate = Float(avatarUploadConfig.quality) / 100
        let destPixel = avatarUploadConfig.limitImageSize
        let sendImageRequest = SendImageRequest(
            input: .image(image),
            sendImageConfig: SendImageConfig(
                checkConfig: SendImageCheckConfig(
                    isOrigin: isOrigin, needConvertToWebp: true, scene: .ProfileAvatar, fromType: .avatar),
                compressConfig: SendImageCompressConfig(compressRate: compressRate, destPixel: destPixel)),
            uploader: sendImageByAvatar)
        return SendImageManager.shared.sendImage(request: sendImageRequest)
    }
}

final class SendImageUploadByAvatar: LarkSendImageUploader {
    typealias AbstractType = [String]
    private let chatAPI: ChatterAPI
    init(chatAPI: ChatterAPI) {
        self.chatAPI = chatAPI
    }
    func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<AbstractType> {
        return Observable<Data?>.create { [weak self] observer in
            let input = request.getInput()
            guard let `self` = self,
                  case .image(let image) = input,
                  let compressResult = request.getCompressResult()?.first?.result,
                  case .success(let result) = compressResult
            else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            let imageData = result.data
            observer.onNext(imageData)
            observer.onCompleted()
            return Disposables.create()
        }
        .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
        .flatMap({ [weak self] (data) -> Observable<AbstractType> in
            guard let `self` = self else { return .just([]) }
            return self.chatAPI.updateAvatar(avatarData: data).map({ [weak self] (key) -> [String] in
                guard let `self` = self else { return [] }
                CoreTracker.trackUploadAvatar()
                return [key]
            })
        })
        .observeOn(MainScheduler.instance)
    }
}

final class SettingSingleImageUploader: PreviewImageUploader {
    let updateCallback: ((Data?, UIImage, Bool)) -> Observable<[String]>

    var imageEditAction: ((ImageEditEvent) -> Void)? {
        let imageEditAction: ((ImageEditEvent) -> Void)? = {
            CoreTracker.trackImageEditEvent($0.event, params: $0.params)
        }
        return imageEditAction
    }

    init(updateCallback: @escaping ((Data?, UIImage, Bool)) -> Observable<[String]>) {
        self.updateCallback = updateCallback
    }

    func upload(_ imageSources: [ImageSourceProvider], isOrigin: Bool) -> Observable<[String]> {
        guard let image = imageSources.first?() else { return .empty() }
        let sendImageBySettingSingle = SendImageUploadBySettingSingle(isOrigin: isOrigin, updateCallback: updateCallback)
        let avatarUploadConfig = LarkImageService.shared.imageUploadSetting.avatarConfig
        let compressRate = Float(avatarUploadConfig.quality) / 100
        let destPixel = avatarUploadConfig.limitImageSize
        let sendImageRequest = SendImageRequest(
            input: .image(image),
            sendImageConfig: SendImageConfig(
                checkConfig: SendImageCheckConfig(
                    isOrigin: isOrigin, needConvertToWebp: true, scene: .Profile, fromType: .avatar),
                compressConfig: SendImageCompressConfig(compressRate: compressRate, destPixel: destPixel)),
            uploader: sendImageBySettingSingle)
        return SendImageManager.shared.sendImage(request: sendImageRequest)
    }
}

final class SendImageUploadBySettingSingle: LarkSendImageUploader {
    typealias AbstractType = [String]
    private let updateCallback: ((Data?, UIImage, Bool)) -> Observable<[String]>
    private let isOrigin: Bool
    init(isOrigin: Bool, updateCallback: @escaping ((Data?, UIImage, Bool)) -> Observable<[String]>) {
        self.updateCallback = updateCallback
        self.isOrigin = isOrigin
    }
    func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<AbstractType> {
        let input = request.getInput()
        if case .image(let image) = input,
           let compressResult = request.getCompressResult()?.first?.result,
           case .success(let result) = compressResult {
            return updateCallback((result.data, image, isOrigin))
        } else {
            return .just([])
        }
    }
}
