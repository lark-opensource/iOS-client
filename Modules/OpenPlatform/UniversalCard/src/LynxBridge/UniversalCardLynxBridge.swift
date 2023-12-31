//
//  UniversalCardLynxBridge.swift
//  UniversalCard
//
//  Created by ByteDance on 2023/8/8.
//



import Foundation
import LarkLynxKit
import Lynx
import LarkOpenPluginManager
import ECOProbe
import LarkOpenAPIModel
import UniversalCardBase
import UniversalCardInterface

public final class UniversalCardLynxBridge: LarkLynxBridgeMethodProtocol {
    private var pluginManager: OpenPluginManager

    public init() {
        self.pluginManager = OpenPluginManager(
            bizDomain: .openPlatform,
            bizType: .universalCard, bizScene: ""
        )
    }

    public func invoke(
        apiName: String!,
        params: [AnyHashable : Any]!,
        lynxContext: LynxContext?,
        bizContext: LynxContainerContext?,
        callback: LynxCallbackBlock?
    ) {
        var apiRename = apiName ?? ""
        if !apiName.hasPrefix("universalCard") {
            apiRename = apiName.replacingOccurrences(of: "MsgCard", with: "")
                .replacingOccurrences(of: "msgCard", with: "")
                .replacingOccurrences(of: "card", with: "")
                .replacingOccurrences(of: "Card", with: "")

            apiRename.replaceSubrange(
                apiRename.startIndex...apiRename.startIndex,
                with: apiRename.prefix(1).capitalized
            )
            apiRename = "UniversalCard" + apiRename
        }

        let responseWrapper: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void = { (response) in
            switch response {
            case let .failure(error: error):
                let data = try? error.errnoInfo.convertToJsonStr()
                callback?(data ?? "")
            case let .success(data: data):
                let res = try? data?.toJSONDict().convertToJsonStr()
                callback?(res ?? "")
            case .continue(event: _, data: let data):
                let res = try? data?.toJSONDict().convertToJsonStr()
                callback?(res ?? "")
            }
        }

        guard let cardContext = (bizContext?.bizExtra?[UniversalCard.Tag] as? UniversalCardLynxBridgeContextWrapper)?.cardContext,
              let lynxContext = lynxContext else {
            assertionFailure("lynxContext or cardContext is nil")
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("lynxContext or cardContext is nil")
            responseWrapper(OpenAPIBaseResponse.failure(error: error))
            return
        }

        let context = UniversalCardAPIContext(
            dispatcher: pluginManager,
            lynxContext: lynxContext,
            cardContext: cardContext
        )

        if (isSyncAPI(apiName: apiRename)) {
            let response = pluginManager.syncCall(
                apiName: apiRename,
                params: params,
                canUseInternalAPI: false,
                context: context
            )
            responseWrapper(response)
        } else {
            pluginManager.asyncCall(
                apiName: apiRename,
                params: params,
                canUseInternalAPI: false,
                context: context,
                callback: responseWrapper
            )
        }
    }

    private func isSyncAPI(apiName: String) -> Bool {
        self.pluginManager.defaultPluginConfig[apiName]?.isSync == true
    }

}
