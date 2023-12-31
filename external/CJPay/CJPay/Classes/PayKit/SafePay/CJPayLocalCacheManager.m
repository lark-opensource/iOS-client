//
//  CJPayLocalCacheManager.m
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/5/20.
//

#import "CJPayLocalCacheManager.h"
#import "CJPaySDKMacro.h"
#import <malloc/malloc.h>
#import "CJPaySafeManager.h"

NSString *const kCacheFileName = @"CJPaySecCache";
NSString *const kSm4Key = @"K/z8a1ddhWR8Uaz8goXVPg==";

@interface CJPayLocalCacheConfig : NSObject

@property (nonatomic, assign) CGFloat singleFeatureMaxCacheKBSize; // 单特征最大占用空间，单位KB
@property (nonatomic, assign) CGFloat singleFeatureMaxPeriod; // 最大天数

@end

@implementation CJPayLocalCacheConfig

@end

@interface CJPayLocalCacheManager()

@property (nonatomic, strong) CJPayLocalCacheConfig *cacheConfig;
@property (nonatomic, strong) NSMutableDictionary *mmapFeaturesMutableDict;
@property (nonatomic, assign) BOOL hasNewChange;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSTimer *saveTriggerTimer;
@property (nonatomic, strong) id<CJPayEngimaProtocol> engimaEngine;

@end

@implementation CJPayLocalCacheManager

- (instancetype)init {
    self = [super init];
    if (self) {
        CJPayLocalCacheConfig *cacheConfig = [CJPayLocalCacheConfig new];
        cacheConfig.singleFeatureMaxCacheKBSize = 1000;
        cacheConfig.singleFeatureMaxPeriod = 3;
        self.cacheConfig = cacheConfig;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchronize) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSRunLoop currentRunLoop] addTimer:self.saveTriggerTimer forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadCache {
    dispatch_async(self.serialQueue, ^{
        NSError *error = nil;
        if (@available(iOS 11.0, *)) {
            NSString *encryptStr = [[NSUserDefaults standardUserDefaults] objectForKey:kCacheFileName];
            if (!Check_ValidString(encryptStr)) {
                return;
            }
            int *errorCode = malloc(sizeof(int));
            NSString *dataStr = [self.engimaEngine sm4Decrypt:encryptStr key:kSm4Key errorCode:errorCode];
            NSData *data = [dataStr base64DecodeData];
            if (data) {
                NSDictionary *dic = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[CJPayBaseSafeFeature.class, CJPayDeviceFeature.class, CJPayIntentionFeature.class, NSDictionary.class, NSArray.class]] fromData:data error:&error];
                CJPayLogAssert(!error, @"加载信息出错，请查看%@", error);
                [self p_tryReduceCacheAndMerge:dic];
                __block NSInteger newCount = 0;
                [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:NSArray.class]) {
                        newCount += ((NSArray *)obj).count;
                    }
                }];
                [CJMonitor trackService:@"wallet_rd_sec_message" extra:@{@"type": @"local_save", @"feature_count": @(newCount), @"data_size": @(data.length / 1000)}];
            } else {
                [CJMonitor trackService:@"wallet_rd_sec_message" extra:@{@"type": @"cache_exception", @"msg": @"解密失败"}];
            }
        } else {
            // Fallback on earlier versions
        }
    });
}

- (BOOL)appendFeature:(CJPayBaseSafeFeature *)feature {
    NSString *featureName = feature.name;
    if (!Check_ValidString(featureName) || !feature.needPersistence) {
        return NO;
    }
    NSMutableArray *featureArray = [self.mmapFeaturesMutableDict cj_objectForKey:featureName] ?: [NSMutableArray new];
    [featureArray addObject:feature];
    [self.mmapFeaturesMutableDict cj_setObject:featureArray forKey:featureName];
    self.hasNewChange = YES;
    return YES;
}

- (BOOL)appendFeatures:(NSArray *)features {
    __block BOOL result = Check_ValidArray(features);
    [features enumerateObjectsUsingBlock:^(CJPayBaseSafeFeature *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        result &= [self appendFeature:obj];
    }];
    self.hasNewChange = YES;
    return result;
}

- (NSArray<CJPayBaseSafeFeature *> *)allFeaturesFor:(NSString *)name conditionBlock:(BOOL (^)(CJPayBaseSafeFeature * _Nonnull))conditionBlock {
    NSArray *originalArray = [self.mmapFeaturesMutableDict cj_arrayValueForKey:name];
    if (!conditionBlock) {
        return originalArray;
    }
    NSMutableArray *mutableArray = [NSMutableArray new];
    [originalArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (conditionBlock(obj)) {
            [mutableArray addObject:obj];
        }
    }];
    return [mutableArray copy];
}

