//
//  LKREOperatorManager.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREOperatorManager.h"
#import "LKREExprRunner.h"
#import "LKRENull.h"
#import "LKREParamMissing.h"

#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface LKREOrOperator : LKREOperator
@end

@interface LKREAndOperator : LKREOperator
@end

@interface LKREEQOperator : LKREOperator
@end

@interface LKRENEQOperator : LKREOperator
@end

@interface LKREGTOperator : LKREOperator
@end

@interface LKREGEOperator : LKREOperator
@end

@interface LKRELTOperator : LKREOperator
@end

@interface LKRELEOperator : LKREOperator
@end

@interface LKREAddOperator : LKREOperator
@end

@interface LKRESubtractOperator : LKREOperator
@end

@interface LKREMultiplyOperator : LKREOperator
@end

@interface LKREDivideOperator : LKREOperator
@end

@interface LKREModOperator : LKREOperator
@end

@interface LKREInOperator : LKREOperator
@end

@interface LKREHasInOperator : LKREOperator
@end

@interface LKRENotOperator : LKREOperator
@end

@implementation LKREOrOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"||";
        self.priority = 300;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of ||", NSStringFromSelector(_cmd)]}];
        return nil;
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]] && [params[1] isKindOfClass:[LKREParamMissing class]]){
        return [LKREParamMissing new];
    } else if ([params[1] isKindOfClass:[LKREParamMissing class]]){
        if ([params[0] boolValue]) {
            return [NSNumber numberWithBool:true];
        }
        return [LKREParamMissing new];
    } else if ([params[0] isKindOfClass:[LKREParamMissing class]]){
        if ([params[1] boolValue]) {
            return [NSNumber numberWithBool:true];
        }
        return [LKREParamMissing new];
    }
    
    return [NSNumber numberWithBool:([params[0] boolValue] || [params[1] boolValue])];
}

@end

@implementation LKREAndOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"&&";
        self.priority = 300;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of &&", NSStringFromSelector(_cmd)]}];
        return nil;
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]] && [params[1] isKindOfClass:[LKREParamMissing class]]){
        return [LKREParamMissing new];
    } else if ([params[1] isKindOfClass:[LKREParamMissing class]]){
        if (![params[0] boolValue]) {
            return [NSNumber numberWithBool:false];
        }
        return [LKREParamMissing new];
    } else if ([params[0] isKindOfClass:[LKREParamMissing class]]){
        if (![params[1] boolValue]) {
            return [NSNumber numberWithBool:false];
        }
        return [LKREParamMissing new];
    }
    
    return [NSNumber numberWithBool:([params[0] boolValue] && [params[1] boolValue])];
}
@end

@implementation LKREEQOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"==";
        self.priority = 400;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of ==", NSStringFromSelector(_cmd)]}];
        return nil;
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    }
    if ([params[0] isKindOfClass:[LKRENull class]] || [params[1] isKindOfClass:[LKRENull class]]) {
        // isEqual: is already overrided
        if ([params[0] isEqual:params[1]]) {
            return [NSNumber numberWithBool:true];
        } else {
            return [NSNumber numberWithBool:false];
        }
    }
    if ([params[0] isKindOfClass:[NSArray class]] || [params[1] isKindOfClass:[NSArray class]]) {
        if ([params[0] isKindOfClass:[NSArray class]] && [params[1] isKindOfClass:[NSArray class]]) {
            NSArray *arr0 = params[0];
            NSArray *arr1 = params[1];
            if ([arr0 isEqualToArray:arr1]) return [NSNumber numberWithBool:true];
            return [NSNumber numberWithBool:false];
        }
        return [NSNumber numberWithBool:false];
    }
    if ([params[0] isKindOfClass:[NSSet class]] || [params[1] isKindOfClass:[NSSet class]]) {
        if ([params[0] isKindOfClass:[NSSet class]] && [params[1] isKindOfClass:[NSSet class]]) {
            NSSet *set0 = params[0];
            NSSet *set1 = params[1];
            if ([set0 isEqualToSet:set1]) return [NSNumber numberWithBool:true];
            return [NSNumber numberWithBool:false];
        }
        return [NSNumber numberWithBool:false];
    }
    return [NSNumber numberWithBool:([params[0] compare:params[1]] == NSOrderedSame)];
}

@end

