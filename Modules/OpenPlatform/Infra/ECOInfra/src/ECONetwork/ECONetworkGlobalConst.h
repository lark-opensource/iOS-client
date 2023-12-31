//
//  ECONetworkGlobalConst.h
//  ECOInfra
//
//  Created by bytedance on 2021/4/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OP_REQUEST_TRACE_HEADER;
extern NSString * const OP_REQUEST_ID_HEADER;
extern NSString * const OP_REQUEST_LOGID_HEADER;
extern NSString * const OP_REQUEST_ENGINE_SOURCE;

extern NSString * const kEventName_mp_post_url;
extern NSString * const kEventName_mp_network_rust_trace;

extern NSString * const kEventName_econetwork_request;
extern NSString * const kEventName_econetwork_error;

extern NSString * const kEventName_op_legacy_internal_request_result;

NS_ASSUME_NONNULL_END
