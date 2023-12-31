//
// LarkMonitor.h
//  Lark
//
//  Created by lichen on 2018/10/22.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Heimdallr/HMDCrashTracker.h>

@interface LarkMonitor : NSObject
+(void)setupMonitor:(nonnull NSString *)appID
            appName:(nonnull NSString *)appName
            channel:(nonnull NSString *)channel
           deviceID:(nonnull NSString *)deviceID
             userID:(nullable NSString *)userID
           userName:(nullable NSString *)userName
    crashUploadHost:(nullable NSString *)crashUploadHost
exceptionUploadHost:(nullable NSString *)exceptionUploadHost
userExceptionUploadHost:(nullable NSString *)userExceptionUploadHost
performanceUploadHost:(nullable NSString *)performanceUploadHost
     fileUploadHost:(nullable NSString *)fileUploadHost
    configHostArray:(nullable NSArray<NSString *> *)configHostArray;

+(void)updateCrashUploadHost:(nullable NSString *)crashUploadHost
         exceptionUploadHost:(nullable NSString *)exceptionUploadHost
     userExceptionUploadHost:(nullable NSString *)userExceptionUploadHost
       performanceUploadHost:(nullable NSString *)performanceUploadHost
              fileUploadHost:(nullable NSString *)fileUploadHost
             configHostArray:(nullable NSArray<NSString *> *)configHostArray;

+(void)updateUserInfo:(nullable NSString *)userID
             userName:(nullable NSString *)userName
             userEnv:(nullable NSString *)userEnv;

+ (void)startCustomException:(nonnull NSDictionary *)config;
+ (void)stopCustomException;

+ (void)trackService:(nonnull NSString *)serviceName metric:(nullable NSDictionary *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extra;
+ (void)immediatelyTrackService:(nonnull NSString *)serviceName metric:(nullable NSDictionary *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extra;
+ (void)trackService:(nonnull NSString *)serviceName status:(NSInteger)status extra:(nullable NSDictionary *)extra;
+ (void)trackService:(nonnull NSString *)serviceName value:(nonnull id)value extra:(nullable NSDictionary *)extra;
+ (void)trackService:(nonnull NSString *)serviceName attributes:(nullable NSDictionary *)attributes;
+ (void)trackData:(nonnull NSDictionary *)data logTypeStr:(nonnull NSString *)logType;
+ (void)addCrashDetectorCallBack:(_Nullable CrashReportBlock)callBack;

@end
