//
//  CJPayJsonParseTracker.m
//  Pods
//
//  Created by 尚怀军 on 2022/6/13.
//

#import "CJPayJsonParseTracker.h"
#import "CJPaySDKMacro.h"
#import "CJPaySettingsManager.h"

@interface CJPayJsonParseTracker()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *classParseNumDic;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *classParseTimeDic;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *classSizeDic;

@end

@implementation CJPayJsonParseTracker

+ (instancetype)sharedInstance {
    static CJPayJsonParseTracker *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayJsonParseTracker alloc] init];
    });
    return manager;
}

- (void)recordParseProcessWithClassName:(NSString *)className
                               costTime:(NSTimeInterval)costTime
                               modelDic:(NSDictionary *)modelDic {
    if (!Check_ValidString(className)) {
        return;
    }
    
    if (![CJPaySettingsManager shared].currentSettings.performanceMonitorIsOpened) {
        return;
    }
    
    [self p_calculateSizeOfDic:modelDic
                    completion:^(NSUInteger size) {
        NSTimeInterval currentTotalCostTime = [self.classParseTimeDic cj_doubleValueForKey:className];
        int currentParseNum = [self.classParseNumDic cj_intValueForKey:className];
        int currentTotalSize = [self.classSizeDic cj_intValueForKey:className];
        currentTotalCostTime += costTime;
        currentParseNum += 1;
        currentTotalSize += size;
        
        // 更新model解析总耗时、总次数以及总大小
        [self.classParseTimeDic cj_setObject:@(currentTotalCostTime)
                                      forKey:className];
        [self.classParseNumDic cj_setObject:@(currentParseNum)
                                     forKey:className];
        [self.classSizeDic cj_setObject:@(currentTotalSize)
                                 forKey:className];
    }];
}

- (void)syncModelParseTime {
    [self.classParseTimeDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        NSTimeInterval currentTotalCostTime = [self.classParseTimeDic cj_doubleValueForKey:CJString(key)];
        int currentParseNum = [self.classParseNumDic cj_intValueForKey:CJString(key)];
        int currentTotalSize = [self.classSizeDic cj_intValueForKey:CJString(key)];
        NSTimeInterval averageCostTime = (currentTotalCostTime * 1000) / currentParseNum;
        if (currentParseNum > 0) {
            [CJTracker event:@"wallet_rd_json_parser_info"
                      params:@{@"type": @"json2obj",
                               @"className": CJString(key),
                               @"time": @(averageCostTime),
                               @"size": @(currentTotalSize / currentParseNum)}];
        }
    }];
    
    [self.classParseNumDic removeAllObjects];
    [self.classParseTimeDic removeAllObjects];
    [self.classSizeDic removeAllObjects];
}

- (void)p_calculateSizeOfDic:(NSDictionary *)modelDic
                  completion:(void(^)(NSUInteger))completion {
    if (!modelDic) {
        CJ_CALL_BLOCK(completion, 0);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *dicData = [NSJSONSerialization dataWithJSONObject:modelDic options:0 error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            CJ_CALL_BLOCK(completion, [dicData length]);
        });
    });
}

- (NSMutableDictionary<NSString *,NSNumber *> *)classParseNumDic {
    if (!_classParseNumDic) {
        _classParseNumDic = [NSMutableDictionary new];
    }
    return _classParseNumDic;
}

- (NSMutableDictionary<NSString *,NSNumber *> *)classParseTimeDic {
    if (!_classParseTimeDic) {
        _classParseTimeDic = [NSMutableDictionary new];
    }
    return _classParseTimeDic;
}

- (NSMutableDictionary<NSString *,NSNumber *> *)classSizeDic {
    if (!_classSizeDic) {
        _classSizeDic = [NSMutableDictionary new];
    }
    return _classSizeDic;
}

@end
