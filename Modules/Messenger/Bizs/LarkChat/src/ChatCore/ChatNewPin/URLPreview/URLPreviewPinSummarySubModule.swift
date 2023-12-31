//
//  URLPreviewPinSummarySubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/31.
//

import Foundation
import RustPB
import TangramService
import LarkOpenChat
import LarkModel
import RxSwift
import RxCocoa

public final class URLPreviewPinSummarySubModule: ChatPinSummarySubModule {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .urlPin
    }

    public override func canHandle(model: ChatPinSummaryMetaModel) -> Bool {
        return true
    }

    public override class func canInitialize(context: ChatPinSummaryContext) -> Bool {
        return true
    }

    public override class func parse(pindId: Int64, pb: UniversalChatPinPBModel, extras: UniversalChatPinsExtras, context: ChatPinSummaryContext) -> ChatPinPayload? {
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
            payload.inlineEntity = InlinePreviewEntity.transform(from: entityPB)
        }
        return payload
    }

    private let disposeBag = DisposeBag()

    public override func setup() {
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
