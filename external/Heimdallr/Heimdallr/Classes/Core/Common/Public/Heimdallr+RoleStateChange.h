//
//  Heimdallr+RoleStateChange.h
//  Heimdallr
//
//  Created by zhouyang11 on 2023/8/24.
//

#import "Heimdallr.h"

NS_ASSUME_NONNULL_BEGIN

@interface Heimdallr (RoleStateChange)

// Heimdallr初始化完成之后才会生效，内部做了判断
- (void)roleStateChangeAndCleanData;

@end

NS_ASSUME_NONNULL_END
