//
//  PostAttachmentManager.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/24.
//

import Foundation
import UIKit
import EditTextView
import LarkRichTextCore
import ByteWebImage
import LarkAttachmentUploader
import LKCommonsLogging

/// 1.负责图片的上传和状态的回调
/// 2.草稿的存储&恢复
public final class PostAttachmentManager: PostAttachmentServer {
    static let logger = Logger.log(PostAttachmentManager.self, category: "Module.IM.PostAttachmentManager")
    public let attachmentUploader: AttachmentUploader
    public var defaultCallBack: (AttachmentUploadTaskCallback)?
    public init(attachmentUploader: AttachmentUploader) {
        self.attachmentUploader = attachmentUploader
        attachmentUploader.defaultCallback = { [weak self] (uploader: AttachmentUploader, key: String, url: String?, data: Data?, error: Error?) in
            self?.defaultCallBack?(uploader, key, url, data, error)
        }
    }
    /// 根据 upload result 更新附件 result
    public func updateAttachmentResultInfo(_ attributedText: NSAttributedString) {
        // 更新 image attachment key
        let imageAttachments: [(String, CustomTextAttachment, ImageTransformInfo, NSRange)] = ImageTransformer.fetchAllImageAttachemnt(attributedText: attributedText)
        for value in imageAttachments {
            if let result = attachmentUploader.results[value.0] {
                value.2.key = result
            }
        }
    }

    public func updateImageAttachmentState(_ textView: LarkEditTextView?) {
        guard let textView = textView else { return }
        self.updateImageAttachmentState(textView.attributedText, gifBackgroundColor: textView.backgroundColor) { [weak textView] in
            return textView?.attributedText ?? NSAttributedString(string: "")
        }
    }

    /// 更新图片附件上传状态 retryCallBack点击重试后需要更新UI的AttributeStr
    public func updateImageAttachmentState(_ attributedText: NSAttributedString,
                                           gifBackgroundColor: UIColor?,
                                           retryCallBack: @escaping () -> NSAttributedString) {
        let imageAttachments: [(key: String, view: CustomTextAttachment, info: ImageTransformInfo, range: NSRange)] =
        ImageTransformer.fetchAllImageAttachemnt(attributedText: attributedText)

        for value in imageAttachments {
            if let attachmentImage = value.view.customView as? AttachmentImageView {
                attachmentImage.clickBlock = { [weak self] (key: String, state: AttachmentImageView.State) in
                    guard let self = self else {
                        return
                    }
                    if state == .failed {
                        self.attachmentUploader.reuploadFailedTask(key: key)
                        self.updateImageAttachmentState(retryCallBack(), gifBackgroundColor: gifBackgroundColor, retryCallBack: retryCallBack)
                    }
                }
                if attachmentUploader.uploadSuccessed(key: value.key) {
                    attachmentImage.state = .success
                } else if attachmentUploader.uploadFailed(key: value.key) {
                    attachmentImage.state = .failed
                } else {
                    attachmentImage.state = .progress
                }
                attachmentImage.updateGifImageBackgroundColorIfNeed(gifBackgroundColor)
            }
        }
    }

