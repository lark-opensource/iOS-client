//
//  BDABTestSettingsAdapter.m
//  BDABTestSDK
//
//  Created by July22 on 2019/2/25.
//

#import "BDABTestSettingsAdapter.h"
#import "BDABTestManager+Cache.h"
#import "BDABTestManager+Private.h"

@implementation BDABTestSettingsAdapter

+ (void)load
{
    [self sharedInstance];
}

+ (instancetype)sharedInstance
{
    static BDABTestSettingsAdapter *sharedInst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [self new];
    });
    return sharedInst;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveABSettings:) name:@"TTKitchenRemoteSettingsDidReceiveNotification" object:nil];
    }
    return self;
}

- (void)didReceiveABSettings:(NSNotification *)notification
{
    NSDictionary *dic = notification.object;
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *data = [dic objectForKey:@"data"];
    if (![data isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *settings = [data objectForKey:@"settings"];
    if (![settings isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *vidInfo = [data objectForKey:@"vid_info"];
    if (![vidInfo isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSMutableDictionary *abDic = [NSMutableDictionary dictionaryWithCapacity:[vidInfo count]];
    for (NSString *key in vidInfo) {
        id value = [settings objectForKey:key];
        if (value) {
            [abDic setObject:@{@"val":value,@"vid":[vidInfo objectForKey:key]} forKey:key];
        }
    }
    [[BDABTestManager sharedManager] saveFetchedJsonData:abDic];
}

@end
