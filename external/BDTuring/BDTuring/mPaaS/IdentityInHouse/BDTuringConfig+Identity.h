//
//  BDTuringConfig+Identity.h
//  BDTuring
//
//  Created by bob on 2020/3/6.
//

#import "BDTuringConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringIdentityModel;

@interface BDTuringConfig (Identity)

- (NSMutableDictionary *)identityParameterWithModel:(BDTuringIdentityModel *)model;

@end

NS_ASSUME_NONNULL_END
