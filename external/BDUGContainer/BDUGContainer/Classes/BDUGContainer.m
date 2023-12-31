//
//  BDUGContainer.m
//  Pods
//
//  Created by shuncheng on 2018/12/27.
//

#import "BDUGContainer.h"

typedef id(^BDUGContainerCodeBlock)(id);

@interface BDUGContainer ()

@property (nonatomic, strong) NSMutableDictionary *codes;

@end

@implementation BDUGContainer

+ (instancetype)sharedInstance
{
    static BDUGContainer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDUGContainer alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _codes = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return self;
}

- (void)setCode:(BDUGContainerCodeBlock)code forKey:(NSString *)key
{
    if (!code || !key.length) {
        return;
    }
    
    @synchronized (self) {
        self.codes[key] = [code copy];
    }
}

- (BDUGContainerCodeBlock)codeForKey:(NSString *)key
{
    @synchronized (self) {
        return [self.codes[key] copy];
    }
}

- (void)setClass:(Class)cls forProtocol:(Protocol *)protocol
{
    if (![cls conformsToProtocol:protocol]) {
        return;
    }
    
    BDUGContainerCodeBlock code = [self codeForKey:[BDUGContainer stringKeyForProtocol:protocol]];
    if (code) {
        return;
    }
    
    [self setCode:^id(id params){return cls;} forKey:[BDUGContainer stringKeyForProtocol:protocol]];
}

- (id)createObjectForProtocol:(Protocol *)protocol
{
    BDUGContainerCodeBlock code = [self codeForKey:[BDUGContainer stringKeyForProtocol:protocol]];
    if (!code) {
        NSAssert(NO, @"没建立class protocol映射?");
        return nil;
    }
    
    Class cls = code(nil);
    if (!cls) {
        NSAssert(NO, @"没建立class protocol映射?");
        return nil;
    }
    
    if ([cls respondsToSelector:@selector(sharedInstance)]) {
        return [cls sharedInstance];
    } else {
        return [[cls alloc] init];
    }
}

#pragma mark -- Helper

+ (NSString *)stringKeyForProtocol:(Protocol *)protocol
{
    return [NSString stringWithFormat:@"com.bytedance.user.growth.%@", NSStringFromProtocol(protocol)];
}

@end
