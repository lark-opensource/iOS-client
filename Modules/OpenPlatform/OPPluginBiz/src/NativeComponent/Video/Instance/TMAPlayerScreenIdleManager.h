//
//  TMAPlayerScreenIdleManager.h
//  AFgzipRequestSerializer
//
//  Created by bupozhuang on 2019/4/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TMAPlayerScreenIdleManager : NSObject
+ (instancetype)shared;
- (void)startPlay:(NSInteger) playerID;
- (void)stopPlay:(NSInteger) playerID;

- (void)idleDisableIfNeed;
@end

NS_ASSUME_NONNULL_END
