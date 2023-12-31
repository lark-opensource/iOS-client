//
//  NSDate+HMDAccurate.m
//  Heimdallr
//
//  Created by fengyadong on 2020/4/2.
//

#import "NSDate+HMDAccurate.h"
#include "HMDTimeSepc.h"

static NSDate *hmd_stadard_date;
CFTimeInterval hmd_standard_up_time;

@implementation NSDate (HMDAccurate)

+ (NSDate *)hmd_accurateDate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hmd_stadard_date = [NSDate date];
        hmd_standard_up_time = NSProcessInfo.processInfo.systemUptime;
    });
    
    NSAssert(hmd_stadard_date && hmd_standard_up_time > 0, @"standard date and up time invalid!");
    NSDate *date = [NSDate date];
    NSDate *accurate = date;
    
    if (hmd_stadard_date && hmd_standard_up_time > 0) {
        CFTimeInterval curUpTime = NSProcessInfo.processInfo.systemUptime;
        NSTimeInterval delta = curUpTime - hmd_standard_up_time;
        
        date = [hmd_stadard_date dateByAddingTimeInterval:delta];
    }
    
    return accurate;
}

@end
