//
//  BDREOperatorManager.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREOperatorManager.h"
#import "BDREExprRunner.h"
#import "BDRENull.h"

#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface OrOperator : BDREOperator
@end

@interface AndOperator : BDREOperator
@end

@interface EQOperator : BDREOperator
@end

@interface NEQOperator : BDREOperator
@end

@interface GTOperator : BDREOperator
@end

@interface GEOperator : BDREOperator
@end

@interface LTOperator : BDREOperator
@end

@interface LEOperator : BDREOperator
@end

@interface AddOperator : BDREOperator
@end

@interface SubtractOperator : BDREOperator
@end

@interface MultiplyOperator : BDREOperator
@end

@interface DivideOperator : BDREOperator
@end

@interface ModOperator : BDREOperator
@end

@interface InOperator : BDREOperator
@end

@interface NotInOperator : BDREOperator
@end

@interface NotOperator : BDREOperator
@end

@interface IsIntersectOperator : BDREOperator
@end

@interface ContainsOperator : BDREOperator
@end

@interface StartwithOperator : BDREOperator
@end

@interface EndwithOperator : BDREOperator
@end

@interface MatchesOperator : BDREOperator
@end

@implementation OrOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    
    return [NSNumber numberWithBool:([params[0] boolValue] || [params[1] boolValue])];
}

@end

@implementation AndOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    
    return [NSNumber numberWithBool:([params[0] boolValue] && [params[1] boolValue])];
}

@end

@implementation EQOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    if ([params[0] isKindOfClass:[BDRENull class]] || [params[1] isKindOfClass:[BDRENull class]]) {
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

@implementation NEQOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    if ([params[0] isKindOfClass:[BDRENull class]] || [params[1] isKindOfClass:[BDRENull class]]) {
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

@implementation GTOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    return [NSNumber numberWithBool:([params[0] compare:params[1]] == NSOrderedDescending)];
}

@end

@implementation GEOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    return [NSNumber numberWithBool:([params[0] compare:params[1]] != NSOrderedAscending)];
}

@end

@implementation LTOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    return [NSNumber numberWithBool:([params[0] compare:params[1]] == NSOrderedAscending)];
}

@end

@implementation LEOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    return [NSNumber numberWithBool:([params[0] compare:params[1]] != NSOrderedDescending)];
}

@end

@implementation AddOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[NSNumber class]] && [params[1] isKindOfClass:[NSNumber class]]) {
        return @([params[0] doubleValue] + [params[1] doubleValue]);
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@implementation SubtractOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[NSNumber class]] && [params[1] isKindOfClass:[NSNumber class]]) {
        return @([params[0] doubleValue] - [params[1] doubleValue]);
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@implementation MultiplyOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[NSNumber class]] && [params[1] isKindOfClass:[NSNumber class]]) {
        return @([params[0] doubleValue] * [params[1] doubleValue]);
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@implementation DivideOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[NSNumber class]] && [params[1] isKindOfClass:[NSNumber class]]) {
        return @([params[0] doubleValue] / [params[1] doubleValue]);
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@implementation ModOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[0] isKindOfClass:[NSNumber class]] && [params[1] isKindOfClass:[NSNumber class]]) {
        return @([params[0] longValue] % [params[1] longValue]);
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@implementation InOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[1] isKindOfClass:[NSArray class]] || [params[1] isKindOfClass:[NSSet class]]) {
        return [NSNumber numberWithBool:([params[1] containsObject:params[0]])];
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@implementation NotInOperator : BDREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"out";
        self.priority = 700;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else if ([params[1] isKindOfClass:[NSArray class]] || [params[1] isKindOfClass:[NSSet class]]) {
        return [NSNumber numberWithBool:(![params[1] containsObject:params[0]])];
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@implementation NotOperator : BDREOperator

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

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
        if (error) {
            *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
        }
        return nil;
    }
    return [NSNumber numberWithBool:(![params[0] boolValue])];
}

@end

