//
//  OKIDFA.m
//  OneKit
//
//  Created by bob on 2021/1/12.
//

#import "OKIDFA.h"
#import "OKServices.h"
#import "OKStartUpFunction.h"

#import <AdSupport/AdSupport.h>

@interface OKIDFA ()<OKIDFAService>

@end


OKAppLoadServiceFunction() {
    [[OKServiceCenter sharedInstance] bindClass:[OKIDFA class] forProtocol:@protocol(OKIDFAService)];
}

@implementation OKIDFA


+ (instancetype)sharedInstance {
    static OKIDFA *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (NSString *)IDFA {
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

@end
