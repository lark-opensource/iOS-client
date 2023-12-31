//
//  BDPTimorClient.m
//  Timor
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//
#import "BDPTimorClient.h"
#import <KVOController/KVOController.h>
#import "OPResolveDependenceUtil.h"

@interface BDPTimorClient ()

@property (nonatomic, strong) BDPRuntimeGlobalConfiguration *globalConfiguration;
@property (nonatomic, strong) BDPAppearanceConfiguration *appearanceConfiguration;
@property (nonatomic, assign) BOOL openURLEnabled;

@end


@implementation BDPTimorClient
+ (instancetype)sharedClient
{
    static BDPTimorClient *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[BDPTimorClient alloc] __init];
    });
    return client;
}

- (instancetype)__init
{
    self = [super init];
    if (self) {
        _openURLEnabled = YES;
        //这边改成懒加载
//        _globalConfiguration = [BDPRuntimeGlobalConfiguration defaultConfiguration];
//        _appearanceConfiguration = [BDPAppearanceConfiguration defaultConfiguration];
        //监听逻辑放在懒加载方法中执行
//        [self.KVOController observe:_globalConfiguration keyPath:@"maxWarmBootCacheCount" options:NSKeyValueObservingOptionNew action:@selector(onMaxBootCacheCountChanged:)];
    }
    return self;
}

- (void)setEnableOpenURL:(BOOL)enabled
{
    _openURLEnabled = enabled;
}

- (BOOL)isOpenURLEnabled
{
    return _openURLEnabled;
}

- (void)onMaxBootCacheCountChanged:(NSDictionary *)change
{
    NSInteger count = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
    // 迁移到Class<OPGadgetPluginDelegate> opGadgetPlugin 中实现，默认实现在OPGadgetPluginImpl.m
    // [[BDPWarmBootManager sharedManager] updateMaxWarmBootCacheCount:(int)count];
    [OPResolveDependenceUtil updateMaxWarmBootCacheCount:(int)count];
}


- (BDPRuntimeGlobalConfiguration *)globalConfiguration {
    if (!_globalConfiguration) {
        _globalConfiguration = [BDPRuntimeGlobalConfiguration defaultConfiguration];
        [self.KVOController observe:_globalConfiguration keyPath:@"maxWarmBootCacheCount" options:NSKeyValueObservingOptionNew action:@selector(onMaxBootCacheCountChanged:)];
    }
    return _globalConfiguration;
}

- (BDPAppearanceConfiguration *)appearanceConfiguration
{
    if (!_appearanceConfiguration) {
        _appearanceConfiguration = [BDPAppearanceConfiguration defaultConfiguration];
    }
    return _appearanceConfiguration;
}


- (BDPRuntimeGlobalConfiguration *)currentNativeGlobalConfiguration
{
    return self.globalConfiguration;
}

@end

#pragma mark - Appearance

@implementation BDPTimorClient (Appearance)

- (BDPAppearanceConfiguration *)appearanceConfg
{
    return self.appearanceConfiguration;
}

- (void)setAppearanceConfg:(BDPAppearanceConfiguration *)appearanceConfg
{
    [self setAppearanceConfiguration:appearanceConfg];
}

@end


