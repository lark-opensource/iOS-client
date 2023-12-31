//
//  BDTuringConfig+AccountSeal.h
//  BDTuring
//
//  Created by bob on 2020/3/5.
//

#import "BDTuringConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringConfig (AccountSeal)

- (NSMutableDictionary *)sealWebURLQueryParameters;
- (NSMutableDictionary *)sealRequestQueryParameters;

@end

NS_ASSUME_NONNULL_END
