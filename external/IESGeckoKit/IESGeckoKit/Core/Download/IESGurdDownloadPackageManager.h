//
//  IESGurdDownloadPackageManager.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/10.
//

#import <Foundation/Foundation.h>

#import "IESGeckoResourceModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^IESGurdDownloadPackageResultBlock)(BOOL isSuccessful, BOOL isPatch, NSError *error);

@interface IESGurdDownloadPackageManager : NSObject

+ (instancetype)sharedManager;

- (void)downloadIfNeeded;

- (void)downloadPackageWithConfig:(IESGurdResourceModel *)config
                          logInfo:(NSDictionary *)logInfo
                      resultBlock:(IESGurdDownloadPackageResultBlock)resultBlock;

- (void)cancelDownloadWithAccessKey:(NSString *)accessKey channel:(NSString *)channel;

@end

NS_ASSUME_NONNULL_END
