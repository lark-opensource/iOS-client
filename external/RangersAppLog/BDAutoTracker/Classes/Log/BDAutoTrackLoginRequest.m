//
//  BDAutoTrackLoginRequest.m
//  RangersAppLog
//
//  Created by bob on 2020/5/28.
//

#import "BDAutoTrackLoginRequest.h"

#import "BDTrackerCoreConstants.h"

@implementation BDAutoTrackLoginRequest

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID type:BDAutoTrackRequestURLSimulatorLogin];
    if (self) {
    }
    
    return self;
}

@end
