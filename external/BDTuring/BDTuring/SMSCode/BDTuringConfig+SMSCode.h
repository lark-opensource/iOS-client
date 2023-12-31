//
//  BDTuringConfig+SMSCode.h
//  BDTuring
//
//  Created by bob on 2021/8/6.
//

#import "BDTuringConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringConfig (SMSCode)

- (NSMutableDictionary *)sendCodeParameters;
- (NSMutableDictionary *)checkCodeParameters;

@end

NS_ASSUME_NONNULL_END
