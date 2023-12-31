//
//  BDWebSecureLinkManager.m
//  BDWebKit
//
//  Created by bytedance on 2020/4/16.
//

#import "BDWebSecureLinkManager.h"
#import <TTReachability/TTReachability.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <TTReachability/TTReachability.h>

#define NSSTRING_WITH_CONTENT(s) (s && s.length >0)
#define STRING_NOT_EMPTY(s) (s?s:@"")

static NSString* const kBDWebViewSLTag = @"securelink";
static NSString* const kBDWebViewSLCacheDurationKey = @"sl_key_cacheDuration";

@interface BDSecureLinkErrModel : NSObject

@property (nonatomic, strong) NSDate *occurDate;
@property (nonatomic, assign) BDWebSecureLinkErrorType errorType;
@property (nonatomic, assign) NSInteger errorCode;
@property (nonatomic, strong) NSString *errorMsg;

@end

@implementation BDSecureLinkErrModel

@end

@interface BDWebSecureLinkManager ()

/// 缓存的通过了安全校验的url，cache链接为15min
@property (nonatomic, strong) NSMutableDictionary *cacheSecueUrlDic;

/// 缓存黑灰名单
@property (nonatomic, strong) NSMutableDictionary *cacheDangerUrlDic;

/// 缓存灰名单
@property (nonatomic, strong) NSMutableDictionary *cacheGrayUrlDic;

/// 缓存错误列表，每次服务错误的时候会填入，校验的时候从头往后校验时间是否超过半小时，超过半小时的错误会被移除
@property (nonatomic, strong) NSMutableArray *errorList;

/// 异常超过阈值的时间点
@property (nonatomic, strong) NSDate *errorOverwhelmingDate;

/// cache生效的时长
@property (nonatomic, assign) NSInteger cacheDuration;

/// domain
@property (nonatomic, strong) NSString *domain;

@end

@implementation BDWebSecureLinkManager

+ (instancetype)shareInstance {
    static BDWebSecureLinkManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDWebSecureLinkManager alloc] init];
        
        id cacheDurationObj = [[NSUserDefaults standardUserDefaults] objectForKey:kBDWebViewSLCacheDurationKey];
        if (cacheDurationObj) {
            NSInteger cacheDuration = [cacheDurationObj integerValue];
            instance.cacheDuration = cacheDuration;
        } else {
            instance.cacheDuration = 900;
        }
        
        instance.errorList = [[NSMutableArray alloc] init];
        instance.customSetting = [[BDWebSecureLinkCustomSetting alloc] init];
        instance.cacheSecueUrlDic = [[NSMutableDictionary alloc] init];
        instance.cacheGrayUrlDic = [[NSMutableDictionary alloc] init];
        instance.cacheDangerUrlDic = [[NSMutableDictionary alloc] init];
    });
    return instance;
}

- (void)configSecureLinkDomain:(NSString *)domain {
    self.domain = domain;
}

- (void)updateCacheDuration:(NSInteger)cacheDuration {
    if (self.cacheDuration == cacheDuration) {
        return;
    }
    self.cacheDuration = cacheDuration;
    [[NSUserDefaults standardUserDefaults] setInteger:cacheDuration forKey:kBDWebViewSLCacheDurationKey];
}

- (void)cacheSecureLink:(NSString *)secureLink {
    if (!secureLink || secureLink.length <= 0) {
        return;
    }
    [self.cacheSecueUrlDic setValue:[NSDate date] forKey:secureLink];
}

- (BOOL)isLinkInSecureLinkCache:(NSString *)link {
    if (!link || link.length <= 0) {
        return NO;
    }
    
    NSDate *date = [self.cacheSecueUrlDic valueForKey:link];
    if (date) {
        if ([[NSDate date] timeIntervalSinceDate:date] <= self.cacheDuration) {
            return YES;
        } else {
            [self.cacheSecueUrlDic removeObjectForKey:link];
            return NO;
        }
    }
    return NO;
}

- (void)cacheDangerLink:(NSString *)dangerLink {
    if (!dangerLink || dangerLink.length <= 0) {
        return;
    }
    [self.cacheDangerUrlDic setValue:[NSDate date] forKey:dangerLink];
}

- (BOOL)isLinkInDangerLinkCache:(NSString *)link {
    if (!link || link.length <= 0) {
        return NO;
    }
    
    NSDate *date = [self.cacheDangerUrlDic valueForKey:link];
    if (date) {
        if ([[NSDate date] timeIntervalSinceDate:date] <= self.cacheDuration) {
            return YES;
        } else {
            [self.cacheDangerUrlDic removeObjectForKey:link];
            return NO;
        }
    }
    return NO;
}

//- (void)cacheGrayLink:(NSString *)grayLink {
//    if (!grayLink || grayLink.length <= 0) {
//        return;
//    }
//    [self.cacheGrayUrlDic setValue:[NSDate date] forKey:grayLink];
//}
//
//- (BOOL)isLinkInGrayLinkCache:(NSString *)link {
//    if (!link || link.length <= 0) {
//        return NO;
//    }
//
//    NSDate *date = [self.cacheGrayUrlDic valueForKey:link];
//    if (date) {
//        if ([[NSDate date] timeIntervalSinceDate:date] <= self.cacheDuration) {
//            return YES;
//        } else {
//            [self.cacheGrayUrlDic removeObjectForKey:link];
//            return NO;
//        }
//    }
//    return NO;
//}

