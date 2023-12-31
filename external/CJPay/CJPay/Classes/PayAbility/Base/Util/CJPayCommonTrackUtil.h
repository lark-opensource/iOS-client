//
//  CJPayCommonTrackUtil.h
//  Pods
//
//  Created by 王新华 on 2020/11/8.
//

#import <Foundation/Foundation.h>
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayCreateOrderResponse;
@class CJPayBDCreateOrderResponse;
@class CJPayDefaultChannelShowConfig;

@interface CJPayCommonTrackUtil : NSObject

+ (NSDictionary *)getCashDeskCommonParamsWithResponse:(CJPayCreateOrderResponse *)response
                                    defaultPayChannel:(NSString *)defaultPayChannel;

+ (NSDictionary *)getBDPayCommonParamsWithResponse:(CJPayBDCreateOrderResponse *)response showConfig:(CJPayDefaultChannelShowConfig *)showConfig;

+ (NSDictionary *)getBytePayDeskCommonTrackerWithResponse:(CJPayCreateOrderResponse *)response;

@end

NS_ASSUME_NONNULL_END
