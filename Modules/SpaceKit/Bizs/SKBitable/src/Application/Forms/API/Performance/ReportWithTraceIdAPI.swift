import Foundation
import LarkOpenAPIModel
import SKFoundation

final class FormsReportWithTraceIdParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "traceId")
    var traceId: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "eventName")
    var eventName: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "biz")
    var biz: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "list")
    var list: [FormsReportWithTraceIdEvent]
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_traceId, _eventName, _biz, _list]
    }
}

final class FormsReportWithTraceIdEvent: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "time")
    var time: Int
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "event")
    var event: String
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_time, _event]
    }
    
}

extension FormsPerformance {
    
    func reportWithTraceId(
        params: FormsReportWithTraceIdParams
    ) {
        // 创建 consumer
        let consumer = FormsConsumer(
            eventName: params.eventName,
            biz: params.biz
        )
        
        // 绑定 consumer 和 trace
        BTStatisticManager
            .shared?
            .addNormalConsumer(
                traceId: params.traceId,
                consumer: consumer
            )
        
        // 添加点
        params
            .list
            .forEach { event in
                let point = BTStatisticNormalPoint(
                    name: event.event,
                    timestamp: event.time
                )
                BTStatisticManager
                    .shared?
                    .addNormalPoint(
                        traceId: params.traceId,
                        point: point
                    )
            }
        
        // stop
        BTStatisticManager
            .shared?
            .stopTrace(
                traceId: params.traceId
            )
    }
    
}
