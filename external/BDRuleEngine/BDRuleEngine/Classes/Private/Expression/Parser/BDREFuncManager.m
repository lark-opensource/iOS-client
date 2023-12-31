//
//  BDREFuncManager.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREFuncManager.h"
#import "BDRENull.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <pthread/pthread.h>

@interface AddFunc : BDREFunc
@end

@interface ArrayFunc : BDREFunc
@end

@interface GetPropertyFunc : BDREFunc
@end

@interface LowcaseFunc : BDREFunc
@end

@interface UpcaseFunc : BDREFunc
@end

@interface VersionCompareFunc : BDREFunc
@end

@implementation AddFunc

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"add";
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    BOOL paramsInvalidate = NO;
    if (params.count < 2) {
        paramsInvalidate = YES;
    } else if (![params[0] isKindOfClass:[NSNumber class]] || ![params[1] isKindOfClass:[NSNumber class]]) {
        paramsInvalidate = YES;
    }
    if (paramsInvalidate) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    return @([params[0] doubleValue] + [params[1] doubleValue]);
}

@end

@implementation ArrayFunc

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"array";
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    return params;
}

@end

@implementation GetPropertyFunc

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"getProperty";
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    BOOL paramsInvalidate = NO;
    if (params.count < 2) {
        paramsInvalidate = YES;
    } else if (![params[0] isKindOfClass:[NSDictionary class]] || ![params[1] conformsToProtocol:@protocol(NSCopying)]) {
        paramsInvalidate = YES;
    }
    if (paramsInvalidate) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    NSDictionary *dict = params[0];
    id<NSCopying> key = params[1];
    id result = dict[key];
    return result ?: [BDRENull new];
}

@end

@implementation LowcaseFunc

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"lowcase";
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    BOOL paramsInvalidate = NO;
    if (params.count < 1) {
        paramsInvalidate = YES;
    } else if (![params[0] isKindOfClass:[NSString class]]) {
        paramsInvalidate = YES;
    }
    if (paramsInvalidate) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    NSString *string = params[0];
    return [string lowercaseString];
}

@end

@implementation UpcaseFunc

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"upcase";
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    BOOL paramsInvalidate = NO;
    if (params.count < 1) {
        paramsInvalidate = YES;
    } else if (![params[0] isKindOfClass:[NSString class]]) {
        paramsInvalidate = YES;
    }
    if (paramsInvalidate) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    NSString *string = params[0];
    return [string uppercaseString];
}

@end

@implementation VersionCompareFunc

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"version_compare";
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    BOOL paramsInvalidate = NO;
    if (params.count < 2) {
        paramsInvalidate = YES;
    } else if (![params[0] isKindOfClass:[NSString class]] || ![params[1] isKindOfClass:[NSString class]]) {
        paramsInvalidate = YES;
    }
    if (paramsInvalidate) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    NSComparisonResult res = [params[0] compare:params[1] options:NSNumericSearch];
    switch (res) {
        case NSOrderedDescending:
            return @(1);
        case NSOrderedSame:
            return @(0);
        case NSOrderedAscending:
            return @(-1);
    }
}

@end

@interface BDREFuncManager ()
{
    pthread_rwlock_t _lock;
}

@property (nonatomic, strong) NSMutableDictionary *functions;

@end

@implementation BDREFuncManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_rwlock_init(&_lock, NULL);
        self.functions = @{
            @"add"             : [[AddFunc alloc] init],
            @"array"           : [[ArrayFunc alloc] init],
            @"getProperty"     : [[GetPropertyFunc alloc] init],
            @"lowcase"         : [[LowcaseFunc alloc] init],
            @"upcase"          : [[UpcaseFunc alloc] init],
            @"version_compare" : [[VersionCompareFunc alloc] init]
        }.mutableCopy;
    }
    return self;
}

+ (BDREFuncManager *)sharedManager
{
    static BDREFuncManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (void)registerFunc:(BDREFunc *)func
{
    pthread_rwlock_wrlock(&_lock);
    [self.functions btd_setObject:func forKey:func.symbol];
    pthread_rwlock_unlock(&_lock);
}

- (BDREFunc *)getFuncFromSymbol:(NSString *)symbol
{
    pthread_rwlock_rdlock(&_lock);
    BDREFunc *func = [self.functions btd_objectForKey:symbol default:nil];
    pthread_rwlock_unlock(&_lock);
    return func;
}

@end
