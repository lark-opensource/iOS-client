//
//  RenderRouterCard+UniversalCardData.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/8/23.
//

import Foundation
import RustPB
import ECOProbe
import LarkContainer
import UniversalCardInterface



func universalCardData(
    from entity: Basic_V1_UniversalCardEntity, 
    context: RenderRouterCardContext?,
    preferWidth: CGFloat,
    userResolver: UserResolver?
) -> (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig) {
    let data = UniversalCardData.transform(entity: entity)
    return (
        data: data,
        context: UniversalCardContext(
            key: context?.trace.traceId ?? entity.cardID,
            trace: context?.trace ?? OPTraceService().generateTrace(),
            sourceData: data,
            sourceVC: context?.dependency.targetVC,
            dependency: UniversalCardDependencyImpl(
                userResolver: userResolver,
                actionDependency: context?.dependency,
                bizID: entity.bizID,
                version: entity.version
            ),
            renderBizType: RenderBusinessType.urlPreview.rawValue,
            bizContext: nil,
            actionContext: CardActionContext(messageID: data.cardID, chatID: context?.dependency.getChatID()),
            host: UniversalCardHostType.imMessage.rawValue,
            deliveryType: UniversalCardDeliveryType.urlPreview.rawValue
        ),
        config: UniversalCardConfig(
            width: preferWidth,
            actionEnable: !data.cardContent.attachment.ignoreAtRemind,
            actionDisableMessage: BundleI18n.LarkOpenPlatform.Lark_Legacy_forwardCardToast
        )
    )
}
