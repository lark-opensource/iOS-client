//
//  PNSUserExceptionImpl.m
//  BDAlogProtocol
//
//  Created by ByteDance on 2022/6/27.
//

#import "PNSUserExceptionImpl.h"
#import "PNSServiceCenter+private.h"
#import <Heimdallr/HMDUserExceptionTracker.h>

PNS_BIND_DEFAULT_SERVICE(PNSUserExceptionImpl, PNSUserExceptionProtocol)

@implementation PNSUserExceptionImpl

- (void)trackUserExceptionWithType:(NSString *_Nonnull)exceptionType
                   backtracesArray:(NSArray *_Nonnull)backtraces
                      customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                           filters:(NSDictionary<NSString *, id> *_Nullable)filters
                          callback:(void (^ _Nullable)(NSError *_Nullable error))callback
{
    [[HMDUserExceptionTracker sharedTracker] trackUserExceptionWithType:exceptionType
                                                        backtracesArray:backtraces
                                                           customParams:customParams
                                                                filters:filters
                                                               callback:^(NSError *_Nullable error) {
        if (callback) {
            callback(error);
        }
    }];
}

- (void)trackUserExceptionWithType:(NSString *_Nonnull)exceptionType
                             title:(NSString *_Nonnull)title
                          subTitle:(NSString *_Nullable)subTitle
                      customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                           filters:(NSDictionary<NSString *, id> *_Nullable)filters
                          callback:(void (^ _Nullable)(NSError *_Nullable error))callback
{
    [[HMDUserExceptionTracker sharedTracker] trackUserExceptionWithExceptionType:exceptionType title:title subTitle:subTitle customParams:customParams filters:filters callback:^(NSError * _Nullable error) {
        if (callback) {
            callback(error);
        }
    }];
}

@end
