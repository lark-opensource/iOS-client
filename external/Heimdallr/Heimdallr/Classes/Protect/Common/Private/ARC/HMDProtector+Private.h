//
//  HMDProtector+Private.h
//  Heimdallr
//
//  Created by sunrunwang on 2021/12/27.
//

#import "HMDProtector.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDProtector (Private)

- (void)respondToNSExceptionPrevent:(NSException *)exception info:(NSDictionary *)info;

- (void)respondToMachExceptionWithInfo:(NSDictionary *)info;

@end

NS_ASSUME_NONNULL_END
