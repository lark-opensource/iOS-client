//
//  IESLynxMonitorConfig.m
//  IESWebViewMonitor
//
//  Created by 小阿凉 on 2020/3/1.
//

#import "IESLynxMonitorConfig.h"
#import "IESLynxPerformanceDictionary.h"
#import <Lynx/LynxVersion.h>

@interface IESLynxMonitorConfig ()

@property (nonatomic, copy) NSString *sessionID;
@property (nonatomic) NSDictionary *commonParams;

@end

@implementation IESLynxMonitorConfig

- (instancetype)init
{
    if (self = [super init]) {
        _sessionID = [NSString stringWithFormat:@"%f-%d", CFAbsoluteTimeGetCurrent(), arc4random() % 10000];
        _channel = @"ttlive";
        _tag = @"ttlive_sdk";
    }
    return self;
}

- (NSDictionary *)commonParams
{
    if (!_commonParams) {
        NSURL *url = [NSURL URLWithString:self.url ?: @""];
        NSString *templateUrl = [NSString stringWithFormat:@"%@://%@%@", url.scheme, url.host, url.path] ?: @"";
        _commonParams = @{
            @"tag": self.tag ? : @"",
            @"url": templateUrl,
            @"template_url": templateUrl,
            @"offline" : @(self.offline),
            @"ts" : @([[NSDate date] timeIntervalSince1970] * 1000.0),
            kLynxMonitorPid : self.pageName ? : @"",
            kLynxMonitorBid : self.channel ? : @"",
            kLynxMonitorLynxVersion : [LynxVersion versionString] ? : @""
        };
    }
    return _commonParams;
}

+ (NSString *)lynxVersion {
    NSString *version = [LynxVersion versionString];
    if (version && [version isKindOfClass:[NSString class]]) {
        return version;
    }
    return @"unknown";
}

@end
