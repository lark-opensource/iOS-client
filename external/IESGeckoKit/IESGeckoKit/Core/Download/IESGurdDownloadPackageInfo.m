//
//  IESGurdDownloadPackageInfo.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/10.
//

#import "IESGurdDownloadPackageInfo.h"

@implementation IESGurdDownloadPackageInfo

- (NSString *)description
{
    NSString *packageTypeString = self.isPatch ? @"P-package" : @"F-package";
    return self.isSuccessful ?
    [NSString stringWithFormat:@"【%@ download successfully; duration(%zd) packageId(%lld) downloadSize(%lld)】",
     packageTypeString, self.downloadDuration, self.packageId, self.downloadSize] :
    [NSString stringWithFormat:@"【%@ download failed; duration(%zd) packageId(%lld) error(%@)】",
     packageTypeString, self.downloadDuration, self.packageId, self.error.localizedDescription];
}

@end
