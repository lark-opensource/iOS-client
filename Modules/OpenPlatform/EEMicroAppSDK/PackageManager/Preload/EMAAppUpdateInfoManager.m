//
//  EMAAppUpdateInfoManager.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/14.
//

#import "EMAAppUpdateInfoManager.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPUtils.h>

static NSString * const kEMAAppUpdateList = @"app_update_info_list";
static NSString * const kUpdateLogTag = @"EMAUpdate";

@protocol EMAAppUpdateInfo;

@interface EMAAppUpdateInfoList : JSONModel

@property (nonatomic, assign) NSTimeInterval last_update_time;
@property (nonatomic, strong) NSDictionary<NSString *, EMAAppUpdateInfo *> <EMAAppUpdateInfo> *app_list;

@end

@implementation EMAAppUpdateInfoList

@end

@interface EMAAppUpdateInfoManager ()

@property (nonatomic, assign) BOOL needSave;
@property (nonatomic, strong) EMAAppUpdateInfoList *infoList;

@end

@implementation EMAAppUpdateInfoManager

- (EMAAppUpdateInfoList *)infoList {
    if (!_infoList) {
        // 从缓存读取
        TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
        NSString *json = [storage objectForKey:kEMAAppUpdateList];
        if (!BDPIsEmptyString(json)) {
            JSONModelError *error = nil;
            EMAAppUpdateInfoList *info = [[EMAAppUpdateInfoList alloc] initWithString:json error:&error];
            if (!error && info) {
                NSTimeInterval todayTime = [self todayTime];
                if (info.last_update_time < todayTime) {
                    // 需要清理所有的更新次数记录
                    [info.app_list enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, EMAAppUpdateInfo * _Nonnull obj, BOOL * _Nonnull stop) {
                        obj.updated_times = 0;
                    }];
                    _needSave = YES;
                    info.last_update_time = NSDate.date.timeIntervalSince1970;
                }
                _infoList = info;
            } else if(error) {
                BDPLogTagError(kUpdateLogTag, @"json parse error:%@", error);
            }
        }
        if (!_infoList) {
            _infoList = [[EMAAppUpdateInfoList alloc] init];
            _infoList.app_list = (NSDictionary<NSString *, EMAAppUpdateInfo *> <EMAAppUpdateInfo> *)NSDictionary.dictionary;
        }
    }
    return _infoList;
}

- (EMAAppUpdateInfo *)appUpdateInfoForUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return nil;
    }
    return self.infoList.app_list[uniqueID.fullString];
}

- (EMAAppUpdateInfo *)mergeNewUpdateInfo:(EMAAppUpdateInfo *)newUpdateInfo {
    if (!newUpdateInfo.uniqueID.isValid) {
        return nil;
    }
    BDPUniqueID *uniqueID = newUpdateInfo.uniqueID;
    NSString *identifier = uniqueID.fullString;
    EMAAppUpdateInfo *info = [self appUpdateInfoForUniqueID:uniqueID];
    if (!info) {
        info = newUpdateInfo;
        NSMutableDictionary *newAppList = self.infoList.app_list.mutableCopy ?: NSMutableDictionary.dictionary;
        newAppList[identifier] = info;
        self.infoList.app_list = newAppList.copy;
    } else {
        if (![info.app_version isEqualToString:newUpdateInfo.app_version]) {
            info.update_failed_times = 0;   // 如果有新版本，则重置失败计数
        }
        info.app_version = newUpdateInfo.app_version;
        info.app_version_code = newUpdateInfo.app_version_code;
        info.need_clear_cache = newUpdateInfo.need_clear_cache;
        info.need_update = newUpdateInfo.need_update;
        info.force_update = newUpdateInfo.force_update;
        info.max_update_times = newUpdateInfo.max_update_times;
        info.strategy_version = newUpdateInfo.strategy_version;
        info.priority = newUpdateInfo.priority;
        info.max_update_failed_times = newUpdateInfo.max_update_failed_times;
        info.ext_type = newUpdateInfo.ext_type;
        info.sourceFrom = newUpdateInfo.sourceFrom;

        // info.updated_times = updateInfo.updated_times; 不需要从最新的merge
        // info.update_failed_times = updateInfo.update_failed_times; 不需要从最新的merge
    }

    [self markInfoChanged];

    return info;
}

- (void)markInfoChanged {
    self.needSave = YES;
    self.infoList.last_update_time = NSDate.date.timeIntervalSince1970;
}

- (void)saveAll {
    if (!self.needSave) {
        return;
    }
    BDPLogTagInfo(kUpdateLogTag, @"saveAll");
    NSString *json = self.infoList.toJSONString;
    TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
    [storage setObject:json forKey:kEMAAppUpdateList];
    self.needSave = NO;
}

- (NSTimeInterval)todayTime {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    NSString *dateStr = [dateFormatter stringFromDate:NSDate.date];
    NSDate *date = [dateFormatter dateFromString:dateStr];
    return date.timeIntervalSince1970;
}

- (NSUInteger)allAppUpdatedTimesWithAppInfo:(EMAAppUpdateInfo *)appInfo {
    __block NSUInteger count = 0;
    NSDictionary<NSString *, EMAAppUpdateInfo *> *appInfoList = self.infoList.app_list.copy;
    [appInfoList enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, EMAAppUpdateInfo * _Nonnull obj, BOOL * _Nonnull stop) {
        //只匹配 ext_type 一致的更新信息，隔离 gadget 和 web_offline
        //若 appInfo 为空，则不区分（兼容老逻辑）
        if (appInfo && [appInfo isKindOfClass:[EMAAppUpdateInfo class]]) {
            //ext_type 本地 为空的情况，默认都是小程序（老数据不下发 ext_type）。
            NSString * existedInfoExtType = obj.ext_type ?: @"gadget";
            NSString * appInfoExtType = appInfo.ext_type ?: @"gadget";
            if ([BDPSafeString(appInfoExtType) isEqualToString:
                 BDPSafeString(existedInfoExtType)]) {
                count = count + obj.updated_times;
            }
        } else {
            count = count + obj.updated_times;
        }
    }];
    return count;
}

- (NSArray<EMAAppUpdateInfo *> *)updateInfos {
    NSArray<EMAAppUpdateInfo *> *appInfoList = self.infoList.app_list.allValues;
    appInfoList = [appInfoList sortedArrayUsingComparator:^NSComparisonResult(EMAAppUpdateInfo *  _Nonnull obj1, EMAAppUpdateInfo *  _Nonnull obj2) {
        if (obj1.priority > obj2.priority) {
            return NSOrderedAscending;
        } else if (obj1.priority < obj2.priority) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    return appInfoList;
}

@end
