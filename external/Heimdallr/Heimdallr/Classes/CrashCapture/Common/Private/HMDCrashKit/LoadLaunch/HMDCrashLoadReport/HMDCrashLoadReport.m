
/*!@header HMDCrashLoadReport.m
   @author somebody
   @abstract crash load launch report object
 */

#import "HMDCrashLoadReport.h"
#import "HMDCrashLoadReport+Private.h"

@interface HMDCrashLoadReport ()

@property(nonatomic, readwrite, getter=isLastTimeCrash) BOOL lastTimeCrash;

@property(nonatomic, readwrite, getter=isLastTimeLoadCrash) BOOL lastTimeLoadCrash;

@property(nonatomic, readwrite) NSTimeInterval launchDuration;

@property(nonatomic, readwrite) NSUInteger moveTrackerProcessFailedCount;

@property(nonatomic, readwrite) NSUInteger dropCrashIfProcessFailedCount;

@end

@implementation HMDCrashLoadReport

+ (instancetype)report {
    return [[self alloc] init];
}

@end
