//
//  BDAutoTrack+CAID.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/2/28.
//

#import "BDAutoTrack+CAID.h"
#import "BDAutoTrack+SharedInstance.h"
#import "BDAutoTrackRegisterService+CAID.h"

@implementation BDAutoTrack (CAID)
+ (NSString *)caid {
    return [[self sharedTrack] caid];
}

+ (NSString *)prevCaid {
    return [[self sharedTrack] prevCaid];
}

- (NSString *)caid {
    return bd_registerServiceForAppID(self.appID).caid;
}

- (NSString *)prevCaid {
    return bd_registerServiceForAppID(self.appID).prevCaid;
}
@end
