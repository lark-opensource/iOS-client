//
//  IESGurdLoadResourcesParams.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/8/19.
//

#import "IESGurdLoadResourcesParams.h"

@implementation IESGurdLoadResourcesParams

- (IESGurdFetchResourcesParams *)toFetchParams
{
    if (self.accessKey.length == 0 ||
        self.channel.length == 0 ||
        self.resourcePath.length == 0) {
        return nil;
    }
    IESGurdFetchResourcesParams *fetchParams = [[IESGurdFetchResourcesParams alloc] init];
    fetchParams.accessKey = self.accessKey;
    fetchParams.channels = @[ self.channel ];
    fetchParams.SDKVersion = self.SDKVersion;
    fetchParams.customParams = self.customParams;
    fetchParams.downloadPriority = self.downloadPriority;
    fetchParams.disableThrottle = self.options & IESGurdLoadResourceOptionDisableThrottle;
    return fetchParams;
}

@end
