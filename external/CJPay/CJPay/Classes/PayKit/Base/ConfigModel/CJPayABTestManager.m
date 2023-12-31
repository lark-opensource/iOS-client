//
//  CJPayABTestManager.m
//  Pods
//
//  Created by 孟源 on 2022/5/19.
//

#import "CJPayABTestManager.h"
#import "CJPayABTestNewPlugin.h"
#import "CJPaySDKMacro.h"


@implementation CJPayABTestManager

+ (instancetype)sharedInstance {
    static CJPayABTestManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayABTestManager alloc] init];
    });
    return manager;
}

- (NSString *)getABTestValWithKey:(NSString *)key {
    return [self getABTestValWithKey:key exposure:YES];
}

- (NSString *)getABTestValWithKey:(NSString *)key exposure:(BOOL)exposure {
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayABTestNewPlugin)) {
        return [CJ_OBJECT_WITH_PROTOCOL(CJPayABTestNewPlugin) getABTestValWithKey:key exposure:exposure];
    } else {
//        CJPayLogAssert(NO, @"未实现CJPayABTestNewPlugin的对应方法");
        return nil;
    }
}

- (NSDictionary *)getExperimentKeyValueDic {
    __block NSMutableDictionary *experimentKeyValueDic = [NSMutableDictionary new];
    
    @CJWeakify(self)
    [self.libraKeyArray enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        // 不曝光获取实验数据
        NSString *value = [self getABTestValWithKey:CJString(key) exposure:NO];
        if (Check_ValidString(value)) {
            [experimentKeyValueDic cj_setObject:value forKey:CJString(key)];
        }
    }];
    
    return [experimentKeyValueDic copy];
}

#pragma mark - getter & setter
- (NSMutableArray<NSString *> *)libraKeyArray {
    if (!_libraKeyArray) {
        _libraKeyArray = [NSMutableArray new];
    }
    return _libraKeyArray;
}


@end
