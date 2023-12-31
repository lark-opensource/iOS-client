//
//  BDREExprRunner.h
//  BDRuleEngine-Expression
//
//  Created by bytedance on 2021/12/9.
//

#import <Foundation/Foundation.h>
#import "BDRuleEngineLogger.h"
#import "BDREExprEnv.h"
#import "BDREFunc.h"
#import "BDREOperator.h"
#import "BDREExprConst.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREExprResponse : NSObject

@property (nonatomic, strong) id result;
@property (nonatomic, assign) NSInteger code;
@property (nonatomic, copy)   NSString *message;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) CFTimeInterval envCost;
@property (nonatomic, assign) CFTimeInterval execCost;
/// 是否命中解析缓存
@property (nonatomic, assign) BOOL parseHitCache;
/// 是否命中指令队列
@property (nonatomic, assign) BOOL ilHitCache;

- (NSDictionary *)jsonFormat;

@end

@interface BDREExprRunner : NSObject

+ (BDREExprRunner *)sharedRunner;

- (BDREExprResponse *)execute:(NSString *)exprStr
                      withEnv:(id<BDREExprEnv>)env;

- (BDREExprResponse *)execute:(NSString *)exprStr
                      withEnv:(id<BDREExprEnv>)env
                         uuid:(NSString *)uuid;

- (BDREExprResponse *)execute:(NSString *)exprStr
                  preCommands:(NSArray *)preCommands
                      withEnv:(id<BDREExprEnv>)env
                         uuid:(NSString *)uuid;

- (void)registerFunc:(BDREFunc *)func;
 
- (void)registerOperator:(BDREOperator *)oper;

/// 尝试从缓存中获取 commands 若失败则解析生成
- (nullable NSArray *)commandsFromExpr:(nonnull NSString *)exprStr;

@end


NS_ASSUME_NONNULL_END
