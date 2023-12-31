//
//  ECOConfig.m
//  EEMicroAppSDK
//
//  Created by Meng on 2021/3/22.
//

#import "ECOConfig.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOProbeMeta/ECOProbeMeta-Swift.h>
#import <ECOProbe/ECOProbe-Swift.h>
#import <ECOProbe/OPMonitor.h>
#import <ECOInfra/BDPLog.h>
#import <pthread/pthread.h>
#import <ECOInfra/ECOInfra-Swift.h>

@interface ECOConfig()

@property (nonatomic, copy) NSDictionary<NSString *, id> *configData;
@property (nonatomic, strong) NSString *configID;

@property (nonatomic, copy) NSNumber *updateTimeStamp;
@property (nonatomic, assign) pthread_rwlock_t timeStampLock;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *reportConfigTimeStamps;
@property (nonatomic, assign) pthread_rwlock_t timeStampDictionaryLock;

@end

@implementation ECOConfig

# pragma mark - 生命周期

- (instancetype)initWithConfigID:(NSString *)configID {
    if (self = [super init]) {
        _configID = configID;
        // lint:disable:next lark_storage_check
        NSString *json = [NSUserDefaults.standardUserDefaults objectForKey:self.configID];
        if (!BDPIsEmptyString(json)) {
            _configData = json.JSONDictionary;
        }
        if (!_configData || _configData.count == 0) {
            _configData = @{};
            BDPLogWarn(@"init ECOCOnfig with empty config.");
        }
        _updateTimeStamp = @0;
        _reportConfigTimeStamps = [[NSMutableDictionary alloc] init];
        pthread_rwlock_init(&_timeStampLock, NULL);
        pthread_rwlock_init(&_timeStampDictionaryLock, NULL);
    }
    return self;
}

- (void)dealloc {
    pthread_rwlock_destroy(&_timeStampLock);
    pthread_rwlock_destroy(&_timeStampDictionaryLock);
}

# pragma mark - 私有属性 getter setter

@synthesize updateTimeStamp = _updateTimeStamp;
// updateTimeStamp setter
- (void)setUpdateTimeStamp:(NSNumber *)updateTimeStamp {
    pthread_rwlock_wrlock(&_timeStampLock);
    _updateTimeStamp = updateTimeStamp;
    pthread_rwlock_unlock(&_timeStampLock);
}
// updateTimeStamp getter
- (NSNumber *)updateTimeStamp {
    pthread_rwlock_rdlock(&_timeStampLock);
    NSNumber *tempUpdateTimeStamp = _updateTimeStamp;
    pthread_rwlock_unlock(&_timeStampLock);
    return tempUpdateTimeStamp;
}

@synthesize reportConfigTimeStamps = _reportConfigTimeStamps;
// reportConfigTimeStamps setter
- (void)setReportConfigTimeStamps:(NSMutableDictionary<NSString *,NSNumber *> *)reportConfigTimeStamps {
    pthread_rwlock_wrlock(&_timeStampDictionaryLock);
    [_reportConfigTimeStamps addEntriesFromDictionary:[reportConfigTimeStamps copy]];
    pthread_rwlock_unlock(&_timeStampDictionaryLock);
}
// reportConfigTimeStamps key-value setter
- (void)setReportConfigTimeStampsValue:(NSNumber *)value forKey:(NSString *)key {
    pthread_rwlock_wrlock(&_timeStampDictionaryLock);
    _reportConfigTimeStamps[key] = value;
    pthread_rwlock_unlock(&_timeStampDictionaryLock);
}
// reportConfigTimeStamps getter
- (NSMutableDictionary<NSString *, NSNumber *> *)reportConfigTimeStamps {
    pthread_rwlock_rdlock(&_timeStampDictionaryLock);
    NSMutableDictionary<NSString *, NSNumber *> *tempReportConfigTimeStamps = [_reportConfigTimeStamps mutableCopy];
    pthread_rwlock_unlock(&_timeStampDictionaryLock);
    return tempReportConfigTimeStamps;
}

# pragma mark - config interface

- (void)updateConfigData:(NSDictionary<NSString *, id> *)configData {
    self.configData = configData;
    // lint:disable:next lark_storage_check
    [NSUserDefaults.standardUserDefaults setObject:self.configData.JSONRepresentation forKey:self.configID];
    [self setUpdateTimeStamp:@([[NSDate date] timeIntervalSince1970])];
}

