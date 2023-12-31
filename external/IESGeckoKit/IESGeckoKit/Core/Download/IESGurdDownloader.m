//
//  IESGurdDownloader.m
//  Pods
//
//  Created by liuhaitian on 2020/4/24.
//

#import "IESGurdDownloader.h"
#import "IESGurdProtocolDefines.h"
#import "IESGeckoResourceManager.h"
#import "IESGeckoKit.h"
#import "IESGurdKit+BackgroundDownload.h"
#import "NSError+IESGurdKit.h"
#import "IESGurdDownloadInfoModel.h"
#import "IESGurdMonitorManager.h"

@implementation IESGurdDownloader

+ (void)downloadPackageWithDownloadInfoModel:(IESGurdDownloadInfoModel *)downloadInfoModel
                                  completion:(IESGurdDownloadResourceCompletion)completion
{
    id<IESGurdDownloaderDelegate> downloaderDelegate = [IESGurdKit downloaderDelegate];
    if ([downloaderDelegate respondsToSelector:@selector(downloadPackageWithDownloadInfoModel:completion:)] && [IESGurdKit useDownloadDelegate]) {
        [downloaderDelegate downloadPackageWithDownloadInfoModel:downloadInfoModel completion:completion];
    } else {
        [IESGurdResourceManager downloadPackageWithDownloadInfoModel:downloadInfoModel completion:completion];
    }
    NSDictionary *metric = @{
        @"size": @(downloadInfoModel.packageSize)
    };
    NSDictionary *category = @{
        @"category": @(IESGurdKit.background)
    };
    [[IESGurdMonitorManager sharedManager] monitorEvent:@"geckosdk_resource_traffic_consume" category:category metric:metric extra:nil];
}

+ (void)cancelDownloadWithIdentity:(NSString *)identity
{
    id<IESGurdDownloaderDelegate> downloaderDelegate = [IESGurdKit downloaderDelegate];
    if ([downloaderDelegate respondsToSelector:@selector(cancelDownloadWithIdentity:)]) {
        [downloaderDelegate cancelDownloadWithIdentity:identity];
    } else {
        [IESGurdResourceManager cancelDownloadWithIdentity:identity];
    }
}

@end
