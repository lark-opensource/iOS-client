//
//  HMDOTManager+HMDUnitTest.h
//  Pods
//
//  Created by liuhan on 2021/10/18.
//

#import "HMDOTManager.h"
#import <Heimdallr/HMDOTManager.h>
#import <OCMock/OCPartialMockObject.h>

@interface HMDOTManager (HMDUnitTest)

+ (instancetype)sharedInstance;

@end

static HMDOTManager *OTManagerMock = nil;

@implementation HMDOTManager (HMDUnitTest)

+ (instancetype)sharedInstance {
    if (OTManagerMock) {
        return OTManagerMock;
    }
    static HMDOTManager *sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[HMDOTManager alloc] init];
    });
    return sharedTracker;
}

@end
