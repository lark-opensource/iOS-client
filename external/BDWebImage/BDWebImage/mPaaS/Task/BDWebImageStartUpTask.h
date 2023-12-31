//
//  BDWebImageStartUpTask.h
//  BDWebImage
//
//  Created on 2020/4/10.
//

#import <BDStartUp/BDStartUpTask.h>
#import <BDWebImage/BDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

/// Config自定义配置参考如下，需要在BDAppCustomConfigFunction中
/// 仅做简单配置，请勿进行耗时操作
///
/**
#import <BDStartUp/BDStartUpGaia.h>
#import <BDWebImage/BDWebImageStartUpTask.h>
 
BDAppCustomConfigFunction() {
    [BDWebImageStartUpTask sharedInstance].urlFilter = xxx; // 自定义 urlFilter
    [BDWebImageStartUpTask sharedInstance].customTaskAfterBlock = ^{
        BDImageCacheConfig *cacheConfig = [BDImageCacheConfig new];
        cacheConfig.diskSizeLimit = 256 * 1024 * 1024;
        cacheConfig.diskAgeLimit = 7 * 24 * 60 * 60;
        cacheConfig.memorySizeLimit = 256 * 1024 * 1024;
        cacheConfig.memoryAgeLimit = 12 * 60 * 60;
        cacheConfig.shouldUseWeakMemoryCache = YES;
        [[BDImageCache sharedImageCache] setConfig:cacheConfig];
    };
 }
 */


@interface BDWebImageStartUpTask : BDStartUpTask

@property (nonatomic, strong)BDWebImageURLFilter *urlFilter;// 默认使用 BDStartUpImageURLFilter

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END

