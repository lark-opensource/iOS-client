//
//  BDAutoTrackETRequest.m
//  RangersAppLog
//
//  Created by bob on 2020/6/11.
//

#import "BDAutoTrackETRequest.h"

#import "BDTrackerCoreConstants.h"

static NSString * const BDTrackerETURL = @"https://log.snssdk.com/service/2/app_log_test/";


@implementation BDAutoTrackETRequest

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID type:BDAutoTrackRequestURLSimulatorLog];
    if (self) {
        self.requestURL = BDTrackerETURL;
    }
    
    return self;
}

- (NSMutableDictionary *)requestHeaderParameters {
    NSMutableDictionary *header = [super requestHeaderParameters];
    
    // 往custom中添加 ByTest 相关信息
    if ([self bytestInfo].count > 0) {
        NSMutableDictionary *newCustom = [NSMutableDictionary new];
        NSDictionary *oldCustom = [header valueForKey:@"custom"];
        if ([oldCustom isKindOfClass:NSDictionary.class]) {
            [newCustom addEntriesFromDictionary:oldCustom];
        }
        [newCustom addEntriesFromDictionary:[self bytestInfo]];
        
        [header setObject:newCustom forKey:@"custom"];
    }
    
    return header;
}

#pragma mark private
- (NSDictionary *)bytestInfo {
    static dispatch_once_t onceToken;
    static NSMutableDictionary *ret;
    dispatch_once(&onceToken, ^{
        ret = [NSMutableDictionary new];
        NSDictionary *bytestInfo = [NSBundle.mainBundle objectForInfoDictionaryKey:@"AutomationTestInfo"];
        for (NSString *key in bytestInfo) {
            NSString *val = [bytestInfo objectForKey:key];
            if ([val isKindOfClass:NSString.class]) {
                [ret setObject:val forKey:key];
            }
        }
    });
    
    return ret;
}

@end
