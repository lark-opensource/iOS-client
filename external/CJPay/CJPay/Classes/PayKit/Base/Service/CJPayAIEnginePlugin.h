//
//  Header.h
//  douyin
//
//  Created by ByteDance on 2023/6/8.
//

#ifndef Header_h
#define Header_h

FOUNDATION_EXTERN NSString * const CAIJING_RISK_SDK_FEATURE;
@protocol CJPayAIEnginePlugin <NSObject>

- (void)setup;
- (NSDictionary *)getOutputForBusiness:(NSString *)business;

@end

#endif /* Header_h */
