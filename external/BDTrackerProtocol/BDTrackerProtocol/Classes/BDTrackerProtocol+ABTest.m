//
//  BDTrackerProtocol+ABTest.m
//  BDTrackerProtocol
//
//  Created by bob on 2020/3/20.
//

#import "BDTrackerProtocol+ABTest.h"
#import "BDTrackerProtocolHelper.h"

@implementation BDTrackerProtocol (ABTest)

+ (void)setBDTrackerEnabled {
    NSCAssert([BDTrackerProtocolHelper bdtrackerCls], @"should not be nil");
    [BDTrackerProtocolHelper setTrackerType:kTrackerTypeBDtracker];
}

+ (void)setTTTrackerEnabled {
    NSCAssert([BDTrackerProtocolHelper tttrackerCls], @"should not be nil");
    [BDTrackerProtocolHelper setTrackerType:kTrackerTypeTTTracker];
}

+ (BOOL)isBDTrackerEnabled {
    return [BDTrackerProtocolHelper trackerType] == kTrackerTypeBDtracker;
}

@end
