//
//  NSTimer+TTNetworkBlockTimer.h
//  TTNetworkManager
//
//  Created by dongyangfan on 2020/11/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (TTNetworkBlockTimer)

+ (NSTimer *)ttnet_scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(void (^)(void))block repeats:(BOOL)repeats;

+ (void)ttnet_blockSelector:(NSTimer *)timer;

@end

NS_ASSUME_NONNULL_END
