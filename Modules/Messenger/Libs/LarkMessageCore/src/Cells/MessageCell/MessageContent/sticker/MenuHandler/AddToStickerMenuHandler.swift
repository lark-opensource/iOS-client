//
//  AddToStickerMenuHandler.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/9.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import EENavigator
import UniverseDesignToast
import LarkMessageBase
import LarkAlertController
import LarkMessengerInterface
import LarkContainer
import ByteWebImage
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkCore
import LKCommonsLogging
import LarkEmotion

final class AddToStickerMenuHandler {

    private static let logger = Logger.log(AddToStickerMenuHandler.self, category: "LarkMessageCore.AddToStickerMenuHandler")

    private let disposeBag = DisposeBag()

    private weak var targetVC: UIViewController?
    private var stickerService: StickerService?
    private var rustService: SDKRustService?
    private let nav: Navigatable

    init(stickerService: StickerService?, rustService: SDKRustService?, nav: Navigatable, targetVC: UIViewController) {
        self.targetVC = targetVC
        self.stickerService = stickerService
        self.rustService = rustService
        self.nav = nav
    }

    func handle(message: Message, chat: Chat, params: [String: Any]) {
        if let content = message.content as? StickerContent, let targetVC = targetVC {
            //如果是未付费表情包.需要提示
            let sticker = content.transformToSticker()
            if  sticker.mode == .meme, !sticker.hasPaid_p {
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackNeedBuy, font: .systemFont(ofSize: 17))
                alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackKnow)
                self.nav.present(alertController, from: targetVC)
                return
            }

            if let error = stickerService?.checkNewStickerEnable(keys: [content.key]) {
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Legacy_Hint)
                alertController.setContent(text: error)
                alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_AddSticker_UnableToAdd_Ok)
                self.nav.present(alertController, from: targetVC)
                return
            }

            let hud = UDToast.showLoading(on: targetVC.view)
            stickerService?
                .uploadStickers([sticker])
                .subscribe(onNext: { _ in
                    hud.remove()
                    hud.showSuccess(with: BundleI18n.LarkMessageCore.Lark_Legacy_StickerAdded, on: targetVC.view)
                }, onError: { _ in
                    hud.remove()
                }).disposed(by: self.disposeBag)
        } else if let imageContent = message.content as? ImageContent, let targetVC = targetVC {
            let hud = UDToast.showLoading(on: targetVC.view)
            let imageKey: String
            // 服务端要求这里只能传 origin key，不能传 intact key
            let originKey = imageContent.image.origin.key
            if !originKey.isEmpty {
                imageKey = originKey
            } else {
                imageKey = ImageItemSet.transform(imageSet: imageContent.image).generateImageMessageKey(forceOrigin: true)
                Self.logger.error("cannot find originKey when saving image to sticker, " +
                                  "keys: \(imageKey); \(imageContent.image.key), " +
                                  "\(imageContent.image.origin.key), \(imageContent.image.intact.key)")
            }

            var request = Im_V1_CreateCustomizedStickersRequest()
            request.type = .imageKey
            request.imageKeys = [imageKey]

            // Slardar表情监控埋点
            let metric: [String: Any] = [
                "count": 1
            ]
            let category: [String: Any] = [
                "source": "imageKey"
            ]
            let beginTime = CACurrentMediaTime()
            rustService?.sendAsyncRequest(request)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (_: Im_V1_CreateCustomizedStickersResponse) in
                    // 转成ms
                    let time = (CACurrentMediaTime() - beginTime) * 1000
                    // 添加自定义贴图
                    EmotionTracker.trackerSlardar(event: "sticker_add_customized_sticker", time: time, category: category, metric: metric, error: nil)
                    EmotionTracker.trackerTea(event: Const.addCustomizedStickerEvent, time: time, extraParams: [Const.count: 1, Const.source: Const.imageKeySource], error: nil)
                    hud.remove()
                    hud.showSuccess(with: BundleI18n.LarkMessageCore.Lark_Legacy_StickerAdded, on: targetVC.view)
                }, onError: { [weak self] (error) in
                    // 转成ms
                    let time = (CACurrentMediaTime() - beginTime) * 1000
                    // 添加自定义贴图
                    EmotionTracker.trackerSlardar(event: "sticker_add_customized_sticker", time: time, category: category, metric: metric, error: error)
                    EmotionTracker.trackerTea(event: Const.addCustomizedStickerEvent, time: time, extraParams: [Const.count: 1, Const.source: Const.imageKeySource], error: error)
                    hud.remove()
                    guard let rcError = error.metaErrorStack.last as? RCError,
                          case let .businessFailure(buzErrorInfo) = rcError else { return }
                    hud.showFailure(with: buzErrorInfo.displayMessage, on: self?.targetVC?.view ?? UIView())
                })
                .disposed(by: disposeBag)
        }
    }
}

extension AddToStickerMenuHandler {
    enum Const {
        static let addCustomizedStickerEvent: String = "sticker_add_customized_sticker"
        static let source: String = "source"
        static let imageKeySource: String = "imageKey"
        static let count: String = "count"
    }
}

final class SaveImageToSticker {
    private static let logger = Logger.log(SaveImageToSticker.self, category: "LarkMessageCore.SaveImageToSticker")

    private let disposeBag = DisposeBag()

    private weak var targetVC: UIViewController?
    private var rustService: SDKRustService?

    init(rustService: SDKRustService?, targetVC: UIViewController) {
        self.targetVC = targetVC
        self.rustService = rustService
    }

    func handle(message: Message, chat: Chat, params: [String: Any]) {
        guard !chat.enableRestricted(.download) else {
            if let targetVC = targetVC {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_EnabledUnableToAddStickers_Tooltip, on: targetVC.view)
            }
            return
        }
        if message.dlpState == .dlpInProgress || message.dlpState == .dlpBlock {
            guard let targetVC = targetVC else { return }
            UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_DLP_UnableToaddStickersTryLater_Toast, on: targetVC.view)
            return
        }
        if let imageContent = message.content as? ImageContent, let targetVC = targetVC {
            let hud = UDToast.showLoading(on: targetVC.view)
            let imageKey: String
            // 服务端要求这里只能传 origin key，不能传 intact key
            let originKey = imageContent.image.origin.key
            if !originKey.isEmpty {
                imageKey = originKey
            } else {
                imageKey = ImageItemSet.transform(imageSet: imageContent.image).generateImageMessageKey(forceOrigin: true)
                Self.logger.error("cannot find originKey when saving image to sticker, " +
                                  "keys: \(imageKey); \(imageContent.image.key), " +
                                  "\(imageContent.image.origin.key), \(imageContent.image.intact.key)")
            }

            var request = Im_V1_CreateCustomizedStickersRequest()
            request.imageKeys = [imageKey]
            request.type = .imageKeyV1
            var imageData = Im_V1_ImageKeyData()
            imageData.imageKey = imageKey
            imageData.messageID = message.id
            request.imageInfos = [imageData]

            rustService?.sendAsyncRequest(request)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (_: Im_V1_CreateCustomizedStickersResponse) in
                    hud.remove()
                    hud.showSuccess(with: BundleI18n.LarkMessageCore.Lark_Legacy_StickerAdded, on: targetVC.view)
                }, onError: { error in
                    hud.remove()
                    guard let rcError = error.metaErrorStack.last as? RCError,
                          case let .businessFailure(buzErrorInfo) = rcError else { return }
                    hud.showFailure(with: buzErrorInfo.displayMessage, on: self.targetVC?.view ?? UIView())
                })
                .disposed(by: disposeBag)
        }
    }
}
