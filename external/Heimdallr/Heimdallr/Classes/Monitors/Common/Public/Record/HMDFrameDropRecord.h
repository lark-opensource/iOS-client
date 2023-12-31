//
//  HMDFrameDropRecord.h
//  Heimdallr
//
//  Created by 王佳乐 on 2019/3/6.
//

#import <Foundation/Foundation.h>
#import "HMDMonitorRecord.h"


@interface HMDFrameDropRecord : HMDMonitorRecord
@property (nonatomic, strong, nullable) NSDictionary *frameDropInfo;
@property (nonatomic, copy, nullable) NSArray *originDropArray;
@property (nonatomic, assign) NSTimeInterval slidingTime;
@property (nonatomic, assign) CGPoint touchReleasedVelocity;
@property (nonatomic, assign) CGPoint targetScrollDistance;
@property (nonatomic, assign) NSUInteger refreshRate;
@property (nonatomic, assign) BOOL isScrolling;
@property (nonatomic, assign) BOOL isLowPowerMode;
@property (nonatomic, assign)BOOL isEvilMethod;
@property (nonatomic, assign) double blockDuration;
@property (nonatomic, assign) NSInteger blockCount;
@property (nonatomic, copy, nullable) NSDictionary *customExtra;

@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval hitchDuration;
@property (nonatomic, copy, nullable) NSDictionary *hitchDurDic;

@end

