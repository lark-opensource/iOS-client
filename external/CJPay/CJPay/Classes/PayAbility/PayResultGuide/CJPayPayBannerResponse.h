//
//  CJPayPayBannerResponse.h
//  Pods
//
//  Created by chenbocheng on 2021/8/4.
//

#import <JSONModel/JSONModel.h>
#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayDynamicComponents;
@interface CJPayPayBannerResponse : CJPayBaseResponse

@property (nonatomic, copy) NSArray<CJPayDynamicComponents> *dynamicComponents;
@property (nonatomic, copy) NSString *benefitInfo;

@end

NS_ASSUME_NONNULL_END
