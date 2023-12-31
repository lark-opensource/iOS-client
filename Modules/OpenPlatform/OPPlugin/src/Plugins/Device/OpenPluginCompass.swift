//
//  OPAPIHandlerCompass.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/2.
//

import Foundation
import CoreLocation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkOPInterface
import ECOProbe
import LKCommonsLogging
import LarkContainer

class OpenPluginCompass: OpenBasePlugin, CLLocationManagerDelegate {
    static let logger = Logger.log(OpenPluginCompass.self, category: "OpenAPI")

    var manager: CLLocationManager?

    var currentContext: OpenAPIContext?

    deinit {
        manager?.delegate = nil
        currentContext = nil
    }
    
    public func startCompass(params: OpenAPIBaseParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        currentContext = context
        if manager == nil {
            manager = CLLocationManager()
            manager?.delegate = self
        }
        manager?.startUpdatingHeading()
        context.apiTrace.info("start listen compass")
        callback(.success(data: nil))
    }

    public func stopCompass(params: OpenAPIBaseParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        manager?.stopUpdatingHeading()
        context.apiTrace.info("stop listen compass")
        currentContext = nil
        callback(.success(data: nil))
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard let compassContext = currentContext else {
            Self.logger.error("context is nil, can not fire event")
            return
        }

        // 判断朝向是否有效
        if newHeading.headingAccuracy < 0 {
            compassContext.apiTrace.error("heading accuracy is invalid \(newHeading.headingAccuracy)")
            return
        }
        // TODO: FireEvent直接接入continue
        do {
            let fireEvent = try OpenAPIFireEventParams(event: "onCompassChange",
                                                       data: ["direction": newHeading.magneticHeading],
                                                       preCheckType: .shouldInterruption)
            let response = compassContext.syncCall(apiName: "fireEvent", params: fireEvent, context: compassContext)
            switch response {
            case .success(data: _):
                compassContext.apiTrace.info("fire compass event success")
            case let .failure(error: error):
                compassContext.apiTrace.error("fire compass event error \(error)")
            case .continue(event: _, data: _):
                compassContext.apiTrace.info("fire event screenshot continue")
            }
        } catch {
            compassContext.apiTrace.error("generate fire compass event params error \(error)")
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "startCompass", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.startCompass(params: params, context: context, callback: callback)
        }
        registerInstanceAsyncHandler(for: "stopCompass", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.stopCompass(params: params, context: context, callback: callback)
        }
    }

}
