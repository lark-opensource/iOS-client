//
//  HMDWatchDogDelegate.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/3/14.
//

#import <Foundation/Foundation.h>


@protocol HMDWatchDogDelegate <NSObject>

- (void)watchDogDidNotHappenLastTime;

- (void)watchDogDidDetectSystemKillWithData:(NSDictionary * _Nullable)dic;

- (void)watchDogDidDetectUserForceQuitWithData:(NSDictionary * _Nullable)dic;

@end

