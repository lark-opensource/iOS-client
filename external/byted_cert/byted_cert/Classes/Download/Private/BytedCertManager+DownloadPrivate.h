//
//  BytedCertManager+DownloadPrivate.h
//  byted_cert-Pods-AwemeCore
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/12.
//

#import "BytedCertManager.h"

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertManager (DownloadPrivate)

+ (NSString *)getModelByPre:(NSString *)path pre:(NSString *)pre;

+ (NSString *)getResourceByPath:(NSString *)path pre:(NSString *)pre suffix:(NSString *)suffix;

+ (bool)checkMd5:(NSString *)filePath md5:(NSString *)md5Str;

@end

NS_ASSUME_NONNULL_END
