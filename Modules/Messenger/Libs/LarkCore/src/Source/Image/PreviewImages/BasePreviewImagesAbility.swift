//
//  BasePreviewImagesAbility.swift
//  LarkCore
//
//  Created by 李勇 on 2020/4/17.
//

import UIKit
import Foundation
import Swinject
import LarkMessengerInterface
import RxSwift
import LarkUIKit
import EENavigator
import LarkSDKInterface
import LarkModel
import LKCommonsLogging
import LarkAssetsBrowser
import LarkImageEditor
import LarkRichTextCore
import LarkContainer

class BasePreviewImagesAbility: UserResolverWrapper {
    let userResolver: UserResolver
    private static let logger = Logger.log(BasePreviewImagesAbility.self, category: "BasePreviewImagesAbility")
    let scene: PreviewImagesScene

    let disposeBag: DisposeBag = DisposeBag()
    var assetPositionMap: [String: (Int32, String)] = [:]

    init(scene: PreviewImagesScene, resolver: UserResolver) {
        self.scene = scene
        self.userResolver = resolver
    }

    func shareImage(by assetKey: String, image: UIImage, from: NavigatorFrom) {
        // 发送图片消息
        func shareImageBySend() {
            userResolver.navigator.present(
                // 收藏分享放开外部限制,下面的forward方法也没做限制
                body: ShareImageBody(image: image, type: .forward, needFilterExternal: false),
                from: from,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
            )
        }
        // 转发图片消息
        func shareImageByForward(message: Message) {
            userResolver.navigator.present(
                body: ForwardMessageBody(originMergeForwardId: nil, message: message, type: .message(message.id), from: .preview, context: [ForwardMessageBody.forwardImageThumbnailKey: image]),
                from: from,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
            )
        }
        // 图片消息走转发，非图片消息走发送
        if let messageId = self.assetPositionMap[assetKey]?.1, !messageId.isEmpty {
            // 用messageId获取message
            try? self.resolver.resolve(assert: MessageAPI.self).fetchLocalMessage(id: messageId)
                .observeOn(MainScheduler.instance).subscribe(onNext: { (message) in
                    if message.type == .image || message.type == .sticker {
                        shareImageByForward(message: message)
                        BasePreviewImagesAbility.logger.info("share image by forward，\(messageId) is a image message")
                    } else {
                        shareImageBySend()
                        BasePreviewImagesAbility.logger.info("share image by send，\(messageId) is not a image message")
                    }
                }, onError: { _ in
                    shareImageBySend()
                    BasePreviewImagesAbility.logger.info("share image by send，\(messageId) fetch error")
                }).disposed(by: self.disposeBag)
        } else {
            shareImageBySend()
            BasePreviewImagesAbility.logger.info("share image by send，no message id")
        }
    }
}
