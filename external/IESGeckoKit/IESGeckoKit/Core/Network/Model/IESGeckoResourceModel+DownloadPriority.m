//
//  IESGeckoResourceModel+DownloadPriority.m
//  IESGeckoKit
//
//  Created by liuhaitian on 2021/10/19.
//

#import "IESGeckoResourceModel+DownloadPriority.h"

@implementation IESGurdResourceModel (DownloadPriority)

- (void)updateDownloadPriorityWithDownloadPrioritiesMap:(NSDictionary<NSString *, NSNumber *> *)downloadPrioritiesMap
{
    if (self.businessIdentifiers.count <= 0) {
        self.downloadPriority = IESGurdDownloadPriorityMedium;
        return;
    }

    IESGurdDownloadPriority downloadPriority = IESGurdDownloadPriorityLow;
    for (NSString *identifier in self.businessIdentifiers) {
        // 如果命中了多个 identifier，取更大值
        downloadPriority = MAX(downloadPriority, [downloadPrioritiesMap[identifier] integerValue]);
    }
    self.downloadPriority = downloadPriority;
}

@end
