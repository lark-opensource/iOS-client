import Foundation
import LarkOpenAPIModel
import LKCommonsLogging
import SKFoundation

final class FormsCreateTraceIdParams: OpenAPIBaseParams {
    
    @OpenAPIOptionalParam(jsonKey: "parentTrace")
    var parentTrace: String?
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_parentTrace]
    }
}

final class FormsCreateTraceIdResult: OpenAPIBaseResult {
    
    let traceId: String
    
    init(traceId: String) {
        self.traceId = traceId
        super.init()
        
    }
    
    override func toJSONDict() -> [AnyHashable: Any] {
        [
            "traceId": traceId
        ]
    }
}

extension FormsPerformance {
    
    func createTraceId(
        params: FormsCreateTraceIdParams,
        success: @escaping (FormsCreateTraceIdResult) -> Void,
        failure: @escaping (OpenAPIError) -> Void
    ) {
        guard let manager = BTStatisticManager
            .shared else {
            let msg = "new BTStatisticManager error"
            let code = -1
            Self.logger.error(msg)
            let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            failure(e)
            return
        }
        
        let traceID = manager
            .createNormalTrace(
                parentTrace: params
                    .parentTrace
            )
        
        let result = FormsCreateTraceIdResult(
            traceId: traceID
        )
        success(result)
    }
    
}