- (id)getConfigValueForKey:(NSString *)key resolver:(id (^)(id _Nullable))resolver {
    return [self getConfigValueForKey:key needLatest:NO resolver:resolver];
}
- (id)getConfigValueForKey:(NSString *)key needLatest:(BOOL)needLatest resolver:(id (^)(id _Nullable))resolver {
    //优先从LarkSetting 中获取对应的配置，默认从静态数据中获取。保证飞书生命周期内数据一致
    id larkSettingValue = [self valueFromLarkSettingsWithKey:key needLatest:needLatest];
    id value = resolver(larkSettingValue);
    // 如果配置为空
    if (!value) {
        NSNumber *tempUpdateTimeStamp = [self updateTimeStamp];
        NSMutableDictionary<NSString *, NSNumber *> *tempReportConfigTimeStamps = [self reportConfigTimeStamps];
        if (tempReportConfigTimeStamps[key] == nil) {
            // 根据 (是否记录过key的上报时间) 判断 是否需要上报，如果未记录过（未取过该config），则上报并记录
            OPMonitorEvent *event = OPNewMonitorEvent(EPMClientOpenPlatformCommonConfigCode.config_value_empty);
            event.addCategoryValue(@"config_key", key)
                 .addCategoryValue(@"config_ts", tempUpdateTimeStamp)
                 .flush();
        } else {
            if (tempReportConfigTimeStamps[key].intValue != tempUpdateTimeStamp.intValue) {
                // 根据 该key上次读取空上报记录的更新时间戳 与 配置更新时间戳 是否相同 判断 是否需要上报
                OPMonitorEvent *event = OPNewMonitorEvent(EPMClientOpenPlatformCommonConfigCode.config_value_empty);
                event.addCategoryValue(@"config_key", key)
                    .addCategoryValue(@"config_ts", tempUpdateTimeStamp)
                    .flush();
            }
        }
        // 置 该key的时间戳 为 此次更新周期时间戳
        [self setReportConfigTimeStampsValue:tempUpdateTimeStamp forKey:key];
    }
    return value;
}

#pragma mark - public
- (NSArray *)getArrayValueForKey:(NSString *)key {
    return  [self getArrayValueForKey:key needLastest:FALSE];
}

- (NSArray *)getLatestArrayValueForKey:(NSString *)key {
    return [self getArrayValueForKey:key needLastest:TRUE];;
}

- (NSArray *)getArrayValueForKey:(NSString *)key needLastest:(BOOL)needLastest {
    return [self getConfigValueForKey: key needLatest: needLastest resolver: ^id(id _Nullable larkSettingValue){
        id value = larkSettingValue ?: [self.configData objectForKey:key];
        if (!value) {
            return nil;
        }

        // 兼容 minaConfig 与 settingsConfig 的类型判断
        if ([value isKindOfClass: [NSArray class]]) {
            return value;
        } else if ([value isKindOfClass:[NSString class]]) {
            NSData *jsonData = [value dataUsingEncoding: NSUTF8StringEncoding];
            NSError *err;
            id obj = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
            if (!obj || err || ![obj isKindOfClass:[NSArray class]]) {
                BDPLogWarn(@"Get array from settings config failed! key: %@, error: %@", key, err);
                return nil;
            }
            return obj;
        } else {
            BDPLogWarn(@"Get array from settings config failed! Unrecognized value type in config. key: %@.", key);
            return nil;
        }
    }];
}

- (NSDictionary<NSString *, id> *)getDictionaryValueForKey:(NSString *)key {
    return [self getDictionaryValueForKey:key needLastest:FALSE];
}

- (NSDictionary<NSString *, id> *)getLatestDictionaryValueForKey:(NSString *)key {
    return [self getDictionaryValueForKey:key needLastest:TRUE];
}

- (NSDictionary<NSString *, id> *)getDictionaryValueForKey:(NSString *)key needLastest:(BOOL)needLastest {
    return [self getConfigValueForKey: key needLatest: needLastest  resolver: ^id(id _Nullable larkSettingValue){
        id value = larkSettingValue ?: [self.configData objectForKey:key];
        if (!value) {
            return nil;
        }
        // 兼容 minaConfig 与 settingsConfig 的类型判断
        if ([value isKindOfClass: [NSDictionary class]]) {
            return value;
        } else if ([value isKindOfClass:[NSString class]]) {
            NSData *jsonData = [value dataUsingEncoding: NSUTF8StringEncoding];
            NSError *err;
            id obj = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
            if (!obj || err || ![obj isKindOfClass:[NSDictionary class]]) {
                BDPLogWarn(@"Get dictionary config failed! key: %@, error: %@", key, err);
                return nil;
            }
            return obj;
        } else {
            BDPLogWarn(@"Get dictionary config failed! Unrecognized value type in config. key: %@", key);
            return nil;
        }
    }];
}

- (NSString *)getStringValueForKey:(NSString *)key {
    return [self getConfigValueForKey: key resolver:^id(id _Nullable larkSettingValue){
        return BDPIsEmptyString(larkSettingValue) ? [self.configData bdp_stringValueForKey:key] : larkSettingValue;
    }];
}

// 以下基础类型值暂不上报读取结果
- (BOOL)getBoolValueForKey:(NSString *)key {
    return [self.configData bdp_boolValueForKey2:key];
}

- (int)getIntValueForKey:(NSString *)key {
    return [self.configData bdp_intValueForKey:key];
}

- (double)getDoubleValueForKey:(NSString *)key {
    return [self.configData bdp_doubleValueForKey:key];
}

- (nullable NSString *)getSerializedStringValueForKey:(NSString *)key {
    return [self getConfigValueForKey:key resolver:^id(id _Nullable larkSettingValue){
        id obj = larkSettingValue ?: [self.configData objectForKey:key];
        if (!obj) {
            BDPLogError(@"Get settings config failed! Failed! value is nil! key: %@", key);
            return nil;
        }
        if ([obj isKindOfClass:[NSString class]]) {
            return obj;
        }
        if ([obj isKindOfClass:[NSNumber class]]) {
            return [obj stringValue];
        }
        NSError *err;
        NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&err];
        if (!data || err) {
            BDPLogError(@"Get settings config failed! key: %@, error: %@", key, err);
            return nil;
        }
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }];
}

@end
