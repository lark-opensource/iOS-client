//
//  NSDate+BDPExtension.m
//  Timor
//
//  Created by houjihu on 2020/6/17.
//

#import "NSDate+BDPExtension.h"

@implementation NSDate (BDPExtension)

#pragma mark - Timestamp Helper
+ (NSInteger)bdp_currentTimestampInMilliseconds {
    return (NSInteger)([[NSDate date] timeIntervalSince1970] * 1000.f);
}

+ (NSDate *)bdp_dateFromTimestampInMilliseconds:(NSInteger)timestamp {
    CFTimeInterval ts = (CFTimeInterval)timestamp / 1000.f;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:ts];
    return date;
}

@end
