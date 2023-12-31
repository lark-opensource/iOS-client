//
//  TTKitchenSyncer+SessionDiff.m
//  TTKitchen-Browser-Core-SettingsSyncer-Swift
//
//  Created by Peng Zhou on 2020/7/7.
//

#import "TTKitchenSyncer+SessionDiff.h"
#import "TTKitchenManager.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSDate+BTDAdditions.h>
#import <ByteDanceKit/NSTimer+BTDAdditions.h>
#import <ByteDanceKit/UIApplication+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <Foundation/Foundation.h>
#import <Heimdallr/HMDInjectedInfo.h>
#import <BDMonitorProtocol/BDMonitorProtocol.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <BDAssert/BDAssert.h>
#import <objc/runtime.h>

#define KITCHEN_DIRECTORY_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/TTKitchen"]

NSString * const kTTKitchenSettingsDiffs = @"kTTKitchenSettingsDiffs";
NSString * const kTTKitchenSettingsDiffTimestamps = @"kTTKitchenSettingsDiffTimestamps";

static NSString * const kHMDInjectedInfoDiffSettingsKey = @"diff_settings";
static NSString * const kHMDInjectedInfoDiffSettingsTimestampKey = @"diff_settings_timestamp";

@implementation TTKitchenSyncer (SessionDiff)

TTRegisterKitchenFunction() {
    TTKConfigDictionary(kTTKitchenSettingsDiffs, @"Settings diffs generated when synchronizing settings.", @{});
    TTKConfigDictionary(kTTKitchenSettingsDiffTimestamps, @"Timestamp of keys in settings diffs.", @{});
}

- (void)injectSettingsDiffsIfNeeded {
    NSDictionary *diffs = [TTKitchen getDictionary:kTTKitchenSettingsDiffs];
    if ([diffs count] > 0) {
        NSMutableString *injectDiffString = NSMutableString.new;
        [diffs enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *diffString = nil;
            if ([NSJSONSerialization isValidJSONObject:obj]) {
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:kNilOptions error:nil];
                diffString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
            else {
                diffString = [obj description];
            }
            [injectDiffString appendFormat:@"%@:%@\n", key, diffString];
        }];
        btd_dispatch_async_on_main_queue(^{
            [[HMDInjectedInfo defaultInfo] setCustomContextValue:[injectDiffString copy] forKey:kHMDInjectedInfoDiffSettingsKey];
        });
    }
    
    // The contextValue's format should be same with the Android's format.
    NSDictionary<NSString *, NSNumber *> *diffTimeStamps = [TTKitchen getDictionary:kTTKitchenSettingsDiffTimestamps];
    if ([diffTimeStamps count] > 0) {
        NSMutableString * injectDiffTimeStampString = NSMutableString.new;
        [diffTimeStamps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull timestamp, BOOL * _Nonnull stop) {
            [injectDiffTimeStampString appendFormat:@"%@:%f,\n", key, timestamp.doubleValue * 1000];
        }];
        btd_dispatch_async_on_main_queue(^{
            [[HMDInjectedInfo defaultInfo] setCustomContextValue:[injectDiffTimeStampString copy] forKey:kHMDInjectedInfoDiffSettingsTimestampKey];
        });
    }
}

- (void)injectKeyAccessTimeToDiffAsyncWithInterval:(NSTimeInterval)injectInterval {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.shouldGenerateSessionDiff && self.shouldInjectDiffToHMDInjectedInfo && !self.accessTimeInjectTimer) {
            self.accessTimeInjectTimer = [NSTimer btd_scheduledTimerWithTimeInterval:injectInterval weakTarget:self selector:@selector(_injectKeyAccessTimeToDiffs) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] run];
        }
    });
}

