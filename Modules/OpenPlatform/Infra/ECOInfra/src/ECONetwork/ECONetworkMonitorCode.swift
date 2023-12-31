//
//  CommonMonitorCode.swift
//  ECOInfra
//
//  Created by MJXin on 2021/4/22.
//

import Foundation

@objcMembers
public final class ECONetworkMonitorCode: OPMonitorCode {
    static public let domain = "client.open_platform.network"
    
    //MARK: - ECONetwork Monitor
    
    static public let request_will_start = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10000, level: OPMonitorLevelNormal, message: "econetwork_request_will_start")
    static public let request_start = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10001, level: OPMonitorLevelNormal, message: "econetwork_request_start")
    static public let request_end = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10002, level: OPMonitorLevelNormal, message: "econetwork_request_end")
    static public let request_will_response = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10003, level: OPMonitorLevelNormal, message: "econetwork_request_will_response")
    
    //MARK: - ECONetworkClient Error
    
    static public let client_request_cancel = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10000, level: OPMonitorLevelError, message: "client_cancel")
    static public let create_local_file_error = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10001, level: OPMonitorLevelError, message: "create_local_file_error")
    static public let create_local_file_stream_error = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10002, level: OPMonitorLevelError, message: "create_local_file_stream_error")
    static public let mock_client_transfer_error = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10003, level: OPMonitorLevelError, message: "mock_client_transfer_error")
    static public let response_data_receive_error = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10004, level: OPMonitorLevelError, message: "response_data_receive_error")

    //MARK: - ECONetworkService Error
    
    static public let request_cancel = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10000, level: OPMonitorLevelError, message: "request_cancel")
    static public let unknown = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10001, level: OPMonitorLevelError, message: "unknown")
    static public let invalid_host = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10002, level: OPMonitorLevelError, message: "invalid_host")
    static public let invalid_params = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10003, level: OPMonitorLevelError, message: "invalid_params")
    static public let network_client_unregistered = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10004, level: OPMonitorLevelError, message: "network_client_unregistered")
    static public let request_complete_with_wrong_response = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10005, level: OPMonitorLevelError, message: "request_complete_with_wrong_response")
    static public let create_task_with_wrong_params = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10006, level: OPMonitorLevelError, message: "create_task_with_wrong_params")
    static public let miss_require_params = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10007, level: OPMonitorLevelError, message: "miss_require_params")
    static public let invalid_serialized_type = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10008, level: OPMonitorLevelError, message: "invalid_serialized_type")
    static public let invalid_URL = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10009, level: OPMonitorLevelError, message: "invalid_URL")
    static public let upsupport_middleware = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10010, level: OPMonitorLevelError, message: "upsupport_middleware")
    static public let context_type_error = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10011, level: OPMonitorLevelError, message: "context_type_error")
    static public let incompatible_result_type = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10012, level: OPMonitorLevelError, message: "incompatible_result_type")
    static public let request_misse_require_params = ECONetworkMonitorCode(domain: ECONetworkMonitorCode.domain, code: 10013, level: OPMonitorLevelError, message: "request_misse_require_params")
}

