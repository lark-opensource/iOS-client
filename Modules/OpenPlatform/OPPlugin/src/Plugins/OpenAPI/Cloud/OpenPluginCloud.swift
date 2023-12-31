//
//  OpenPluginCloud.swift
//  OPPlugin
//
//  Created by yi on 2021/4/12.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import LarkContainer

enum OpenLightServiceResponseCode: Int {
    case success = 0
    case unknownError = 1000
    case invalidParameter = 1001
    case requestFail = 1002
    case resourceNotFound = 1003
}

final class OpenPluginCloud: OpenBasePlugin {

    func callLightService(params: OpenAPICallLightServiceParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenCallLightServiceResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        context.apiTrace.info("cloud run invoke app=\(uniqueID.fullString)")

        EMARequestUtil.requestLightServiceInvoke(byAppID: uniqueID.appID, context: params.context) { [weak context] (result, error) in
            guard let result = result, error == nil else {
                // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
                let errMsg = "empty callback params, \(error?.localizedDescription)"
                context?.apiTrace.error("cloud run requestLightServiceInvoke app=\(uniqueID.fullString) error \(errMsg)")
                return
            }

            guard let responseCodeValue = result["code"] as? Int, let responseCode = OpenLightServiceResponseCode(rawValue: responseCodeValue) else {
                // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
                context?.apiTrace.error("cloud run requestLightServiceInvoke app=\(uniqueID.fullString) error responseCode is nil")

                return
            }

            switch responseCode {
            case .success:
                var isValidResult = false
                var dataResult: [AnyHashable: Any]?
                let dataSource = result["data"] as? [AnyHashable: Any]
                let dataJson = dataSource?["data"] as? String
                if let isEmpty = dataJson?.isEmpty, !isEmpty {
                    do {
                        dataResult = try dataJson?.convertToJsonObject() as? [AnyHashable : Any]
                        if dataResult != nil {
                            isValidResult = true
                        }
                    } catch {
                        let err = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("json convert fail").setOuterMessage("unknown error")
                        callback(.failure(error: err))
                        context?.apiTrace.error("cloud run requestLightServiceInvoke app=\(uniqueID.fullString) error convertToJsonObject fail")
                    }
                }
                if isValidResult {
                    callback(.success(data: OpenCallLightServiceResult(data: dataResult ?? [AnyHashable: Any]())))
                } else {
                    context?.apiTrace.error("cloud run error app=\(uniqueID.fullString) json data invalid")
                    // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage("json data invalid")
                    callback(.failure(error: err))
                }
            case .unknownError:
                context?.apiTrace.error("cloud run error app=\(uniqueID.fullString) errorCode:\(responseCode)")
                // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("unknown error, errorCode\(responseCode.rawValue)")
                callback(.failure(error: err))
            case .invalidParameter:
                context?.apiTrace.error("cloud run error app=\(uniqueID.fullString) errorCode:\(responseCode)")
                let err = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setMonitorMessage("invalid parameter, errorCode\(responseCode.rawValue)")
                callback(.failure(error: err))
            case .requestFail:
                context?.apiTrace.error("cloud run error app=\(uniqueID.fullString) errorCode:\(responseCode)")
                let err = OpenAPIError(code: CallLightServiceErrorCode.cloudServiceRequestFail)
                    .setMonitorMessage("cloud service request fail, errorCode\(responseCode.rawValue)")
                callback(.failure(error: err))
            case .resourceNotFound:
                context?.apiTrace.error("cloud run error app=\(uniqueID.fullString) errorCode:\(responseCode)")
                let err = OpenAPIError(code: CallLightServiceErrorCode.resourceNotFound)
                    .setMonitorMessage("resource not found, errorCode\(responseCode.rawValue)")
                callback(.failure(error: err))
            default:
                context?.apiTrace.error("cloud run error app=\(uniqueID.fullString) errorCode:\(responseCode)")
                // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。 
                callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
            }
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "callLightService", pluginType: Self.self, paramsType: OpenAPICallLightServiceParams.self, resultType: OpenCallLightServiceResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.callLightService(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