- (void)_injectKeyAccessTimeToDiffs {
    NSDictionary <NSString *, NSNumber *> *keyAccessTime = TTKitchen.keyAccessTime;
    // The diff_settings_timestamp's format should be same with the Android's format.
    NSDictionary * diffTimeStamps = [TTKitchen getDictionary:kTTKitchenSettingsDiffTimestamps];
    NSMutableString * diffTimeStampString = NSMutableString.new;
    [diffTimeStamps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull timestamp, BOOL * _Nonnull stop) {
        [diffTimeStampString appendFormat:@"%@:%f,", key, timestamp.doubleValue * 1000];
        NSNumber *accessTimeStamp = [keyAccessTime btd_numberValueForKey:key];
        if (accessTimeStamp) {
            [diffTimeStampString appendFormat:@"%f", accessTimeStamp.doubleValue * 1000];
        }
        [diffTimeStampString appendString:@"\n"];
    }];
    btd_dispatch_async_on_main_queue(^{
        [[HMDInjectedInfo defaultInfo] setCustomContextValue:[diffTimeStampString copy] forKey:kHMDInjectedInfoDiffSettingsTimestampKey];
    });
}

- (void)_updateSettingsDiff:(NSDictionary *)settingsDiff {
    NSMutableDictionary *diffs = [NSMutableDictionary dictionaryWithDictionary:[TTKitchen getDictionary:kTTKitchenSettingsDiffs]];
    [diffs addEntriesFromDictionary:settingsDiff];
    
    // 删除diff中的过期Key
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSMutableDictionary * diffTimeStamps = [NSMutableDictionary dictionaryWithDictionary:[TTKitchen getDictionary:kTTKitchenSettingsDiffTimestamps]];
    [[diffs allKeys] enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *timeStamp = [diffTimeStamps btd_numberValueForKey:key];
        if (timeStamp && (currentTime - timeStamp.doubleValue > self.diffKeepTime)) {
            [diffs removeObjectForKey:key];
            [diffTimeStamps removeObjectForKey:key];
        }
    }];
    [TTKitchen setDictionary:diffs forKey:kTTKitchenSettingsDiffs];
    [TTKitchen setDictionary:diffTimeStamps forKey:kTTKitchenSettingsDiffTimestamps];
}

- (void)_updateTimestampsWithSettingsDiff:(NSDictionary *)settingsDiff {
    NSNumber * timestamp = [settingsDiff btd_numberValueForKey:@"timestamp"];
    if (timestamp) {
        NSMutableDictionary * diffTimestamps = [NSMutableDictionary dictionaryWithDictionary:[TTKitchen getDictionary:kTTKitchenSettingsDiffTimestamps]];
        [settingsDiff enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [diffTimestamps setObject:timestamp forKey:key];
        }];
        [diffTimestamps removeObjectForKey:@"timestamp"];
        [TTKitchen setDictionary:diffTimestamps forKey:kTTKitchenSettingsDiffTimestamps];
    }
}

- (void)_reportSettingsDiffWithHMDTrackerService:(NSDictionary *)settingsDiff {
    NSString *diffKeys = [NSString stringWithFormat:@"[%@]",[settingsDiff.allKeys componentsJoinedByString:@","]];
    [BDMonitorProtocol hmdTrackService:@"settings_diff_monitor" metric:@{
        @"settings_diff_count":@([settingsDiff count])
    } category:@{
        @"settings_diff_keys":diffKeys
    } extra:@{}];
}

