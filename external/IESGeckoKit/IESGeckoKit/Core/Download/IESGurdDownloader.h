//
//  IESGurdDownloader.h
//  Pods
//
//  Created by liuhaitian on 2020/4/24.
//

#import "IESGeckoDefines.h"

@class IESGurdDownloadInfoModel;
@interface IESGurdDownloader : NSObject

+ (void)downloadPackageWithDownloadInfoModel:(IESGurdDownloadInfoModel *)downloadInfoModel
                                  completion:(IESGurdDownloadResourceCompletion)completion;

+ (void)cancelDownloadWithIdentity:(NSString *)identity;

@end
