//
//  BDImageSettingModel.m
//  BDWebImage_Example
//
//  Created by 陈奕 on 2020/4/8.
//  Copyright © 2020 Bytedance.com. All rights reserved.
//

#import "BDImageSettingModel.h"
#import "BDImageAdapter.h"

@implementation BDImageSettingModel

+ (NSArray<BDImageSettingModel *> *)defaultSettingModels {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:9];
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"APPID";
        model.info = @"171055";
        model.type = BDImageSettingInfoType;
        model;
    })];
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"动图边下边放";
        model.type = BDImageSettingSelectType;
        model.showSelect = ^BOOL{
            return [BDImageAdapter sharedAdapter].options & BDImageAnimatedImageProgressiveDownload;
        };
        model.selectItem = ^{
            [BDImageAdapter sharedAdapter].options ^= BDImageAnimatedImageProgressiveDownload;
        };
        model;
    })];
    static BOOL isSolid = NO;
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"开启硬解码(没开就是软解)";
        model.type = BDImageSettingSelectType;
        model.showSelect = ^BOOL {
            if(isSolid) {
                BDWebImageManager.sharedManager.isSystemHeicDecoderFirst = YES;
                BDWebImageManager.sharedManager.isCustomSequenceHeicsDecoderFirst = NO;
            } else {
                BDWebImageManager.sharedManager.isSystemHeicDecoderFirst = NO;
                BDWebImageManager.sharedManager.isCustomSequenceHeicsDecoderFirst = YES;
            }
            return isSolid;
        };
        model.selectItem = ^{
            isSolid = !isSolid;
            if(isSolid) {
                BDWebImageManager.sharedManager.isSystemHeicDecoderFirst = YES;
                BDWebImageManager.sharedManager.isCustomSequenceHeicsDecoderFirst = NO;
            } else {
                BDWebImageManager.sharedManager.isSystemHeicDecoderFirst = NO;
                BDWebImageManager.sharedManager.isCustomSequenceHeicsDecoderFirst = YES;
            }
        };
        model;
    })];
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"动图循环播放";
        model.type = BDImageSettingSelectType;
        model.showSelect = ^BOOL{
            return [BDImageAdapter sharedAdapter].isCyclePlayAnim;
        };
        model.selectItem = ^{
            [BDImageAdapter sharedAdapter].isCyclePlayAnim = ![BDImageAdapter sharedAdapter].isCyclePlayAnim;
        };
        model;
    })];
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"失败后自动重试";
        model.type = BDImageSettingSelectType;
        model.showSelect = ^BOOL{
            return [BDImageAdapter sharedAdapter].isRetry;
        };
        model.selectItem = ^{
            [BDImageAdapter sharedAdapter].isRetry = ![BDImageAdapter sharedAdapter].isRetry;
        };
        model;
    })];
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"预加载";
        model.type = BDImageSettingSelectType;
        model.showSelect = ^BOOL{
            return [BDImageAdapter sharedAdapter].isPrefetch;
        };
        model.selectItem = ^{
            [BDImageAdapter sharedAdapter].isPrefetch = ![BDImageAdapter sharedAdapter].isPrefetch;
        };
        model;
    })];
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"预解码";
        model.type = BDImageSettingSelectType;
        model.showSelect = ^BOOL{
            return [BDImageAdapter sharedAdapter].isDecodeForDisplay;
        };
        model.selectItem = ^{
            [BDImageAdapter sharedAdapter].isDecodeForDisplay = ![BDImageAdapter sharedAdapter].isDecodeForDisplay;
        };
        model;
    })];
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"缓存控制";
        model.type = BDImageSettingActionType;
        model;
    })];
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"清除缓存";
        [[BDImageAdapter sharedAdapter] updateCacheSize];
        model.info = @([BDImageAdapter sharedAdapter].cacheSize).stringValue;
        model.type = BDImageSettingActionType;
        model;
    })];
    return array;
}

+ (NSArray<BDImageSettingModel *> *)cacheSettingModels {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:3];
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"忽略内存缓存";
        model.type = BDImageSettingSelectType;
        model.showSelect = ^BOOL{
            return [BDImageAdapter sharedAdapter].options & BDImageRequestIgnoreMemoryCache;
        };
        model.selectItem = ^{
            [BDImageAdapter sharedAdapter].options ^= BDImageRequestIgnoreMemoryCache;
        };
        model;
    })];
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"忽略磁盘缓存";
        model.type = BDImageSettingSelectType;
        model.showSelect = ^BOOL{
            return [BDImageAdapter sharedAdapter].options & BDImageRequestIgnoreDiskCache;
        };
        model.selectItem = ^{
            [BDImageAdapter sharedAdapter].options ^= BDImageRequestIgnoreDiskCache;
        };
        model;
    })];
    [array addObject:({
        BDImageSettingModel *model = [BDImageSettingModel new];
        model.name = @"下载后不存内存缓存";
        model.type = BDImageSettingSelectType;
        model.showSelect = ^BOOL{
            return [BDImageAdapter sharedAdapter].options & BDImageRequestNotCacheToDisk;
        };
        model.selectItem = ^{
            [BDImageAdapter sharedAdapter].options ^= BDImageRequestNotCacheToDisk;
        };
        model;
    })];
    return array;
}

@end