- (BOOL)synchronize {
    if (!self.hasNewChange) {
        return NO;
    }
    if (@available(iOS 11.0, *)) {
        NSDictionary *cacheDic = [self.mmapFeaturesMutableDict copy];
        dispatch_async(self.serialQueue, ^{
            NSError *error;
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject: cacheDic ?: @{} requiringSecureCoding:YES error:&error];
            NSString *dataStr = [data base64EncodedStringWithOptions:0];
            int *errorCode = malloc(sizeof(int));
            NSString *encryptStr = [self.engimaEngine sm4Encrypt:dataStr key:kSm4Key errorCode:errorCode];
            if (Check_ValidString(encryptStr)) {
                [[NSUserDefaults standardUserDefaults] setObject:encryptStr forKey:kCacheFileName];
                CJPayLogAssert(!error, @"保存失败，error信息%@", error.description);
            } else {
                [CJMonitor trackService:@"wallet_rd_sec_message" extra:@{@"type": @"cache_exception", @"msg": @"加密失败"}];
            }
        });
    } else {
        return NO;
    }
 
    self.hasNewChange = NO;
    return YES;
}

- (void)p_tryReduceCacheAndMerge:(NSDictionary *)cacheDic {
    NSMutableDictionary *reduceDict = [NSMutableDictionary new];
    NSTimeInterval curTime = [[NSDate new] timeIntervalSince1970];
    __block BOOL needClean = NO;
    [cacheDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        size_t objectSize = malloc_size((__bridge const void *)obj);
        if (obj && [obj isKindOfClass:NSArray.class]) {
            NSMutableArray *objArray = (NSMutableArray *)[obj mutableCopy];
            if (objArray.count > 2 && objectSize > self.cacheConfig.singleFeatureMaxCacheKBSize * 1000) {
                [objArray removeObjectsInRange:NSMakeRange(0, objArray.count / 2)];
                needClean = YES;
            }
            // 简化处理，在进行一次判断，主要解决在初一2之后仍然大于self.cacheConfig.singleFeatureMaxCacheKBSize * 1000的情况
            objectSize = malloc_size((__bridge const void *)objArray);
            if (objArray.count > 2 && objectSize > self.cacheConfig.singleFeatureMaxCacheKBSize * 1000) {
                [objArray removeObjectsInRange:NSMakeRange(0, objArray.count / 2)];
                needClean = YES;
            }
            [[objArray copy] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:CJPayIntentionFeature.class]) {
                    CJPayIntentionFeature *feature = (CJPayIntentionFeature *)obj;
                    if (feature.timeStamp < curTime - self.cacheConfig.singleFeatureMaxPeriod * 24 * 3600) {
                        [objArray removeObject:obj];
                        needClean = YES;
                    };
                }
            }];
            [reduceDict cj_setObject:objArray forKey:key];
        }
    }];
    if (needClean) { // 记录清理的埋点信息
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:reduceDict];
        __block NSInteger newCount = 0;
        [reduceDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:NSArray.class]) {
                newCount += ((NSArray *)obj).count;
            }
        }];
        __block NSInteger oldCount = 0;
        [cacheDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:NSArray.class]) {
                oldCount += ((NSArray *)obj).count;
            }
        }];
        [CJMonitor trackService:@"wallet_rd_sec_message" extra:@{@"type": @"local_clean", @"feature_count": @(newCount), @"data_size": @(data.length / 1000), @"old_feature_count": @(oldCount)}];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [reduceDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray *  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.count >= 1) {
                NSMutableArray *mutableArray = [[self.mmapFeaturesMutableDict btd_arrayValueForKey:key] mutableCopy] ?: [NSMutableArray new];
                [mutableArray addObjectsFromArray:obj];
                [self.mmapFeaturesMutableDict cj_setObject:mutableArray forKey:key];
            }
        }];
    });
}

- (id<CJPayEngimaProtocol>)engimaEngine {
    if (!_engimaEngine) {
        _engimaEngine = [CJPaySafeManager buildEngimaEngine:@"Sec"];
    }
    return _engimaEngine;
}

- (dispatch_queue_t)serialQueue {
    if (!_serialQueue) {
        _serialQueue = dispatch_queue_create("cjpay.sec.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _serialQueue;
}

- (NSMutableDictionary *)mmapFeaturesMutableDict {
    if (!_mmapFeaturesMutableDict) {
        _mmapFeaturesMutableDict = [NSMutableDictionary new];
    }
    return _mmapFeaturesMutableDict;
}

- (NSTimer *)saveTriggerTimer {
    if (!_saveTriggerTimer) {
        // 每隔两分钟出发一次保存
        _saveTriggerTimer = [NSTimer timerWithTimeInterval:1 * 60 target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(synchronize) userInfo:nil repeats:YES];
    }
    return _saveTriggerTimer;
}

@end
