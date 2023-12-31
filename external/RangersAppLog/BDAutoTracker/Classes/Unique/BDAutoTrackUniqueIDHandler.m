//
//  BDAutoTrackUniqueIDHandler.m
//  RangersAppLog
//
//  Created by bob on 2020/7/13.
//

#import "BDAutoTrackUniqueIDHandler.h"
#import "BDAutoTrackIDFA.h"

__attribute__((constructor)) void bdauto_unique_handler(void) {
    [RangersAppLogConfig sharedInstance].handler = [BDAutoTrackUniqueIDHandler new];
}

@implementation BDAutoTrackUniqueIDHandler

- (NSString *)uniqueID {
    return [BDAutoTrackIDFA trackingIdentifier];
}

@end
