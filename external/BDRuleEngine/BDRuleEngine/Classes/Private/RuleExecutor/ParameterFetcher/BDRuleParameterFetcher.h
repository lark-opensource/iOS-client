//
//  BDRuleParameterFetcher.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/26.
//

#import <Foundation/Foundation.h>
#import "BDREExprEnv.h"
NS_ASSUME_NONNULL_BEGIN


@interface BDRuleParameterFetcher : NSObject<BDREExprEnv>

- (instancetype)initWithExtraParameters:(NSDictionary *)extraParameters;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (NSDictionary *)usedParameters;

@end

NS_ASSUME_NONNULL_END
