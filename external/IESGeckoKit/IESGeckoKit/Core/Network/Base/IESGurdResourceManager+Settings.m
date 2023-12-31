//
//  IESGurdResourceManager+Settings.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by liuhaitian on 2021/4/22.
//

#import "IESGurdResourceManager+Settings.h"

#import <objc/runtime.h>
#import "IESGeckoAPI.h"
#import "IESGeckoDefines.h"
#import "IESGurdSettingsCacheManager.h"
#import "IESGurdAppLogger.h"

static const int kGurdSettingsRetryMaxTotalDuration = 5115; // 5115秒（85.25分钟）

@interface IESGurdResourceManager ()

@property (class, nonatomic, assign) NSInteger retryCount;

@property (class, nonatomic, assign) NSInteger retryTotalDuration;

@end

@implementation IESGurdResourceManager (Settings)

+ (void)fetchSettingsWithRequest:(IESGurdSettingsRequest *)request
                      completion:(IESGurdSettingsCompletion)completion
{
    [self POSTWithURLString:[IESGurdAPI settings] params:[request paramsForRequest] completion:^(IESGurdNetworkResponse * _Nonnull response) {
        id responseObject = response.responseObject;
        response.logInfo = request.logInfo;
        BOOL isServerAvailable = (responseObject && response.statusCode == 200);
        [IESGurdAppLogger recordQuerySettingsWithResponse:response];
        
        if (!isServerAvailable) {
            // 退避重试机制 https://bytedance.feishu.cn/docs/doccnTrmP2SSGQtLMiL0JSdCPSd
            self.retryCount++;
            
            srand48(time(0));
            double r = drand48();
            int delayInSeconds = (int)((r + 0.5) * pow(2, MIN(self.retryCount - 2, 8)) * 5);
            self.retryTotalDuration += delayInSeconds;
            
            if (self.retryTotalDuration <= kGurdSettingsRetryMaxTotalDuration) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
                    request.requestType = IESGurdSettingsRequestTypeRetry;
                    [self fetchSettingsWithRequest:request completion:completion];
                });
                !completion ? : completion(IESGurdSettingsStatusUnavailable, nil, nil);
            } else {
                !completion ? : completion(IESGurdSettingsStatusNoUpdate, nil, nil);
            }
            return;
        }
        
        self.retryCount = 0;
        self.retryTotalDuration = 0;
        
        // handle response
        NSDictionary *responseDictionary = nil;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            responseDictionary = responseObject;
        } else if ([responseObject isKindOfClass:[NSData class]]) {
            responseDictionary = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject
                                                                 options:0
                                                                   error:NULL];
        }
        
        if (![responseDictionary isKindOfClass:[NSDictionary class]]) {
            !completion ? : completion(IESGurdSettingsStatusNoUpdate, nil, nil);
            return;
        }
        
        IESGurdSettingsResponseExtra *extra = [IESGurdSettingsResponseExtra extraWithDictionary:responseDictionary[@"extra"]];
        
        NSInteger statusCode = [responseDictionary[@"status"] integerValue];
        // 命中黑名单
        if (statusCode == IESGurdStatusCodeSettingsRequestInBlocklist) {
            [[IESGurdSettingsCacheManager sharedManager] cleanCache];
            !completion ? : completion(IESGurdSettingsStatusUnavailable, nil, extra);
            return;
        }
        
        // 0和本地版本错误以外的状态码
        if (statusCode != 0 && statusCode != IESGurdStatusCodeSettingsVersionNotExists) {
            !completion ? : completion(IESGurdSettingsStatusNoUpdate, nil, extra);
            return;
        }
        
        NSDictionary *dataDictionary = responseDictionary[@"data"];
        IESGurdSettingsResponse *settingsResponse = [IESGurdSettingsResponse responseWithDictionary:dataDictionary];
        // 解析失败
        if (!settingsResponse) {
            !completion ? : completion(IESGurdSettingsStatusNoUpdate, nil, extra);
            return;
        }
        
        [[IESGurdSettingsCacheManager sharedManager] saveResponseDictionary:dataDictionary];
        !completion ? : completion(IESGurdSettingsStatusDidUpdate, settingsResponse, extra);
    }];
}

+ (NSInteger)retryCount
{
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

+ (void)setRetryCount:(NSInteger)retryCount
{
    objc_setAssociatedObject(self, @selector(retryCount), @(retryCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSInteger)retryTotalDuration
{
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

+ (void)setRetryTotalDuration:(NSInteger)retryTotalDuration
{
    objc_setAssociatedObject(self, @selector(retryTotalDuration), @(retryTotalDuration), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
