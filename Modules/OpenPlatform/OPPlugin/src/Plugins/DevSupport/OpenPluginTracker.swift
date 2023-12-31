//
//  OpenPluginTracker.swift
//  OPPlugin
//
//  Created by yi on 2021/2/18.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import OPSDK
import ECOInfra
import LarkContainer

let kReportEventStringMAXLength = 85

private let enableFGKey = "ecosystem.fix.gadget.tti_duration"

final class OpenPluginTracker: OpenBasePlugin {
    func reportAnalytics(params: OpenAPIReportAnalyticsParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID

        if !EMAFeatureGating.boolValue(forKey: EMAFeatureGatingKeyMicroAppReportAnalytics) {
            context.apiTrace.error("feature closed")
            let error = OpenAPIError(code: ReportAnalyticsErrorCode.failed).setMonitorMessage("feature \(EMAFeatureGatingKeyMicroAppReportAnalytics) closed")
            callback(.failure(error: error))
            return
        }
        let eventName = params.event
        if eventName.isEmpty {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setOuterMessage("invalid event param")
            callback(.failure(error: error))
            return
        }
        if eventName.count > kReportEventStringMAXLength {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setOuterMessage("event name is too long")
            callback(.failure(error: error))
            return
        }

        let eventData = params.value
        do {
            let eventDataString = try eventData.convertToJsonStr()
            let name = kEventName_mp_report_analytics
            var data = [AnyHashable : Any]()
            data[kEventKey_app_id] = uniqueID.appID
            if let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) {
                if let model = OPUnsafeObject(common.model) {
                    data[kEventKey_app_version] = OPUnsafeObject(model.version) ?? ""
                }
                if let schema = OPUnsafeObject(common.schema) {
                    data[kEventKey_scene] = OPUnsafeObject(schema.scene) ?? ""
                    data[kEventKey_sub_scene] = OPUnsafeObject(schema.subScene) ?? ""
                }
            }
            data["event_name"] = eventName
            data["event_data"] = eventDataString
            
            if eventName == "mp_page_tti", let trace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID) {
                data["from_app_launch_start_duration"] = getTTIDuration(eventDataString:eventDataString, trace:trace, context: context)
            }
                
            BDPTracker.event(name, attributes: data, uniqueID: uniqueID)
            callback(.success(data: nil))
        } catch {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setError(error as NSError)
            callback(.failure(error: error))
        }
    }

    private func getTTIDuration(eventDataString:String, trace: BDPTracing, context:OpenAPIContext) -> Int {
        do{
            if let json = eventDataString.data(using: String.Encoding.utf8){
                if let jsonData = try JSONSerialization.jsonObject(with: json, options: .allowFragments) as? [String:Any]{
                    if let timestamp = jsonData["timestamp"] as? Int64 {
                        return trace.endDuration(kEventName_mp_app_launch_start, timestamp: Int(timestamp))
                    }
                }
            }
        }catch {
            context.apiTrace.error("can't parse mp_page_tti for timestamp")
        }
        return 0
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "reportAnalytics", pluginType: Self.self, paramsType: OpenAPIReportAnalyticsParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            

            this.reportAnalytics(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
