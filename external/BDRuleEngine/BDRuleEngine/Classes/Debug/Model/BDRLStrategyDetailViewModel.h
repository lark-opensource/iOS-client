//
//  BDRLStrategyDetailViewModel.h
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 27.4.22.
//

#import "BDRLStrategyViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDRLStrategyDetailViewModel : BDRLStrategyViewModel

- (instancetype)initWithJson:(NSDictionary *)json;

- (NSString *)strategyTitle;

- (NSString *)strategyCel;

- (NSString *)policyTitleAtIndexPath:(NSIndexPath *)indexPath;

- (NSString *)policyConfAtIndexPath:(NSIndexPath *)indexPath;

- (NSString *)policyCelAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
