//
//  BDXGlobalContext.m
//  TTLynx
//
//  Created by LinFeng on 2021/4/20.
//

#import "BDXGlobalContext.h"
#import "BDXServiceDefines.h"
@interface BDXGlobalContext ()

@property(nonatomic, strong) NSMutableDictionary<NSString *, BDXContext *> *contextMap;

@end

@implementation BDXGlobalContext

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static BDXGlobalContext *_globalCtx;
    dispatch_once(&onceToken, ^{
        _globalCtx = [BDXGlobalContext new];
    });
    return _globalCtx;
}

- (instancetype)init
{
    if (self = [super init]) {
        _contextMap = [NSMutableDictionary dictionary];
    }
    return self;
}

#define BDX_GET_CONTEXT_(bid, create)                                                  \
    if (!bid) {                                                                        \
        bid = DEFAULT_SERVICE_BIZ_ID;                                                  \
    }                                                                                  \
    BDXContext *ctx = [[BDXGlobalContext sharedInstance].contextMap objectForKey:bid]; \
    if (!ctx && create) {                                                              \
        ctx = [[BDXContext alloc] init];                                               \
        [[BDXGlobalContext sharedInstance].contextMap setObject:ctx forKey:bid];       \
    }

+ (void)registerWeakObj:(nullable id)obj forType:(Class)aClass withBid:(nullable NSString *)bid
{
    BDX_GET_CONTEXT_(bid, YES)[ctx registerStrongObj:obj forType:aClass];
}

+ (void)registerStrongObj:(nullable id)obj forType:(Class)aClass withBid:(nullable NSString *)bid
{
    BDX_GET_CONTEXT_(bid, YES)[ctx registerStrongObj:obj forType:aClass];
}

+ (void)registerCopyObj:(nullable id<NSCopying>)obj forType:(Class)aClass withBid:(nullable NSString *)bid
{
    BDX_GET_CONTEXT_(bid, YES)[ctx registerCopyObj:obj forType:aClass];
}

+ (void)registerWeakObj:(nullable id)obj forKey:(NSString *)key withBid:(nullable NSString *)bid
{
    BDX_GET_CONTEXT_(bid, YES)[ctx registerWeakObj:obj forKey:key];
}

+ (void)registerStrongObj:(nullable id)obj forKey:(NSString *)key withBid:(nullable NSString *)bid
{
    BDX_GET_CONTEXT_(bid, YES)[ctx registerStrongObj:obj forKey:key];
}

+ (void)registerCopyObj:(nullable id<NSCopying>)obj forKey:(NSString *)key withBid:(nullable NSString *)bid
{
    BDX_GET_CONTEXT_(bid, YES)[ctx registerCopyObj:obj forKey:key];
}

+ (nullable id)getObjForType:(Class)aClass withBid:(nullable NSString *)bid
{
    BDX_GET_CONTEXT_(bid, NO)
    return [ctx getObjForType:aClass];
}

+ (nullable id)getObjForKey:(NSString *)key withBid:(nullable NSString *)bid
{
    BDX_GET_CONTEXT_(bid, NO)
    return [ctx getObjForKey:key];
}

+ (BOOL)isWeakObjForKey:(NSString *)key withBid:(nullable NSString *)bid
{
    BDX_GET_CONTEXT_(bid, NO)
    return [ctx isWeakObjForKey:key];
}

+ (BDXContext *)mergeContext:(BDXContext *)context withBid:(nullable NSString *)bid
{
    BDX_GET_CONTEXT_(bid, YES)
    BDXContext *globalCtx = ctx.copy;
    [globalCtx mergeContext:context];
    return globalCtx;
}

@end