- (void)_reportSettingsDiffWithALog:(NSDictionary *)settingsDiff {
    NSString *versionCode = [[UIApplication btd_bundleVersion] stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString *diffKeys = [NSString stringWithFormat:@"[%@]",[settingsDiff.allKeys componentsJoinedByString:@","]];
    NSString *diffTag = [NSString stringWithFormat:@"settings_diff_keys_%@", versionCode];
    BDALOG_PROTOCOL_INFO_TAG(diffTag, @"%@", diffKeys);
}

- (NSMutableDictionary *)_generateSessionDiffWithdiff:(NSMutableDictionary *)diff key:(NSString *)key object:(id)anObject type:(TTKitchenModelType)type {
    switch (type) {
        case TTKitchenModelTypeString:{
            if ([anObject isKindOfClass:[NSString class]]) {
                if (![[TTKitchen getString:key] isEqualToString:(NSString *)anObject]) {
                    [diff btd_setObject:anObject forKey:key];
                }
            } else {
                BDAssert(NO, @"Value of key:%@ does not match with the required type. String is needed", key);
            }
        }
            break;
        case TTKitchenModelTypeBOOL: {
            if ([(NSNumber *)anObject respondsToSelector:@selector(boolValue)]) {
                if ([TTKitchen getBOOL:key] != [(NSNumber *)anObject boolValue]) {
                    [diff btd_setObject:anObject forKey:key];
                }
            } else {
                BDAssert(NO, @"Value of key:@%@ does not match with the required type. Bool is needed", key);
            }
        }
            break;
        case TTKitchenModelTypeFloat: {
            if ([(NSNumber *)anObject respondsToSelector:@selector(doubleValue)]) {
                if (fabs([TTKitchen getFloat:key] - [(NSNumber *) anObject doubleValue]) > 0.01) {
                    [diff btd_setObject:anObject forKey:key];
                }
            } else {
                 BDAssert(NO, @"Value of key:%@ does not match with the required type. Float is needed", key);
            }
        }
            break;
        case TTKitchenModelTypeArray: {
            if ([anObject isKindOfClass:[NSArray class]]) {
                NSSet *arrSet = [NSSet setWithArray:anObject];
                NSSet *kitchenArrSet = [NSSet setWithArray:[TTKitchen getArray:key]];
                if (![arrSet isEqualToSet:kitchenArrSet]) {
                    [diff btd_setObject:anObject forKey:key];
                }
            } else {
                BDAssert(NO, @"Value of key:%@ does not match with the required type. Array is needed.", key);
            }
        }
            break;
        case TTKitchenModelTypeDictionary: {
            NSDictionary *dic = (NSDictionary *)anObject;
            if ([dic isKindOfClass:[NSDictionary class]]) {
                NSDictionary *kitchenDic = [TTKitchen getDictionary:key];
                if (![dic isEqualToDictionary:kitchenDic]) {
                    [diff btd_setObject:dic forKey:key];
                }
            } else {
                BDAssert(NO, @"Value of key:%@ does not match with the required type. Dictionary is needed.", key);
            }
        }
            break;
        case TTKitchenModelTypeModel:
            break;
        case TTKitchenModelTypeStringArray: {
            if ([anObject isKindOfClass:[NSArray class]]) {
                NSSet *arrSet = [NSSet setWithArray:anObject];
                NSSet *kitchenArrSet = [NSSet setWithArray:[TTKitchen getStringArray:key]];
                if (![arrSet isEqualToSet:kitchenArrSet]) {
                    [diff btd_setObject:anObject forKey:key];
                }
            } else {
                BDAssert(NO, @"Value of key:%@ does not match with the required type. Array is needed.", key);
            }
        }
            break;
        case TTKitchenModelTypeBOOLArray: {
            if ([anObject isKindOfClass:[NSArray class]]) {
                NSSet *arrSet = [NSSet setWithArray:anObject];
                NSSet *kitchenArrSet = [NSSet setWithArray:[TTKitchen getBOOLArray:key]];
                if (![arrSet isEqualToSet:kitchenArrSet]) {
                    [diff btd_setObject:anObject forKey:key];
                }
            } else {
                BDAssert(NO, @"Value of key:%@ does not match with the required type. Array is needed.", key);
            }
        }
            break;
        case TTKitchenModelTypeFloatArray: {
            if ([anObject isKindOfClass:[NSArray class]]) {
                NSSet *arrSet = [NSSet setWithArray:anObject];
                NSSet *kitchenArrSet = [NSSet setWithArray:[TTKitchen getFloatArray:key]];
                if (![arrSet isEqualToSet:kitchenArrSet]) {
                    [diff btd_setObject:anObject forKey:key];
                }
            } else {
                BDAssert(NO, @"Value of key:%@ does not match with the required type. Array is needed.", key);
            }
        }
            break;
        case TTKitchenModelTypeArrayArray: {
            if ([anObject isKindOfClass:[NSArray class]]) {
                NSSet *arrSet = [NSSet setWithArray:anObject];
                NSSet *kitchenArrSet = [NSSet setWithArray:[TTKitchen getArrayArray:key]];
                if (![arrSet isEqualToSet:kitchenArrSet]) {
                    [diff btd_setObject:anObject forKey:key];
                }
            } else {
                BDAssert(NO, @"Value of key:%@ does not match with the required type. Array is needed.", key);
            }
        }
            break;
        case TTKitchenModelTypeDictionaryArray: {
            if ([anObject isKindOfClass:[NSArray class]]) {
                NSSet *arrSet = [NSSet setWithArray:anObject];
                NSSet *kitchenArrSet = [NSSet setWithArray:[TTKitchen getDictionaryArray:key]];
                if (![arrSet isEqualToSet:kitchenArrSet]) {
                    [diff btd_setObject:anObject forKey:key];
                }
            } else {
                BDAssert(NO, @"Value of key:%@ does not match with the required type. Array is needed.", key);
            }
        }
            break;
        default:
            break;
    }
    
    return diff;
}

- (NSDictionary *)generateSessionDiffWithSettingsIfNeeded:(NSDictionary *)settings {
    if (!self.shouldInjectDiffToHMDInjectedInfo) {
        // 如果HMDInjectedInfo注入开关关闭，清空settings diff的本地及上报缓存。
        if ([TTKitchen hasCacheForKey:kTTKitchenSettingsDiffs]) {
            [TTKitchen setDictionary:nil forKey:kTTKitchenSettingsDiffs];
            [[HMDInjectedInfo defaultInfo] removeCustomContextKey:kHMDInjectedInfoDiffSettingsKey];
        }
        if ([TTKitchen hasCacheForKey:kTTKitchenSettingsDiffTimestamps]) {
            [TTKitchen setDictionary:nil forKey:kTTKitchenSettingsDiffTimestamps];
            [[HMDInjectedInfo defaultInfo] removeCustomContextKey:kHMDInjectedInfoDiffSettingsTimestampKey];
        }
    }
    if (!self.shouldGenerateSessionDiff || !settings || settings.count == 0) {
        return @{};
    }
    
    NSArray *arr = [TTKitchen allKitchenModels];
    __block NSMutableDictionary *diff = NSMutableDictionary.dictionary;
    [arr enumerateObjectsUsingBlock:^(TTKitchenModel * model, NSUInteger idx, BOOL * _Nonnull stop) {
        id settingValue = nil;
        NSString *key = model.key;
        if ([key containsString:@"."]) {
            @try {
                settingValue = [settings valueForKeyPath:key];
            } @catch (NSException *exception) {
                BDAssert(NO, @"Unexpected keypath in key = %@. Check the input dictionary. %@", key, exception.userInfo ?: @"");
            }
        } else {
            settingValue = [settings objectForKey:key];
        }
        
        if (settingValue) {
            [self _generateSessionDiffWithdiff:diff key:key object:settingValue type:model.type];
        }

    }];
    
    if (diff.count > 0) {
        [diff setValue:@([[NSDate date] timeIntervalSince1970]) forKey:@"timestamp"];
        [diff setValue:[TTKitchen getString:@"kTTKitchenContextData"] forKey:@"ctx_info"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (self.shouldInjectDiffToHMDInjectedInfo) {
                [self _updateSettingsDiff:diff];
                [self _updateTimestampsWithSettingsDiff:diff];
                [self injectSettingsDiffsIfNeeded];
            }
            if (self.shouldReportSettingsDiffWithHMDTrackService) {
                [self _reportSettingsDiffWithHMDTrackerService:diff];
            }
            if (self.shouldReportSettingsDiffWithALog) {
                [self _reportSettingsDiffWithALog:diff];
            }
        });
    }
    return diff;
    
}

- (void)setAccessTimeInjectTimer:(NSTimer *)accessTimeInjectTimer {
    objc_setAssociatedObject(self, @selector(accessTimeInjectTimer), accessTimeInjectTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimer *)accessTimeInjectTimer {
    return objc_getAssociatedObject(self, _cmd);
}

@end
