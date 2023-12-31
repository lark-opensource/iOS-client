//
//  EMAAppUpdateInfo.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/14.
//

#import "EMAAppUpdateInfo.h"
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPModuleEngineType.h>

@interface EMAAppUpdateInfo()

/// 兼容 Push version
@property (nonatomic, copy) NSString *version;

@end

@implementation EMAAppUpdateInfo

+ (NSArray *)arrayOfAppUpdateInfoFromDictionaries:(NSArray *)array error:(NSError **)err {
    return [[self arrayOfModelsFromDictionaries:array error:err] copy];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    if (self = [super initWithDictionary:dict error:err]) {
        if (!self.app_version && self.version) {
            self.app_version = self.version;
        }
    }
    return self;
}

- (NSUInteger)max_update_failed_times {
    if (_max_update_failed_times <= 0) {
        //默认值3
        return 3;
    }
    return _max_update_failed_times;
}

- (BDPUniqueID *)uniqueID {
    //如果应用类型是 web_offline，则构建 webApp 的appId类型。否则返回老的uniqueID构建逻辑
    if ([@"web_offline" isEqualToString:self.ext_type]) {
        return [BDPUniqueID uniqueIDWithAppID:self.app_id identifier:nil versionType:OPAppVersionTypeCurrent appType:BDPTypeWebApp instanceID:@"appUpdateInfo"];
    }
    // 目前仅支持 线上版本、小程序，所以使用 OPAppVersionTypeCurrent 和 BDPTypeNativeApp 配置
    return [BDPUniqueID uniqueIDWithAppID:self.app_id identifier:nil versionType:OPAppVersionTypeCurrent appType:BDPTypeNativeApp];
}

- (NSNumber *)sourceFrom {
    if (!_sourceFrom) {
        _sourceFrom = [NSNumber numberWithInteger:OPMetaHitSourceFromUnknown];
    }
    return _sourceFrom;
}
@end
