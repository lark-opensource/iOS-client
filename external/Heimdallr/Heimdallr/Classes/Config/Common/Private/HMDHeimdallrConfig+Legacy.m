//
//  HMDHeimdallrConfig+Legacy.m
//  Heimdallr
//
//  Created by bytedance on 2020/3/26.
//

#import "HMDHeimdallrConfig+Legacy.h"
#import "HMDConfigManager.h"
#import "HeimdallrUtilities.h"
#import <objc/runtime.h>

@implementation HMDHeimdallrConfig (Legacy)

- (instancetype)initWithAppId:(NSString *)appId defaultConfig:(NSDictionary *)dic {
    // 清理过期本地文件
    [self.class _removeExpiredConfigIfNeeded:appId];
    
    // 优先使用当前本地config
    NSString *configPath = [[HMDConfigManager sharedInstance] configPathWithAppID:appId];
    NSData *jsonData = [NSData dataWithContentsOfFile:configPath];
    if (jsonData != nil) {
        self = [self initWithJSONData:jsonData];
        if (self) {
            return self;
        }
    }
    
    // 生成默认配置
    HMDHeimdallrConfig *currentConfig = [self initWithDictionary:dic];
    currentConfig.isDefault = YES;
    return currentConfig;
}

+ (void)_removeExpiredConfigIfNeeded:(NSString *)appID {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *fileName = [NSString stringWithFormat:@"%@_config.json", appID];
        NSString *filePath = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:fileName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
        }
    });
}

#pragma mark - Getter & Setter

- (BOOL)isDefault {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setIsDefault:(BOOL)isDefault {
    objc_setAssociatedObject(self, @selector(isDefault), @(isDefault), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
