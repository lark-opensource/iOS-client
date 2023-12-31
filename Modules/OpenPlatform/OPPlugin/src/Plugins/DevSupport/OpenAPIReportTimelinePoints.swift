//
//  OpenAPIReportTimelinePoints.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/7/5.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkContainer

final class OpenAPIReportTimelinePoints: OpenBasePlugin {

    public func reportTimelinePoints(params: OpenAPIReportTimelinePointsModel, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let cpu_time = Int64(ProcessInfo.processInfo.systemUptime * 1000)
        BDPTracker.sharedInstance().monitorLoadTimeline(withJSONPoints: params.points, uniqueId: gadgetContext.uniqueID)
        BDPTracker.sharedInstance().monitorLoadTimeline(withName: "verify_time", extra: nil, date: Date(), cpuTime: cpu_time, uniqueId: gadgetContext.uniqueID)
        callback(.success(data: nil))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "reportTimelinePoints", pluginType: Self.self, paramsType: OpenAPIReportTimelinePointsModel.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.reportTimelinePoints(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }

}
