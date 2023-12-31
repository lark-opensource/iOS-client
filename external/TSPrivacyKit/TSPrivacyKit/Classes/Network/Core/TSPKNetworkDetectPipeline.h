//
//  TSPKNetworkDetectPipeline.h
//  BDAlogProtocol
//
//  Created by admin on 2022/8/23.
//

#import <Foundation/Foundation.h>

@class TSPKHandleResult;
@protocol TSPKCommonRequestProtocol;
@protocol TSPKCommonResponseProtocol;

@interface TSPKNetworkDetectPipeline : NSObject

+ (void)preload;

+ (void)reportWithBacktrace:(NSString *_Nullable)source url:(NSURL *_Nullable)url;

+ (TSPKHandleResult *_Nullable)onRequest:(id<TSPKCommonRequestProtocol> _Nullable)request;

+ (TSPKHandleResult *_Nullable)onResponse:(id<TSPKCommonResponseProtocol> _Nullable)response request:(id<TSPKCommonRequestProtocol> _Nullable)request data:(id _Nullable)data;

@end
