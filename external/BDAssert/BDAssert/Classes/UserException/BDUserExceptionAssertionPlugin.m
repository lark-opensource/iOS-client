//
//  BDUserExceptionAssertionPlugin.m
//  BDAlogProtocol
//
//  Created by 李琢鹏 on 2019/4/26.
//

#import "BDUserExceptionAssertionPlugin.h"
#import <Heimdallr/HMDUserExceptionTracker.h>
#import "BDAssert.h"

@implementation BDUserExceptionAssertionPlugin

+ (void)load {
    [BDAssertionPluginManager addPlugin:self];
}

+ (void)handleFailureWithDesc:(NSString *)desc {
    [[HMDUserExceptionTracker sharedTracker] trackCurrentThreadLogExceptionType:@"BDAssert" skippedDepth:3 customParams:@{@"desc" : desc} filters:nil callback:^(NSError * _Nullable error) {
        
    }];
}

@end
