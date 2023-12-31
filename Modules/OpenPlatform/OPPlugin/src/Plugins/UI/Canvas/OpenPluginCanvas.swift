//
//  OpenPluginCanvas.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/4/12.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkContainer

final class OpenPluginCanvas: OpenBasePlugin {

    // implemention of api handlers
    public func measureText(params: OpenAPIMeasureTextParams, context: OpenAPIContext) -> OpenAPIBaseResponse<OpenAPIMeasureTextResult> {
        let size = BDPParagraphHelper.drawSize(for: params.text, fontNameList: params.fonts, size: params.fontSize)
        let result = OpenAPIMeasureTextResult(width: size.width)
        return .success(data: result)
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)

        // register your api handlers here
        registerInstanceSyncHandler(for: "measureText", pluginType: Self.self, paramsType: OpenAPIMeasureTextParams.self, resultType: OpenAPIMeasureTextResult.self) { (this, params, context) -> OpenAPIBaseResponse<OpenAPIMeasureTextResult> in
            
            return this.measureText(params: params, context: context)
        }
    }

}
