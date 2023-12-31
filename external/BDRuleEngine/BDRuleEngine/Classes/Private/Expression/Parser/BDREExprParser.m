//
//  BDREExprParser.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREExprParser.h"
#import "BDREWordParser.h"
#import "BDREOperatorManager.h"
#import "BDREFuncManager.h"
#import "BDREExprGrammer.h"
#import "BDRECommand.h"

@implementation BDREExprParser

+ (NSArray *)parse:(NSString *)expr error:(NSError *__autoreleasing  _Nullable *)error
{
    NSArray *words = [BDREWordParser splitWord:expr error:error];        //分词
    if (*error) return nil;
    NSArray *nodes = [BDREWordParser parseWordToNode:words error:error]; //单词识别
    if (*error) return nil;
    return [BDREExprGrammer parseNodesToCommands:nodes error:error];     //语法解析
}

@end
