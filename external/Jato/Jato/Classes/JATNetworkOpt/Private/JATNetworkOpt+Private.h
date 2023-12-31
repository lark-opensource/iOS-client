//
//  JATNetworkOpt+Private.h
//  Jato
//
//  Created by zhangxiao on 2022/8/4.
//

#import "JATNetworkOpt.h"

NS_ASSUME_NONNULL_BEGIN

@interface JATNetworkOpt (Private)

- (BOOL)needSwitchToSubThreadForcelyWitURLString:(NSString *)URLString;
- (void)execTaskOnSubThread:(void(^)(void))taskBlock;

@end

NS_ASSUME_NONNULL_END
