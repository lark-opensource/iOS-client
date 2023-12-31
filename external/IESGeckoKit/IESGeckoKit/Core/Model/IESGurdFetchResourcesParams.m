//
//  IESGurdFetchResourcesParams.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/8/19.
//

#import "IESGurdFetchResourcesParams+Private.h"

@implementation IESGurdFetchResourcesParams

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloadPriority = IESGurdDownloadPriorityMedium;
        _retryDownload = YES;
        _modelActivePolicy = IESGurdPackageModelActivePolicyNormal;
        _requestWhenHasLocalVersion = YES;
    }
    return self;
}

- (BOOL)isValid
{
    if (self.accessKey.length == 0) {
        return NO;
    }
    if (self.channels.count == 0 && self.groupName.length == 0) {
        return NO;
    }
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"accessKey(%@) groupName(%@) channels(%@)",
            self.accessKey, self.groupName, [self.channels componentsJoinedByString:@"、"]];
}

#pragma mark - Accessor

- (void)setResourceVersion:(NSString *)resourceVersion
{
    _resourceVersion = resourceVersion;
    self.SDKVersion = resourceVersion;
}

@end