@implementation LKRENEQOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"!=";
        self.priority = 400;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of !=", NSStringFromSelector(_cmd)]}];
        return nil;
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    }
    if ([params[0] isKindOfClass:[LKRENull class]] || [params[1] isKindOfClass:[LKRENull class]]) {
        // isEqual: is already overrided
        if ([params[0] isEqual:params[1]]) {
            return [NSNumber numberWithBool:false];
        } else {
            return [NSNumber numberWithBool:true];
        }
    }
    if ([params[0] isKindOfClass:[NSArray class]] || [params[1] isKindOfClass:[NSArray class]]) {
        if ([params[0] isKindOfClass:[NSArray class]] && [params[1] isKindOfClass:[NSArray class]]) {
            NSSet *set0 = [NSSet setWithArray:params[0]];
            NSSet *set1 = [NSSet setWithArray:params[1]];
            if ([set0 isEqualToSet:set1]) return [NSNumber numberWithBool:false];
            return [NSNumber numberWithBool:true];
        }
        return [NSNumber numberWithBool:true];
    }
    if ([params[0] isKindOfClass:[NSSet class]] || [params[1] isKindOfClass:[NSSet class]]) {
        if ([params[0] isKindOfClass:[NSSet class]] && [params[1] isKindOfClass:[NSSet class]]) {
            NSSet *set0 = params[0];
            NSSet *set1 = params[1];
            if ([set0 isEqualToSet:set1]) return [NSNumber numberWithBool:false];
            return [NSNumber numberWithBool:true];
        }
        return [NSNumber numberWithBool:true];
    }
    
    return [NSNumber numberWithBool:([params[0] compare:params[1]] != NSOrderedSame)];
}

@end

@implementation LKREGTOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @">";
        self.priority = 500;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of >", NSStringFromSelector(_cmd)]}];
        return nil;
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    }
    return [NSNumber numberWithBool:([params[0] compare:params[1]] == NSOrderedDescending)];
}

@end

@implementation LKREGEOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @">=";
        self.priority = 500;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of >=", NSStringFromSelector(_cmd)]}];
        return nil;
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    }
    return [NSNumber numberWithBool:([params[0] compare:params[1]] != NSOrderedAscending)];
}

@end

@implementation LKRELTOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"<";
        self.priority = 500;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of <", NSStringFromSelector(_cmd)]}];
        return nil;
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    }
    return [NSNumber numberWithBool:([params[0] compare:params[1]] == NSOrderedAscending)];
}

@end

@implementation LKRELEOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"<=";
        self.priority = 500;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of <=", NSStringFromSelector(_cmd)]}];
        return nil;
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    }
    return [NSNumber numberWithBool:([params[0] compare:params[1]] != NSOrderedDescending)];
}

@end

@implementation LKREAddOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"+";
        self.priority = 600;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    } else if ([params[0] isKindOfClass:[NSNumber class]] && [params[1] isKindOfClass:[NSNumber class]]) {
        return @([params[0] doubleValue] + [params[1] doubleValue]);
    }
    *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of +", NSStringFromSelector(_cmd)]}];
    return @(-1);
}

@end

@implementation LKRESubtractOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"-";
        self.priority = 600;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    } else if ([params[0] isKindOfClass:[NSNumber class]] && [params[1] isKindOfClass:[NSNumber class]]) {
        return @([params[0] doubleValue] - [params[1] doubleValue]);
    }
    *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of -", NSStringFromSelector(_cmd)]}];
    return @(-1);
}

@end

@implementation LKREMultiplyOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"*";
        self.priority = 700;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[NSNumber class]] && [params[1] isKindOfClass:[NSNumber class]]) {
        return @([params[0] doubleValue] * [params[1] doubleValue]);
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    }
    *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of *", NSStringFromSelector(_cmd)]}];
    return @(-1);
}

@end

@implementation LKREDivideOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"/";
        self.priority = 700;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    } else if ([params[0] isKindOfClass:[NSNumber class]] && [params[1] isKindOfClass:[NSNumber class]]) {
        NSNumber *ret = @([params[0] doubleValue] / [params[1] doubleValue]);
        if (isnan(ret.doubleValue)) {
            *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of / , unexpect result for nan", NSStringFromSelector(_cmd)]}];
            return @(-1);
        }
        return ret;
    }
    *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of /", NSStringFromSelector(_cmd)]}];
    return @(-1);
}

