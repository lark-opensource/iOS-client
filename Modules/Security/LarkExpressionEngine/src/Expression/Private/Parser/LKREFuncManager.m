//
//  LKREFuncManager.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREFuncManager.h"
#import "LKRENull.h"
#import "LKREParamMissing.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface LKREArrayFunc : LKREFunc
@end

@interface LKRETimestampFunc : LKREFunc
@end

@interface LKREIsNullFunc : LKREFunc
@end

@interface LKREIsExistedFunc : LKREFunc
@end

@implementation LKREArrayFunc

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"array";
        self.argsLength = NSIntegerMax;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of array func", NSStringFromSelector(_cmd)]}];
        return nil;
    }
    return params;
}

@end

@implementation LKRETimestampFunc

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"SecondsFromNow";
        self.argsLength = 1;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    NSError *err = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of SecondsFromNow func", NSStringFromSelector(_cmd)]}];
    if (params == nil) {
        *error = err;
        return nil;
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    }
    if (![params[0] isKindOfClass:[NSNumber class]]) {
        *error = err;
        return nil;
    }
    NSNumber *timestamp = params[0];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp.integerValue];
    return @((NSInteger)[[NSDate date] timeIntervalSinceDate:date]);
}

@end

@implementation LKREIsNullFunc

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"IsNull";
        self.argsLength = 1;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    NSError *err = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of IsNull func", NSStringFromSelector(_cmd)]}];
    if (params == nil || params.count != self.argsLength) {
        *error = err;
        return nil;
    }
    if ([params[0] isKindOfClass:[LKRENull class]]) {
        return [NSNumber numberWithBool:true];
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    }
    return [NSNumber numberWithBool:false];
}

@end

@implementation LKREIsExistedFunc

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"IsExisted";
        self.argsLength = 1;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    NSError *err = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of IsExisted func", NSStringFromSelector(_cmd)]}];
    if (params == nil || params.count != self.argsLength) {
        *error = err;
        return nil;
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]]) {
        return [NSNumber numberWithBool:false];
    }
    return [NSNumber numberWithBool:true];
}

@end

@interface LKREFuncManager ()

@property (nonatomic, strong) NSDictionary *functions;

@end

@implementation LKREFuncManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.functions = @{
            @"array"           : [[LKREArrayFunc alloc] init],
            @"SecondsFromNow"  : [[LKRETimestampFunc alloc] init],
            @"IsNull"          : [[LKREIsNullFunc alloc] init],
            @"IsExisted"       : [[LKREIsExistedFunc alloc] init]
        };
    }
    return self;
}

+ (LKREFuncManager *)sharedManager
{
    static LKREFuncManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (void)registerFunc:(LKREFunc *)func
{
    if (func) {
        NSMutableDictionary *functions = self.functions.mutableCopy;
        [functions btd_setObject:func forKey:func.symbol];
        self.functions = functions.copy;
    }
}

- (LKREFunc *)getFuncFromSymbol:(NSString *)symbol
{
    return [self.functions btd_objectForKey:symbol default:nil];
}

@end
