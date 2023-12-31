//
//  BDABTestExperimentCache.m
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "BDABTestManager+Cache.h"
#import "BDABTestExposureManager.h"
#import "BDABTestExperimentItemModel.h"
#import "BDClientABManager.h"

NSString * const kBDABTestResultUpdatedNotificaion = @"kBDABTestResultUpdatedNotificaion";

/*
 网络请求的结果存在这个UserDefaults中
 */
static NSString * const kBDABTestFetchedResultUserDefaultsKey = @"kBDABTestFetchedResultUserDefaultsKey";

/*
 用户手动修改的结果存在这个UserDefaults中
 */
static NSString * const kBDABTestEditedResultUserDefaultsKey = @"kBDABTestEditedResultUserDefaultsKey";

@implementation BDABTestManager (Cache)

/**
 存储网络请求获得的json数据（common接口）
 
 @param jsonData 已经经过合法性校验的json数据
 */
- (void)saveFetchedJsonData:(NSDictionary<NSString *, NSDictionary *> *)jsonData {
    [[NSUserDefaults standardUserDefaults] setValue:jsonData forKey:kBDABTestFetchedResultUserDefaultsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDABTestResultUpdatedNotificaion object:nil];
}

/**
 存储用户手动修改的结果
 
 @param key 用户手动修改的key
 @param value 用户手动修改后的值
 @param vid 这个实验的vid
 */
- (void)editExperimentWithKey:(NSString *)key value:(id)value vid:(NSNumber *)vid {
    if (!key) {
        return;
    }
    NSMutableDictionary *editDict = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBDABTestEditedResultUserDefaultsKey] mutableCopy];
    if (!editDict) {
        editDict = [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] init];
    [mutableDic setValue:value forKey:@"val"];
    [mutableDic setValue:vid forKey:@"vid"];
    if (value) {
        [editDict setValue:mutableDic forKey:key];
    }
    else { //如果value为空，则清空这个key
        [editDict setValue:nil forKey:key];
    }
    [[NSUserDefaults standardUserDefaults] setValue:editDict forKey:kBDABTestEditedResultUserDefaultsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDABTestResultUpdatedNotificaion object:nil];
}

/**
 key对应的实验结果，会merge网络请求结果和手动修改结果
 */
- (BDABTestExperimentItemModel *)savedItemForKey:(NSString *)key {
    NSDictionary *fetchedDic = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBDABTestFetchedResultUserDefaultsKey] objectForKey:key];
    NSDictionary *editedDic = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBDABTestEditedResultUserDefaultsKey] objectForKey:key];
    BDABTestExperimentItemModel *item = nil;
    id val = [editedDic valueForKey:@"val"];
    id vid = [editedDic valueForKey:@"vid"];
    if (!val) {
        val = [fetchedDic valueForKey:@"val"];
    }
    if (!vid) {
        vid = [fetchedDic valueForKey:@"vid"];
    }
    if (!val) {
        item = nil;
    }
    else {
        item = [[BDABTestExperimentItemModel alloc] initWithVal:val vid:vid];
    }
    return item;
}

/**
 获取某个key被用户修改的结果，和网络请求结果无关
 */
- (BDABTestExperimentItemModel *)editedItemForKey:(NSString *)key {
    NSDictionary *editedDic = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBDABTestEditedResultUserDefaultsKey] objectForKey:key];
    BDABTestExperimentItemModel *item = nil;
    id val = [editedDic valueForKey:@"val"];
    id vid = [editedDic valueForKey:@"vid"];
    if (!val) {
        item = nil;
    }
    else {
        item = [[BDABTestExperimentItemModel alloc] initWithVal:val vid:vid];
    }
    return item;
}

/**
 获取目前有效的vid。如果一个vid不在common接口下发的列表或客户端本地分流实验里，则认为无效。
 */
- (NSSet<NSString *> *)validVids {
    NSMutableSet<NSString *> *validVids = [[NSMutableSet alloc] init];
    NSDictionary<NSString *, NSDictionary *> *fetchedJsonData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kBDABTestFetchedResultUserDefaultsKey];
    [fetchedJsonData enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj[@"vid"] && [obj[@"vid"] isKindOfClass:[NSNumber class]]) {
            [validVids addObject:[obj[@"vid"] stringValue]];
        }
    }];
    NSDictionary *editedJsonData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kBDABTestEditedResultUserDefaultsKey];
    [editedJsonData enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj[@"vid"] && [obj[@"vid"] isKindOfClass:[NSNumber class]]) {
            [validVids addObject:[obj[@"vid"] stringValue]];
        }
    }];
    NSArray *clientVidList = [[BDClientABManager sharedManager] vidList];
    for (NSString *vid in clientVidList) {
        [validVids addObject:vid];
    }
    return validVids;
}

@end