    /// 视频由于有时间的存在 需要有个最小的宽度
    public func applyAttachmentDraftForTextView(_ textView: LarkEditTextView,
                                                async: Bool,
                                                imageMaxHeight: CGFloat?,
                                                imageMinWidth: CGFloat?,
                                                finishBlock: (() -> Void)?,
                                                didUpdateAttrText: (() -> Void)?) {
        guard let attributedText = textView.attributedText else {
            return
        }
        let imageAttachments: [(key: String, view: CustomTextAttachment, info: ImageTransformInfo, range: NSRange)] =
        ImageTransformer.fetchAllImageAttachemnt(attributedText: attributedText)
        // 视频逻辑
        let videoAttachments: [(key: String, view: CustomTextAttachment, info: VideoTransformInfo, range: NSRange)] = VideoTransformer.fetchAllVideoAttachemnt(attributedText: attributedText)

        let remoteImageAttachments: [(key: String, view: CustomTextAttachment, info: ImageTransformInfo, range: NSRange)] =
        ImageTransformer.fetchAllRemoteImageAttachemnt(attributedText: attributedText)

        let remoteVideoAttachments: [(key: String, view: CustomTextAttachment, info: VideoTransformInfo, range: NSRange)] =
        VideoTransformer.fetchAllRemoteVideoAttachemnt(attributedText: attributedText)

        /// 如果没有没有视频 或者Video就不需要处理
        if imageAttachments.isEmpty, videoAttachments.isEmpty,
           remoteImageAttachments.isEmpty, remoteVideoAttachments.isEmpty {
            finishBlock?()
            return
        }

        let group = DispatchGroup()
        // 图片逻辑
        imageAttachments.forEach { value in
            group.enter()
            attachmentUploader.getDraftAttachment(attachmentName: value.key, callback: { [weak self, weak textView] (data) in
                guard let self = self, let textView = textView else {
                    group.leave()
                    return
                }
                if let data = data,
                   !data.isEmpty,
                   let task = self.attachmentUploader.task(key: value.key),
                    task.attachment.type == .secureImage {
                    let block: (UIImage?) -> Void = { [weak self] image in
                        guard let image = image else {
                            Self.logger.error("applyAttachment give image = nil")
                            group.leave()
                            return
                        }
                        if value.info.imageSize == .zero {
                            value.info.imageSize = image.size
                        }
                        if let result = self?.attachmentUploader.results[value.key] {
                            value.info.key = result
                        }
                        if let imageView = value.view.customView as? UIImageView {
                            var size = ImageTransformer.imageSize(
                                image: image,
                                inset: textView.contentInset,
                                originSize: value.info.imageSize,
                                editerWidth: textView.bounds.width
                            )
                            if let maxHeight = imageMaxHeight, size.height > maxHeight {
                                size = CGSize(width: size.width * (maxHeight / size.height), height: maxHeight)
                                if let imageMinWidth = imageMinWidth, size.width < imageMinWidth {
                                    size.width = imageMinWidth
                                    imageView.contentMode = .scaleAspectFill
                                }
                            }
                            value.view.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                            imageView.image = ImageTransformer.attachmentImage(image: image, size: size)
                        }
                        group.leave()
                    }
                    if async {
                        DispatchQueue.global(qos: .userInteractive).async {
                            let image = (try? ByteImage(data))?.lu.fixOrientation()
                            DispatchQueue.main.async {
                                block(image)
                            }
                        }
                    } else {
                        block((try? ByteImage(data))?.lu.fixOrientation())
                    }
                } else {
                    Self.logger.error("can find picture in draft data count \(data?.count ?? 0)", additionalData: ["key": value.key])
                    group.leave()
                }
            })
        }

        videoAttachments.forEach { value in
            group.enter()
            attachmentUploader.getDraftAttachment(attachmentName: value.key, callback: { [weak self, weak textView] (data) in
                guard let self = self, let textView = textView else {
                    group.leave()
                    return
                }
                if let data = data,
                   let task = self.attachmentUploader.task(key: value.key),
                    task.attachment.type == .secureImage {
                    let block: (UIImage?) -> Void = { (image) in
                        guard let image = image  else {
                            Self.logger.error("give video.image = nil")
                            group.leave()
                            return
                        }
                        if value.info.imageSize == .zero {
                            value.info.imageSize = image.size
                        }
                        if value.info.imageData.isEmpty {
                            value.info.imageData = data
                        }
                        if let imageView = value.view.customView as? UIImageView {
                            var size = VideoTransformer.imageSize(
                                image: image,
                                inset: textView.contentInset,
                                originSize: value.info.imageSize,
                                editerWidth: textView.bounds.width
                            )
                            if let maxHeight = imageMaxHeight, size.height > maxHeight {
                                size = CGSize(width: size.width * (maxHeight / size.height), height: maxHeight)
                                if let imageMinWidth = imageMinWidth, size.width < imageMinWidth {
                                    size.width = imageMinWidth
                                    imageView.contentMode = .scaleAspectFill
                                }
                            }
                            value.view.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                            imageView.image = VideoTransformer.attachmentImage(image: image, size: size)
                        }
                        group.leave()
                    }
                    if async {
                        DispatchQueue.global(qos: .userInteractive).async {
                            let image = (try? ByteImage(data))?.lu.fixOrientation()
                            DispatchQueue.main.async {
                                block(image)
                            }
                        }
                    } else {
                        block((try? ByteImage(data))?.lu.fixOrientation())
                    }
                } else {
                    Self.logger.error("can not find video cover image in draft data: count \(data?.count)", additionalData: ["key": value.key])
                    if let imageMinWidth = imageMinWidth, let imageMaxHeight = imageMaxHeight {
                        self.updateCustomTextAttachmentSize(value.view, height: imageMaxHeight, imageMinWidth: imageMinWidth)
                    }
                    group.leave()
                }
            })
        }

        remoteImageAttachments.forEach { value in
            if let imageView = value.view.customView as? UIImageView {
                var size = ImageTransformer.imageSize(
                    image: nil,
                    inset: textView.contentInset,
                    originSize: value.info.imageSize,
                    editerWidth: textView.bounds.width
                )
                if let maxHeight = imageMaxHeight, size.height > maxHeight {
                    size = CGSize(width: size.width * (maxHeight / size.height), height: maxHeight)
                    if let imageMinWidth = imageMinWidth, size.width < imageMinWidth {
                        size.width = imageMinWidth
                        imageView.contentMode = .scaleAspectFill
                    }
                }
                value.view.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                var loadKey = value.info.key
                /// 如果原图本地有的话 优先展示原图的,否则展示缩略图
                if let thumbKey = value.info.thumbKey,
                   !LarkImageService.shared.isCached(resource: .default(key: loadKey)) {
                    loadKey = thumbKey
                }
                imageView.bt.setLarkImage(with: .default(key: loadKey),
                                          trackStart: {
                    return TrackInfo(biz: .Messenger,
                                     scene: .Chat,
                                     isOrigin: value.info.useOrigin,
                                     fromType: .post)
                }) { imageResult in
                    if case .failure(let error) = imageResult {
                        Self.logger.error("applyAttachmentDraftForTextView error for image key: \(loadKey)", error: error)
                    }
                }
            }
        }
        remoteVideoAttachments.forEach { value in
            if let imageView = value.view.customView as? UIImageView {
                var size = VideoTransformer.imageSize(
                    image: nil,
                    inset: textView.contentInset,
                    originSize: value.info.imageSize,
                    editerWidth: textView.bounds.width
                )
                if let maxHeight = imageMaxHeight, size.height > maxHeight {
                    size = CGSize(width: size.width * (maxHeight / size.height), height: maxHeight)
                    if let imageMinWidth = imageMinWidth, size.width < imageMinWidth {
                        size.width = imageMinWidth
                        imageView.contentMode = .scaleAspectFill
                    }
                }
                value.view.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                let imageKey = value.info.imageRemoteKey
                imageView.bt.setLarkImage(with: .default(key: imageKey),
                                          trackStart: {
                    return TrackInfo(biz: .Messenger,
                                     scene: .Chat,
                                     isOrigin: false,
                                     fromType: .post)
                }) { imageResult in
                    if case .failure(let error) = imageResult {
                        Self.logger.error("applyAttachmentDraftForTextView error for video cover key: \(imageKey)", error: error)
                    }
                }
            }
        }

        group.notify(queue: DispatchQueue.main) { [weak textView] in
            finishBlock?()
            // 用于强制刷新 contentTextView
            textView?.attributedText = NSAttributedString()
            textView?.attributedText = attributedText
            didUpdateAttrText?()
        }
    }

