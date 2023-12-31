//
//  BDPRuntimeGlobalConfiguration.m
//  Timor
//
//  Created by 王浩宇 on 2019/3/5.
//

#import "BDPRuntimeGlobalConfiguration.h"
#import <AVFoundation/AVFoundation.h>
#import "BDPScopeConfig.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>

@interface BDPRuntimeGlobalConfiguration ()
@property (nonatomic, assign) BOOL hasAssignedAudioSession;
@property (nonatomic, assign, readwrite) BOOL shouldNotUpdateSettingsData;
@property (nonatomic, assign, readwrite) BOOL shouldNotUpdateJSSDK;
@end

@implementation BDPRuntimeGlobalConfiguration

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
+ (instancetype)defaultConfiguration
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _maxWarmBootCacheCount = 5;
        _shouldDismissShareLoading = YES;
        _shouldAutoUpdateRelativeData = YES;
        //+load启动优化: 这两个属性之前在+load时机就被设置成YES,且没有其他地方再进行赋值,因此设置其默认值为YES;
        //这两个值是为了不拉取TT那边JSSDK和settings数据使用的;
        _shouldNotUpdateSettingsData = YES;
        _shouldNotUpdateJSSDK = YES;
        _scopeConfig = [BDPScopeConfig new];
        NSString *channel = [[[NSBundle mainBundle] infoDictionary] bdp_stringValueForKey:@"CHANNEL_NAME"];
        _debugVdomEnable = [channel isEqualToString:@"local_test"];
#if DEBUG
        _debugVdomEnable = YES;
#endif
    }
    return self;
}

- (instancetype)initWithConfiguration:(BDPRuntimeGlobalConfiguration *)configuration
{
    self = [super init];
    if (self) {
        if (configuration) {
            _maxWarmBootCacheCount = configuration.maxWarmBootCacheCount;
            _shouldDismissShareLoading = configuration.shouldDismissShareLoading;
            _shouldAutoUpdateRelativeData = configuration.shouldAutoUpdateRelativeData;
            _scopeConfig = configuration.scopeConfig;
            _debugVdomEnable = configuration.debugVdomEnable;
        }
    }
    return self;
}

#pragma mark - Variables Getters & Setters
/*-----------------------------------------------*/
//     Variables Getters & Setters - 变量相关
/*-----------------------------------------------*/
- (void)setMaxWarmBootCacheCount:(NSInteger)maxWarmBootCacheCount
{
    if (_maxWarmBootCacheCount != maxWarmBootCacheCount) {
        _maxWarmBootCacheCount = MIN(5, MAX(1, maxWarmBootCacheCount));
    }
}

@end
