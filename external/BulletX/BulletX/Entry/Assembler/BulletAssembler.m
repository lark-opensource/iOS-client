//
//  BulletAssembler.m
//  AFgzipRequestSerializer
//
//  Created by wangxiang on 2021/4/6.
//

#import "BulletAssembler.h"
#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import <BDXServiceCenter/BDXGlobalContext.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <Foundation/Foundation.h>

@implementation BulletAssembler

+ (instancetype)shareInstance
{
    static BulletAssembler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [BulletAssembler new];
    });

    return instance;
}

- (void)setup
{
    id<BDXLynxKitProtocol> lynxKitService = BDXSERVICE(BDXLynxKitProtocol, nil);
    if (!lynxKitService) {
        return;
    }

#if __has_include(<Lynx/LynxDebugger.h>)
  	[lynxKitService addDevtoolDelegate:self];
#endif

    [lynxKitService initLynxKit];
}

#if __has_include(<Lynx/LynxDebugger.h>)
- (BOOL)openDevtoolCard:(nonnull NSString *)url
{
    id<BDXRouterProtocol> routerService = BDXSERVICE_OBJECT_WITH_PROTOCOL(BDXRouterProtocol, nil);
    BDXContext *context = [[BDXContext alloc] init];
    [routerService openWithUrl:url context:context completion:^(id<BDXContainerProtocol> vc, NSError *err){
        // nothing
    }];
  	return YES;
}

- (BOOL)enableLynxDevtool:(NSURL *)url withOptions:(NSDictionary *)options
{
    id<BDXLynxKitProtocol> lynxKitService = BDXSERVICE(BDXLynxKitProtocol, nil);
    if (!lynxKitService || ![url.absoluteString hasPrefix:@"lynx://remote_debug_lynx/enable"]) {
        return FALSE;
    }
    return [lynxKitService enableLynxDevtool:url withOptions:options];
}
#endif

- (void)registerBridgeProvider:(Class)bridgeProvider withBid:(NSString *)bid;
{
    id bridgeClassArray = [BDXGlobalContext getObjForKey:kBDXContextKeyBridgeProviderClasses withBid:bid];
    if (!bridgeClassArray) {
        bridgeClassArray = [NSMutableArray new];
    } else {
        NSAssert([bridgeClassArray isKindOfClass:NSArray.class], @"kBDXContextKeyBridgeProviderClass should be an NSArray");
        bridgeClassArray = [bridgeClassArray mutableCopy];
    }
    [((NSMutableArray *)bridgeClassArray) addObject:bridgeProvider];
    [BDXGlobalContext registerStrongObj:[bridgeClassArray copy] forKey:kBDXContextKeyBridgeProviderClasses withBid:bid];
}

@end
