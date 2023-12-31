//
//  OpenInputModel.swift
//  OPPlugin
//
//  Created by zhysan on 2021/4/26.
//

import Foundation
import LarkOpenAPIModel
import LarkSetting
import OPPluginBiz

final class OpenAPIRichTextParams: OpenAPIBaseParams {
    // TODOZJX
    @FeatureGatingValue(key: "openplatform.component.customized_input.params_parse_opt.disable")
    public static var disableParamsParseOpt: Bool
    
    public let inputModel: TMAStickerInputModel
    
    public required init(with params: [AnyHashable : Any]) throws {
        if (Self.disableParamsParseOpt) {
            inputModel = try TMAStickerInputModel(dictionary: params)
        } else {
            let request = try OpenPluginCustomizedInputShowRequest(with: params)
            inputModel = request.buildModel()
        }
        try super.init(with: params)
    }
}

extension OpenPluginCustomizedInputShowRequest {
    func buildModel() -> TMAStickerInputModel {
        let model = TMAStickerInputModel()
        model.picture = picture
        if let atModels = at {
            var atResult: [TMAStickerInputAtModel] = []
            for atItem in atModels {
                let atModel = TMAStickerInputAtModel()
                atModel.id = atItem.id
                atModel.name = atItem.name
                atModel.offset = atItem.offset ?? 0
                atModel.length = atItem.length ?? 0
                atResult.append(atModel)
            }
            model.at = atResult
        }
        model.content = content
        model.placeholder = placeholder
        if let userModelSelect = userModelSelect {
            let userSelect = TMAStickerInputUserSelectModel()
            userSelect.items = userModelSelect.items
            userSelect.data = userModelSelect.data
            model.userModelSelect = userSelect
        }
        model.avatar = avatar
        model.showEmoji = showEmoji
        model.eventName = eventName ?? "richTextEvent"
        model.enablesReturnKey = enablesReturnKey
        model.externalContact = externalContact ?? false
        
        return model
    }
}