@implementation IsIntersectOperator : BDREOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"isIntersect";
        self.priority = 700;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else {
        BOOL firKeyIsAvailable = [params[0] isKindOfClass:[NSArray class]] || [params[0] isKindOfClass:[NSSet class]];
        BOOL secKeyIsAvailable = [params[1] isKindOfClass:[NSArray class]] || [params[1] isKindOfClass:[NSSet class]];
        if (firKeyIsAvailable && secKeyIsAvailable) {
            for (id obj in params[0]) {
                if ([params[1] containsObject:obj]) {
                    return @(YES);
                }
            }
            return @(NO);
        }
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@implementation ContainsOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"contains";
        self.priority = 700;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else {
        id firValue = params[0];
        id secValue = params[1];
        if ([firValue isKindOfClass:[NSString class]]) {
            if ([secValue isKindOfClass:[NSString class]]) {
                return @([(NSString *)firValue containsString:secValue]);
            } else if ([secValue isKindOfClass:[NSArray class]] || [secValue isKindOfClass:[NSSet class]]) {
                for (id obj in secValue) {
                    if ([obj isKindOfClass:[NSString class]] && [(NSString *)firValue containsString:obj]) {
                        return @(YES);
                    }
                }
                return @(NO);
            }
            return @(NO);
        }
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@implementation StartwithOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"startwith";
        self.priority = 700;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else {
        id firValue = params[0];
        id secValue = params[1];
        if ([firValue isKindOfClass:[NSString class]]) {
            if ([secValue isKindOfClass:[NSString class]]) {
                return @([(NSString *)firValue hasPrefix:secValue]);
            } else if ([secValue isKindOfClass:[NSArray class]] || [secValue isKindOfClass:[NSSet class]]) {
                for (id obj in secValue) {
                    if ([obj isKindOfClass:[NSString class]] && [(NSString *)firValue hasPrefix:obj]) {
                        return @(YES);
                    }
                }
                return @(NO);
            }
            return @(NO);
        }
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@implementation EndwithOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"endwith";
        self.priority = 700;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else {
        id firValue = params[0];
        id secValue = params[1];
        if ([firValue isKindOfClass:[NSString class]]) {
            if ([secValue isKindOfClass:[NSString class]]) {
                return @([(NSString *)firValue hasSuffix:secValue]);
            } else if ([secValue isKindOfClass:[NSArray class]] || [secValue isKindOfClass:[NSSet class]]) {
                for (id obj in secValue) {
                    if ([obj isKindOfClass:[NSString class]] && [(NSString *)firValue hasSuffix:obj]) {
                        return @(YES);
                    }
                }
                return @(NO);
            }
            return @(NO);
        }
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@implementation MatchesOperator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.symbol = @"matches";
        self.priority = 700;
        self.argsLength = 2;
    }
    return self;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    if (params == nil || params.count != self.argsLength) {
    } else {
        id firValue = params[0];
        id secValue = params[1];
        if ([firValue isKindOfClass:[NSString class]]) {
            if ([secValue isKindOfClass:[NSString class]]) {
                return @([(NSString *)firValue btd_matchsRegex:secValue]);
            } else if ([secValue isKindOfClass:[NSArray class]] || [secValue isKindOfClass:[NSSet class]]) {
                for (id obj in secValue) {
                    if ([obj isKindOfClass:[NSString class]] && [(NSString *)firValue btd_matchsRegex:obj]) {
                        return @(YES);
                    }
                }
                return @(NO);
            }
            return @(NO);
        }
    }
    if (error) {
        *error = [self paramsInvalidateErrorWithSelectorName:NSStringFromSelector(_cmd)];
    }
    return nil;
}

@end

@interface BDREOperatorManager ()

@property (nonatomic, strong) NSDictionary *operators;

@end

@implementation BDREOperatorManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.operators = @{
            @"+"           : [[AddOperator alloc] init],
            @"=="          : [[EQOperator alloc] init],
            @"!="          : [[NEQOperator alloc] init],
            @"-"           : [[SubtractOperator alloc] init],
            @"&&"          : [[AndOperator alloc] init],
            @"||"          : [[OrOperator alloc] init],
            @"<="          : [[LEOperator alloc] init],
            @"<"           : [[LTOperator alloc] init],
            @">="          : [[GEOperator alloc] init],
            @">"           : [[GTOperator alloc] init],
            @"!"           : [[NotOperator alloc] init],
            @"*"           : [[MultiplyOperator alloc] init],
            @"/"           : [[DivideOperator alloc] init],
            @"%"           : [[ModOperator alloc] init],
            @"out"         : [[NotInOperator alloc] init],
            @"in"          : [[InOperator alloc] init],
            @"isIntersect" : [[IsIntersectOperator alloc] init],
            @"contains"    : [[ContainsOperator alloc] init],
            @"startwith"   : [[StartwithOperator alloc] init],
            @"endwith"     : [[EndwithOperator alloc] init],
            @"matches"     : [[MatchesOperator alloc] init]
        };
    }
    return self;
}

+ (BDREOperatorManager *)sharedManager
{
    static BDREOperatorManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return  sharedManager;
}

- (BDREOperator *)getOperatorFromSymbol:(NSString *)symbol
{
    return [self.operators btd_objectForKey:symbol default:nil];
}

- (void)registerOperator:(BDREOperator *)op
{
    if (op) {
        NSMutableDictionary *operators = self.operators.mutableCopy;
        [operators btd_setObject:op forKey:op.symbol];
        self.operators = operators.copy;
    }
}

@end
