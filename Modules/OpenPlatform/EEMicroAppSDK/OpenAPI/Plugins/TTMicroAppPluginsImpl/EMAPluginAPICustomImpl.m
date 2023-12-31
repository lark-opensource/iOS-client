//
//  EMAPluginAPICustomImpl.m
//  EEMicroAppSDK
//
//  Created by lixiaorui on 2020/12/25.
//

#import "EMAPluginAPICustomImpl.h"
#import <OPFoundation/OPAPIFeatureConfig.h>
#import <OPFoundation/BDPBundle.h>
#import "EMAAppEngine.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/BDPLog.h>
#import <LarkStorage/LarkStorage-Swift.h>

@interface EMAPluginAPICustomImpl()
@property (nonatomic, copy) NSDictionary *localAPICommandConfig;
@end

@implementation EMAPluginAPICustomImpl

+ (id<BDPBasePluginDelegate>)sharedPlugin {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSDictionary *)bdp_getAPIDispatchConfig {
    return [EMAAppEngine.currentEngine.onlineConfig apiDispatchConfig];
}

- (OPAPIFeatureConfig *)bdp_getAPIDispatchConfig:(NSDictionary *)config forAppType:(OPAppType)appType apiName:(NSString *)apiName {
    OPAPIFeatureConfig *apiConfig = [EMAAppEngine.currentEngine.onlineConfig apiIDispatchConfig:config forAppType:appType apiName:apiName];
    //当用户切换租户的时候currentEngine会被释放，因此可能会获取到一个空的config，而这个接口设计是返回一个非空值；
    //当获取到config为nil时，返回默认的OPAPIFeatureConfig对象;
    if (apiConfig.apiCommand == OPAPIFeatureCommandUnknown) {
        apiConfig = [self getLocalAPIFeatureConfigForApiName:apiName];
    }
    return apiConfig ? : [[OPAPIFeatureConfig alloc] initWithCommandString:@""];
}

// 获取local api 配置信息
- (OPAPIFeatureConfig *)getLocalAPIFeatureConfigForApiName:(NSString *)apiName {
    if (!_localAPICommandConfig) {
        NSString *resource = [[BDPBundle mainBundle] pathForResource:@"PluginAPICommand" ofType:@"plist"];
        if (BDPIsEmptyString(resource)) {
            BDPLogWarn(@"get local api command fail, path is nil");
            return [[OPAPIFeatureConfig alloc] initWithCommandString:@""];
        }
        NSURL *resourceURL = [NSURL fileURLWithPath:resource];

        NSError *error;
        NSDictionary *universalAPIConfig = [NSDictionary lss_dictionaryWithContentsOfURL:resourceURL error:&error];
        if (error) {
            BDPLogWarn(@"get local api command fail %@", error);
            return [[OPAPIFeatureConfig alloc] initWithCommandString:@""];
        }
        _localAPICommandConfig = universalAPIConfig;
    }
    NSDictionary *apiCommandList = [_localAPICommandConfig bdp_dictionaryValueForKey:@"api"];
    NSString *apiConfig = [apiCommandList bdp_stringValueForKey:apiName];
    return [[OPAPIFeatureConfig alloc] initWithCommandString:apiConfig];
}

@end
