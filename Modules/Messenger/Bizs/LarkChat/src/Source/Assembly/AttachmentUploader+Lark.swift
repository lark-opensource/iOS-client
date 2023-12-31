//
//  AttachmentUploader.swift
//  Lark
//
//  Created by lichen on 2017/8/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkContainer
import LarkFoundation
import LarkCore
import Swinject
import LarkAttachmentUploader
import LarkSDKInterface
import LarkSendMessage
import RustPB
import ByteWebImage

extension AttachmentUploader {
    class func getDefaultHandler(name: String,
                                 cache: AttachmentDataStorage,
                                 progressService: ProgressService,
                                 resolver: Resolver) -> AttachmentUploader {
        let uploader = AttachmentUploader(name: name, cache: cache)
        uploader.register(type: .image) { (uploader, key, _, callback, _) in
            guard let data = cache.syncGetDraftAttachment(domain: uploader.name, attachmentName: key),
                let imageAPI = try? resolver.resolve(assert: ImageAPI.self)
            else {
                let error = PlainError("Image Attachment \(uploader.name) \(key) data 不存在")
                callback(key, nil, nil, error)
                return
            }
            imageAPI.uploadImage(data: data, imageCompressedSizeKb: 0)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (imageSetModel: LarkModel.ImageSet) in
                    let imageKey = imageSetModel.key
                    let width = imageSetModel.origin.width
                    let height = imageSetModel.origin.height
                    let imageDraft = UploadedImageDraft(key: imageKey, width: width, height: height)
                    callback(key, imageDraft.stringify(), data, nil)
                }, onError: { (err) in
                    callback(key, nil, nil, err)
                })
                .disposed(by: uploader.disposeBag)
        }

        uploader.register(type: .file) { (uploader, key, attachment, callback, _) in
            guard let path = attachment.info["path"],
                let type = attachment.info["type"],
                let filename = attachment.info["fileName"],
                let fileAPI = try? resolver.resolve(assert: SecurityFileAPI.self),
                let pushCenter = try? resolver.userPushCenter
            else {
                callback(key, nil, nil, PlainError("Upload file not have path or type"))
                return
            }
            let filepath = AttachmentDataStorage.draftPath(root: uploader.cache.root, domain: uploader.name, attachmentName: path)
            let newfilepath = AttachmentDataStorage.draftPath(root: uploader.cache.root, domain: uploader.name, attachmentName: filename)
            try? filepath.copyItem(to: newfilepath)
            var uploadType: RustPB.Basic_V1_File.EntityType = .message
            if type == "email" {
                uploadType = .email
            }

            pushCenter
                .observable(for: PushUploadFile.self)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (push) in
                    if push.localKey != key {
                        return
                    }
                    if push.state == .uploadSuccess {
                        callback(push.localKey, push.key, nil, nil)
                    } else if push.state == .uploadCancel ||
                        push.state == .uploadFail {
                        callback(push.localKey, nil, nil, nil)
                    }
                })
                .disposed(by: uploader.disposeBag)

            fileAPI.uploadFiles(keyAndPaths: [key: newfilepath.absoluteString], type: uploadType).subscribe(onError: { (error) in
                callback(key, nil, nil, error)
            }).disposed(by: uploader.disposeBag)
        }

        uploader.register(type: .secureImage) { (uploader, key, attachment, callback, _) in
            guard let data = cache.syncGetDraftAttachment(domain: uploader.name, attachmentName: key),
                let imageAPI = try? resolver.resolve(assert: ImageAPI.self)
            else {
                    let error = PlainError("Image Attachment \(uploader.name) \(key) data 不存在")
                    callback(key, nil, nil, error)
                    return
            }

            // 视频首帧图片不上传 只存储
            if let isVideo = attachment.info["isVideo"], isVideo == "1" {
                callback(key, key, nil, nil)
                return
            }

            var type = RustPB.Media_V1_UploadSecureImageRequest.TypeEnum.normal
            if let imageType = attachment.info["type"], imageType == "post" {
                type = RustPB.Media_V1_UploadSecureImageRequest.TypeEnum.post
            }
            let startTimeinterval = Date().timeIntervalSince1970
            imageAPI.uploadSecureImage(data: data, type: type, imageCompressedSizeKb: 0, encrypt: false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (token) in
                    callback(key, token, data, nil)
                }, onError: { (err) in
                    callback(key, nil, nil, err)
                })
                .disposed(by: uploader.disposeBag)
        }

        return uploader
    }
}
