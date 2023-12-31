//
//  TTVideoEngineSettings.m
//  TTVideoEngine
//
//  Created by 黄清 on 2021/5/26.
//

#import "TTVideoEngineSettings.h"
#import <VCVodSettings/VodSettingsConfigEnv.h>
#include "TTVideoEngine+Private.h"
#include "TTVideoEngineKeys.h"
#include "TTVideoEngineNetwork.h"
#include <TTPlayerSDK/TTAVPlayer.h>
#include "TTVideoEngine+Preload.h"

@interface TTVideoEngineSettings ()
@property (nonatomic, copy) NSString *playerVersion;
@property (nonatomic, copy) NSString *mdlVersion;
@property (nonatomic, copy) NSString *strategyVersion;
@property (nonatomic, copy) NSString *settingsVersion;
@property (nonatomic, copy) NSString *engineVersion;
@end

@implementation TTVideoEngineSettings

+ (instancetype)settings {
    static dispatch_once_t onceToken;
    static TTVideoEngineSettings *_settings = nil;
    dispatch_once(&onceToken, ^{
        _settings = [[self alloc] init];
    });
    return _settings;
}

- (instancetype)init {
    if (self = [super init]) {
        _debug = NO;
        _enable = NO;
        _netClient = [[TTVideoEngineNetwork alloc] init];
    }
    return self;
}

+ (VodSettingsManager *)manager {
    return VodSettingsManager.shareSettings;
}

- (void)setDebug:(BOOL)debug {
    _debug = debug;
    [TTVideoEngineSettings.manager setDebug:debug];
}

- (TTVideoEngineSettings *(^)(BOOL))setDebug {
    return ^id(BOOL debug) {
        [self setDebug:debug];
        return self;
    };
}

- (TTVideoEngineSettings *(^)(BOOL))setEnable {
    return ^id(BOOL enable) {
        [self setEnable:enable];
        return self;
    };
}

- (TTVideoEngineSettings *(^)(id<TTVideoEngineNetClient>))setNetClient {
    return ^id(id<TTVideoEngineNetClient> netClient) {
        [self setNetClient:netClient];
        return self;
    };
}

- (void)setUsEast:(NSString *)usEast {
    _usEast = usEast;
    [[TTVideoEngineSettings manager].env setUsEast:usEast];
}

- (TTVideoEngineSettings *(^)(NSString *))setUSEast {
    return ^id(NSString *hostString) {
        [self setUsEast:hostString];
        return self;
    };
}

- (void)setSgSingapore:(NSString *)sgSingapore {
    _sgSingapore = sgSingapore;
    [[TTVideoEngineSettings manager].env setSgSingapore:sgSingapore];
}

- (TTVideoEngineSettings *(^)(NSString *))setSGSingapore {
    return ^id(NSString *hostString) {
        [self setSgSingapore:hostString];
        return self;
    };
}

- (void)setCnNorth:(NSString *)cnNorth {
    _cnNorth = cnNorth;
    [[TTVideoEngineSettings manager].env setCnNorth:cnNorth];
}

- (TTVideoEngineSettings *(^)(NSString *))setCNNorth {
    return ^id(NSString *hostString) {
        [self setCnNorth:hostString];
        return self;
    };
}

- (NSString *)engineVersion {
    if (!_engineVersion) {
        _engineVersion = [TTVideoEngine _engineVersionString];
    }
    return _engineVersion;
}

- (NSString *)playerVersion {
    if (!_playerVersion) {
        _playerVersion = [TTAVPlayer playerVersion];
    }
    return _playerVersion;
}

- (NSString *)mdlVersion {
    if (!_mdlVersion) {
        _mdlVersion = [TTVideoEngine _ls_getMDLVersion];
    }
    return _mdlVersion;
}

- (NSString *)strategyVersion {
    if (!_strategyVersion) {
        _strategyVersion = @""; /// TODO:
    }
    return _strategyVersion;
}

- (NSString *)settingsVersion {
    if (!_settingsVersion) {
        _settingsVersion = [VodSettingsManager versionString];
    }
    return _settingsVersion;;
}

