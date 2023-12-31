//
//  OpenPluginShowCardChartAPI.swift
//  UniversalCardBase
//
//  Created by ByteDance on 2023/9/26.
//

import Foundation
import UniversalCardBase
import UniversalCardInterface
import LarkOpenAPIModel
import EENavigator
import LarkModel
import ECOProbe
import RustPB
import LarkContainer
import LarkUIKit

open class OpenPluginShowCardChartAPI: UniversalCardAPIPlugin {
    
    enum APIName: String {
        case UniversalCardShowChartDetail
    }
    
    private func showCardChartDetail(params: OpenPluginShowCardChartParams, context: UniversalCardAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        guard let sourceData = context.cardContext.sourceData,
              let actionService = context.cardContext.dependency?.actionService else {
            let errorMsg = "showCardChartDetail API: cardContent is nil"
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage(errorMsg)
            callback(.failure(error: error))
            context.apiTrace.error(errorMsg)
            return
        }
        let vc = CardChartDetailController(
            userResolver: userResolver, 
            containerData: sourceData,
            targetElement: UniversalCardConfig.TargetElementConfig(elementID: params.elementID, isTranslateElement: params.isTranslateElement),
            translateConfig: actionService.getTranslateConfig() ?? UniversalCardConfig.TranslateConfig.default
        )
        
        guard let mainWindow = userResolver.navigator.mainSceneWindow else {
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("showCardChartDetail API: mainWindow is nil")
            callback(.failure(error: error))
            assertionFailure()
            return
        }
        userResolver.navigator.present(vc, from: mainWindow, animated: false)
        callback(.success(data: nil))
    }
    
    required public init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerCardAsyncHandler(for: APIName.UniversalCardShowChartDetail.rawValue, pluginType: Self.self, paramsType: OpenPluginShowCardChartParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            context.apiTrace.info("showCardChartDetail API call start")
            this.showCardChartDetail(params: params, context: context, callback: callback)
            context.apiTrace.info("showCardChartDetail API call end")
        }
    }

}
