//
//  LKREExprRunner.h
//  LKRuleEngine-Expression
//
//  Created by bytedance on 2021/12/9.
//

#import <Foundation/Foundation.h>
//#import "LKRuleEngineMacroDefines.h"
#import "LKREExprEnv.h"
#import "LKREFunc.h"
#import "LKREOperator.h"
#import "LKREExprConst.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREExprResponse : NSObject

// TODO: 这里是否要加上数据类型？
@property (nonatomic, strong) id result;
@property (nonatomic, assign) NSUInteger code;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) CFTimeInterval envCost;
@property (nonatomic, assign) CFTimeInterval execCost;
@property (nonatomic, assign) CFTimeInterval parseCost;
/// 是否命中解析缓存
@property (nonatomic, assign) BOOL parseHitCache;
/// 是否命中指令队列
@property (nonatomic, assign) BOOL ilHitCache;


- (NSDictionary *)jsonFormat;

@end

@interface LKREExprRunner : NSObject

+ (LKREExprRunner *)sharedRunner;

- (LKREExprResponse *)execute:(NSString *)exprStr
                      withEnv:(id<LKREExprEnv>)env;

- (LKREExprResponse *)execute:(NSString *)exprStr
                      withEnv:(id<LKREExprEnv>)env
                         uuid:(NSString * _Nullable)uuid;

- (LKREExprResponse *)execute:(NSString *)exprStr
                  preCommands:(NSArray * _Nullable)preCommands
                      withEnv:(id<LKREExprEnv>)env
                         uuid:(NSString * _Nullable)uuid;

- (LKREExprResponse *)execute:(NSString *)exprStr
                  preCommands:(NSArray * _Nullable)preCommands
                      withEnv:(id<LKREExprEnv>)env
                         uuid:(NSString * _Nullable)uuid
                 disableCache:(BOOL)disableCache;

- (void)registerFunc:(LKREFunc *)func;

- (void)registerOperator:(LKREOperator *)oper;

- (NSArray *)commandsWithPreCache:(NSString *)exprStr;

@end


NS_ASSUME_NONNULL_END
