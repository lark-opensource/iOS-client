//
//  TTVideoEnginePlayDuration.h
//  Pods
//
//  Created by bytedance on 2022/3/10.
//

#ifndef TTVideoEnginePlayDuration_h
#define TTVideoEnginePlayDuration_h

#import <Foundation/Foundation.h>

static NSInteger const PlayDurationStatePlaying = 1;
static NSInteger const PlayDurationStateStop = 2;

@interface TTVideoEnginePlayDuration : NSObject

- (void) start;
- (void) stop;
- (NSTimeInterval) getPlayedDuration;
- (void) clear;
- (void) reset;

@property(nonatomic, assign) NSInteger state;
@property(nonatomic, assign) NSTimeInterval playedDuration;
@property(nonatomic, assign) NSTimeInterval startPlayTime;

@end

#endif /* TTVideoEnginePlayDuration_h */
