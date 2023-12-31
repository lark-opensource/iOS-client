//
//  ECONetworkGlobalConst.m
//  ECOInfra
//
//  Created by bytedance on 2021/4/7.
//

#import "ECONetworkGlobalConst.h"

NSString * const OP_REQUEST_TRACE_HEADER = @"x-request-id-op";
NSString * const OP_REQUEST_ID_HEADER = @"x-request-id";
NSString * const OP_REQUEST_LOGID_HEADER = @"x-tt-logid";
NSString * const OP_REQUEST_ENGINE_SOURCE = @"gadget";

NSString * const kEventName_mp_post_url = @"mp_post_url";
NSString * const kEventName_mp_network_rust_trace = @"mp_network_rust_trace";

NSString * const kEventName_econetwork_request = @"op_econetwork_request";
NSString * const kEventName_econetwork_error = @"op_econetwork_error";

NSString * const kEventName_op_legacy_internal_request_result = @"op_legacy_internal_request_result";
