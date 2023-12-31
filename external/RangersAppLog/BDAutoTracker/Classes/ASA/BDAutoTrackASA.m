//
//  BDAutoTrackASA.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/6/22.
//

#import "BDAutoTrackASA.h"
#import <iAd/iAd.h>

#ifdef __IPHONE_14_3
#import <AdServices/AdServices.h>
#endif

NSCharacterSet *bd_asa_customQueryAllowedCharacters(void);

#pragma mark - ASA
static NSString *const kBDAutoTrackASAAdsToken = @"custom_asa_ads_token";
static NSString *const kBDAutoTrackASAiAdAttribution = @"custom_asa_iad_attribution";

/*
 在iOS14.3之前，Apple Search Ads通过iAd framework来进行归因监测；
 从iOS14.3之后，Apple Search Ads通过新的Ad Services framework来进行归因监测，并且在之后会弃用原来的iAd framework。
 目前appsflyer、adjust、branch、singular现状都是两者都支持，新的Ad Service framework发布时间为2021年4月，苹果没有具体说明iAd framework的具体下线日期。

 Applog SDK同时支持iAd和Ad Services两种方式。
 https://bytedance.feishu.cn/docs/doccngi62mIxDGoybtILDSglYic#
 
 为什么要在device_resgiter接口上报参数，而不是设备激活接口：
 - 私有化场景下，由device_register一个接口完成设备注册和激活上报，所以SDK需要在设备注册之前请求iAd/AdServices获取归因结果/token，作为参数传递给设备服务的device_register接口。
 */

@interface BDAutoTrackASA ()

@property (nonatomic) NSString *AdServicesAttrToken;
@property (nonatomic) NSString *AdServicesAttrToken_QueryPercented;
@property (nonatomic) NSDictionary *iAdAttrDetails;

@end

@implementation BDAutoTrackASA

- (instancetype)init {
    self = [super init];
    if (self) {
        if (@available(iOS 14.3, *)) {
            _useAdServicesAPI = NSClassFromString(@"AAAttribution") != nil;
        }
    }
    return self;
}

+ (BDAutoTrackASA *)sharedInstance {
    static BDAutoTrackASA *_;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ = [[BDAutoTrackASA alloc] init];
    });
    return _;
}

+ (void)start {
    [[self sharedInstance] start];
}

- (void)start {
    if (_useAdServicesAPI) {
        _AdServicesAttrToken = [self _AdServicesAttributionToken];
    } else {
        _iAdAttrDetails = [self _iAdAttributionDetails];
    }
}

#pragma mark - public
+ (NSDictionary *)ASAParams {
    NSMutableDictionary *header = [[NSMutableDictionary alloc] init];
    BDAutoTrackASA *asa = [BDAutoTrackASA sharedInstance];
    if (asa.useAdServicesAPI) {
        NSString *token = asa.AdServicesAttrToken;
        NSString *token_QueryPercented = [token stringByAddingPercentEncodingWithAllowedCharacters:bd_asa_customQueryAllowedCharacters()];
        [header setValue:token_QueryPercented forKey:kBDAutoTrackASAAdsToken];
    } else {
        NSString *iAdAttrDetails_JSON = [[BDAutoTrackASA sharedInstance] iAdAttrDetails_JSON];
        NSString *iAdAttrDetails_JSON_QueryPercented = [iAdAttrDetails_JSON stringByAddingPercentEncodingWithAllowedCharacters:bd_asa_customQueryAllowedCharacters()];
        [header setValue:iAdAttrDetails_JSON_QueryPercented forKey:kBDAutoTrackASAiAdAttribution];
    }
    
    return [header copy];
}

- (NSString *)iAdAttrDetails_JSON {
    NSString *iAdAttrDetailsJSON;
    NSError *err;
    NSDictionary *iAdAttrDetails = self.iAdAttrDetails;
    NSData *data = iAdAttrDetails ? [NSJSONSerialization dataWithJSONObject:iAdAttrDetails options:0 error:&err] : nil;
    if (!err && data) {
        iAdAttrDetailsJSON = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return iAdAttrDetailsJSON;
}

#pragma mark - private

/// Old API. Since iOS 4.0+
- (NSDictionary *)_iAdAttributionDetails {
    if (NSClassFromString(@"RALFlagDisableiAd")) {
        return nil;
    }
    
    __block NSDictionary *b_attriData;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    // time it
    CFTimeInterval _ = CACurrentMediaTime();
    [[ADClient sharedClient] requestAttributionDetailsWithBlock:^(NSDictionary *attributionDetails, NSError *error) {
        b_attriData = attributionDetails;
        dispatch_semaphore_signal(semaphore);
#ifdef DEBUG
        NSLog(@"RangersAppLog - BDAutoTrackASA: return");
#endif
    }];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    CFTimeInterval costTime = CACurrentMediaTime() - _;
#ifdef DEBUG
    NSLog(@"RangersAppLog - BDAutoTrackASA: get iAdAttributionDetails cost time: %.3f", costTime);
#endif
    return b_attriData;
}

/// New API. since iOS 14.3.
- (NSString *)_AdServicesAttributionToken {
    NSString *attributionToken;
#ifdef __IPHONE_14_3
    if (@available(iOS 14.3, *)) {
        NSError *error;
        Class AAAttributionClass = NSClassFromString(@"AAAttribution");
        if (AAAttributionClass) {
            // time it
            CFTimeInterval _ = CACurrentMediaTime();
            attributionToken = [AAAttributionClass attributionTokenWithError:&error];
            CFTimeInterval costTime = CACurrentMediaTime() - _;
    #ifdef DEBUG
            NSLog(@"RangersAppLog - BDAutoTrackASA: get AdServicesAttributionToken cost time: %.3f", costTime);
    #endif
        }
    }
#endif
    
    return attributionToken;
}

@end

NSCharacterSet *bd_asa_customQueryAllowedCharacters(void) {
    static NSCharacterSet *turing_set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *set = [NSMutableCharacterSet new];
        [set formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        // [set addCharactersInString:@"$-_.+!*'(),"];
        // Why '+' should be percent-encoded? see https://stackoverflow.com/questions/6855624/plus-sign-in-query-string
        [set addCharactersInString:@"-_."];
        turing_set = set;
    });
    
    return turing_set;
}
