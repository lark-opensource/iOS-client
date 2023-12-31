//
//  ECONetworkServiceError.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/24.
//

import Foundation

extension OPError {
    public static func cancel(id: String, step: Int) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.request_cancel, message: "\(id) cancel in step: \(step)")
    }
    public static func unknownError(detail: String) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.unknown, message: detail)
    }
    public static func invalidURL(detail: String) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.invalid_URL, message: detail)
    }
    public static func invalidHost(detail: String?) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.invalid_host, message: detail ?? "")
    }
    public static func invalidParams(detail: String?) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.invalid_params, message: detail ?? "")
    }
    public static func upsupportMiddleware() -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.upsupport_middleware)
    }
    public static func networkClientUnregistered() -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.network_client_unregistered)
    }
    public static func requestCompleteWithUnexpectResponse(detail: String) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.request_complete_with_wrong_response)
    }
    public static func createTaskWithWrongParams(detail: String) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.create_task_with_wrong_params)
    }
    public static func missRequireParams(detail: String?) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.miss_require_params)
    }
    public static func invalidSerializedType(detail: String) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.invalid_serialized_type)
    }
    public static func contextTypeError(detail: String) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.context_type_error)
    }
    public static func incompatibleResultType(detail: String) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.incompatible_result_type, message: detail)
    }
    public static func requestMissRequireParams(detail: String) -> OPError {
        return OPError.error(monitorCode: ECONetworkMonitorCode.request_misse_require_params, message: detail)
    }
}