    public func resizeAttachmentView(textView: LarkEditTextView, toSize: CGSize) {
        guard let attributedText = textView.attributedText else {
            return
        }
        let imageAttachments: [(key: String, view: CustomTextAttachment, info: ImageTransformInfo, range: NSRange)] =
        ImageTransformer.fetchAllImageAttachemnt(attributedText: attributedText)

        let videoAttachments: [(key: String, view: CustomTextAttachment, info: VideoTransformInfo, range: NSRange)] =
        VideoTransformer.fetchAllVideoAttachemnt(attributedText: attributedText)

        let remoteImageAttachments: [(key: String, view: CustomTextAttachment, info: ImageTransformInfo, range: NSRange)] =
        ImageTransformer.fetchAllRemoteImageAttachemnt(attributedText: attributedText)

        let remoteVideoAttachments: [(key: String, view: CustomTextAttachment, info: VideoTransformInfo, range: NSRange)] =
        VideoTransformer.fetchAllRemoteVideoAttachemnt(attributedText: attributedText)

        if imageAttachments.isEmpty, videoAttachments.isEmpty,
           remoteImageAttachments.isEmpty, remoteVideoAttachments.isEmpty {
            return
        }
        let gifBackgroundColor = textView.backgroundColor
        let group = DispatchGroup()
        // 图片逻辑
        imageAttachments.forEach { value in
            group.enter()
            attachmentUploader.getDraftAttachment(attachmentName: value.key, callback: { (data) in
                defer {
                    group.leave()
                }
                if let data = data,
                   let image = (try? ByteImage(data))?.lu.fixOrientation() {
                    if let imageView = value.view.customView as? UIImageView {
                        let size = ImageTransformer.imageSize(
                            image: image,
                            inset: textView.contentInset,
                            originSize: value.info.imageSize,
                            editerWidth: toSize.width
                        )
                        value.view.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                        imageView.image = ImageTransformer.attachmentImage(image: image, size: size)
                    }
                    if let view = value.view.customView as? AttachmentImageView {
                        view.updateGifImageBackgroundColorIfNeed(gifBackgroundColor)
                    }
                }
            })
        }

        // 视频逻辑
        videoAttachments.forEach { value in
            group.enter()
            attachmentUploader.getDraftAttachment(attachmentName: value.key, callback: { (data) in
                defer {
                    group.leave()
                }
                var draftImage: UIImage?
                if let data = data,
                    let image = (try? ByteImage(data))?.lu.fixOrientation() {
                    draftImage = image
                }
                let size = VideoTransformer.imageSize(
                    image: draftImage,
                    inset: textView.contentInset,
                    originSize: value.info.imageSize,
                    editerWidth: toSize.width
                )
                value.view.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                if let imageView = value.view.customView as? UIImageView, let image = draftImage {
                    imageView.image = VideoTransformer.attachmentImage(image: image, size: size)
                }
            })
        }

        remoteImageAttachments.forEach { value in
            if let imageView = value.view.customView as? UIImageView {
                let size = ImageTransformer.imageSize(
                    image: nil,
                    inset: textView.contentInset,
                    originSize: value.info.imageSize,
                    editerWidth: toSize.width
                )
                value.view.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                var loadKey = value.info.key
                /// 如果原图本地有的话 优先展示原图的,否则展示缩略图
                if let thumbKey = value.info.thumbKey,
                   !LarkImageService.shared.isCached(resource: .default(key: loadKey)) {
                    loadKey = thumbKey
                }
                imageView.bt.setLarkImage(with: .default(key: loadKey),
                                          trackStart: {
                    return TrackInfo(biz: .Messenger,
                                     scene: .Chat,
                                     isOrigin: value.info.useOrigin,
                                     fromType: .post)
                }) { imageResult in
                    switch imageResult {
                    case .success(_):
                        DispatchQueue.main.async { [weak imageView] in
                            if let view = imageView as? AttachmentImageView {
                                view.updateGifImageBackgroundColorIfNeed(gifBackgroundColor)
                            }
                        }
                    case .failure(let error):
                        Self.logger.error("resizeAttachmentView error for image Key: \(loadKey)", error: error)
                    }
                }
            }
        }

        remoteVideoAttachments.forEach { value in
            if let imageView = value.view.customView as? UIImageView {
                let size = VideoTransformer.imageSize(
                    image: nil,
                    inset: textView.contentInset,
                    originSize: value.info.imageSize,
                    editerWidth: toSize.width
                )
                value.view.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                let imageKey = value.info.imageRemoteKey
                imageView.bt.setLarkImage(with: .default(key: imageKey),
                                          trackStart: {
                    return TrackInfo(biz: .Messenger,
                                     scene: .Chat,
                                     isOrigin: false,
                                     fromType: .post)
                }) { imageResult in
                    if case .failure(let error) = imageResult {
                        Self.logger.error("resizeAttachmentView error for video cover image Key: \(imageKey)", error: error)
                    }
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            textView.attributedText = NSAttributedString()
            textView.attributedText = attributedText
        }
    }

    public func storeImageToCacheFromDraft(image: UIImage, imageData: Data, originKey: String) {
        // store image to cache from draft cache
        if !LarkImageService.shared.isCached(resource: .default(key: originKey)) {
            LarkImageService.shared.cacheImage(image: image, data: imageData, resource: .default(key: originKey))
        }
    }

    public func retryUploadAttachment(textView: LarkEditTextView,
                                      start: (() -> Void)?,
                                      finish: ((Bool) -> Void)?) {
        guard let attruibuteStr = textView.attributedText else {
            finish?(true)
            return
        }
        attachmentUploader.reuploadAllFailedTasks()
        updateAttachmentResultInfo(attruibuteStr)
        updateImageAttachmentState(textView)
        start?()
        let attachmentIds = attachmentIdsForAttruibuteStr(attruibuteStr)
        attachmentUploader.allFinishedCallback = { [weak self] uploader in
            defer { uploader.allFinishedCallback = nil }
            guard let self = self else {
                return
            }
            let allUploadFailedIds = self.attachmentUploader.failedTasks.map({ (task) -> String in
                return task.key
            })

            let uploadFailedIdsInPost = allUploadFailedIds.filter({ attachmentIds.contains($0) })
            // 存在图片上传失败的情况
            if !uploadFailedIdsInPost.isEmpty {
                finish?(false)
                return
            }
            finish?(true)
        }
    }

    public func checkAttachmentAllUploadSuccessFor(attruibuteStr: NSAttributedString) -> Bool {
        let attachmentIds = attachmentIdsForAttruibuteStr(attruibuteStr)
        let succesAttachmentIds = attachmentUploader.successedTasks.map { (task) -> String in
            return task.key
        }
        return attachmentIds.filter({ !succesAttachmentIds.contains($0) }).isEmpty
    }

    public func attachmentIdsForAttruibuteStr(_ attruibuteStr: NSAttributedString) -> [String] {
        let imageIds = ImageTransformer.fetchAllImageKey(attributedText: attruibuteStr)
        let remoteImageIds = ImageTransformer.fetchAllRemoteImageKey(attributedText: attruibuteStr)
        let videoIds = VideoTransformer.fetchAllVideoKey(attributedText: attruibuteStr)
        let remoteVideoIds = VideoTransformer.fetchAllRemoteVideoKey(attributedText: attruibuteStr)
        return imageIds + remoteImageIds + videoIds + remoteVideoIds
    }

    public func savePostDraftAttachment(attachmentKeys: [String],
                                        key: String,
                                        async: Bool,
                                        log: Log) {
        var allTasks: [AttachmentUploadTask] = []
        attachmentKeys.forEach { id in
            if let task = attachmentUploader.allTasks.task(key: id) {
                allTasks.append(task)
            } else {
                log.error("缺少贴子 image or imageId草稿信息", additionalData: ["key": key])
            }
        }

        let rootCache = attachmentUploader.cache.root
        let checkTaskAttachment = { (task: AttachmentUploadTask) in
            if task.isInvalid(in: rootCache, domain: key) {
                log.error("attachment task 数据丢失")
                assertionFailure("attachment data 数据丢失")
            }
        }

        let taskKeys = allTasks.map({ (task) -> String in
            return task.key
        })
        /// 清楚和当前key无关的草稿
        attachmentUploader.cleanPostDraftAttachment(excludeKeys: taskKeys) {
            allTasks.forEach({ (task) in
                checkTaskAttachment(task)
            })
        }
    }

    public func updateAttachmentSizeWithMaxHeight(_ height: CGFloat,
                                                  imageMinWidth: CGFloat,
                                                  attributedText: NSAttributedString?,
                                                  textView: LarkEditTextView?) {
        guard let attributedText = attributedText else {
            return
        }
        let gifBackgroundColor = textView?.backgroundColor
        // 图片逻辑
        let imageAttachments: [(String, CustomTextAttachment, ImageTransformInfo, NSRange)] = ImageTransformer.fetchAllImageAttachemnt(attributedText: attributedText)
        imageAttachments.forEach { value in
            updateCustomTextAttachmentSize(value.1,
                                    height: height, imageMinWidth: imageMinWidth)
            if let view = value.1.customView as? AttachmentImageView {
                view.updateGifImageBackgroundColorIfNeed(gifBackgroundColor)
            }
        }

        // 视频逻辑
        let videoAttachments: [(key: String, view: CustomTextAttachment, info: VideoTransformInfo, range: NSRange)] = VideoTransformer.fetchAllVideoAttachemnt(attributedText: attributedText)
        videoAttachments.forEach { value in
            if let imageView = value.view.customView as? UIImageView, imageView.bounds.height > 0 {
                updateCustomTextAttachmentSize(value.view,
                                    height: height, imageMinWidth: imageMinWidth)
            }
        }

        let remoteImageAttachments: [(String, CustomTextAttachment, ImageTransformInfo, NSRange)] = ImageTransformer.fetchAllRemoteImageAttachemnt(attributedText: attributedText)
        remoteImageAttachments.forEach { value in
            updateCustomTextAttachmentSize(value.1,
                                    height: height, imageMinWidth: imageMinWidth)
            if let view = value.1.customView as? AttachmentImageView {
                view.updateGifImageBackgroundColorIfNeed(gifBackgroundColor)
            }
        }

        let remoteVideoAttachments: [(key: String, view: CustomTextAttachment, info: VideoTransformInfo, range: NSRange)] =
        VideoTransformer.fetchAllRemoteVideoAttachemnt(attributedText: attributedText)
        remoteVideoAttachments.forEach { value in
            updateCustomTextAttachmentSize(value.view,
                                    height: height, imageMinWidth: imageMinWidth)
        }
    }

    func updateCustomTextAttachmentSize(_ attachment: CustomTextAttachment,
                             height: CGFloat,
                             imageMinWidth: CGFloat) {
        var size = attachment.bounds.size
        if size.height > height {
            size = CGSize(width: size.width * (height / size.height), height: height)
            if size.width < imageMinWidth, let imageView = attachment.customView as? UIImageView {
                size.width = imageMinWidth
                imageView.contentMode = .scaleAspectFill
            }
            attachment.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
    }
}
