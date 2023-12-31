//
//  Heimdallr+DartTracker.m
//  Heimdallr
//
//  Created by 王佳乐 on 2018/10/28.
//

#import "Heimdallr+DartTracker.h"
#import "HMDDartTracker.h"

@implementation Heimdallr (DartTracker)

+ (void)recordDartErrorWithTraceStack:(NSString *)stack {
    [[HMDDartTracker sharedTracker] recordDartErrorWithTraceStack:stack];
}

+ (void)recordDartErrorWithTraceStack:(NSString *)stack
                           customData:(NSDictionary *)dictionary
                            customLog:(NSString *)customLog {
    [[HMDDartTracker sharedTracker] recordDartErrorWithTraceStack:stack
                                                       customData:dictionary
                                                        customLog:customLog];
}

+ (void)recordDartErrorWithTraceStack:(NSString *)stack customData:(NSDictionary *)dictionary customLog:(NSString *)customLog filters:(NSDictionary *)filters{
    [[HMDDartTracker sharedTracker] recordDartErrorWithTraceStack:stack
                                                       customData:dictionary
                                                        customLog:customLog
                                                          filters:filters];
}

@end
