//
//  BDRLRawJsonViewModel.h
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 26.4.22.
//

#import "BDRLStrategyViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDRLRawJsonViewModel : BDRLStrategyViewModel

- (instancetype)initWithJson:(NSDictionary *)json;

- (NSString *)jsonFormat;

@end

NS_ASSUME_NONNULL_END
