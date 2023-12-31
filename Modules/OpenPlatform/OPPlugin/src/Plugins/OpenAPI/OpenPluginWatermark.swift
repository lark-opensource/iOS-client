//
//  OpenPluginWatermark.swift
//  OPPlugin
//
//  Created by yi on 2021/3/23.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import OPPluginBiz
import OPFoundation
import LarkContainer

final class OpenPluginWatermark: OpenBasePlugin {

    func checkWatermark(context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPICheckWatermarkResult>) -> Void) {
        let hasWatermark = EMAProtocolProvider.getEMADelegate()?.checkWatermark() ?? false
        context.apiTrace.info("call lark api, check watermark result is \(hasWatermark)")
        callback(.success(data: OpenAPICheckWatermarkResult(hasWatermark: hasWatermark)))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "checkWatermark", pluginType: Self.self, resultType: OpenAPICheckWatermarkResult.self) { (this, _, context, callback) in
            
            this.checkWatermark(context: context, callback: callback)
        }
    }
}
