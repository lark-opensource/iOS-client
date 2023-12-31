//
//  CJPayKVContext.h
//  CJPay
//
//  Created by 王新华 on 2020/10/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
extern NSString * const CJPayDeskTitleKVKey;
extern NSString * const CJPayStayAlertShownKey;
extern NSString * const CJPayTrackerCommonParamsIsCreavailable;
extern NSString * const CJPayTrackerCommonParamsCreditStageList;
extern NSString * const CJPayTrackerCommonParamsCreditStage;
extern NSString * const CJPayUnionPayIsUnAvailable;
extern NSString * const CJPayMicroappBindCardCallBack;
extern NSString * const CJPaySignPayRetainProcessId;
extern NSString * const CJPayOuterPayTrackData;
extern NSString * const CJPayWithDrawAddHeaderData;

@interface CJPayKVContext : NSObject

+ (BOOL)kv_setValue:(id)value forKey:(NSString *)key;
+ (id)kv_valueForKey:(NSString *)key;
+ (NSString *)kv_stringForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
