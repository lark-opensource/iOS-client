//
//  IESGurdKit+BackgroundDownload.m
//  Indexer
//
//  Created by bytedance on 2021/10/13.
//

#import "IESGurdKit+BackgroundDownload.h"
#import "IESGurdDownloadPackageManager.h"

@implementation IESGurdKit (BackgroundDownload)

static IESGurdDownloadPolicy kDownloadPolicy = IESGurdDownloadPolicyDefault;
+ (void)setDownloadPolicy:(IESGurdDownloadPolicy)downloadPolicy
{
    kDownloadPolicy = downloadPolicy;
}

+ (IESGurdDownloadPolicy)downloadPolicy
{
    return kDownloadPolicy;
}

static BOOL kBackground = NO;
+ (void)setBackground:(BOOL)background
{
    kBackground = background;
}

+ (BOOL)background
{
    return kBackground;
}

static NSArray<NSString *> *kBackgroundAccessKeys = nil;
+ (NSArray<NSString *> *)backgroundAccessKeys
{
    return kBackgroundAccessKeys;
}

+ (void)setBackgroundAccessKeys:(NSArray<NSString *> *)backgroundAccessKeys
{
    kBackgroundAccessKeys = backgroundAccessKeys;
}

+ (BOOL)useDownloadDelegate
{
    if (self.downloadPolicy == IESGurdDownloadPolicyDefault) {
        return NO;
    }
    return self.background;
}

@end
