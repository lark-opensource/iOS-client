//
//  SendSingleEmotionProvider.swift
//  LarkForward
//
//  Created by huangjianming on 2019/9/3.
//

import UIKit
import Foundation
import RxSwift
import UniverseDesignToast
import LarkModel
import ByteWebImage
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import LarkAlertController
import EENavigator
import RustPB

struct SendSingleEmotionContent: ForwardAlertContent {
    let sticker: RustPB.Im_V1_Sticker
    let sendMessageAPI: SendMessageAPI
    let message: Message
    var getForwardContentCallback: GetForwardContentCallback {
        let param = MessageForwardParam(type: .message(message.id),
                                        originMergeForwardId: nil)
        let forwardContent = ForwardContentParam.transmitSingleMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }
    init(sticker: RustPB.Im_V1_Sticker, sendMessageAPI: SendMessageAPI, message: Message) {
        self.sticker = sticker
        self.sendMessageAPI = sendMessageAPI
        self.message = message
    }
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class SendSingleEmotionProvider: ForwardAlertProvider {
    // MARK: - override
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? SendSingleEmotionContent != nil {
            return true
        }
        return false
    }

    override var isSupportMention: Bool {
        return true
    }

    override var isSupportMultiSelectMode: Bool {
        return false
    }

    override func isShowInputView(by items: [ForwardItem]) -> Bool {
        return true
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let content = content as? SendSingleEmotionContent else { return nil }

        let container = UIView()
        let imageView = ByteImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.bt.setLarkImage(with: .sticker(key: content.sticker.image.origin.key,
                                                 stickerSetID: content.sticker.stickerSetID),
                                  trackStart: {
                                    TrackInfo(scene: .Chat, isOrigin: true, fromType: .sticker)
                                  })
        container.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.width.equalTo(100)
        }

        return container
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let content = content as? SendSingleEmotionContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        // 这里threadIDAndChatIDs应该为空
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }

        Tracer.trackStickerForward(from: .emotionDetailPage)

        return forwardService.forward(originMergeForwardId: nil,
                                      type: TransmitType.message(content.message.id),
                                      message: content.message,
                                      checkChatIDs: ids.chatIds,
                                      to: items.filter { $0.type == .chat }.map { $0.id },
                                      to: threadIDAndChatIDs,
                                      userIds: ids.userIds,
                                      extraText: input ?? "",
                                      from: .chat)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak window] (_, filePermCheck) in
                hud.remove()
                if let window = window,
                   let filePermCheck = filePermCheck {
                    UDToast.showTips(with: filePermCheck.toast, on: window)
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).map({ (chatIds, _) in return chatIds })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let content = content as? SendSingleEmotionContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        // 这里threadIDAndChatIDs应该为空
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }

        Tracer.trackStickerForward(from: .emotionDetailPage)

        return forwardService.forward(originMergeForwardId: nil,
                                      type: TransmitType.message(content.message.id),
                                      message: content.message,
                                      checkChatIDs: ids.chatIds,
                                      to: items.filter { $0.type == .chat }.map { $0.id },
                                      to: threadIDAndChatIDs,
                                      userIds: ids.userIds,
                                      attributeExtraText: attributeInput ?? NSAttributedString(string: ""),
                                      from: .chat)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak window] (_, filePermCheck) in
                hud.remove()
                if let window = window,
                   let filePermCheck = filePermCheck {
                    UDToast.showTips(with: filePermCheck.toast, on: window)
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).map({ (chatIds, _) in return chatIds })
    }

    // MARK: - 内部方法
}