- (NSString *)wrapToSecureLink:(NSString *)link aid:(int)aid scene:(NSString *)scene lang:(NSString *)lang {
    if (!NSSTRING_WITH_CONTENT(scene) || !NSSTRING_WITH_CONTENT(link)) {
        return link;
    }
    if (!NSSTRING_WITH_CONTENT(lang)) {
        lang = @"zh";
    }
    
    
    NSString *secureLink = [NSString stringWithFormat:@"%@?aid=%d&lang=%@&scene=%@&jumper_version=1&target=%@"
                            ,[self seclinkDomain]
                            ,aid
                            ,lang
                            ,scene
                            ,[link btd_stringByURLEncode]];
    return secureLink;
}

- (NSString *)wrapToQuickMiddlePage:(NSString *)link aid:(int)aid scene:(NSString *)scene lang:(NSString *)lang risk:(int)risk {
    if (!NSSTRING_WITH_CONTENT(scene) || !NSSTRING_WITH_CONTENT(link)) {
        return link;
    }
    if (!NSSTRING_WITH_CONTENT(lang)) {
        lang = @"zh";
    }
    
    
    NSString *secureLink = [NSString stringWithFormat:@"%@middle-page?aid=%d&lang=%@&scene=%@&target=%@&type=%d"
                            ,[self seclinkDomain]
                            ,aid
                            ,lang
                            ,scene
                            ,[link btd_stringByURLEncode]
                            ,risk];
    return secureLink;
}

- (BOOL)isSecureLink:(NSString *)link {
    if (!NSSTRING_WITH_CONTENT(link)) {
        return NO;
    }
    return [link hasPrefix:[self seclinkDomain]];
}

- (BOOL)isLinkPassForSecureLinkServiceErr {
    NSInteger timeLimit = self.customSetting.safeDuraionAfterOverWhelming;
    if (self.errorOverwhelmingDate) {
        if ([[NSDate date] timeIntervalSinceDate:self.errorOverwhelmingDate] <= timeLimit) {
            return YES;
        } else {
            self.errorOverwhelmingDate = nil;
            return NO;
        }
    }
    
    return NO;
}

- (void)onTriggerSecureLinkError:(BDWebSecureLinkErrorType)errorType errorCode:(NSInteger)errorCode errorMsg:(NSString *)errorMsg {
    BDALOG_PROTOCOL_WARN_TAG(kBDWebViewSLTag, @"onTriggerSecureLinkError, errorType:%lu, errorCode:%ld, errorMsg:%@",(unsigned long)errorType,(long)errorCode,STRING_NOT_EMPTY(errorMsg));
    [BDTrackerProtocol eventV3:@"secure_link_exception" params:@{@"error_type":@(errorType),@"error_code":@(errorCode),@"error_info":STRING_NOT_EMPTY(errorMsg)}];
    @synchronized (self) {
        [self handleSecureLinkError:errorType errorCode:errorCode errorMsg:errorMsg];
    }
    
}
- (void)handleSecureLinkError:(BDWebSecureLinkErrorType)errorType errorCode:(NSInteger)errorCode errorMsg:(NSString *)errorMsg {
    if (errorType == BDWebSecureLinkErrorType_ApiResultError) {
        return;
    } else if (errorType == BDWebSecureLinkErrorType_ApiRequestFail && ![TTReachability isNetworkConnected]) {
        return;
    } else {
        BDSecureLinkErrModel *model = [[BDSecureLinkErrModel alloc] init];
        model.occurDate = [NSDate date];
        model.errorType = errorType;
        model.errorCode = errorCode;
        model.errorMsg = errorMsg;
        
        [self.errorList addObject:model];
    }
    
    NSInteger timeLimit = self.customSetting.errorOverwhelmingDuration;
    NSMutableArray *overTimeItemList = [[NSMutableArray alloc] init];
    for (BDSecureLinkErrModel *item in self.errorList) {
        if (!item.occurDate) {
            [overTimeItemList addObject:item];
            continue;
        }
        if ([[NSDate date] timeIntervalSinceDate:item.occurDate] > timeLimit) {
            [overTimeItemList addObject:item];
        }
    }
    [self.errorList removeObjectsInArray:overTimeItemList];
    
    NSInteger errorOverwhelmingCount = self.customSetting.errorOverwhelmingCount;
    if (self.errorList.count >= errorOverwhelmingCount) {
        BDALOG_PROTOCOL_WARN_TAG(kBDWebViewSLTag, @"onTriggerSecureLinkError, overwhilming");
        self.errorOverwhelmingDate = [NSDate date];
        [self.errorList removeAllObjects];
    }
}

/// 安全链接的域名，根据setting的地点不同而不同
- (NSString *)seclinkDomain {
    return STRING_NOT_EMPTY(self.domain);
}

// 安全链接请求的api
- (NSString *)seclinkApi {
    return [NSString stringWithFormat:@"%@api/verify/v1",STRING_NOT_EMPTY(self.domain)];
}

@end
