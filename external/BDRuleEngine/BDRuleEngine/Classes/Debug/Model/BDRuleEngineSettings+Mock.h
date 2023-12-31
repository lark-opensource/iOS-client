//
//  BDRuleEngineSettings+Mock.h
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/6/6.
//

#import "BDRuleEngineSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDRuleEngineSettings (Mock)

+ (void)prepareForMock;

+ (NSDictionary *)config;

@end

NS_ASSUME_NONNULL_END
