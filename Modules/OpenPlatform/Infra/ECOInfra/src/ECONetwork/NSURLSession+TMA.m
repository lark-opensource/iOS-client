//
//  NSURLSession+TMA.m
//  Timor
//
//  Created by houjihu on 2018/10/8.
//

#import "NSURLSession+TMA.h"
#import <ECOInfra/NSURLSessionTask+Tracing.h>
#import <ECOInfra/BDPLogHelper.h>
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/ECONetworkGlobalConst.h>
#import <ECOInfra/OPTrace+RequestID.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOProbe/OPTraceService.h>

@implementation NSURLSession (TMA)

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                    eventName:(NSString * _Nullable)eventName
                               requestTracing:(OPTrace * _Nullable)tracing {
    tracing = [self safeTrace:tracing];
    request = [self addReqeustTraceHeader:request trace:tracing];
    NSString *url = request.URL.absoluteString;
    [BDPLogHelper logRequestBeginWithEventName:eventName URLString:url withTrace:tracing.traceId];
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request];
    [task bindTrace:tracing];
    return task;
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url
                        completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                eventName:(NSString * _Nullable)eventName
                           requestTracing:(OPTrace * _Nullable)tracing {
    tracing = [self safeTrace:tracing];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    request = [self addReqeustTraceHeader:request trace:tracing];
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:completionHandler eventName:eventName requestTracing:tracing];
    return task;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                    eventName:(NSString * _Nullable)eventName
                               requestTracing:(OPTrace * _Nullable)tracing {
    tracing = [self safeTrace:tracing];
    request = [self addReqeustTraceHeader:request trace:tracing];
    NSString *url = request.URL.absoluteString;
    [BDPLogHelper logRequestBeginWithEventName:eventName URLString:url withTrace:tracing.traceId];
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(data, response, error);
        }
        [BDPLogHelper logRequestEndWithEventName:eventName URLString:url URLResponse:response];
    }];
    [task bindTrace:tracing];
    return task;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                            eventName:(NSString * _Nullable)eventName
                                       requestTracing:(OPTrace * _Nullable)tracing {
    tracing = [self safeTrace:tracing];
    request = [self addReqeustTraceHeader:request trace:tracing];
    NSString *url = request.URL.absoluteString;
    [BDPLogHelper logRequestBeginWithEventName:eventName URLString:url withTrace:tracing.traceId];
    NSURLSessionDownloadTask *task = [self downloadTaskWithRequest:request];
    [task bindTrace:tracing];
    return task;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                    completionHandler:(void (^)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                            eventName:(NSString * _Nullable)eventName
                                       requestTracing:(OPTrace * _Nullable)tracing {
    tracing = [self safeTrace:tracing];
    request = [self addReqeustTraceHeader:request trace:tracing];
    NSString *url = request.URL.absoluteString;
    [BDPLogHelper logRequestBeginWithEventName:eventName URLString:url withTrace:tracing.traceId];
    NSURLSessionDownloadTask *task = [self downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(location, response, error);
        }
        [BDPLogHelper logRequestEndWithEventName:eventName URLString:url URLResponse:response];
    }];
    [task bindTrace:tracing];
    return task;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                    completionHandler:(void (^)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                            eventName:(NSString * _Nullable)eventName
                                          preloadPath:(NSString *)preloadPath
                                       requestTracing:(OPTrace * _Nullable)tracing {
    tracing = [self safeTrace:tracing];
    if (preloadPath && [NSFileManager.defaultManager fileExistsAtPath:preloadPath]) {
        if (completionHandler) {
            completionHandler([NSURL fileURLWithPath:preloadPath], nil, nil);
        }
        // lint:disable:next lark_storage_check
        [NSFileManager.defaultManager removeItemAtPath:preloadPath error:nil];
        return nil;
    }
    NSURLSessionDownloadTask *task = [self downloadTaskWithRequest:request completionHandler:completionHandler eventName:eventName requestTracing:tracing];
    return task;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(nullable NSData *)bodyData
                                completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                        eventName:(NSString * _Nullable)eventName
                                   requestTracing:(OPTrace * _Nullable)tracing {
    tracing = [self safeTrace:tracing];
    request = [self addReqeustTraceHeader:request trace:tracing];
    NSString *url = request.URL.absoluteString;
    [BDPLogHelper logRequestBeginWithEventName:eventName URLString:url withTrace:tracing.traceId];
    NSURLSessionUploadTask *task = [self uploadTaskWithRequest:request fromData:bodyData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(data, response, error);
        }
        [BDPLogHelper logRequestEndWithEventName:eventName URLString:url URLResponse:response];
    }];
    [task bindTrace:tracing];
    return task;
}

- (OPTrace *)safeTrace:(OPTrace *)trace {
    if (!trace) {
        trace = [[OPTraceService defaultService] generateTrace];
        BDPLogInfo(@"request trace is nil, generate new, traceId=%@",  trace.traceId);
    }
    return trace;
}

- (NSURLRequest *)addReqeustTraceHeader:(NSURLRequest *)request trace:(OPTrace * _Nullable)trace {
    if (!BDPIsEmptyString(request.allHTTPHeaderFields[OP_REQUEST_TRACE_HEADER])) {
        BDPLogInfo(@"trace is exist, trace=%@, needLinkTrace=%@", request.allHTTPHeaderFields[OP_REQUEST_TRACE_HEADER], trace.traceId);
        return request;
    }
    if (!trace) {
        trace = [self safeTrace:trace];
    }
    if (BDPIsEmptyString([trace getRequestID])) {
        [trace genRequestID:OP_REQUEST_ENGINE_SOURCE];
    }
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    NSMutableDictionary *header = [modifyRequest.allHTTPHeaderFields mutableCopy];
    header[OP_REQUEST_TRACE_HEADER] = trace.traceId;
    if (BDPIsEmptyString(header[OP_REQUEST_ID_HEADER])) {
        header[OP_REQUEST_ID_HEADER] = [trace getRequestID];
    }
    if (BDPIsEmptyString(header[OP_REQUEST_LOGID_HEADER])) {
        header[OP_REQUEST_LOGID_HEADER] = [trace getRequestID];
    }
    modifyRequest.allHTTPHeaderFields = header;
    return [modifyRequest copy];
}
@end
