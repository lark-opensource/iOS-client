//
//  LKREExprParser.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREExprParser.h"
#import "LKREWordParser.h"
#import "LKREOperatorManager.h"
#import "LKREFuncManager.h"
#import "LKREExprGrammer.h"
#import "LKRECommand.h"

@interface LKREExprParser ()

@property (nonatomic, strong) LKREWordParser *LKREWordParser;

@end

@implementation LKREExprParser

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.LKREWordParser = [[LKREWordParser alloc] init];
    }
    return self;
}

- (NSArray *)parse:(NSString *)expr error:(NSError **)error
{
    NSArray *words = [self.LKREWordParser splitWord:expr error:error];        //分词
    if (*error) return nil;
    NSArray *nodes = [self.LKREWordParser parseWordToNode:words error:error]; //单词识别
    if (*error) return nil;
    return [LKREExprGrammer parseNodesToCommands:nodes error:error];          //语法解析
}

@end
