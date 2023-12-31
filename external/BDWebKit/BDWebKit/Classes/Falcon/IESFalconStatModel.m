//
//  IESFalconStatModel.m
//  IESWebKit-Pods-Aweme
//
//  Created by 陈煜钏 on 2019/10/30.
//

#import "IESFalconStatModel.h"

@implementation IESFalconStatModel

- (NSDictionary *)statDictionary
{
    NSMutableDictionary *statDictionary = [NSMutableDictionary dictionary];
    if (self.resourceURLString.length > 0) {
        statDictionary[@"resource_url"] = self.resourceURLString;
    }
    if (self.offlineRule.length > 0) {
        statDictionary[@"offline_rule"] = self.offlineRule;
    }
    if (self.mimeType.length > 0) {
        statDictionary[@"mime_type"] = self.mimeType;
    }
    if (self.accessKey.length > 0) {
        statDictionary[@"access_key"] = self.accessKey;
    }
    if (self.channel.length > 0) {
        statDictionary[@"channel"] = self.channel;
    }
    
    statDictionary[@"offline_status"] = @(self.offlineStatus);
    statDictionary[@"offline_duration"] = @(self.offlineDuration);
    statDictionary[@"online_duration"] = @(self.onlineDuration);
    statDictionary[@"pkg_version"] = @(self.packageVersion);
    
    if (self.errorCode > 0) {
        statDictionary[@"err_code"] = @(self.errorCode).stringValue;
    }
    if (self.errorMessage.length > 0) {
        statDictionary[@"err_msg"] = self.errorMessage;
    }
    return [statDictionary copy];
}

@end