@end

@implementation LKREModOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"%";
        self.priority = 700;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    } else if ([params[0] isKindOfClass:[NSNumber class]] && [params[1] isKindOfClass:[NSNumber class]]) {
        return @([params[0] longValue] % [params[1] longValue]);
    }
    *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of %%", NSStringFromSelector(_cmd)]}];
    return @(-1);
}

@end

@implementation LKREInOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"in";
        self.priority = 700;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    } else if ([params[1] isKindOfClass:[NSArray class]]) {
        if (![params[1] containsObject:params[0]]) {
            for (id element in params[1]) {
                if ([element isKindOfClass:[LKREParamMissing class]]) {
                    return [LKREParamMissing new];
                }
            }
        }
        return [NSNumber numberWithBool:([params[1] containsObject:params[0]])];
    }
    *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of in", NSStringFromSelector(_cmd)]}];
    return @(-1);
}

@end

@implementation LKREHasInOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"hasIn";
        self.priority = 700;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[LKREParamMissing class]] || [params[1] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    } else if ([params[1] isKindOfClass:[NSArray class]]) {
        if ([params[0] isKindOfClass:[NSArray class]]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY SELF IN %@", params[1]];
            if ([predicate evaluateWithObject:params[0]]) {
                return @(YES);
            }
            for (id obj in params[0]) {
                if ([obj isKindOfClass:[LKREParamMissing class]]) {
                    return [LKREParamMissing new];
                }
            }
            for (id obj in params[1]) {
                if ([obj isKindOfClass:[LKREParamMissing class]]) {
                    return [LKREParamMissing new];
                }
            }
            return @(NO);
        } else {
            if (![params[1] containsObject:params[0]]) {
                for (id obj in params[1]) {
                    if ([obj isKindOfClass:[LKREParamMissing class]]) {
                        return [LKREParamMissing new];
                    }
                }
            }
            return [NSNumber numberWithBool:([params[1] containsObject:params[0]])];
        }
    }
    *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of in", NSStringFromSelector(_cmd)]}];
    return @(-1);
}

@end

@implementation LKRENotOperator : LKREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"!";
        self.priority = 600;
        self.argsLength = 1;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError **)error
{
    if (params == nil || params.count != self.argsLength) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_PARAMS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | params invalid of !", NSStringFromSelector(_cmd)]}];
        return nil;
    }
    if ([params[0] isKindOfClass:[LKREParamMissing class]]) {
        return [LKREParamMissing new];
    }
    return [NSNumber numberWithBool:(![params[0] boolValue])];
}

@end

@interface LKREOperatorManager ()

@property (nonatomic, strong) NSDictionary *operators;

@end

@implementation LKREOperatorManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.operators = @{
            @"+"           : [[LKREAddOperator alloc] init],
            @"=="          : [[LKREEQOperator alloc] init],
            @"!="          : [[LKRENEQOperator alloc] init],
            @"-"           : [[LKRESubtractOperator alloc] init],
            @"&&"          : [[LKREAndOperator alloc] init],
            @"||"          : [[LKREOrOperator alloc] init],
            @"<="          : [[LKRELEOperator alloc] init],
            @"<"           : [[LKRELTOperator alloc] init],
            @">="          : [[LKREGEOperator alloc] init],
            @">"           : [[LKREGTOperator alloc] init],
            @"!"           : [[LKRENotOperator alloc] init],
            @"*"           : [[LKREMultiplyOperator alloc] init],
            @"/"           : [[LKREDivideOperator alloc] init],
            @"%"           : [[LKREModOperator alloc] init],
            @"in"          : [[LKREInOperator alloc] init],
            @"hasIn"       : [[LKREHasInOperator alloc] init],
        };
    }
    return self;
}

+ (LKREOperatorManager *)sharedManager
{
    static LKREOperatorManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return  sharedManager;
}

- (LKREOperator *)getOperatorFromSymbol:(NSString *)symbol
{
    return [self.operators btd_objectForKey:symbol default:nil];
}

- (void)registerOperator:(LKREOperator *)op
{
    if (op) {
        NSMutableDictionary *operators = self.operators.mutableCopy;
        [operators btd_setObject:op forKey:op.symbol];
        self.operators = operators.copy;
    }
}

@end
