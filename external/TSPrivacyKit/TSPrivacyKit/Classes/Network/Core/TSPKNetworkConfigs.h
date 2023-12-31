//
//  TSPKNetworkConfigs.h
//  TSPrivacyKit
//
//  Created by admin on 2022/9/17.
//

#import <Foundation/Foundation.h>

@class TSPKNetworkEvent;

@interface TSPKNetworkAllowConfig : NSObject

@property(nonatomic, strong, nullable) NSArray<NSString *> *endWithDomains; // if param is empty or null, return true
@property(nonatomic, strong, nullable) NSArray<NSString *> *startWithPaths; // if param is empty or null, return true
@property(nonatomic, copy, nullable) NSString *invokeType;

@end

@interface TSPKNetworkConfigs : NSObject

+ (void)setConfigs:(NSDictionary *_Nullable)configs;

+ (BOOL)isEnable;
+ (BOOL)enableReuqestAnalyzeSubscriber;
+ (BOOL)enableNetworkFuseSubscriber;
+ (BOOL)enableNetworkSubscriber;
+ (BOOL)canAnalyzeRequest;
+ (BOOL)enableURLProtocolURLSessionInvalidate;
+ (NSArray *_Nullable)reportBlockList;
+ (BOOL)canReportAllowNetworkEvent:(TSPKNetworkEvent *_Nullable)event;
+ (BOOL)isAllowEvent:(TSPKNetworkEvent *_Nullable)event;
+ (BOOL)canReportJsonBody;

+ (NSArray *_Nullable)uploadBacktraceURL:(NSString *_Nullable)source;
+ (BOOL)canReportNetworkBacktrace;

@end
