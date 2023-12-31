//
//  BDREFuncNode.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREFuncNode.h"

@interface BDREFuncNode ()

@property (nonatomic, strong, readwrite) BDREFunc *func;
@property (nonatomic, copy, readwrite) NSString *funcName;

@end

@implementation BDREFuncNode

- (instancetype)initWithFuncName:(NSString *)funcName func:(BDREFunc *)func originValue:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsBaseNode:originValue index:index];
    if (self) {
        self.func = func;
        self.funcName = funcName;
        self.priority = 1000;
    }
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[Expression] get stub func node : [%@], [%@], [%ld]", [self class], self.funcName, index];
    }];
    return self;
}

@end
