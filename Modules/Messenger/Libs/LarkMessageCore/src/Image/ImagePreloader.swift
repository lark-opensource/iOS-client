//
//  ImagePreloader.swift
//  LarkMessageCore
//
//  Created by Saafo on 2023/1/3.
//

import ByteWebImage
import Foundation
import LarkContainer
import LarkModel
import LarkRichTextCore
import LarkSDKInterface
import LKCommonsLogging
import RxSwift
import ThreadSafeDataStructure

/// 图片预加载类
///
/// 主要能力：含有较多业务逻辑：缓存 MessageID、从 Message / MessageID 解析 ImageKey，最终调用 ImagePreloadManager 进行预加载
public final class ImagePreloader {

    public static let shared: ImagePreloader = .init()

    public enum Scene: String {
        case feed
        case chat
    }

    var operateQueue = DispatchQueue(label: "image.preload.baseobserver", qos: .utility)
    /// cache messageID
    var unsafeKeyCache = UnsafeLRUStack<String>(maxSize: LarkImageService.shared.imagePreloadConfig.preloadCacheCount) // TODO: 多用户态后切租户清空

    private var disposeBag = DisposeBag()

    private static let logger = Logger.log(ImagePreloader.self)

    /// - Note: Thread safe
    func preload(scene: Scene, sceneID: String, messageID: String, messageAPI: MessageAPI?) {
        operateQueue.async { [weak self] in
            // checkCache
            guard let self, !self.unsafeKeyCache.use(messageID), let messageAPI = messageAPI else {
                Self.logger.trace("already exist messageID \(messageID) in ImagePreloader cache, ignore.")
                return
            }
            self.getLocalMessage(byID: messageID, messageAPI: messageAPI) { [weak self] message in
                guard let self, let message else {
                    Self.logger.warn("cannot find local message \(messageID), cancel preload.")
                    return
                }
                self.unsafePreload(scene: scene.rawValue, sceneID: sceneID, message: message)
            }
        }
    }

    func preload(scene: Scene, sceneID: String, message: Message) {
        operateQueue.async { [weak self] in
            guard let self, !self.unsafeKeyCache.use(message.id) else {
                Self.logger.trace("already exist messageID \(message.id) in ImagePreloader cache, ignore.")
                return
            }
            self.unsafePreload(scene: scene.rawValue, sceneID: sceneID, message: message)
        }
    }

    public func cancelPreload(scene: Scene, sceneID: String) {
        operateQueue.async {
            ImagePreloadManager.shared.cancelPreload(scene: scene.rawValue, sceneID: sceneID)
        }
    }

    // MARK: Private

    private func unsafePreload(scene: String, sceneID: String, message: Message) {
        let imageItems = defaultParser(message)
        Self.logger.trace("parsed imageKeys from message: \(message.id), keys: \(imageItems.map { $0.key })")
        imageItems.forEach { imageItem in
            ImagePreloadManager.shared.preload(scene: scene, sceneID: sceneID, sceneSubID: message.id, imageItem: imageItem)
        }
    }

    // MARK: - Utils
    private func getLocalMessage(byID messageID: String, messageAPI: MessageAPI, completion: @escaping ((Message?) -> Void)) {
        messageAPI.fetchLocalMessage(id: messageID)
            .subscribe(onNext: { message in
                completion(message)
            }).disposed(by: disposeBag)
    }

    private var defaultParser: ((Message) -> [ImageItem]) = { message in
        switch message.type {
        case .image:
            guard let imageContent = message.content as? ImageContent else { return [] }
            return [ImageItemSet.transform(imageSet: imageContent.image).getThumbItem()]
        case .media:
            guard let mediaContent = message.content as? MediaContent else { return [] }
            return [ImageItemSet.transform(imageSet: mediaContent.image).getThumbItem()]
        case .post:
            guard let postContent = message.content as? PostContent else { return [] }
            return postContent.richText.imageIds.compactMap { id in
                guard let property = postContent.richText.elements[id]?.property,
                      property.hasImage,
                      !property.image.originKey.hasPrefix(LarkRichTextCore.Resources.localDocsPrefix) else { return nil }
                return ImageItemSet.transform(imageProperty: property.image).getThumbItem()
            } + postContent.richText.mediaIds.compactMap { id in
                guard let property = postContent.richText.elements[id]?.property,
                      property.hasMedia, property.media.hasImage else { return nil }
                return ImageItemSet.transform(imageSet: property.media.image).getThumbItem()
            }
        @unknown default:
            return []
        }
    }
}
