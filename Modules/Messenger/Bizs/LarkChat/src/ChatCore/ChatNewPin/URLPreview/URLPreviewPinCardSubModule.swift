//
//  URLPreviewPinCardSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/31.
//

import Foundation
import LarkOpenChat
import RustPB
import LarkModel
import DynamicURLComponent
import TangramService
import RxSwift
import RxCocoa

public class URLPreviewBasePinCardSubModule: ChatPinCardSubModule {

    public override func canHandle(model: ChatPinCardMetaModel) -> Bool {
        return true
    }

    public override class func canInitialize(context: ChatPinCardContext) -> Bool {
        return true
    }

    private var metaModel: ChatPinCardMetaModel?
    public override func modelDidChange(model: ChatPinCardMetaModel) {
        self.metaModel = model
    }

    public override func handleAfterParse(pinPayloads: [ChatPinPayload], extras: UniversalChatPinsExtras) {
        (try? context.userResolver.resolve(assert: URLTemplateChatPinService.self))?.update(templates: extras.previewTemplates)
        (try? context.userResolver.resolve(assert: URLPreviewChatPinService.self))?.fetchMissingURLPreviews(models: pinPayloads.compactMap { $0 as? URLPreviewChatPinModel })
    }

    public override func setup() {
        guard let chatId = self.metaModel?.chat.id else { return }
        URLPreviewChatPinCardListService.setup(context: self.context, chatId: chatId)
    }
}

public final class URLPreviewPinCardSubModule: URLPreviewBasePinCardSubModule {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .urlPin
    }

    public override class func parse(pindId: Int64, pb: UniversalChatPinPBModel, extras: UniversalChatPinsExtras, context: ChatPinCardContext) -> ChatPinPayload? {
        guard case .urlPin(let urlPinData) = pb else {
            return nil
        }
        var payload = URLPreviewChatPinPayload(
            icon: urlPinData.icon,
            url: urlPinData.url,
            title: urlPinData.title,
            titleUpdated: urlPinData.titleUpdated,
            iconUpdated: urlPinData.iconUpdated,
            hangPoint: urlPinData.urlPreviewHangPoint
        )
        if let entityPB = extras.previewEntities[payload.hangPoint.previewID] {
            payload.urlPreviewEntity = URLPreviewEntity.transform(from: entityPB)
            payload.inlineEntity = InlinePreviewEntity.transform(from: entityPB)
        }
        return payload
    }

    private let disposeBag = DisposeBag()

    public override func setup() {
        super.setup()

        context.pushCenter.observable(for: URLPreviewScenePush.self)
            .subscribe(onNext: { [weak context] push in
                guard let context = context else { return }
                context.update(doUpdate: { payload in
                    guard var previewPayload = payload as? URLPreviewChatPinPayload else { return nil }
                    let previewID = previewPayload.hangPoint.previewID

                    var needUpdate: Bool = false
                    if let newInlineEntity = push.inlinePreviewEntities[previewID] {
                        if let oldEntity = previewPayload.inlineEntity {
                            if newInlineEntity.version >= oldEntity.version {
                                previewPayload.inlineEntity = newInlineEntity
                                needUpdate = true
                            }
                        } else {
                            previewPayload.inlineEntity = newInlineEntity
                            needUpdate = true
                        }
                    }
                    return needUpdate ? previewPayload : nil
                }, completion: nil)
            }).disposed(by: self.disposeBag)
    }
}
