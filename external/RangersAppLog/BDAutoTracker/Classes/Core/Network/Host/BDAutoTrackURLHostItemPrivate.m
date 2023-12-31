//
//  BDAutoTrackURLHostItemPrivate.m
//  RangersAppLog
//
//  Created by bob on 2020/8/11.
//

#import "BDAutoTrackURLHostItemPrivate.h"

BDAutoTrackServiceVendor const BDAutoTrackServiceVendorPrivate  = @"private";

@implementation BDAutoTrackURLHostItemPrivate

- (BDAutoTrackServiceVendor)vendor {
    return BDAutoTrackServiceVendorPrivate;
}

- (NSString *)URLForURLType:(BDAutoTrackRequestURLType)type {
    return nil;
}

@end
