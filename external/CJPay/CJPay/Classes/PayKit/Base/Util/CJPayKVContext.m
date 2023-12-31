//
//  CJPayKVContext.m
//  CJPay
//
//  Created by 王新华 on 2020/10/8.
//

#import "CJPayKVContext.h"

NSMutableDictionary *cjpayKVContextDic;

NSString * const CJPayDeskTitleKVKey = @"CJPayDeskTitleKVKey";
NSString * const CJPayStayAlertShownKey = @"CJPayStayAlertShownKey";
NSString * const CJPayTrackerCommonParamsIsCreavailable = @"CJPayTrackerCommonParamsIsCreavailable";
NSString * const CJPayTrackerCommonParamsCreditStageList = @"CJPayTrackerCommonParamsCreditStageList";
NSString * const CJPayTrackerCommonParamsCreditStage = @"CJPayTrackerCommonParamsCreditStage";
NSString * const CJPayUnionPayIsUnAvailable = @"CJPayUnionPayIsUnAvailable";
NSString * const CJPayMicroappBindCardCallBack = @"CJPayMicroappBindCardCallBack";
NSString * const CJPaySignPayRetainProcessId = @"CJPaySignPayRetainProcessId";
NSString * const CJPayOuterPayTrackData = @"CJPayOuterPayTrackData";//对应的value是NSMutableDictionary
NSString * const CJPayWithDrawAddHeaderData = @"CJPayWithDrawAddHeaderData";

@implementation CJPayKVContext

+ (NSMutableDictionary *)cjpayKVContextDic {
    if (!cjpayKVContextDic) {
        cjpayKVContextDic = [NSMutableDictionary new];
    }
    return cjpayKVContextDic;
}

+ (BOOL)kv_setValue:(id)value forKey:(NSString *)key {
    [[self cjpayKVContextDic] setValue:value forKey:key];
    return YES;
}

+ (id)kv_valueForKey:(NSString *)key {
    return [[self cjpayKVContextDic] valueForKey:key];
}

+ (NSString *)kv_stringForKey:(NSString *)key {
    return (NSString *)[[self cjpayKVContextDic] valueForKey:key];
}

@end
