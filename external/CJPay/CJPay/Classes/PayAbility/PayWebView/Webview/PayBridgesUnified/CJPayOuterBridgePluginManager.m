//
//  CJPayOuterBridgePluginManager.m
//  CJPay
//
//  Created by liyu on 2020/1/17.
//

#import "CJPayOuterBridgePluginManager.h"
#import "CJPaySDKMacro.h"

@interface CJPayOuterBridgePluginManager ()

@property (nonatomic, strong) NSMutableDictionary *bridgeRegistry;

@end

@implementation CJPayOuterBridgePluginManager

+ (instancetype)shared
{
    static CJPayOuterBridgePluginManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CJPayOuterBridgePluginManager alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _bridgeRegistry = [[NSMutableDictionary alloc] initWithCapacity:4];
    }
    return self;
}

+ (void)registerOuterBridge:(id<CJPayOuterBridgeProtocol>)bridgeInstance forMethod:(NSString *)name
{
    if ([name length] == 0) {
        CJPayLogAssert(NO, @"注册方法名参数错误");
        return;
    }
    if (![bridgeInstance conformsToProtocol:@protocol(CJPayOuterBridgeProtocol)]) {
        CJPayLogAssert(NO, @"注册bridge对象错误");
        return;
    }
    
    NSMutableDictionary *bridgeDict = [CJPayOuterBridgePluginManager shared].bridgeRegistry;
    
    if (bridgeDict[name] != nil) {
        CJPayLogAssert(NO, @"重复注册");
        return;
    }
    
    bridgeDict[name] = bridgeInstance;
}

+ (id<CJPayOuterBridgeProtocol>)bridgeForMethod:(NSString *)name
{
    return  [CJPayOuterBridgePluginManager shared].bridgeRegistry[name];
}

@end