- (TTVideoEngineSettings *(^)(void))config {
    return ^id{
        if (!self->_enable) {
            return self;
        }
        NSNumber *server = [TTVideoEngineAppInfo_Dict objectForKey:TTVideoEngineServiceVendor];
        if (server != nil) {
            VodSettingsRegion region = VodSettingsRegionCN;
            switch (server.integerValue) {
                case TTVideoEngineServiceVendorCN:
                    region = VodSettingsRegionCN;
                    break;
                case TTVideoEngineServiceVendorSG:
                    region = VodSettingsRegionSG;
                    break;
                case TTVideoEngineServiceVendorVA:
                    region = VodSettingsRegionUS;
                    break;
                default:
                    break;
            }
            
            [[TTVideoEngineSettings manager].env setRegion:region];
        }
        
        /// App info
        NSMutableDictionary *appInfo = [NSMutableDictionary dictionary];
        [appInfo setValue:TTVideoEngineAppInfo_Dict[TTVideoEngineAID] forKey:@"aid"];
        [appInfo setValue:TTVideoEngineAppInfo_Dict[TTVideoEngineAppName] forKey:@"app_name"];
        [appInfo setValue:TTVideoEngineAppInfo_Dict[TTVideoEngineDeviceId] forKey:@"device_id"];
        [appInfo setValue:TTVideoEngineAppInfo_Dict[TTVideoEngineChannel] forKey:@"app_channel"];
        [appInfo setValue:TTVideoEngineAppInfo_Dict[TTVideoEngineAppVersion] forKey:@"app_version"];
        [[TTVideoEngineSettings manager].env setAppInfo:appInfo];
        
        /// SDK info
        NSMutableDictionary *sdkInfo = [NSMutableDictionary dictionary];
        [sdkInfo setValue:self.engineVersion forKey:@"sdk_version"];
        [sdkInfo setValue:self.playerVersion forKey:@"player_version"];
        [sdkInfo setValue:self.mdlVersion forKey:@"mdl_version"];
        [sdkInfo setValue:self.strategyVersion forKey:@"st_version"];
        [sdkInfo setValue:self.settingsVersion forKey:@"settings_version"];
        [[TTVideoEngineSettings manager].env setSdkInfo:sdkInfo];
        return self;
    };
}

- (TTVideoEngineSettings *(^)(void))load {
    return  ^id {
        if (!self->_enable) {
            return self;
        }
        
        [TTVideoEngineSettings.manager setNetImp:(id<VodSettingsNetProtocol> _Nonnull)self];
        [TTVideoEngineSettings.manager loadLocal:YES];
        return self;
    };
}

/// MARK: - VodSettingsNetProtocol

- (void)start:(NSString *)urlString
      queries:(NSDictionary<NSString *, NSString *> *)queries
       result:(void(^)(NSError * _Nullable error, _Nullable id jsonObject)) result {
    [_netClient configTaskWithURL:[NSURL URLWithString:urlString]
                           params:queries
                          headers:nil
                       completion:^(id  _Nullable jsonObject, NSError * _Nullable error) {
        !result ?: result(error,jsonObject);
    }];
    ///  resume
    [_netClient resume];
}

- (void)cancel {
    [_netClient cancel];
}

@end

@implementation TTVideoEngineSettings (Get)

- (nullable NSNumber *)getVodNumber:(NSString *)key dValue:(nullable NSNumber *)dValue {
    if (!_enable) {
        return dValue;
    }
    return [VodSettingsManager.shareSettings getVodNumber:key dValue:dValue];
}

- (nullable NSString *)getVodString:(NSString *)key dValue:(nullable NSString *)dValue {
    if (!_enable) {
        return dValue;
    }
    return [VodSettingsManager.shareSettings getVodString:key dValue:dValue];
}

- (nullable NSDictionary *)getVodDict:(NSString *)key {
    if (!_enable) {
        return nil;
    }
    return [VodSettingsManager.shareSettings getVodDict:key];
}

- (nullable NSArray *)getVodArray:(NSString *)key dValue:(nullable NSArray *)dValue {
    if (!_enable) {
        return dValue;
    }
    return [VodSettingsManager.shareSettings getVodArray:key dValue:dValue];
}

- (nullable NSNumber *)getMDLNumber:(NSString *)key dValue:(nullable NSNumber *)dValue {
    if (!_enable) {
        return dValue;
    }
    return [VodSettingsManager.shareSettings getMDLNumber:key dValue:dValue];
}

- (nullable NSString *)getMDLString:(NSString *)key dValue:(nullable NSString *)dValue {
    if (!_enable) {
        return dValue;
    }
    return [VodSettingsManager.shareSettings getMDLString:key dValue:dValue];;
}

- (nullable NSDictionary *)getMDLDict:(NSString *)key {
    if (!_enable) {
        return nil;
    }
    return [VodSettingsManager.shareSettings getMDLDict:key];
}

- (nullable NSArray *)getMDLArray:(NSString *)key dValue:(nullable NSArray *)dValue {
    if (!_enable) {
        return dValue;
    }
    return [VodSettingsManager.shareSettings getMDLArray:key dValue:dValue];
}

- (nullable NSDictionary *)getJson:(NSInteger)module {
    if (!_enable) {
        return nil;
    }
    return [VodSettingsManager.shareSettings getJson:module];
}

@end

